import 'package:easy_localization/easy_localization.dart';
import 'package:app_template/core/platform/extensions/datetime_extensions.dart';
import 'package:flutter/material.dart';

import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/media/attachment_preview.dart';
import 'package:app_template/ui/widgets/media/captured_photo.dart';
import 'package:app_template/ui/widgets/media/captured_photo_image.dart';

/// **الصورة الميدانية بالتطبيق كلّه** — مصغَّرةٌ يُطبع فوقها ما يُثبتها.
///
/// كانت ثلاث نسخ: شبكةُ المقاسم (`CapturedMediaTile`)، وصفُّ حقل الالتقاط،
/// وشبكةُ السجلات التي كانت ترسم **أيقونةً عامّة بدل الصورة** — فأربع صورٍ
/// تظهر أربعة مربّعات متطابقة لا يُعرف أيّها يُحذف. وثلاثتها تطبع بياناتٍ
/// مختلفة بترتيبٍ مختلف عن الشيء نفسه.
///
/// - النقر يفتح [AttachmentPreview] — **وهي التي تقرّر**: الصورةُ تُكبَّر بحوار
///   المعاينة، والمستندُ (PDF · DWG) يُسلَّم لتطبيق النظام، وما لا بايتات له
///   يُردّ برسالةٍ تقول لماذا. وحوارٌ يُفتح على أيقونةٍ مكسورة كان جوابَ ملفٍّ
///   سليمٍ لا يُرسم صورةً.
/// - [onRemove] اختياري: بلا حذفٍ لا يُرسم الزرّ — السجل المقبول يُقرأ ولا يُعدَّل.
/// - وشريط البيانات يُسقط السطر الذي لا مصدر له، ولا يترك مكانه فارغاً.
class CapturedPhotoTile extends StatelessWidget {
  const CapturedPhotoTile({
    required this.photo,
    this.onRemove,
    this.onTap,
    this.height,
    this.showMeta = true,
    super.key,
  });

  final CapturedPhoto photo;
  final VoidCallback? onRemove;

  /// يستبدل فتحَ المعاينة الافتراضي.
  final VoidCallback? onTap;

  /// ارتفاعٌ ثابت، أو `null` فتملأ ما يمنحه الأب — كخليّة شبكة.
  final double? height;
  final bool showMeta;

  @override
  Widget build(BuildContext context) {
    context.locale;
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap:
          onTap ??
          () =>
              AttachmentPreview.open(context, photo: photo, onDelete: onRemove),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: colors.bgNeutral,
                child: CapturedPhotoImage(photo: photo, sizeToParent: true),
              ),
              if (onRemove != null)
                PositionedDirectional(
                  top: 6,
                  start: 6,
                  child: _RoundAction(
                    icon: Icons.delete_outline,
                    onTap: onRemove!,
                  ),
                ),
              PositionedDirectional(
                top: 6,
                end: 6,
                child: Icon(
                  photo.isUploaded
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_upload_outlined,
                  size: 16,
                  color: photo.isUploaded
                      ? colors.onBrand
                      : colors.onBrandAccent,
                  shadows: [Shadow(color: colors.scrim, blurRadius: 6)],
                ),
              ),
              if (showMeta) _MetaStrip(photo: photo),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: colors.scrim.withValues(alpha: .72),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: colors.onBrand),
      ),
    );
  }
}

class _MetaStrip extends StatelessWidget {
  const _MetaStrip({required this.photo});

  final CapturedPhoto photo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.textTheme.labelSmall;
    final lines = <(String, Color)>[
      if (photo.capturedAt != null)
        (photo.capturedAt!.timeAndDayMonthYear, colors.onBrand),
      if (photo.hasCoordinates) (photo.coordinatesLabel, colors.onBrandAccent),
      if (photo.capturedBy?.isNotEmpty ?? false)
        (photo.capturedBy!, colors.onBrandAccent),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    return PositionedDirectional(
      start: 0,
      end: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        color: colors.scrim.withValues(alpha: .72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final line in lines)
              Text(
                line.$1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style?.copyWith(color: line.$2),
              ),
          ],
        ),
      ),
    );
  }
}
