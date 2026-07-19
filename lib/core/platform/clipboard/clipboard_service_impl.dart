import 'package:flutter/services.dart';
import 'package:app_template/core/platform/clipboard/clipboard_service.dart';

/// [ClipboardService] implementation using Flutter's built-in [Clipboard].
///
/// No external package needed — uses `flutter/services.dart`.
/// Registered manually in `di/injection_module.dart`.
class ClipboardServiceImpl implements ClipboardService {
  const ClipboardServiceImpl();

  @override
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  @override
  Future<String?> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  @override
  Future<bool> hasText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text?.isNotEmpty == true;
  }
}
