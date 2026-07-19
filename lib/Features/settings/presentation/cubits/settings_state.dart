import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool notificationsEnabled;
  final String appVersion;
  final bool isClearingCache;

  const SettingsState({
    this.notificationsEnabled = false,
    this.appVersion = '-',
    this.isClearingCache = false,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    String? appVersion,
    bool? isClearingCache,
  }) =>
      SettingsState(
        notificationsEnabled:
            notificationsEnabled ?? this.notificationsEnabled,
        appVersion: appVersion ?? this.appVersion,
        isClearingCache: isClearingCache ?? this.isClearingCache,
      );

  @override
  List<Object?> get props => [notificationsEnabled, appVersion, isClearingCache];
}
