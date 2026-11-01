import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/foundation/value_objects/email.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The inputs as playgrounds — the text field (its validation shakes the
/// field: [ShakeOnError]), the select field, chips, radio options, the search
/// and filter bars — then focus that walks fields only and the form that
/// reveals its first missing field.
class InputsDemo extends StatefulWidget {
  const InputsDemo({super.key});

  @override
  State<InputsDemo> createState() => _InputsDemoState();
}

class _InputsDemoState extends State<InputsDemo> {
  final _form = GlobalKey<FormState>();
  final _reveal = GlobalKey<FormState>();
  bool? _fieldValid;
  int? _selected;
  int? _chip = 1;
  List<int> _tags = const [];
  int? _radio = 1;
  int? _revealSelected;
  String _query = '';
  bool _searching = false;
  String? _searched;
  bool _revealOk = false;

  static const _items = [1, 2, 3, 4];
  static const _manyItems = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  static const _prefixIcons = <String, Widget?>{
    'null': null,
    'Icon(Icons.person_outline)': Icon(Icons.person_outline),
    'Icon(Icons.email_outlined)': Icon(Icons.email_outlined),
  };

  static String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? LocaleKeys.fieldRequired.tr() : null;

  static String? _emailValidator(String? v) => Email.validate(
    v ?? '',
  ).fold((_) => LocaleKeys.invalidEmailAddress.tr(), (_) => null);

  String _item(int n) => LocaleKeys.showcaseItem.tr(args: ['$n']);

  // A fake lookup: the bar shows its spinner while "the request" runs.
  Future<void> _search(String q) async {
    setState(() => _searching = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _searching = false;
      _searched = q;
    });
  }

  Widget _note(String text, {Color? color}) => Text(
    text,
    style: context.textTheme.bodySmall?.copyWith(
      color: color ?? context.colors.textSecondary,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoPlayground(
          call: 'CustomTextField',
          previewAlignment: AlignmentDirectional.topStart,
          knobs: [
            TextKnob('labelText', initial: LocaleKeys.showcaseName.tr()),
            TextKnob('hint', initial: LocaleKeys.showcaseInputsHint.tr()),
            const BoolKnob('showRequired', initial: true),
            const BoolKnob('showOption'),
            const BoolKnob('isFieldObscure'),
            const BoolKnob('enabled', initial: true, apiDefault: true),
            ChoiceKnob<bool?>('ltr', const {
              'null': null,
              'true': true,
              'false': false,
            }, apiDefaultCode: 'null'),
            ChoiceKnob<TextInputType?>('keyboardType', const {
              'null': null,
              'TextInputType.emailAddress': TextInputType.emailAddress,
              'TextInputType.number': TextInputType.number,
              'TextInputType.phone': TextInputType.phone,
            }, apiDefaultCode: 'null'),
            ChoiceKnob<Widget?>(
              'prefixIcon',
              _prefixIcons,
              apiDefaultCode: 'null',
            ),
            ChoiceKnob<int?>('maxLines', const {
              'null': null,
              '3': 3,
              '5': 5,
            }, apiDefaultCode: 'null'),
            ChoiceKnob<int?>('maxLength', const {
              'null': null,
              '20': 20,
              '200': 200,
            }, apiDefaultCode: 'null'),
            EnumKnob(
              'autovalidateMode',
              AutovalidateMode.values,
              AutovalidateMode.disabled,
              typeName: 'AutovalidateMode',
            ),
            ChoiceKnob<String? Function(String?)?>(
              'validator',
              const {
                'null': null,
                '(v) => (v ?? \'\').trim().isEmpty ? '
                        'LocaleKeys.fieldRequired.tr() : null':
                    _requiredValidator,
                '(v) => Email.validate(v ?? \'\').fold('
                        '(_) => LocaleKeys.invalidEmailAddress.tr(), '
                        '(_) => null)':
                    _emailValidator,
              },
              initialCode:
                  '(v) => (v ?? \'\').trim().isEmpty ? '
                  'LocaleKeys.fieldRequired.tr() : null',
              apiDefaultCode: 'null',
            ),
          ],
          builder: (context, k) {
            final obscure = k<bool>('isFieldObscure');
            final lines = k<int?>('maxLines');
            return Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    // The obscure state is read once, when the field is made.
                    key: ValueKey(obscure),
                    labelText: k('labelText'),
                    hint: k('hint'),
                    showRequired: k('showRequired'),
                    showOption: k('showOption'),
                    isFieldObscure: obscure,
                    enabled: k('enabled'),
                    ltr: k('ltr'),
                    keyboardType: k('keyboardType'),
                    prefixIcon: k('prefixIcon'),
                    // An obscured field is one line — Flutter asserts it.
                    maxLines: obscure ? null : lines,
                    maxLength: k('maxLength'),
                    autovalidateMode: k('autovalidateMode'),
                    validator: k('validator'),
                  ),
                  if (obscure && lines != null) ...[
                    8.heightBox,
                    _note(LocaleKeys.showcaseInputsObscureOneLine.tr()),
                  ],
                  12.heightBox,
                  AppButton(
                    text: LocaleKeys.showcaseInputsValidate.tr(),
                    variant: AppButtonVariant.tonal,
                    onTap: () => setState(
                      () => _fieldValid = _form.currentState?.validate(),
                    ),
                  ),
                  if (_fieldValid != null) ...[
                    8.heightBox,
                    _note(
                      _fieldValid!
                          ? LocaleKeys.showcaseInputsValid.tr()
                          : LocaleKeys.showcaseInputsShook.tr(),
                      color: _fieldValid!
                          ? context.colors.statusSuccessFg
                          : context.colors.error,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        DemoPlayground(
          call: 'AppSelectField<int>',
          previewAlignment: AlignmentDirectional.topStart,
          knobs: [
            EnumKnob('mode', AppSelectMode.values, AppSelectMode.dropdown),
            TextKnob('labelText', initial: LocaleKeys.showcaseInputsTitle.tr()),
            TextKnob('hint', initial: LocaleKeys.showcaseDialogsPickTitle.tr()),
            const BoolKnob('showRequired'),
            const BoolKnob('showOption'),
            const BoolKnob('enabled', initial: true, apiDefault: true),
            ChoiceKnob<Widget?>(
              'prefixIcon',
              _prefixIcons,
              apiDefaultCode: 'null',
            ),
          ],
          trailingCode: const [
            'items: items',
            "labelResolver: (n) => LocaleKeys.showcaseItem.tr(args: ['\$n'])",
            'value: selected',
            'onChanged: (v) => setState(() => selected = v)',
          ],
          builder: (context, k) => AppSelectField<int>(
            items: _manyItems,
            labelResolver: _item,
            mode: k('mode'),
            labelText: k('labelText'),
            hint: k('hint'),
            showRequired: k('showRequired'),
            showOption: k('showOption'),
            enabled: k('enabled'),
            prefixIcon: k('prefixIcon'),
            value: _selected,
            onChanged: (v) => setState(() => _selected = v),
          ),
        ),
        DemoPlayground(
          call: 'ChipRow<int>',
          previewAlignment: AlignmentDirectional.topStart,
          knobs: const [
            BoolKnob('scrollable', initial: true, apiDefault: true),
            NumberKnob(
              'spacing',
              initial: 8,
              min: 0,
              max: 24,
              divisions: 12,
              apiDefault: 8,
            ),
          ],
          trailingCode: const [
            'items: items',
            'labelResolver: …',
            'selectedValue: chip',
            'onSelected: (v) => setState(() => chip = v)',
          ],
          builder: (context, k) => ChipRow<int>(
            items: _manyItems.take(8).toList(),
            labelResolver: _item,
            scrollable: k('scrollable'),
            spacing: k('spacing'),
            selectedValue: _chip,
            onSelected: (v) => setState(() => _chip = v),
          ),
        ),
        DemoPlayground(
          call: 'ChipRow<int>.multi',
          previewAlignment: AlignmentDirectional.topStart,
          knobs: const [
            BoolKnob('scrollable', initial: true, apiDefault: true),
            NumberKnob(
              'spacing',
              initial: 8,
              min: 0,
              max: 24,
              divisions: 12,
              apiDefault: 8,
            ),
          ],
          trailingCode: const [
            'items: items',
            'labelResolver: …',
            'selectedValues: tags',
            'onChanged: (v) => setState(() => tags = v)',
          ],
          builder: (context, k) => ChipRow<int>.multi(
            items: _manyItems.take(8).toList(),
            labelResolver: _item,
            scrollable: k('scrollable'),
            spacing: k('spacing'),
            selectedValues: _tags,
            onChanged: (v) => setState(() => _tags = v),
          ),
        ),
        DemoPlayground(
          call: 'AppRadioGroup<int>',
          previewAlignment: AlignmentDirectional.topStart,
          knobs: [
            ChoiceKnob<bool>('descriptions', const {
              'const {}': false,
              '{1: …, 2: …, 3: …}': true,
            }, apiDefaultCode: 'const {}'),
            ChoiceKnob<bool>(
              'onDeselect',
              const {'null': false, '() => setState(() => value = null)': true},
              initialCode: '() => setState(() => value = null)',
              apiDefaultCode: 'null',
            ),
            const BoolKnob('enabled', initial: true, apiDefault: true),
            TextKnob(
              'footnote',
              initial: LocaleKeys.showcaseInputsFootnote.tr(),
              // Empty = not passed.
              apiDefault: '',
            ),
            const NumberKnob(
              'spacing',
              initial: 8,
              min: 0,
              max: 24,
              divisions: 12,
              apiDefault: 8,
            ),
          ],
          trailingCode: const [
            'options: {1: …, 2: …, 3: …}',
            'value: value',
            'onChanged: (v) => setState(() => value = v)',
          ],
          builder: (context, k) {
            final String footnote = k('footnote');
            return AppRadioGroup<int>(
              options: {for (final n in _items.take(3)) n: _item(n)},
              descriptions: k<bool>('descriptions')
                  ? {
                      for (final n in _items.take(3))
                        n: LocaleKeys.showcaseInputsOptionDescription.tr(
                          args: ['$n'],
                        ),
                    }
                  : const {},
              value: _radio,
              onChanged: (v) => setState(() => _radio = v),
              onDeselect: k<bool>('onDeselect')
                  ? () => setState(() => _radio = null)
                  : null,
              enabled: k('enabled'),
              footnote: footnote.isEmpty ? null : footnote,
              spacing: k('spacing'),
            );
          },
        ),
        DemoPlayground(
          call: 'AppSearchBar',
          previewAlignment: AlignmentDirectional.topStart,
          knobs: [
            TextKnob('hint', initial: LocaleKeys.showcaseInputsSearchHint.tr()),
            ChoiceKnob<Duration>(
              'debounceDuration',
              const {
                'const Duration(milliseconds: 400)': Duration(
                  milliseconds: 400,
                ),
                'Duration.zero': Duration.zero,
                'const Duration(seconds: 1)': Duration(seconds: 1),
              },
              apiDefaultCode: 'const Duration(milliseconds: 400)',
            ),
            const BoolKnob('isLoading'),
          ],
          trailingCode: const [
            'onSearch: (q) => cubit.search(q)',
            'onClear: () => cubit.clear()',
          ],
          builder: (context, k) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchBar(
                hint: k('hint'),
                debounceDuration: k('debounceDuration'),
                // The fake lookup spins it too.
                isLoading: k<bool>('isLoading') || _searching,
                onSearch: _search,
                onClear: () => setState(() => _searched = null),
              ),
              if (_searched != null) ...[
                8.heightBox,
                _note(LocaleKeys.showcaseInputsSearched.tr(args: [_searched!])),
              ],
            ],
          ),
        ),
        DemoPlayground(
          call: 'ListFilterBar',
          previewAlignment: AlignmentDirectional.topStart,
          knobs: [
            TextKnob('hint', initial: LocaleKeys.showcaseInputsSearchHint.tr()),
            const BoolKnob('isLoading'),
            ChoiceKnob<bool>(
              'onClearAll',
              const {'null': false, '() => cubit.clearFilters()': true},
              initialCode: '() => cubit.clearFilters()',
              apiDefaultCode: 'null',
            ),
          ],
          trailingCode: const [
            'onSearch: (q) => cubit.search(q)',
            'onClearSearch: () => cubit.search(\'\')',
            'activeFilters: [ /* the multi chips above */ ]',
          ],
          builder: (context, k) => ListFilterBar(
            hint: k('hint'),
            isLoading: k('isLoading'),
            onSearch: (q) => setState(() => _query = q),
            onClearSearch: () => setState(() => _query = ''),
            // The search term counts as a filter too, and the multi chips
            // above feed the rest.
            activeFilters: [
              if (_query.isNotEmpty) '"$_query"',
              for (final t in _tags) _item(t),
            ],
            onClearAll: k<bool>('onClearAll')
                ? () => setState(() => _tags = const [])
                : null,
          ),
        ),
        DemoBlock(
          code: 'CustomTextField(textInputAction: next) — InputFocusNode',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _note(LocaleKeys.showcaseInputsNextHint.tr()),
              12.heightBox,
              CustomTextField(labelText: LocaleKeys.showcaseInputsTitle.tr()),
              12.heightBox,
              // Focusable, yet "next" walks past them: only the fields' nodes
              // carry the InputFocusNode tag.
              ChipRow<int>(
                items: _items,
                labelResolver: _item,
                selectedValue: _chip,
                onSelected: (v) => setState(() => _chip = v),
              ),
              12.heightBox,
              CustomTextField(labelText: LocaleKeys.showcaseName.tr()),
              12.heightBox,
              CustomTextField(
                labelText: LocaleKeys.password.tr(),
                isFieldObscure: true,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'formKey.validateAndReveal() — FormReveal',
          child: Form(
            key: _reveal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _note(LocaleKeys.showcaseInputsRevealHint.tr()),
                12.heightBox,
                CustomTextField(
                  labelText: LocaleKeys.showcaseInputsTitle.tr(),
                  showRequired: true,
                  validator: _requiredValidator,
                ),
                12.heightBox,
                AppSelectField<int>(
                  items: _items,
                  labelResolver: _item,
                  hint: LocaleKeys.showcaseDialogsPickTitle.tr(),
                  showRequired: true,
                  value: _revealSelected,
                  validator: (v) =>
                      v == null ? LocaleKeys.fieldRequired.tr() : null,
                  onChanged: (v) => setState(() => _revealSelected = v),
                ),
                12.heightBox,
                CustomTextField(
                  labelText: LocaleKeys.showcaseInputsBody.tr(),
                  showRequired: true,
                  maxLines: 3,
                  validator: _requiredValidator,
                ),
                12.heightBox,
                AppButton(
                  text: LocaleKeys.save.tr(),
                  onTap: () =>
                      setState(() => _revealOk = _reveal.validateAndReveal()),
                ),
                if (_revealOk) ...[
                  8.heightBox,
                  _note(
                    LocaleKeys.showcaseInputsValid.tr(),
                    color: context.colors.statusSuccessFg,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
