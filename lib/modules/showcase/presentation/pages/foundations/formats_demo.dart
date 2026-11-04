import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/core/foundation/formatting/app_formats.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/date_picker_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The format shapes built from their parts: pick a date, a time, a number,
/// then choose each part of `AppDateFormat`, `AppTimeFormat`,
/// `AppNumberFormat`, `AppDistanceFormat` and `AppDurationFormat` — the
/// result shows in Arabic and English side by side, with the call to write.
class FormatsDemo extends StatefulWidget {
  const FormatsDemo({super.key});

  @override
  State<FormatsDemo> createState() => _FormatsDemoState();
}

class _FormatsDemoState extends State<FormatsDemo> {
  // The Umm al-Qura table's range — a Hijri shape has no answer outside it.
  static final _min = DateTime(1924, 8, 1);
  static final _max = DateTime(2077, 11, 16);

  late DateTime _date = _dateOnly(DateTime.now());
  double _hour = 14;
  double _minute = 5;
  bool _h24 = false;
  late final _number = TextEditingController(text: '1234567');
  double _km = 0.85;
  double _seconds = 3912;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  void _shift(int days) {
    final next = DateTime(_date.year, _date.month, _date.day + days);
    if (next.isBefore(_min) || next.isAfter(_max)) return;
    setState(() => _date = next);
  }

  Future<void> _pick() async {
    final picked = await context.showDatePicker(
      initDate: _date,
      minDate: _min,
      maxDate: _max,
    );
    if (!mounted || picked == null) return;
    setState(() => _date = _dateOnly(picked));
  }

  String get _dateCode =>
      'DateTime(${_date.year}, ${_date.month}, ${_date.day})';

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final h = _hour.round();
    final m = _minute.round();
    final n = int.tryParse(_number.text.trim());
    final s = _seconds.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code: 'final date = $_dateCode;',
          child: Row(
            children: [
              IconButton(
                tooltip: LocaleKeys.showcaseFormatsPrevDay.tr(),
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1),
              ),
              Expanded(
                child: AppButton(
                  text: LocaleKeys.showcaseFormatsPick.tr(),
                  variant: AppButtonVariant.tonal,
                  leadingIcon: Icons.calendar_month_outlined,
                  onTap: _pick,
                ),
              ),
              IconButton(
                tooltip: LocaleKeys.showcaseFormatsNextDay.tr(),
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shift(1),
              ),
            ],
          ),
        ),
        DemoPlayground(
          call: 'AppDateFormat',
          knobs: [
            EnumKnob(
              'calendar',
              DateCalendar.values,
              DateCalendar.gregorian,
              typeName: 'DateCalendar',
              required: true,
            ),
            EnumKnob(
              'months',
              MonthNames.values,
              MonthNames.gregorian,
              typeName: 'MonthNames',
              required: true,
            ),
            const BoolKnob('weekday'),
            EnumKnob(
              'weekdayJoin',
              WeekdayJoin.values,
              WeekdayJoin.comma,
              typeName: 'WeekdayJoin',
            ),
            const BoolKnob('year', initial: true, apiDefault: true),
            EnumKnob(
              'era',
              EraMarker.values,
              EraMarker.none,
              typeName: 'EraMarker',
            ),
            EnumKnob(
              'digits',
              ArabicDigits.values,
              ArabicDigits.latin,
              typeName: 'ArabicDigits',
            ),
            const BoolKnob('englishMonthFirst'),
            EnumKnob(
              'englishMonths',
              EnglishMonths.values,
              EnglishMonths.full,
              typeName: 'EnglishMonths',
            ),
          ],
          builder: (context, k) {
            final f = AppDateFormat(
              calendar: k('calendar'),
              months: k('months'),
              weekday: k('weekday'),
              weekdayJoin: k('weekdayJoin'),
              year: k('year'),
              era: k('era'),
              digits: k('digits'),
              englishMonthFirst: k('englishMonthFirst'),
              englishMonths: k('englishMonths'),
            );
            return _Results(
              code: '.apply(date, language: …)',
              ar: f.apply(_date, language: 'ar'),
              en: f.apply(_date, language: 'en'),
              current: AppDateText.format(
                _date,
                format: f,
                style: context.textTheme.titleMedium,
              ),
            );
          },
        ),
        DemoPlayground(
          call: 'AppDateText',
          knobs: [
            EnumKnob(
              'calendar',
              AppDateCalendar.values,
              AppDateCalendar.hijri,
              typeName: 'AppDateCalendar',
            ),
            EnumKnob(
              'layout',
              AppDateLayout.values,
              AppDateLayout.stacked,
              typeName: 'AppDateLayout',
            ),
            EnumKnob(
              'monthFormat',
              AppDateMonthFormat.values,
              AppDateMonthFormat.nameFull,
              typeName: 'AppDateMonthFormat',
            ),
            EnumKnob(
              'language',
              AppDateLanguage.values,
              AppDateLanguage.auto,
              typeName: 'AppDateLanguage',
            ),
            ChoiceKnob<String>('partSeparator', const {
              "'/'": '/',
              "'-'": '-',
              "'.'": '.',
              "' '": ' ',
            }, apiDefaultCode: "'/'"),
            ChoiceKnob<String>('calendarSeparator', const {
              "'  •  '": '  •  ',
              "' | '": ' | ',
              "' — '": ' — ',
            }, apiDefaultCode: "'  •  '"),
          ],
          // Dart takes the positional argument after the named ones too.
          trailingCode: const ['date'],
          builder: (context, k) => AppDateText(
            _date,
            calendar: k('calendar'),
            layout: k('layout'),
            monthFormat: k('monthFormat'),
            language: k('language'),
            partSeparator: k('partSeparator'),
            calendarSeparator: k('calendarSeparator'),
            style: context.textTheme.titleMedium,
          ),
        ),
        DemoPlayground(
          call: 'AppTimeFormat',
          knobs: [
            EnumKnob(
              'clock',
              TimeClock.values,
              TimeClock.preference,
              typeName: 'TimeClock',
            ),
            const BoolKnob('padTwelveHour'),
            const BoolKnob('suffix'),
            EnumKnob(
              'digits',
              ArabicDigits.values,
              ArabicDigits.latin,
              typeName: 'ArabicDigits',
            ),
          ],
          builder: (context, k) {
            final f = AppTimeFormat(
              clock: k('clock'),
              padTwelveHour: k('padTwelveHour'),
              suffix: k('suffix'),
              digits: k('digits'),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SliderRow(
                  name: 'hour',
                  value: _hour,
                  max: 23,
                  onChanged: (v) => setState(() => _hour = v),
                ),
                _SliderRow(
                  name: 'minute',
                  value: _minute,
                  max: 59,
                  onChanged: (v) => setState(() => _minute = v),
                ),
                _SwitchRow(
                  name: 'h24',
                  value: _h24,
                  onChanged: (v) => setState(() => _h24 = v),
                ),
                const ResponsiveGap(8),
                _Results(
                  code: '.apply($h, $m, language: …, h24: $_h24)',
                  ar: f.apply(h, m, language: 'ar', h24: _h24),
                  en: f.apply(h, m, language: 'en', h24: _h24),
                ),
              ],
            );
          },
        ),
        DemoPlayground(
          call: 'AppNumberFormat',
          knobs: [
            const BoolKnob('grouping', initial: true, apiDefault: true),
            EnumKnob(
              'digits',
              ArabicDigits.values,
              ArabicDigits.latin,
              typeName: 'ArabicDigits',
            ),
          ],
          builder: (context, k) {
            final f = AppNumberFormat(
              grouping: k('grouping'),
              digits: k('digits'),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _number,
                  labelText: LocaleKeys.showcaseFormatsNumber.tr(),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  ltr: true,
                  onChanged: (_) => setState(() {}),
                ),
                const ResponsiveGap(12),
                _Results(
                  code: '.apply(${n ?? '…'}, language: …)',
                  ar: n == null ? '—' : f.apply(n, language: 'ar'),
                  en: n == null ? '—' : f.apply(n, language: 'en'),
                ),
              ],
            );
          },
        ),
        DemoPlayground(
          call: 'AppDistanceFormat',
          knobs: const [BoolKnob('approximate')],
          builder: (context, k) {
            final d = AppDistanceFormat(
              approximate: k('approximate'),
            ).apply(_km);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SliderRow(
                  name: 'km',
                  value: _km,
                  max: 5,
                  divisions: 100,
                  decimals: 2,
                  onChanged: (v) => setState(() => _km = v),
                ),
                const ResponsiveGap(8),
                _Results(
                  code:
                      '.apply(${_km.toStringAsFixed(2)}) → '
                      '${d == null ? 'null' : "AppDistance('${d.value}', meters: ${d.meters})"}',
                  current: Text(
                    d == null
                        ? LocaleKeys.showcaseFormatsNothing.tr()
                        : (d.meters
                                  ? LocaleKeys.showcaseFormatsMeters
                                  : LocaleKeys.showcaseFormatsKm)
                              .tr(args: [d.value]),
                    style: context.textTheme.titleMedium,
                  ),
                ),
              ],
            );
          },
        ),
        DemoPlayground(
          call: 'AppDurationFormat',
          knobs: const [BoolKnob('hours', initial: true, apiDefault: true)],
          builder: (context, k) {
            final f = AppDurationFormat(hours: k('hours'));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SliderRow(
                  name: 'seconds',
                  value: _seconds,
                  max: 7200,
                  divisions: 240,
                  onChanged: (v) => setState(() => _seconds = v),
                ),
                const ResponsiveGap(8),
                _Results(
                  code: '.apply($s)',
                  current: Text(
                    f.apply(s),
                    style: context.textTheme.titleMedium,
                  ),
                ),
              ],
            );
          },
        ),
        // The named catalog a screen actually uses, on the same inputs.
        DemoBlock(
          code: 'AppDateFormats · AppTimeFormats · AppNumberFormats',
          child: Builder(
            builder: (context) {
              final language = Localizations.localeOf(context).languageCode;
              final rows = [
                (
                  'AppDateFormats.listDate',
                  AppDateFormats.listDate.apply(_date, language: language),
                ),
                (
                  'AppDateFormats.detailHijri',
                  AppDateFormats.detailHijri.apply(_date, language: language),
                ),
                (
                  'AppTimeFormats.listTime',
                  AppTimeFormats.listTime.apply(
                    h,
                    m,
                    language: language,
                    h24: _h24,
                  ),
                ),
                (
                  'AppNumberFormats.count',
                  n == null
                      ? '—'
                      : AppNumberFormats.count.apply(n, language: language),
                ),
                (
                  'AppNumberFormats.countdown',
                  AppNumberFormats.countdown.apply(s),
                ),
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (name, value) in rows)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: context.screen.space(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Code(name),
                          Text(value, style: context.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A line of code, muted and left to right.
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

/// The `apply` call, then its result in Arabic and English (each in its own
/// direction) and/or as drawn in the current language.
class _Results extends StatelessWidget {
  const _Results({required this.code, this.ar, this.en, this.current});

  final String code;
  final String? ar;
  final String? en;
  final Widget? current;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    Widget line(String tag, String text, TextDirection dir) => Padding(
      padding: EdgeInsets.symmetric(vertical: context.screen.space(2)),
      child: Row(
        children: [
          SizedBox(width: context.screen.size(28), child: _Code(tag)),
          Expanded(
            child: Directionality(
              textDirection: dir,
              child: Text(text, style: context.textTheme.titleMedium),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Code(code),
        const ResponsiveGap(6),
        if (ar != null) line('ar', ar!, TextDirection.rtl),
        if (en != null) line('en', en!, TextDirection.ltr),
        if (current != null) ...[
          if (ar != null) ...[
            const ResponsiveGap(8),
            Text(
              LocaleKeys.showcaseFormatsCurrent.tr(),
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ],
          current!,
        ],
      ],
    );
  }
}

/// An input of the `apply` call (not of the format) as a slider.
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.name,
    required this.value,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.decimals = 0,
  });

  final String name;
  final double value;
  final double max;
  final int? divisions;
  final int decimals;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Row(
      children: [
        SizedBox(width: context.screen.size(56), child: _Code(name)),
        Expanded(
          child: Slider.adaptive(
            value: value,
            max: max,
            divisions: divisions ?? max.round(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: context.screen.size(44),
          child: Text(
            value.toStringAsFixed(decimals),
            style: context.textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
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
