import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/placeholders/skeleton_scope.dart';

/// النبرة الدلالية لشارة حالة — لا لونها.
///
/// الشاشة تقول «هذا نجاح» و«هذا تحذير»، والتوكنات تقرّر ما اللون. فتغيير درجة
/// الأخضر يقع بموضعٍ واحد، لا بأربع شاشات تعرض الشارة نفسها.
enum StatusTone { neutral, info, success, warning, error }

/// شارة الحالة الموحَّدة — «مسوّدة · مُرسل · مقبول · مرفوض · قيد العمل · مكتمل».
///
/// **عامّة من اليوم الأول، خلافاً لقاعدة «انتظر ثاني مستهلك» (F21).** الاستثناء
/// مقصود: شارةُ الحالة تتكرّر بكل تطبيقٍ فيه سجلٌّ يمرّ بمراحل، وبأربع شاشاتٍ
/// على الأقل. ونسخُها يعني أن «مرفوض» أحمرُ هنا وبرتقاليٌّ هناك، ولا يكشفه إلا
/// مستخدمٌ يقارن شاشتين.
///
/// ⬜ **وبالقالب بلا مستهلكٍ بعد** — يُغلق بأوّل شاشةٍ تعرض حالةَ سجلّ.
class StatusChip extends StatelessWidget {
  const StatusChip({
    this.labelKey,
    this.labelText,
    required this.tone,
    super.key,
  }) : assert(labelKey != null || labelText != null);

  final String? labelKey;
  final String? labelText;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — registers this element with EasyLocalization
    context.locale;
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      StatusTone.neutral => (colors.statusNeutralBg, colors.statusNeutralFg),
      StatusTone.info => (colors.statusInfoBg, colors.statusInfoFg),
      StatusTone.success => (colors.statusSuccessBg, colors.statusSuccessFg),
      StatusTone.warning => (colors.statusWarningBg, colors.statusWarningFg),
      StatusTone.error => (colors.statusErrorBg, colors.statusErrorFg),
    };

    // داخل [Skeletonized] كبسولةٌ بنفس القطر وبمقاس نصّها — الحالةُ بيانةٌ
    // من الخادم كغيرها. وخارجها [Bone] تمريرةٌ صافية.
    return Bone(
      radius: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          // نصف قطر ٢٠ — كبسولة كاملة بارتفاع ٢٦، كما بالتصميم.
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          labelText ?? labelKey!.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.headlineSmall?.copyWith(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
