/// The three server-owned values that control the update flow.
class AppUpdateSettings {
  const AppUpdateSettings({
    required this.version,
    required this.downloadUrl,
    required this.forceUpdate,
  });

  factory AppUpdateSettings.fromEntries(List<dynamic> entries) {
    final values = <String, String>{};
    for (final entry in entries) {
      if (entry is! Map) continue;
      if (entry['isActive'] == false) continue;
      final key = entry['key']?.toString();
      if (key == null || key.isEmpty) continue;
      values[key] = entry['value']?.toString() ?? '';
    }

    final version = values['app_version']?.trim() ?? '';
    if (version.isEmpty) {
      throw const FormatException('settings response has no app_version');
    }

    return AppUpdateSettings(
      version: version,
      downloadUrl: values['app_download_url']?.trim() ?? '',
      forceUpdate: values['force_update']?.toLowerCase() == 'true',
    );
  }

  factory AppUpdateSettings.fromJson(Map<String, dynamic> json) =>
      AppUpdateSettings(
        version: json['version']?.toString() ?? '',
        downloadUrl: json['download_url']?.toString() ?? '',
        forceUpdate: json['force_update'] == true,
      );

  final String version;
  final String downloadUrl;
  final bool forceUpdate;

  Map<String, dynamic> toJson() => {
    'version': version,
    'download_url': downloadUrl,
    'force_update': forceUpdate,
  };
}

/// Compares dotted app versions without making the UI depend on the network.
bool isVersionOlder(String current, String target) {
  List<int> parts(String value) => value
      .split('+')
      .first
      .split('-')
      .first
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList(growable: false);

  final left = parts(current);
  final right = parts(target);
  final length = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final a = i < left.length ? left[i] : 0;
    final b = i < right.length ? right[i] : 0;
    if (a != b) return a < b;
  }
  return false;
}
