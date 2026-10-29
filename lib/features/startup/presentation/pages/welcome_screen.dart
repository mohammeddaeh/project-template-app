import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/features/auth/shared/current_user_repository.dart';
import 'package:app_template/features/startup/presentation/widgets/welcome_body.dart';
import 'package:app_template/features/startup/startup_destination.dart';
import 'package:app_template/features/startup/startup_resolver.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// **الترحيب — مرّةً واحدة على الجهاز**، بكل أوضاع الدخول.
///
/// `StartupResolver` يُرسل إليها حين لم يُعلَّم [PersistenceKeys.welcomeSeen]؛
/// «ابدأ» يعلّمه ثم يذهب حيث كان الإقلاعُ سيذهب لولاها ([decideStartup]):
/// الدخول بوضع `required` بلا جلسة، وإلا الرئيسية.
@RoutePage()
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _start(BuildContext context) async {
    await getIt<StorageService>().writeBool(
      PersistenceKeys.welcomeSeen,
      value: true,
    );
    if (!context.mounted) return;
    final next = decideStartup(
      mode: AppFeatures.authMode,
      welcomeSeen: true,
      signedIn: getIt<CurrentUserRepository>().currentUser != null,
    );
    context.router.replaceAll([
      next == StartupDestination.login
          ? const LoginRoute()
          : const MainShellRoute(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgBrand,
      body: SafeArea(
        child: ResponsiveContentBox(
          width: ContentWidth.form,
          child: WelcomeBody(onStart: () => _start(context)),
        ),
      ),
    );
  }
}
