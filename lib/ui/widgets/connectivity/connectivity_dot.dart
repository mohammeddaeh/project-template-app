import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/state/connectivity/connectivity_cubit.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// **نقطةُ الاتصال** — كلُّ ما يقوله التطبيق عن الشبكة بعد 2026-08-26.
///
/// ```dart
/// Row(children: [Text(name), const SizedBox(width: 6), const ConnectivityDot()])
/// ```
///
/// ## ولماذا نقطةٌ لا شريط
///
/// سبقها `ConnectivityOverlay`: نقطةٌ بعد ثانيةٍ ونصف، ثم شريطٌ أحمر عريض بعد
/// أربع، ثم رقاقةٌ بعدّادٍ تنازليّ ثلاثين ثانية. وذلك منطقُ تطبيقٍ **يحتاج
/// الشبكة** — وهذا لا يحتاجها: الانقطاع هنا **الحالةُ الطبيعية** لا العطل،
/// والجولة الميدانية كلُّها تجري بلا تغطية عمداً.
///
/// فكان الشريط يعترض الشاشة ليعلن أمراً واقعاً ومقصوداً، والعدّادُ يَعِد
/// بإعادة محاولةٍ لا يفعلها أحد.
///
/// ## وتقول الحالتين لا الانقطاع وحده
///
/// «لا شيء حين الاتصال» كان سيجعل النقطةَ إنذاراً، وهي ليست كذلك. والسؤال الذي
/// يسأله الموظّف ميدانياً هو العكس: **«هل أنا متصلٌ الآن كي أُزامن؟»** — وجوابُه
/// لا يُقرأ من غياب علامة.
///
/// | الحالة | اللون | `semanticsLabel` |
/// |---|---|---|
/// | `online` | `onBrandOnline` | «متصل بالشبكة» |
/// | `offline` | `stateError` | «لا إنترنت» |
/// | `unknown` | `onBrand` بشفافية | «جاري التحقق…» |
///
/// ## وتُقرأ من `getIt` لا من السياق
///
/// نفسُ اختيار `LoginConnectivityStrip`: الكيوبت مفردٌ بالـDI، وقراءتُه مباشرةً
/// تجعل الودجة تعمل بأي موضعٍ بالشجرة — بما فيه ما هو خارج مُوفِّر `app.dart`.
class ConnectivityDot extends StatelessWidget {
  const ConnectivityDot({super.key, this.size = 8});

  /// قطرُ النقطة. الافتراضي ٨ — نفسُ مقاس شريط شاشة الدخول.
  final double size;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — registers this element with EasyLocalization
    context.locale;
    return BlocBuilder<ConnectivityCubit, NetworkState>(
      bloc: getIt<ConnectivityCubit>(),
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
            duration: const Duration(milliseconds: 250),
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
