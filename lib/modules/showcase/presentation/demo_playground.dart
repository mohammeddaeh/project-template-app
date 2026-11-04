import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/clipboard/clipboard_service.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// **A widget with its options as controls** — change a control and both the
/// widget and the call written above it change with it, so the call can be
/// copied exactly as chosen.
///
/// ```dart
/// DemoPlayground(
///   call: 'AppButton',
///   knobs: [
///     const TextKnob('text', initial: 'Save', required: true),
///     EnumKnob('variant', AppButtonVariant.values, AppButtonVariant.filled),
///     const BoolKnob('isLoading', apiDefault: false),
///   ],
///   builder: (context, k) => AppButton(
///     text: k('text'),
///     variant: k('variant'),
///     isLoading: k('isLoading'),
///     onTap: () {},
///   ),
/// )
/// ```
///
/// The call shows the required arguments and every argument whose value
/// differs from the widget's own default ([Knob.apiDefault]) — what one would
/// actually write.
class DemoPlayground extends StatefulWidget {
  const DemoPlayground({
    required this.call,
    required this.knobs,
    required this.builder,
    this.trailingCode = const [],
    this.previewAlignment = Alignment.center,
    super.key,
  });

  /// The constructor, e.g. `AppButton` or `AppButton.icon`.
  final String call;

  final List<Knob<Object?>> knobs;

  final Widget Function(BuildContext context, KnobValues k) builder;

  /// Arguments the controls do not cover, always written, e.g. `onTap: …`.
  final List<String> trailingCode;

  final AlignmentGeometry previewAlignment;

  @override
  State<DemoPlayground> createState() => _DemoPlaygroundState();
}

class _DemoPlaygroundState extends State<DemoPlayground> {
  /// What each control holds — a [ChoiceKnob] holds its option's code, so a
  /// value rebuilt on every frame (a theme colour, a widget) still matches.
  late final Map<String, Object?> _values = {
    for (final k in widget.knobs) k.name: k.storedInitial,
  };

  String get _code {
    final args = [
      for (final k in widget.knobs)
        if (k.inCall && k.positional) k.codeOf(_values[k.name]),
      for (final k in widget.knobs)
        if (k.inCall &&
            !k.positional &&
            (k.required || _values[k.name] != k.storedApiDefault))
          '${k.name}: ${k.codeOf(_values[k.name])}',
      ...widget.trailingCode,
    ];
    if (args.isEmpty) return '${widget.call}()';
    return '${widget.call}(\n${args.map((a) => '  $a,').join('\n')}\n)';
  }

  Future<void> _copy() async {
    if (!getIt.isRegistered<ClipboardService>()) return;
    await getIt<ClipboardService>().copy(_code);
    if (!mounted) return;
    context.feedback.toast(LocaleKeys.showcasePlaygroundCopied.tr());
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    final values = KnobValues._({
      for (final k in widget.knobs) k.name: k.resolve(_values[k.name]),
    });

    return Padding(
      padding: EdgeInsets.only(bottom: context.screen.space(16)),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Code reads left to right in either language.
            Directionality(
              textDirection: TextDirection.ltr,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.bgNeutral,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(context.screen.space(12)),
                        child: Text(
                          _code,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    if (getIt.isRegistered<ClipboardService>())
                      IconButton(
                        tooltip: LocaleKeys.showcasePlaygroundCopy.tr(),
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: colors.textMuted,
                        ),
                        onPressed: _copy,
                      ),
                  ],
                ),
              ),
            ),
            const ResponsiveGap(16),
            Align(
              alignment: widget.previewAlignment,
              child: widget.builder(context, values),
            ),
            const ResponsiveGap(16),
            const DividerWidget(),
            const ResponsiveGap(8),
            // The controls name code arguments — laid out as code reads.
            Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final k in widget.knobs)
                    if (k.control)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: context.screen.space(4),
                        ),
                        child: k.buildControl(
                          context,
                          _values[k.name],
                          (v) => setState(() => _values[k.name] = v),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The chosen values, read by name in [DemoPlayground.builder]: `k('variant')`.
class KnobValues {
  KnobValues._(this._values);

  final Map<String, Object?> _values;

  T call<T>(String name) => _values[name] as T;
}

/// One option of the widget under test, and the control that changes it.
abstract class Knob<T> {
  const Knob(
    this.name, {
    required this.initial,
    this.apiDefault,
    this.required = false,
    this.control = true,
    this.positional = false,
    this.inCall = true,
  });

  /// The argument's name in code.
  final String name;
  final T initial;

  /// The widget's own default — an argument at this value is left out of the
  /// written call.
  final T? apiDefault;

  /// Always written, whatever its value.
  final bool required;

  /// Shown as a control; `false` keeps a fixed argument in the written call.
  final bool control;

  /// Written first and without its name — `success('Saved')`.
  final bool positional;

  /// `false` for a control of the preview only (how many tabs to draw) —
  /// never written in the call.
  final bool inCall;

  /// What the control holds at first, and at the widget's default — the
  /// value itself for every knob but [ChoiceKnob].
  Object? get storedInitial => initial;
  Object? get storedApiDefault => apiDefault;

  /// The value the builder reads, from what the control holds.
  Object? resolve(Object? stored) => stored;

  /// How the held [value] is written in Dart.
  String codeOf(Object? value);

  Widget buildControl(
    BuildContext context,
    Object? value,
    ValueChanged<Object?> onChanged,
  );
}

/// One value of an enum, picked from chips.
class EnumKnob<T extends Enum> extends Knob<T> {
  EnumKnob(
    super.name,
    this.values,
    T initial, {
    T? apiDefault,
    String? typeName,
    super.required,
    super.positional,
  }) : typeName = typeName ?? values.first.runtimeType.toString(),
       super(initial: initial, apiDefault: apiDefault ?? initial);

  final List<T> values;

  /// The enum's name in code — given explicitly where obfuscation could
  /// rename the runtime type.
  final String typeName;

  @override
  String codeOf(Object? value) => '$typeName.${(value as T).name}';

  @override
  Widget buildControl(
    BuildContext context,
    Object? value,
    ValueChanged<Object?> onChanged,
  ) => _Labelled(
    name: name,
    child: ChipRow<T>(
      items: values,
      labelResolver: (v) => v.name,
      selectedValue: value as T,
      onSelected: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
}

/// One of a few named values that are not an enum — a colour token, an icon,
/// a sample text. [options] maps the code written to the value used.
class ChoiceKnob<T> extends Knob<T> {
  ChoiceKnob(
    super.name,
    this.options, {
    String? initialCode,
    this.apiDefaultCode,
    super.required,
    super.positional,
  }) : initialCode = initialCode ?? options.keys.first,
       super(initial: options[initialCode ?? options.keys.first] as T);

  final Map<String, T> options;
  final String initialCode;

  /// The code of the widget's own default — left out of the written call.
  final String? apiDefaultCode;

  @override
  T? get apiDefault => apiDefaultCode == null ? null : options[apiDefaultCode];

  @override
  Object? get storedInitial => initialCode;

  @override
  Object? get storedApiDefault => apiDefaultCode;

  @override
  Object? resolve(Object? stored) => options[stored];

  @override
  String codeOf(Object? value) => value! as String;

  @override
  Widget buildControl(
    BuildContext context,
    Object? value,
    ValueChanged<Object?> onChanged,
  ) => _Labelled(
    name: name,
    child: ChipRow<String>(
      items: options.keys.toList(),
      labelResolver: (c) => c,
      selectedValue: value! as String,
      onSelected: (c) {
        if (c != null) onChanged(c);
      },
    ),
  );
}

/// A `bool` argument as a switch.
class BoolKnob extends Knob<bool> {
  const BoolKnob(
    super.name, {
    super.initial = false,
    bool super.apiDefault = false,
    super.required,
    super.positional,
  });

  @override
  String codeOf(Object? value) => '$value';

  @override
  Widget buildControl(
    BuildContext context,
    Object? value,
    ValueChanged<Object?> onChanged,
  ) => Row(
    children: [
      Expanded(child: KnobName(name)),
      Switch.adaptive(value: value! as bool, onChanged: onChanged),
    ],
  );
}

/// A `String` argument as a text field.
class TextKnob extends Knob<String> {
  const TextKnob(
    super.name, {
    required super.initial,
    super.apiDefault,
    super.required,
    super.positional,
  });

  @override
  String codeOf(Object? value) => "'$value'";

  @override
  Widget buildControl(
    BuildContext context,
    Object? value,
    ValueChanged<Object?> onChanged,
  ) => _TextControl(name: name, value: value! as String, onChanged: onChanged);
}

/// A number argument as a slider.
class NumberKnob extends Knob<double> {
  const NumberKnob(
    super.name, {
    required super.initial,
    required this.min,
    required this.max,
    this.divisions,
    this.integer = false,
    super.apiDefault,
    super.required,
    super.positional,
    super.inCall,
  });

  final double min;
  final double max;
  final int? divisions;

  /// Written as an `int` (`3`, not `3.0`).
  final bool integer;

  @override
  String codeOf(Object? value) {
    final v = value! as double;
    return integer ? '${v.round()}' : v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
  }

  @override
  Widget buildControl(
    BuildContext context,
    Object? value,
    ValueChanged<Object?> onChanged,
  ) => Row(
    children: [
      KnobName(name),
      Expanded(
        child: Slider.adaptive(
          value: value! as double,
          min: min,
          max: max,
          divisions: divisions ?? (integer ? (max - min).round() : null),
          label: codeOf(value),
          onChanged: (v) => onChanged(integer ? v.roundToDouble() : v),
        ),
      ),
      SizedBox(
        width: context.screen.size(40),
        child: Text(codeOf(value), style: context.textTheme.bodySmall),
      ),
    ],
  );
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.name, required this.child});

  final String name;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [KnobName(name), const ResponsiveGap(4), child],
  );
}

/// A control's caption: what the option means in the reader's language, and
/// the argument's name in code beside it — `الشكل · variant`.
///
/// The meaning is the translation key `showcaseKnob<Name>`; a name without
/// one (or an English reader, whose label is the name) shows the name alone.
class KnobName extends StatelessWidget {
  const KnobName(this.name, {super.key});

  final String name;

  /// The option's meaning, or `null` when it has none apart from its name.
  static String? meaningOf(String name) {
    final key = 'showcaseKnob${name[0].toUpperCase()}${name.substring(1)}';
    final meaning = key.tr();
    return meaning == key || meaning == name ? null : meaning;
  }

  /// `الشكل · variant` as plain text — for a field's label.
  static String caption(String name) {
    final meaning = meaningOf(name);
    return meaning == null ? name : '$meaning · $name';
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final meaning = meaningOf(name);
    final translated = meaning != null;
    final colors = context.colors;
    return Text.rich(
      TextSpan(
        children: [
          if (translated) ...[
            TextSpan(
              text: meaning,
              style: context.textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const TextSpan(text: '  ·  '),
          ],
          TextSpan(text: name),
        ],
      ),
      style: context.textTheme.labelSmall?.copyWith(color: colors.textMuted),
    );
  }
}

class _TextControl extends StatefulWidget {
  const _TextControl({
    required this.name,
    required this.value,
    required this.onChanged,
  });

  final String name;
  final String value;
  final ValueChanged<Object?> onChanged;

  @override
  State<_TextControl> createState() => _TextControlState();
}

class _TextControlState extends State<_TextControl> {
  late final _c = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomTextField(
    controller: _c,
    labelText: KnobName.caption(widget.name),
    ltr: true,
    onChanged: widget.onChanged,
  );
}
