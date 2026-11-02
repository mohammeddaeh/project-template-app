import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/state/connectivity/connectivity_cubit.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// **نقطةُ الاتصال** — كلُّ ما يقوله التطبيق عن الشبكة.
///
/// ```dart
/// Row(children: [Text(name), const SizedBox(width: 6), const ConnectivityDot()])
/// ```
///
/// ## ولماذا نقطةٌ لا شريط
///
/// `ConnectivityOverlay` يعترض الشاشة بشريطٍ ثم بعدّادٍ تنازليّ — منطقُ تطبيقٍ
/// **لا يعمل بلا شبكة**. أمّا تطبيقٌ يعمل دون اتصال فالانقطاع فيه حالةٌ عاديّة لا
/// عطل، والنقطة تقولها بلا أن تعترض شيئاً.
///
/// ## وتقول الحالتين لا الانقطاع وحده
///
/// «لا شيء حين الاتصال» يجعل النقطةَ إنذاراً، وهي ليست كذلك. والسؤال الذي
/// يسأله المستخدم هو العكس: **«هل أنا متصلٌ الآن كي أُزامن؟»** — وجوابُه لا يُقرأ
/// من غياب علامة.
///
/// | الحالة | اللون | `semanticsLabel` |
/// |---|---|---|
/// | `online` | `onBrandOnline` | «متصل بالشبكة» |
/// | `offline` | `stateError` | «لا إنترنت» |
/// | `unknown` | `onBrand` بشفافية | «جاري التحقق…» |
///
/// ## وتُقرأ من `getIt` لا من السياق
///
/// الكيوبت مفردٌ بالـDI، وقراءتُه مباشرةً تجعل الودجة تعمل بأي موضعٍ بالشجرة —
/// بما فيه ما هو خارج مُوفِّر `app.dart`. و[bloc] يمرّر غيرَه لاختبارٍ أو معاينة.
class ConnectivityDot extends StatelessWidget {
  const ConnectivityDot({super.key, this.size = 8, this.bloc});

  /// قطرُ النقطة. الافتراضي ٨ — نفسُ مقاس شريط شاشة الدخول.
  final double size;

  /// كيوبتٌ غيرُ المسجَّل بالـDI — لاختبارٍ أو معاينة. `null` ⇐ `getIt`.
  final ConnectivityCubit? bloc;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — registers this element with EasyLocalization
    context.locale;
    return BlocBuilder<ConnectivityCubit, NetworkState>(
      bloc: bloc ?? getIt<ConnectivityCubit>(),
      builder: (context, state) {
        final colors = context.colors;
        final (color, labelKey) = switch (state) {
          // **نغمةُ «متّصل» دلاليّةٌ لا لونُ علامة** — فالنقطةُ قد تقع فوق
          // سطحٍ ملوَّن بالهوية أو فوق صفحةٍ عادية، و`statusSuccessFg` يُقرأ
          // على الاثنين (بوابةُ التباين تحرسه).
          NetworkState.online => (
            colors.statusSuccessFg,
            LocaleKeys.networkConnected,
          ),
          NetworkState.offline => (colors.stateError, LocaleKeys.noInternet),
          NetworkState.unknown => (
            colors.textMuted,
            LocaleKeys.networkChecking,
          ),
        };

        return Semantics(
          // **الفرقُ لونٌ وحده — فلا يصل قارئَ الشاشة ولا من لا يميّز الأحمر
          // من الأخضر.** والنصُّ هنا هو النسخة الوحيدة الباقية منه.
          label: labelKey.tr(),
          child: AnimatedContainer(
            duration: AppMotion.of(context).base,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              // هالةٌ خفيفة تفصلها عن أخضر الشريط — بلا حدٍّ يزيد قطرها.
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
