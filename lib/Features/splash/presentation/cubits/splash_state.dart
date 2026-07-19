part of 'splash_cubit.dart';

@freezed
abstract class SplashState with _$SplashState {
  const factory SplashState.initial() = SplashInitial;

  const factory SplashState.loading() = SplashLoading;

  const factory SplashState.loaded() = SplashLoaded;

  const factory SplashState.loadedWithAuth() = SplashLoadedWithAuth;

  const factory SplashState.guestLoaded() = SplashGuestLoaded;

  const factory SplashState.error({required String errorMessage}) = SplashError;
}
