import 'package:easy_localization/easy_localization.dart';
import 'package:app_template/core/platform/extensions/datetime_extensions.dart';
import 'package:flutter/material.dart';

import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/media/captured_photo.dart';
import 'package:app_template/ui/widgets/media/captured_photo_image.dart';

/// معاينةُ صورةٍ ميدانية بملء الشاشة — تكبيرٌ وسحب، وبياناتها أسفلها.
///
/// **وهي مدخلُ التطوير لاحقاً**: «معاينة بعد الالتقاط» (تأكيدٌ قبل الحفظ)
/// و«إعادة فتح المرفوعة» كلاهما هذه الشاشة بوسيطٍ مختلف — لا شاشةٌ ثالثة.
/// ولذلك [onDelete] اختياري: من يفتحها للقراءة لا يُمرّره، ومن يفتحها للمراجعة
/// يُمرّره فيظهر الزرّ.
class CapturedPhotoViewer extends StatelessWidget {
  const CapturedPhotoViewer({required this.photo, this.onDelete, super.key});

  final CapturedPhoto photo;
  final VoidCallback? onDelete;

  static Future<void> show(
    BuildContext context, {
    required CapturedPhoto photo,
    VoidCallback? onDelete,
  }) => showDialog<void>(
    context: context,
    barrierColor: context.colors.scrim.withValues(alpha: .88),
    builder: (_) => CapturedPhotoViewer(photo: photo, onDelete: onDelete),
  );

  @override
  Widget build(BuildContext context) {
    context.locale;
    final colors = context.colors;
    // أرضيةٌ سوداء بالوضعين: `scrim` هو اللون الوحيد بالنظام الذي لا ينقلب
    // مع الوضع (F06) — وصورةٌ تُعاين على أبيضَ ليلاً تُبهر العين وتكذب ألوانها.
    return Dialog.fullscreen(
      backgroundColor: colors.scrim.withValues(alpha: .92),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: Navigator.of(context).pop,
                  icon: Icon(Icons.close_rounded, color: colors.onBrand),
                ),
                const Spacer(),
                if (onDelete != null)
                  IconButton(
                    tooltip: LocaleKeys.delete.tr(),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete!();
                    },
                    icon: Icon(Icons.delete_outline, color: colors.stateError),
                  ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: CapturedPhotoImage(
                    photo: photo,
                    fit: BoxFit.contain,
                    // فُتحت بضغطة إصبع — وهي وحدها ما يُنزِّل ما يملكه
                    // الخادم. راجع `CapturedPhotoImage.download`.
                    download: true,
                  ),
                ),
              ),
            ),
            _MetaPanel(photo: photo),
          ],
        ),
      ),
    );
  }
}

class _MetaPanel extends StatelessWidget {
  const _MetaPanel({required this.photo});

  final CapturedPhoto photo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lines = <(IconData, String)>[
      if (photo.capturedAt != null)
        (Icons.schedule_rounded, photo.capturedAt!.timeAndDayMonthYear),
      if (photo.hasCoordinates)
        (
          Icons.location_on_outlined,
          photo.accuracyMeters == null
              ? photo.coordinatesLabel
              : '${photo.coordinatesLabel}  ±${photo.accuracyMeters!.toStringAsFixed(0)}m',
        ),
      if (photo.capturedBy?.isNotEmpty ?? false)
        (Icons.person_outline_rounded, photo.capturedBy!),
      if (photo.label?.isNotEmpty ?? false)
        (Icons.insert_drive_file_outlined, photo.label!),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: colors.scrim.withValues(alpha: .55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(line.$1, size: 16, color: colors.onBrandAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line.$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onBrand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
