import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/presentation/shared/refresh/refresh_cubit.dart';
import 'package:app_template/presentation/extensions/screen_sizes_extensions.dart';
import 'package:app_template/Features/splash/presentation/cubits/splash_cubit.dart';
import 'package:app_template/resources/assets.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/shared/widgets/images/app_asset_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

@RoutePage()
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  var _logoHeight = 120.0;

  final _refreshCubit = RefreshCubit();
  final _animationDuration = const Duration(seconds: 1);

  late final SplashCubit _splashCubit;

  @override
  void initState() {
    super.initState();
    _splashCubit = SplashCubit(getIt<SessionRepository>());
    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      setState(() => _logoHeight = 160);
      _refreshCubit.refresh();
      return Future.delayed(const Duration(seconds: 1));
    }).whenComplete(_splashCubit.loadResources);
  }

  @override
  void dispose() {
    _splashCubit.close();
    _refreshCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPage,
      body: SafeArea(
        child: SizedBox(
          width: context.sw,
          child: BlocConsumer<SplashCubit, SplashState>(
            bloc: _splashCubit,
            listener: _onSplashStateChanged,
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        duration: _animationDuration,
                        tween: Tween(begin: 0.0, end: _logoHeight),
                        builder: (_, value, _) => AppAssetImage(
                          Assets.images.test.test,
                          height: value,
                        ),
                      ),
                    ),
                  ),
                  // if (state is SplashLoading) ...[
                  //   const CircularProgressIndicator.adaptive(),
                  //   const SizedBox(height: 64),
                  // ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _onSplashStateChanged(BuildContext context, SplashState state) {
    state.maybeWhen(
      loadedWithAuth: () => context.router.replaceAll([const HomeRoute()]),
      loaded: () => context.router.replaceAll([const TestDashboardRoute()]),
      guestLoaded: () => context.router.replaceAll([const TestDashboardRoute()]),
      orElse: () {},
    );
  }
}
