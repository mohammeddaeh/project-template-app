import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/infra/session/session_guard_fresh_auth.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/core/platform/biometrics/biometrics_service.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/lifecycle/app_lifecycle_service.dart';
import 'package:app_template/modules/session_guard/data/session_guard_pin_store.dart';
import 'package:app_template/modules/session_guard/presentation/cubits/session_guard_cubit.dart';
import 'package:app_template/modules/session_guard/presentation/pages/session_lock_screen.dart';
import 'package:app_template/modules/session_guard/presentation/pages/session_pin_setup_screen.dart';

/// المكان الوحيد الذي يُركَّب فيه الموديول — يُغلَّف به الغلاف
/// (`MainShellPage`)، أعلى أي معلِنٍ آخر: قفلٌ محجوبٌ خلف لافتة تحديثٍ أو
/// ترحيبٍ يُفشل الغرض كلَّه.
///
/// نفس نمط `AppUpdateGate`/`Can` حرفياً: يقرأ `AppFeatures.sessionGuard`
/// **هنا لا عند المستدعي** — فيستحيل أن يعرض القشرةُ قفلاً بلا موديولٍ خلفه.
///
/// **بلا `AppLifecycleService` مُسجَّلة** (علَمها `appLifecycle` مطفأ) لا
/// يُبنى شيء: القفل يحتاج معرفة متى غاب التطبيق، ولا بديل عنها.
class SessionGuardGate extends StatelessWidget {
  const SessionGuardGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppFeatures.sessionGuard) return child;

    final di = GetIt.instance;
    if (!di.isRegistered<AppLifecycleService>()) return child;

    return BlocProvider(
      create: (_) => SessionGuardCubit(
        di<SessionGuardPinStore>(),
        di<SessionGuardFreshAuth>(),
        di<SessionRepository>(),
        lifecycleStream: di<AppLifecycleService>().stateStream,
        biometrics:
            AppFeatures.biometrics && di.isRegistered<BiometricsService>()
            ? di<BiometricsService>()
            : null,
      ),
      child: BlocBuilder<SessionGuardCubit, SessionGuardState>(
        builder: (context, state) => state.when(
          checking: () => const SizedBox.shrink(),
          unlocked: () => child,
          needsSetup: () => const SessionPinSetupScreen(),
          locked: (_) => const SessionLockScreen(),
        ),
      ),
    );
  }
}
