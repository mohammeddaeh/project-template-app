import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    emit(state.copyWith(appVersion: '${info.version}+${info.buildNumber}'));
  }

  void toggleNotifications() =>
      emit(state.copyWith(notificationsEnabled: !state.notificationsEnabled));

  Future<void> clearCache() async {
    emit(state.copyWith(isClearingCache: true));
    await Future.delayed(const Duration(milliseconds: 600));
    emit(state.copyWith(isClearingCache: false));
  }
}
