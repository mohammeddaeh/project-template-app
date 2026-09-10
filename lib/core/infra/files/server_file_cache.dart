import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:app_template/core/foundation/contracts/account_scoped_store.dart';
import 'package:app_template/core/foundation/contracts/network_origin.dart';
import 'package:app_template/core/foundation/utils/inline_file_data.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// ماذا آل إليه طلبُ ملفّ — **أربعةُ أجوبةٍ لا جوابان**.
///
/// «لم ينزل» وحدها لا تكفي الشاشة: مَن لا اتصالَ له يُقال له «غير متوفّر دون
/// اتصال» فينتظر، ومَن ذهب ملفُّه من الخادم يُقال له غيرُ ذلك — ورسالةٌ واحدة
/// للحالتين تُرسل الموظّف يعيد المحاولة أبداً حيث لا محاولةَ تُجدي.
enum ServerFileOutcome {
  /// البايتات بالجهاز — من المخزن أو نزلت الآن.
  ok,

  /// لم يغادر الطلبُ الجهازَ أصلاً — راجع `InternetCheckerInterceptor`.
  offline,

  /// ردّ الخادم `404`: المسارُ الذي بالصفّ لا ملفَّ له عنده.
  notFound,

  /// كلُّ ما عداها — خطأُ خادمٍ أو ردٌّ بلا بايتات.
  failed,
}

/// نتيجةُ [ServerFileCache.fetch] — الملفُّ وسببُ غيابه معاً.
typedef ServerFileFetch = ({File? file, ServerFileOutcome outcome});

/// **ملفّاتُ الخادم على هذا الجهاز** — تنزيلٌ مرّةً، وقراءةٌ بعدها بلا شبكة.
///
/// ## النقطة، وما كان قبلها
///
/// حقولُ الملفّات تنزل **مسارَ تخزينٍ لا رابطاً**
/// (`storage\files\1787…png`)، ولم تكن بالعقد نقطةُ تنزيل — فكان الجهاز يعرض
/// اسمَ الملفّ ولا يفتحه: صورةُ الهوية التي رفعها زميلٌ من جهازٍ آخر، وعقدُ
/// الإيجار الذي عليه مدارُ قسم الاستثمار، كلاهما سطرٌ يُقرأ ولا يُرى
/// (`readme/16_UNITS_CONTRACT.md` §٣).
///
/// و[ApiUrls.files] هي الجواب: `GET /api/v1/files?path=<المسار كما نزل>`
/// بتوكن، فتردّ البايتات.
///
/// ## ولماذا مخزنٌ لا نداءٌ مباشر
///
/// | | |
/// |---|---|
/// | **مدخلان لا ثالث** | ضغطةُ المستخدم ([NetworkOrigin.userFile])، و**طورُ التنزيل المسبق** بدورة المزامنة (`MediaPrefetchManager` — على Wi‑Fi وحده افتراضاً). **ولا شيء ينزل بفتحِ شاشة**: المصغَّرةُ تعرض ما بالمخزن وسحابةً لما سواه |
/// | **مرّةً واحدة** | ما نزل يُكتب بالتخزين الخاصّ باسم بصمةِ مساره، فالفتحةُ الثانية بلا شبكة — وهي حالُ الميدان |
/// | **نداءٌ واحد للمسار الواحد** | مصغَّرةٌ ومعاينةٌ تُبنيان معاً لنفس الصورة، و[_inFlight] تجعلهما طلباً واحداً |
/// | **يُمحى مع الحساب** | صورُ موظّفٍ لا تبقى لمن يستلم جهازَه — [AccountScopedStore] |
///
/// ## والامتدادُ يُحفظ باسم الملفّ عمداً
///
/// `AttachmentFileStore` بموديول المزامنة معنونٌ بالمحتوى **وبلا امتداد**،
/// فيُنسخ منه كلُّ ملفٍّ إلى المؤقّت قبل تسليمه لتطبيق النظام (أندرويد يستنتج
/// النوع من الامتداد وحده). وهنا يُؤخذ الامتدادُ من المسار نفسه —
/// `…image.png` — فيُسلَّم الملفُّ كما هو بلا نسخةٍ ثانية.
@lazySingleton
class ServerFileCache implements AccountScopedStore {
  ServerFileCache(this._dio) {
    // لا شبكةَ هنا: مجرّدُ حلٍّ لمسار المجلَّد، كي تعرف المصغَّراتُ من أوّل
    // إطارٍ ما نزل بجلسةٍ سابقة. وبلاه تبقى السحابةُ مرسومةً فوق ملفٍّ بالقرص
    // حتى يضغطه أحد.
    unawaited(_ensureRoot());
  }

  final Dio _dio;

  static const _tag = 'SERVER-FILES';
  static const _dirName = 'server_files';

  /// يرتفع كلّما نزل ملفٌّ أو مُحي المخزن — تسمعه المصغَّرات فتُعيد السؤال.
  ///
  /// ودفترٌ واحد لا بثٌّ لكل مسار: الشاشةُ قد تعرض ستَّ صور، وستةُ مبثّاتٍ
  /// ثمنُها أكثر من إعادةِ فحصٍ لخريطةٍ بالذاكرة.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  final Map<String, File> _ready = <String, File>{};
  final Map<String, Future<ServerFileFetch>> _inFlight =
      <String, Future<ServerFileFetch>>{};

  Directory? _root;

  /// **هل هذا الملفّ بالجهاز الآن؟** — جوابٌ فوريّ بلا شبكة ولا `await`.
  ///
  /// تُنادى من `build`، فلا تلمس القرص إلا بأوّل سؤالٍ عن كل مسار.
  File? cached(String? serverPath) {
    final path = serverPath?.trim() ?? '';
    if (path.isEmpty) return null;

    final key = _keyFor(path);
    final known = _ready[key];
    if (known != null) {
      if (known.existsSync()) return known;
      _ready.remove(key);
    }

    final root = _root;
    if (root == null) return null;
    final file = File(p.join(root.path, key));
    if (!file.existsSync() || file.lengthSync() == 0) return null;
    _ready[key] = file;
    return file;
  }

  /// **مساراتٌ ردّ الخادمُ عنها 404** — لا يُعاد سؤالها.
  ///
  /// وُجدت لطور التنزيل المسبق (`MediaPrefetchManager`): ذاك يمرّ على جرد
  /// المسارات **بكل دورة**، ومسارٌ بصفٍّ لا ملفَّ له عند الخادم كان سيُطلب
  /// أبداً — نداءٌ مضمونُ الإخفاق يتكرّر ما دام الصفُّ على الجهاز.
  ///
  /// وبالذاكرة لا بالقرص: الغيابُ قد يكون خطأً مؤقّتاً بالخادم، وإقلاعةٌ
  /// جديدة تستحقّ سؤالاً جديداً. **ويُمحى مع الحساب** كسائر ما هنا.
  final Set<String> _gone = <String>{};

  /// هل سبق أن قال الخادمُ إن هذا المسار لا ملفَّ له؟
  bool isGone(String? serverPath) => _gone.contains(serverPath?.trim() ?? '');

  /// ينزّل الملفّ إن لم يكن بالجهاز — **وبفعلٍ من المستخدم أو بطور التنزيل
  /// المسبق بدورة المزامنة، ولا ثالثَ لهما**.
  Future<ServerFileFetch> fetch(String? serverPath) async {
    final path = serverPath?.trim() ?? '';
    if (path.isEmpty) {
      return (file: null, outcome: ServerFileOutcome.failed);
    }

    final hit = cached(path);
    if (hit != null) return (file: hit, outcome: ServerFileOutcome.ok);

    final key = _keyFor(path);
    final running = _inFlight[key];
    if (running != null) return running;

    final job = _download(path, key);
    _inFlight[key] = job;
    try {
      return await job;
    } finally {
      _inFlight.remove(key);
    }
  }

  @override
  Future<void> clearForAccount() async {
    _ready.clear();
    _gone.clear();
    final root = _root;
    if (root != null && root.existsSync()) {
      await root.delete(recursive: true);
      await root.create(recursive: true);
    }
    revision.value++;
  }

  // ── التنزيل ───────────────────────────────────────────────────────────────

  Future<ServerFileFetch> _download(String serverPath, String key) async {
    final root = await _ensureRoot();
    if (root == null) return (file: null, outcome: ServerFileOutcome.failed);

    // نزل بجلسةٍ سابقة، والمجلَّد لم يكن محلولاً حين سُئلت [cached].
    final target = File(p.join(root.path, key));
    if (target.existsSync() && target.lengthSync() > 0) {
      return (file: _remember(key, target), outcome: ServerFileOutcome.ok);
    }

    // **والمنطقةُ وسمُ المنفذ**: بلاها يصرخ `NetworkOriginInterceptor` بحقّ —
    // طلبٌ خرج من شاشة. وهذا هو المنفذ الرابع بعينه: مرفقٌ طلبه المستخدم.
    // **والوسمُ يُورَّث إن وُجد**: نفسُ الدالّة تخدم ضغطةَ المستخدم وطورَ
    // التنزيل المسبق بدورة المزامنة — ووسمُ `userFile` بالثاني يكذب.
    final origin = NetworkOrigin.current ?? NetworkOrigin.userFile;
    return NetworkOrigin.run(origin, () async {
      try {
        var response = await _get(serverPath);

        // المسارُ ينزل بشرطاتٍ خلفية (`storage\files\…`) ويُرسَل كما نزل. فإن
        // كان الخادمُ ينتظر الأمامية كشفتها محاولةٌ ثانيةٌ واحدة — ولا ثالثة.
        if (response.statusCode == 404 && serverPath.contains(r'\')) {
          response = await _get(serverPath.replaceAll(r'\', '/'));
        }

        final status = response.statusCode ?? 0;
        if (status == 404) {
          LogService.warning(
            'الخادم لا يعرف الملفّ "$serverPath" (404).',
            tag: _tag,
          );
          _gone.add(serverPath);
          return (file: null, outcome: ServerFileOutcome.notFound);
        }
        if (status != 200) {
          LogService.warning('تنزيلُ "$serverPath" ردّ $status.', tag: _tag);
          return (file: null, outcome: ServerFileOutcome.failed);
        }

        final bytes = _bytesOf(response);
        if (bytes == null || bytes.isEmpty) {
          LogService.warning(
            'ردُّ "$serverPath" وصل بلا بايتات (content-type: '
            '${response.headers.value(Headers.contentTypeHeader)}).',
            tag: _tag,
          );
          return (file: null, outcome: ServerFileOutcome.failed);
        }

        await target.writeAsBytes(bytes, flush: true);
        LogService.info('نزل "$serverPath" — ${bytes.length} بايت.', tag: _tag);
        return (file: _remember(key, target), outcome: ServerFileOutcome.ok);
      } on DioException catch (error) {
        final offline =
            error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.error is SocketException;
        LogService.warning(
          'تعذّر تنزيل "$serverPath": ${error.type}',
          tag: _tag,
        );
        if (offline) return (file: null, outcome: ServerFileOutcome.offline);
        return (
          file: null,
          outcome: error.response?.statusCode == 404
              ? ServerFileOutcome.notFound
              : ServerFileOutcome.failed,
        );
      } catch (error, stackTrace) {
        LogService.error(
          'تعذّر حفظ "$serverPath" على الجهاز.',
          tag: _tag,
          error: error,
          stackTrace: stackTrace,
        );
        return (file: null, outcome: ServerFileOutcome.failed);
      }
    });
  }

  Future<Response<dynamic>> _get(String serverPath) => _dio.get<dynamic>(
    '${Env.baseUrl.replaceAll(RegExp(r'/+$'), '')}${ApiUrls.files}',
    queryParameters: <String, dynamic>{'path': serverPath},
    options: Options(
      // بايتاتٌ لا JSON: الردُّ صورةٌ أو PDF، وقراءتُه نصّاً تُتلفه.
      responseType: ResponseType.bytes,
      headers: <String, dynamic>{'Accept': '*/*'},
      // و`404` جوابٌ يُقرأ لا استثناءٌ يُلتقط — راجع فرعَ الشرطات أعلاه.
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  /// بايتاتُ الردّ — **وبفرعٍ لمغلَّف JSON**.
  ///
  /// المنتظَرُ بايتاتٌ خام، وهو ما تردّه النقطةُ لملفٍّ موجود. لكنّ ردَّ خطأٍ
  /// (أو مغلَّفاً يحمل base64) يصل بنفس القناة وقد فُتحت بـ`ResponseType.bytes`
  /// — فيُقرأ هنا بدل أن يُكتب بالقرص ملفَّ صورةٍ محتواه رسالةُ خطأ.
  Uint8List? _bytesOf(Response<dynamic> response) {
    final data = response.data;
    if (data is! List<int>) return null;
    final bytes = Uint8List.fromList(data);

    final contentType =
        response.headers.value(Headers.contentTypeHeader)?.toLowerCase() ?? '';
    if (!contentType.contains('json')) return bytes;

    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      final payload = decoded is Map ? decoded['data'] : decoded;
      final raw = payload is Map ? payload['data'] : payload;
      return InlineFileData.decode(raw?.toString());
    } catch (_) {
      return null;
    }
  }

  // ── المخزن ────────────────────────────────────────────────────────────────

  File _remember(String key, File file) {
    _ready[key] = file;
    revision.value++;
    return file;
  }

  /// اسمُ الملفّ بالقرص: **بصمةُ مساره + امتدادُه**.
  ///
  /// البصمةُ لأن المسار يحمل شرطاتٍ ومحارفَ لا تصلح أسماءَ ملفّات، والامتدادُ
  /// لأن تطبيقات النظام تستنتج النوعَ منه وحده.
  String _keyFor(String serverPath) {
    final digest = sha1.convert(utf8.encode(serverPath)).toString();
    final extension = p.extension(serverPath.replaceAll(r'\', '/'));
    // وامتدادٌ طويل ليس امتداداً — مسارٌ بلا لاحقةٍ معروفة يُترك بلا لاحقة.
    final safe = RegExp(r'^\.[A-Za-z0-9]{1,8}$').hasMatch(extension)
        ? extension.toLowerCase()
        : '';
    return '$digest$safe';
  }

  /// `<appDocuments>/server_files/` — التخزينُ الخاصّ لا المؤقّت.
  ///
  /// نفسُ حجّة `AttachmentFileStore`: المؤقّت يفرغه النظام حين تضيق المساحة —
  /// وهي اللحظةُ نفسُها التي يكون فيها الموظّف بالميدان بلا تغطية.
  Future<Directory?> _ensureRoot() async {
    if (_root != null) return _root;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, _dirName));
      if (!dir.existsSync()) await dir.create(recursive: true);
      _root = dir;
      // وما نزل بجلسةٍ سابقة صار مقروءاً الآن — تُسأل المصغَّرات ثانيةً.
      revision.value++;
      return dir;
    } catch (error) {
      LogService.error(
        'تعذّر تهيئة مجلَّد ملفّات الخادم — لن يُخزَّن ما ينزل.',
        tag: _tag,
        error: error,
      );
      return null;
    }
  }
}
