import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/infra/files/server_file_cache.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/images/cached_image_widget.dart';
import 'package:app_template/ui/widgets/indicators/app_progress.dart';
import 'package:app_template/ui/widgets/media/captured_photo.dart';

/// **بايتاتُ [CapturedPhoto] كما تُرسم** — ترتيبُ المصادر بموضعٍ واحد.
///
/// كانت المصغَّرةُ والمعاينةُ تكتبان الترتيبَ نفسه كلٌّ على حدة، فاختلفتا: هذه
/// تفحص وجودَ الملفّ قبل قراءته وتلك لا، وواحدةٌ منهما وحدها كانت تسقط إلى
/// الرابط. ونسخُ ترتيبٍ من ثلاثة فروع هو نسخُ ثلاثة أخطاءٍ ممكنة (R34).
///
/// و[cacheWidth] ليس تحسيناً: صورةُ كاميرا ٢٠٤٨×١٥٣٦ تحتلّ ~١٢٫٦ ميغابايت خاماً
/// بالذاكرة، و`ImageCache` يمسكها. ستُّ صورٍ باستمارةٍ واحدة = ~٧٥ ميغابايت
/// مقيمة **لحظةَ** ترسل الكاميرا العمليةَ إلى الخلفية — وهي اللحظة التي يختار
/// فيها النظام ماذا يستردّ.
class CapturedPhotoImage extends StatelessWidget {
  const CapturedPhotoImage({
    required this.photo,
    this.fit = BoxFit.cover,
    this.sizeToParent = false,
    this.download = false,
    super.key,
  });

  final CapturedPhoto photo;
  final BoxFit fit;

  /// يفكّ الترميز بعرض الأب لا بعرض اللقطة — للمصغَّرات داخل شبكةٍ أو شريط.
  final bool sizeToParent;

  /// **هل يُنزَّل ما يملكه الخادمُ وحده؟** — `false` بكل مصغَّرة، وافتراضاً.
  ///
  /// المصغَّرةُ تُرسم بفتح شاشة، وشاشةٌ تفتح ستَّ صورٍ تفتح ستَّ رحلات — وذلك
  /// بعينه ما تمنعه قاعدةُ «التنقّل لا يمسّ الشبكة» (`NetworkOrigin`). فتعرض
  /// المصغَّرةُ ما بالمخزن وحده، **ومَن يمرّرها `true` هو من فُتح بضغطة إصبع**:
  /// `CapturedPhotoViewer`.
  final bool download;

  @override
  Widget build(BuildContext context) {
    final bytes = photo.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (_, _, _) => const _BrokenBytes(),
      );
    }

    final path = photo.localPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return _FileImage(file: File(path), fit: fit, sizeToParent: sizeToParent);
    }

    if (photo.hasRemotePath) {
      return _ServerFileImage(
        serverPath: photo.remotePath!,
        fit: fit,
        sizeToParent: sizeToParent,
        download: download,
      );
    }

    if (photo.hasRemote) {
      return CachedImageWidget(imageUrl: photo.remoteUrl!, fit: fit);
    }
    return _MissingSource(photo: photo);
  }
}

/// ملفٌّ على القرص ⇒ صورة — بموضعٍ واحد، ومنه [CapturedPhotoImage] و
/// [_ServerFileImage] معاً.
class _FileImage extends StatelessWidget {
  const _FileImage({
    required this.file,
    required this.fit,
    required this.sizeToParent,
  });

  final File file;
  final BoxFit fit;
  final bool sizeToParent;

  @override
  Widget build(BuildContext context) {
    if (!sizeToParent) {
      return Image.file(
        file,
        fit: fit,
        errorBuilder: (_, _, _) => const _BrokenBytes(),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Image.file(
        file,
        fit: fit,
        // و`maxWidth` قد يكون غير محدود و`round()` عليه يرمي — فيُحرس.
        cacheWidth: constraints.maxWidth.isFinite
            ? (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .round()
            : null,
        errorBuilder: (_, _, _) => const _BrokenBytes(),
      ),
    );
  }
}

/// **صورةٌ يملكها الخادم** — تُرسم من المخزن، أو تُنزَّل إن فُتحت بضغطة.
///
/// وحالاتُها الأربع تُقرأ من الشاشة بلا كلمة: صورةٌ ⇒ نزلت · دوّارةٌ ⇒ تنزل ·
/// سحابةٌ بسهم ⇒ **اضغط لتراها** · نصٌّ يقول لماذا لم تنزل ⇒ اضغط لتعيد.
class _ServerFileImage extends StatefulWidget {
  const _ServerFileImage({
    required this.serverPath,
    required this.fit,
    required this.sizeToParent,
    required this.download,
  });

  final String serverPath;
  final BoxFit fit;
  final bool sizeToParent;
  final bool download;

  @override
  State<_ServerFileImage> createState() => _ServerFileImageState();
}

class _ServerFileImageState extends State<_ServerFileImage> {
  final ServerFileCache _cache = getIt<ServerFileCache>();

  File? _file;
  bool _loading = false;
  ServerFileOutcome? _failure;

  @override
  void initState() {
    super.initState();
    _file = _cache.cached(widget.serverPath);
    // **ويُسمع الدفتر حتى بعد أن يُوجد الملف**: مسحُ الحساب يحذف المخزن،
    // وصورةٌ تبقى مرسومةً من ملفٍّ لم يعد موجوداً هي بيانُ حسابٍ سابق يُعرض.
    _cache.revision.addListener(_onCacheChanged);
    if (_file == null && widget.download) _startQuietly();
  }

  @override
  void dispose() {
    _cache.revision.removeListener(_onCacheChanged);
    super.dispose();
  }

  void _onCacheChanged() {
    final found = _cache.cached(widget.serverPath);
    if (found?.path == _file?.path) return;
    if (mounted) setState(() => _file = found);
  }

  /// **أوّلُ محاولة — من `initState` وحدها.** تكتب الحقلَ بلا إخطار: أوّلُ
  /// بناءٍ لم يقع بعد، فيقرأ الدوّارةَ منه كما هو. و`setState` هنا تكون
  /// إخطاراً وسطَ بناءٍ جارٍ.
  void _startQuietly() {
    _loading = true;
    _failure = null;
    unawaited(_run());
  }

  /// **إعادةُ المحاولة — بضغطة.** وقعت بعد بناءٍ، فتلزمها الدوّارةُ فوراً.
  void _retry() {
    setState(() {
      _loading = true;
      _failure = null;
    });
    unawaited(_run());
  }

  Future<void> _run() async {
    final result = await _cache.fetch(widget.serverPath);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _file = result.file;
      _failure = result.outcome == ServerFileOutcome.ok ? null : result.outcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    if (file != null) {
      return _FileImage(
        file: file,
        fit: widget.fit,
        sizeToParent: widget.sizeToParent,
      );
    }
    if (_loading) {
      return const AppProgress.circular(
        size: AppProgressSize.sm,
        centered: true,
      );
    }
    if (_failure != null) return _RetryHint(outcome: _failure!, onTap: _retry);

    // لم يُطلب تنزيلُها بعد — سحابةٌ بسهمٍ تقول إن وراء الضغطة شيئاً.
    return Center(
      child: Icon(
        Icons.cloud_download_outlined,
        color: context.colors.iconSubtle,
      ),
    );
  }
}

/// لماذا لم تنزل، وأنّ الضغطةَ تُعيد الكرّة.
class _RetryHint extends StatelessWidget {
  const _RetryHint({required this.outcome, required this.onTap});

  final ServerFileOutcome outcome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    final (icon, message) = switch (outcome) {
      ServerFileOutcome.offline => (
        Icons.cloud_off_outlined,
        LocaleKeys.attachmentOfflineUnavailable.tr(),
      ),
      ServerFileOutcome.notFound => (
        Icons.search_off_outlined,
        LocaleKeys.attachmentNotOnServer.tr(),
      ),
      _ => (Icons.refresh_rounded, LocaleKeys.attachmentFailed.tr()),
    };

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(context.screen.space(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: context.colors.iconSubtle),
              // نصُّ السبب يسقط بالمصغَّرات الضيّقة ويبقى بالمعاينة — أيقونةٌ
              // بلا تفسيرٍ خيرٌ من نصٍّ يُقصّ بمربّعٍ ٥٦px.
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// لا بايتات هنا — **وذلك ليس دائماً عطلاً**.
///
/// ملفٌّ رُفع ثم نُظّف من الجهاز، أو ملفٌّ لم يُلتقط بهذا الجهاز أصلاً: كلاهما
/// سليمٌ بالسجل ولا شيء منه يُعرض. والسحابةُ تقول ذلك، والصورةُ المكسورة تقول
/// «عطل» — والفرق هو الفرق بين موظّفٍ يطمئنّ وموظّفٍ يعيد الالتقاط بلا داعٍ.
class _MissingSource extends StatelessWidget {
  const _MissingSource({required this.photo});

  final CapturedPhoto photo;

  @override
  Widget build(BuildContext context) => Center(
    child: Icon(
      photo.isUploaded
          ? Icons.cloud_outlined
          : photo.isImage
          ? Icons.image_not_supported_outlined
          : Icons.description_outlined,
      color: context.colors.iconSubtle,
    ),
  );
}

/// البايتات هنا ولا تُرسم — ملفٌّ تلف بالنسخ، أو مستندٌ سُئل أن يكون صورة.
class _BrokenBytes extends StatelessWidget {
  const _BrokenBytes();

  @override
  Widget build(BuildContext context) => Center(
    child: Icon(Icons.broken_image_outlined, color: context.colors.iconSubtle),
  );
}
