part of 'settings_cubit.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(false) bool notificationsEnabled,
    @Default('-') String appVersion,
    @Default(false) bool isClearingCache,
  }) = _SettingsState;
}
