import 'package:kit_contracts/kit_contracts.dart';

/// The recogniser or voice locale for [languageCode] among [available]
/// (`ar_SA` · `ar-EG` · `en_US` — both separators occur).
///
/// [preferred] — the device's own locale — wins when it speaks the language,
/// so an Egyptian phone hears Egyptian Arabic rather than the first `ar_*` the
/// engine lists. An engine that lists nothing gets the bare code, which most
/// accept; `null` only when the list exists and lacks the language.
String? pickLocale(
  List<String> available,
  String languageCode, {
  String? preferred,
}) {
  final code = languageCode.toLowerCase();
  bool speaks(String id) {
    final l = id.toLowerCase();
    return l == code || l.startsWith('${code}_') || l.startsWith('$code-');
  }

  if (available.isEmpty) return languageCode;
  if (preferred != null && speaks(preferred) && available.contains(preferred)) {
    return preferred;
  }
  for (final id in available) {
    if (speaks(id)) return id;
  }
  return null;
}

/// `speech_to_text` error codes (Android and iOS share them).
SpeechFailure speechFailureOf(String errorMsg) => switch (errorMsg) {
  'error_no_match' || 'error_speech_timeout' => SpeechFailure.noMatch,
  'error_network' ||
  'error_network_timeout' ||
  'error_server' ||
  'error_server_disconnected' => SpeechFailure.network,
  'error_busy' || 'error_too_many_requests' => SpeechFailure.busy,
  'error_language_not_supported' ||
  'error_language_unavailable' => SpeechFailure.language,
  _ => SpeechFailure.unknown,
};
