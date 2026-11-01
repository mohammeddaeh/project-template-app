import 'package:dartz/dartz.dart' show Either;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/foundation/extensions/num_extensions.dart';
import 'package:app_template/core/foundation/utils/arabic_digits.dart';
import 'package:app_template/core/foundation/utils/calendar_names.dart';
import 'package:app_template/core/foundation/utils/hijri_date_extension.dart';
import 'package:app_template/core/foundation/utils/natural_order.dart';
import 'package:app_template/core/foundation/utils/validators.dart';
import 'package:app_template/core/foundation/value_objects/value_objects.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The pure-Dart tools under `core/foundation/` that are not formats — value
/// objects, digits, the Hijri calendar, natural ordering, number extensions.
/// Each takes an input and shows what it returns, beside the call.
class ToolsDemo extends StatefulWidget {
  const ToolsDemo({super.key});

  @override
  State<ToolsDemo> createState() => _ToolsDemoState();
}

class _ToolsDemoState extends State<ToolsDemo> {
  late final _email = TextEditingController(text: ' Name@Example.com ');
  late final _phone = TextEditingController(text: '050 123 4567');
  late final _digits = TextEditingController(
    text: LocaleKeys.showcaseToolsSampleText.tr(),
  );
  late final _int = TextEditingController(text: '15320');
  late final _password = TextEditingController(text: 'secret12');

  String _countryCode = '+966';
  double _from = -6;
  double _to = 0;
  bool _allowFuture = true;
  int _dayShift = 0;
  double _adjustment = 0;
  List<int> _order = [10, 2, 1, 21, 3];

  @override
  void dispose() {
    for (final c in [_email, _phone, _digits, _int, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  void _refresh(Object? _) => setState(() {});

  /// `Right` → the normalized value; `Left` → the field messages.
  static (bool, String) _either<T>(Either<ValidationFailure, T> r) =>
      r.fold((f) => (false, f.fields.values.join(' · ')), (v) => (true, '$v'));

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day + _dayShift);
    final adj = _adjustment.round();
    final hijri = day.tryToHijri(adjustment: adj);
    final n = int.tryParse(_int.text.trim());
    final range = DateRange.create(
      from: DateTime(today.year, today.month, today.day + _from.round()),
      to: DateTime(today.year, today.month, today.day + _to.round()),
      allowFuture: _allowFuture,
    );
    final items = [
      for (final i in _order) LocaleKeys.showcaseItem.tr(args: ['$i']),
    ];
    final naturalSorted = [...items]..sort(NaturalOrder.compare);
    final plainSorted = [...items]..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Tool(
          code: 'Email.validate(input)',
          input: CustomTextField(
            controller: _email,
            labelText: LocaleKeys.showcaseToolsEmail.tr(),
            keyboardType: TextInputType.emailAddress,
            ltr: true,
            onChanged: _refresh,
          ),
          result: _Verdict(_either(Email.validate(_email.text))),
        ),
        _Tool(
          code: "PhoneNumber.parse(input, defaultCountryCode: '$_countryCode')",
          input: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _phone,
                labelText: LocaleKeys.showcaseToolsPhone.tr(),
                keyboardType: TextInputType.phone,
                ltr: true,
                onChanged: _refresh,
              ),
              8.heightBox,
              Directionality(
                textDirection: TextDirection.ltr,
                child: ChipRow<String>(
                  items: const ['+966', '+962', '+20', '+1'],
                  labelResolver: (c) => c,
                  selectedValue: _countryCode,
                  onSelected: (c) {
                    if (c != null) setState(() => _countryCode = c);
                  },
                ),
              ),
            ],
          ),
          result: _Verdict(
            _either(
              PhoneNumber.parse(_phone.text, defaultCountryCode: _countryCode),
            ),
          ),
        ),
        _Tool(
          code:
              'DateRange.create(from: today${_signed(_from.round())}, '
              'to: today${_signed(_to.round())}, allowFuture: $_allowFuture)',
          input: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Slider(
                label: LocaleKeys.showcaseToolsFrom.tr(),
                value: _from,
                min: -30,
                max: 30,
                onChanged: (v) => setState(() => _from = v),
              ),
              _Slider(
                label: LocaleKeys.showcaseToolsTo.tr(),
                value: _to,
                min: -30,
                max: 30,
                onChanged: (v) => setState(() => _to = v),
              ),
              _Switch(
                name: 'allowFuture',
                value: _allowFuture,
                onChanged: (v) => setState(() => _allowFuture = v),
              ),
            ],
          ),
          result: range.fold(
            (f) => _Verdict((false, f.fields.values.join(' · '))),
            (r) => _Lines([
              ('daysCount', '${r.daysCount}'),
              ('isSingleDay', '${r.isSingleDay}'),
              ('isToday', '${r.isToday}'),
            ]),
          ),
        ),
        _Tool(
          code: 'toArabicIndicDigits(input)',
          input: CustomTextField(
            controller: _digits,
            labelText: LocaleKeys.showcaseToolsText.tr(),
            onChanged: _refresh,
          ),
          result: Text(
            toArabicIndicDigits(_digits.text),
            style: context.textTheme.titleMedium,
          ),
        ),
        _Tool(
          code: 'date.tryToHijri(adjustment: $adj)',
          input: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: LocaleKeys.showcaseFormatsPrevDay.tr(),
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _dayShift--),
                  ),
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        'DateTime(${day.year}, ${day.month}, ${day.day})',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: LocaleKeys.showcaseFormatsNextDay.tr(),
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() => _dayShift++),
                  ),
                ],
              ),
              _Slider(
                label: LocaleKeys.showcaseToolsAdjustment.tr(),
                value: _adjustment,
                min: -2,
                max: 2,
                onChanged: (v) => setState(() => _adjustment = v),
              ),
            ],
          ),
          result: _Lines([
            ('tryToHijri(adjustment: $adj)', '$hijri'),
            ("toHijriString(language: 'ar')", day.toHijriString()),
            (
              "toHijriString(language: 'en')",
              day.toHijriString(language: 'en'),
            ),
            (
              'CalendarNames.weekday(${day.weekday}, arabic: true)',
              CalendarNames.weekday(day.weekday, arabic: true),
            ),
            (
              'CalendarNames.weekday(${day.weekday}, arabic: false)',
              CalendarNames.weekday(day.weekday, arabic: false),
            ),
          ]),
        ),
        _Tool(
          code: 'list.sort(NaturalOrder.compare)',
          input: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              text: LocaleKeys.showcaseToolsShuffle.tr(),
              variant: AppButtonVariant.tonal,
              size: AppButtonSize.small,
              leadingIcon: Icons.shuffle,
              onTap: () => setState(() => _order = [..._order]..shuffle()),
            ),
          ),
          result: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SortedList('list.sort()', plainSorted)),
              12.widthBox,
              Expanded(
                child: _SortedList(
                  'list.sort(NaturalOrder.compare)',
                  naturalSorted,
                ),
              ),
            ],
          ),
        ),
        _Tool(
          code: 'int · IntEx',
          input: CustomTextField(
            controller: _int,
            labelText: LocaleKeys.showcaseToolsNumber.tr(),
            keyboardType: TextInputType.number,
            ltr: true,
            onChanged: _refresh,
          ),
          result: n == null
              ? const _Verdict((false, '—'))
              : _Lines([
                  ('n.formatNumber', n.formatNumber),
                  ('n.getPlus()', n.getPlus()),
                  ('n.getTimeFromIntSeconds', n.getTimeFromIntSeconds),
                  ('(n / 7).formatNumber', (n / 7).formatNumber),
                ]),
        ),
        _Tool(
          code: 'CustomRegex.passwordRegex.hasMatch(input)',
          input: CustomTextField(
            controller: _password,
            labelText: LocaleKeys.password.tr(),
            ltr: true,
            onChanged: _refresh,
          ),
          result: _Verdict((
            CustomRegex.passwordRegex.hasMatch(_password.text),
            CustomRegex.passwordRegex.pattern,
          )),
        ),
      ],
    );
  }

  static String _signed(int days) => days == 0
      ? ''
      : days > 0
      ? ' + $days'
      : ' − ${-days}';
}

/// One tool: the call, its input, what it returns.
class _Tool extends StatelessWidget {
  const _Tool({required this.code, required this.input, required this.result});

  final String code;
  final Widget input;
  final Widget result;

  @override
  Widget build(BuildContext context) => DemoBlock(
    code: code,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        input,
        12.heightBox,
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.bgNeutral,
            borderRadius: AppRadius.smRadius,
          ),
          child: Padding(padding: 12.allPadding, child: result),
        ),
      ],
    ),
  );
}

/// Valid or not, and what came back — a normalized value or the reason.
class _Verdict extends StatelessWidget {
  const _Verdict(this.verdict);

  final (bool, String) verdict;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final (ok, text) = verdict;
    return Row(
      children: [
        AppLabel(
          labelText: ok
              ? LocaleKeys.showcaseToolsValid.tr()
              : LocaleKeys.showcaseToolsInvalid.tr(),
          variant: ok ? AppLabelVariant.success : AppLabelVariant.error,
          icon: ok ? Icons.check_rounded : Icons.close_rounded,
          compact: true,
        ),
        8.widthBox,
        Expanded(child: Text(text, style: context.textTheme.bodyMedium)),
      ],
    );
  }
}

/// Getter → value rows, the getter written as code.
class _Lines extends StatelessWidget {
  const _Lines(this.rows);

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (name, value) in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Code(name),
              Text(value, style: context.textTheme.titleSmall),
            ],
          ),
        ),
    ],
  );
}

class _SortedList extends StatelessWidget {
  const _SortedList(this.title, this.items);

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Code(title),
      4.heightBox,
      for (final i in items) Text(i, style: context.textTheme.bodyMedium),
    ],
  );
}

class _Code extends StatelessWidget {
  const _Code(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text(
      text,
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colors.textMuted,
      ),
    ),
  );
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(flex: 2, child: Text(label, style: context.textTheme.bodySmall)),
      Expanded(
        flex: 3,
        child: Slider.adaptive(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          label: value.toStringAsFixed(0),
          onChanged: onChanged,
        ),
      ),
      SizedBox(
        width: 32,
        child: Text(
          value.toStringAsFixed(0),
          style: context.textTheme.bodySmall,
        ),
      ),
    ],
  );
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.name,
    required this.value,
    required this.onChanged,
  });

  final String name;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Row(
      children: [
        Expanded(child: _Code(name)),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    ),
  );
}
