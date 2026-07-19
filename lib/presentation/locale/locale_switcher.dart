import 'package:flutter/widgets.dart';

import 'variants/locale_icon_button_variant.dart';
import 'variants/locale_segmented_variant.dart';
import 'variants/locale_text_toggle_variant.dart';
import 'variants/locale_tile_variant.dart';

/// Locale switcher widget — choose the visual style, logic is identical.
///
/// ─── Variants ────────────────────────────────────────────────────────────────
/// ```dart
/// LocaleSwitcher()               // = .tile() — default for settings screens
/// LocaleSwitcher.tile()          // ListTile + bottom-sheet picker
/// LocaleSwitcher.iconButton()    // Compact icon for AppBar actions
/// LocaleSwitcher.segmented()     // SegmentedButton: العربية | English
/// LocaleSwitcher.textToggle()    // Inline text: العربية | English
/// ```
///
/// All variants share the same controller — only the UI differs.
class LocaleSwitcher extends StatelessWidget {
  const LocaleSwitcher._({required Widget child, super.key}) : _child = child;

  /// Default — same as [LocaleSwitcher.tile].
  const factory LocaleSwitcher({Key? key}) = _DefaultLocaleSwitcher;

  /// ListTile with a bottom-sheet picker — best for settings screens.
  const factory LocaleSwitcher.tile({Key? key}) = _TileLocaleSwitcher;

  /// Compact icon button — best for AppBar actions.
  const factory LocaleSwitcher.iconButton({Key? key}) = _IconButtonLocaleSwitcher;

  /// SegmentedButton — best for onboarding or inline settings cards.
  const factory LocaleSwitcher.segmented({Key? key}) = _SegmentedLocaleSwitcher;

  /// Inline text toggle: العربية | English — minimal footprint.
  const factory LocaleSwitcher.textToggle({Key? key}) = _TextToggleLocaleSwitcher;

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

// ── Private factory implementations ─────────────────────────────────────────

class _DefaultLocaleSwitcher extends LocaleSwitcher {
  const _DefaultLocaleSwitcher({super.key}) : super._(child: const LocaleTileVariant());
}

class _TileLocaleSwitcher extends LocaleSwitcher {
  const _TileLocaleSwitcher({super.key}) : super._(child: const LocaleTileVariant());
}

class _IconButtonLocaleSwitcher extends LocaleSwitcher {
  const _IconButtonLocaleSwitcher({super.key}) : super._(child: const LocaleIconButtonVariant());
}

class _SegmentedLocaleSwitcher extends LocaleSwitcher {
  const _SegmentedLocaleSwitcher({super.key}) : super._(child: const LocaleSegmentedVariant());
}

class _TextToggleLocaleSwitcher extends LocaleSwitcher {
  const _TextToggleLocaleSwitcher({super.key}) : super._(child: const LocaleTextToggleVariant());
}
