import 'package:injectable/injectable.dart';

import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/session/account_data_cleaner.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';

/// **مِن أيِّ خادمٍ جاءت البيانات التي على هذا الجهاز؟**
///
/// ## العطل الذي وُلد منه هذا الملف
///
/// بُدّل `BASE_URL` من نفقٍ مؤقّت إلى الخادم الحقيقي، وأُعيد تشغيل التطبيق —
/// **فعرض بيانات النفق**. لا رمية، ولا شاشة خطأ، ولا سطر سجلّ: قاعدةُ
/// `synced_entities` بقيت كما هي، والمغلِّفات تقرأ منها **ولا تسأل الشبكة
/// إطلاقاً**. فالجهاز يعرض صفوفَ خادمٍ آخر بثقةٍ تامّة.
///
/// وأخطرُ من العرض: **التوكن**. توكنُ JWT يحمل `iss` الخاصَّ بمصدره، وخادمٌ
/// آخر يرفضه — فيمضي المستخدم إلى شاشاتٍ ترتدّ ٤٠١ واحدةً واحدة، أو يُنهى
/// جلستُه بلا سببٍ يفهمه.
///
/// ## والحلّ سؤالٌ واحد قبل أي قراءة
///
/// يُخزَّن أصلُ البيانات مع البيانات. فإن خالف [Env.baseUrl] ما هو مخزَّن:
///
/// | يُمحى | لماذا |
/// |---|---|
/// | الجلسة (توكن + تحديث) | توكنُ مصدرٍ آخر لا يصلح لهذا، وبقاؤه يُنتج ٤٠١ متفرّقة |
/// | كلُّ بيانات الحساب | صفوفُ خادمٍ آخر، ولقطاتُه، ومسوّداتُه المؤقّتة |
///
/// فيعود التطبيق إلى شاشة الدخول بجهازٍ نظيف — وهو الجوابُ الصادق الوحيد.
///
/// ## ⚠️ وشغلٌ ميدانيّ لم يُرفع يضيع بذلك
///
/// وهذا مقصودٌ لا مُغفَل: كتابةٌ محلّية تخصّ سجلاً **على خادمٍ آخر** لا مكان لها
/// هنا — معرّفُ أبيها لا يقابل شيئاً، ورفعُها يُنشئ سجلاً بمكانٍ خاطئ. وضياعٌ
/// يُرى ويُعاد إدخالُه أهونُ من رفعٍ يقع بالمكان الغلط.
///
/// > **ولا يقع إلا حين يتبدّل الأصل فعلاً.** إعادةُ تشغيلٍ عادية تقرأ نفس
/// > العنوان فتمرّ بلا مسح — والفحص قراءةُ مفتاحٍ واحد.
///
/// ## وموضعُ النداء: أولُ سطرٍ بالسبلاش
///
/// **قبل `loadCachedToken`** — وهو الترتيب الذي كان يشغله حقنُ توكن التطوير،
/// وسقط معه. وأيُّ ترتيبٍ آخر يعني أن السبلاش قرأ توكناً من مصدرٍ آخر ومضى
/// عليه قبل أن يُسأل عن أصله.
@lazySingleton
class DataOriginGuard {
  const DataOriginGuard(this._storage, this._session, this._accountData);

  final StorageService _storage;
  final SessionRepository _session;
  final AccountDataCleaner _accountData;

  static const _tag = 'DATA-ORIGIN';

  /// يُعيد `true` حين مُسح الجهاز لأن الأصل تبدّل.
  Future<bool> ensureCurrentOrigin() async {
    final current = Env.baseUrl;
    // عنوانٌ فارغ يعني إعداداً ناقصاً — والمسح عندها يمحو بيانات صحيحة لأن
    // ملفَّ البيئة لم يُمرَّر. فيُترك كلُّ شيء، ويُقال بالسجلّ.
    if (current.isEmpty) {
      LogService.warning(
        'BASE_URL is empty — skipping the data-origin check rather than '
        'wiping on a missing --dart-define-from-file.',
        tag: _tag,
      );
      return false;
    }

    final stored = await _read();

    // أولُ تشغيلٍ بعد تركيب هذا الحارس: يُكتب الأصل ولا يُمحى شيء.
    //
    // **والمسحُ هنا كان سيكون خطأً**: جهازٌ يحمل بيانات الخادم الصحيح ليس له
    // ذنبٌ بأن الحارس لم يكن موجوداً حين نزلت. وأولُ تبدّلٍ **بعد** اليوم هو
    // ما يُمسك.
    if (stored == null || stored.isEmpty) {
      await _write(current);
      return false;
    }

    if (stored == current) return false;

    LogService.warning(
      'The data origin changed ($stored -> $current) — clearing the session '
      'and every local row, because what is on this device belongs to a '
      'different server.',
      tag: _tag,
    );
    _session.clearSession();
    await _accountData.clearForSignOut();
    await _write(current);
    return true;
  }

  Future<String?> _read() async {
    try {
      return await _storage.readString(PersistenceKeys.dataOrigin);
    } catch (error) {
      // **قراءةٌ تُخفق تُقرأ «لا أصلَ مخزَّن»** لا «تبدّل الأصل»: الأولى تكتب
      // مفتاحاً وتمضي، والثانية تمحو جهازاً كاملاً. والفرق بينهما جولةُ عمل.
      LogService.error(
        'Could not read the stored data origin — treating it as unset.',
        tag: _tag,
        error: error,
      );
      return null;
    }
  }

  Future<void> _write(String origin) async {
    try {
      await _storage.writeString(PersistenceKeys.dataOrigin, origin);
    } catch (error) {
      // **يُقال ولا يُبتلع**: أصلٌ لا يُكتب يعني أن التبدّل القادم لن يُمسك،
      // فيعود العطل الذي وُجد له هذا الملف.
      LogService.error(
        'Could not store the data origin — a future BASE_URL change will not '
        'be detected.',
        tag: _tag,
        error: error,
      );
    }
  }
}
