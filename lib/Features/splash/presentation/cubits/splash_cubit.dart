import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/core/platform/features/app_features.dart';

part 'splash_cubit.freezed.dart';
part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._sessionRepository) : super(const SplashState.initial());

  final SessionRepository _sessionRepository;

  Future<void> loadResources() async {
    emit(const SplashState.loading());
    if (AppFeatures.debugSkipLogin) {
      emit(const SplashState.guestLoaded());
      return;
    }
    final token = await _sessionRepository.loadCachedToken();
    if (token != null && token.isNotEmpty) {
      emit(const SplashState.loadedWithAuth());
    } else {
      emit(const SplashState.loaded());
    }
  }
}
