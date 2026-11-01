import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// Knobs shared by the widget pages: a colour token and a callback.
///
/// A knob's value is compared with its options on every rebuild, so it holds a
/// stable identity — the token's *name*, or `true` for "a callback is given" —
/// and the widget resolves it at build time. A [Color] read from the theme
/// would change with the theme and stop matching its option.

/// A `Color?` argument picked from the theme's tokens; `null` is the widget's
/// own default. Resolve the value with [tokenColor].
ChoiceKnob<String?> colorKnob(
  String name,
  List<String> tokens, {
  String? initial,
}) => ChoiceKnob<String?>(
  name,
  {'null': null, for (final t in tokens) 'context.colors.$t': t},
  initialCode: initial == null ? 'null' : 'context.colors.$initial',
  apiDefaultCode: 'null',
);

/// The colour a [colorKnob] value names.
Color? tokenColor(BuildContext context, String? token) {
  final c = context.colors;
  return switch (token) {
    null => null,
    'primary' => c.primary,
    'secondary' => c.secondary,
    'tertiary' => c.tertiary,
    'error' => c.error,
    'onError' => c.onError,
    'feedbackSuccess' => c.feedbackSuccess,
    'feedbackWarning' => c.feedbackWarning,
    'feedbackInfo' => c.feedbackInfo,
    'bgBrand' => c.bgBrand,
    'onBrand' => c.onBrand,
    'bgNeutral' => c.bgNeutral,
    'textPrimary' => c.textPrimary,
    'textOnPrimary' => c.textOnPrimary,
    'borderSubtle' => c.borderSubtle,
    'primaryContainer' => c.primaryContainer,
    'onPrimaryContainer' => c.onPrimaryContainer,
    _ => throw ArgumentError.value(token, 'token'),
  };
}

/// A callback argument: absent (`null`) or given — written as [code].
ChoiceKnob<bool> callbackKnob(
  String name, {
  String code = '() {}',
  bool initial = true,
}) => ChoiceKnob<bool>(
  name,
  {'null': false, code: true},
  initialCode: initial ? code : 'null',
  apiDefaultCode: 'null',
);
