import 'package:flutter/material.dart';

import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// A playground for a call [DemoPlayground] cannot write: a static `show`
/// whose first argument is `context`, or a method whose shape changes with
/// the chosen options (`context.feedback.success(…)` vs `.show(FeedbackConfig(…))`).
///
/// The same knobs drive it; [code] composes the call from them, usually with
/// [writeCall] and [CallArgs.named].
class CallPlayground extends StatefulWidget {
  const CallPlayground({
    required this.knobs,
    required this.code,
    required this.builder,
    super.key,
  });

  final List<Knob<Object?>> knobs;
  final String Function(CallArgs a) code;
  final Widget Function(BuildContext context, CallArgs a) builder;

  @override
  State<CallPlayground> createState() => _CallPlaygroundState();
}

class _CallPlaygroundState extends State<CallPlayground> {
  late final Map<String, Object?> _values = {
    for (final k in widget.knobs) k.name: k.storedInitial,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final args = CallArgs._(widget.knobs, _values);

    return Padding(
      padding: EdgeInsets.only(bottom: context.screen.space(16)),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.bgNeutral,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Padding(
                  padding: EdgeInsets.all(context.screen.space(12)),
                  child: Text(
                    widget.code(args),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            const ResponsiveGap(16),
            widget.builder(context, args),
            const ResponsiveGap(16),
            const DividerWidget(),
            const ResponsiveGap(8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final k in widget.knobs)
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

/// The chosen values of a [CallPlayground], read by name: `a('tone')`.
class CallArgs {
  CallArgs._(this._knobs, this._values);

  final List<Knob<Object?>> _knobs;
  final Map<String, Object?> _values;

  T call<T>(String name) =>
      _knobs.firstWhere((k) => k.name == name).resolve(_values[name]) as T;

  /// `name: code` for every knob that is required or off its default, in
  /// order — leaving out [skip].
  List<String> named({Set<String> skip = const {}}) => [
    for (final k in _knobs)
      if (!skip.contains(k.name) &&
          (k.required || _values[k.name] != k.storedApiDefault))
        '${k.name}: ${k.codeOf(_values[k.name])}',
  ];
}

/// `call(args…)` one argument per line, as [DemoPlayground] writes it; a
/// nested call keeps its own indentation.
String writeCall(String call, List<String> args) {
  if (args.isEmpty) return '$call()';
  final lines = args.map((a) => '  ${a.replaceAll('\n', '\n  ')},').join('\n');
  return '$call(\n$lines\n)';
}

/// An optional number: off is `null`, on is a slider — `value` of a progress
/// indicator, where `null` means "indeterminate".
class OptionalNumberKnob extends Knob<double?> {
  const OptionalNumberKnob(
    super.name, {
    required super.initial,
    this.whenOn = 0.5,
    this.min = 0,
    this.max = 1,
    super.apiDefault,
  });

  /// The value the slider starts at when switched on.
  final double whenOn;
  final double min;
  final double max;

  @override
  String codeOf(Object? value) {
    if (value == null) return 'null';
    final v = value as double;
    return v.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  }

  @override
  Widget buildControl(
    BuildContext context,
    Object? value,
    ValueChanged<Object?> onChanged,
  ) {
    final v = value as double?;
    return Row(
      children: [
        KnobName(name),
        Switch.adaptive(
          value: v != null,
          onChanged: (on) => onChanged(on ? whenOn : null),
        ),
        Expanded(
          child: Slider.adaptive(
            value: v ?? whenOn,
            min: min,
            max: max,
            divisions: 20,
            onChanged: v == null ? null : onChanged,
          ),
        ),
        SizedBox(
          width: context.screen.size(40),
          child: Text(codeOf(v), style: context.textTheme.bodySmall),
        ),
      ],
    );
  }
}
