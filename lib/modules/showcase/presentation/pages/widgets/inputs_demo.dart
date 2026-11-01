import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The text field with its validation shake and its modes, focus that walks
/// fields only, the search and filter bars, the select field, chips and radio
/// options.
class InputsDemo extends StatefulWidget {
  const InputsDemo({super.key});

  @override
  State<InputsDemo> createState() => _InputsDemoState();
}

class _InputsDemoState extends State<InputsDemo> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  int? _selected;
  int _chip = 1;
  int? _radio = 1;
  int? _sheetSelected;
  int? _revealSelected;
  List<int> _tags = const [];
  String _query = '';
  bool _searching = false;
  String? _searched;
  final _reveal = GlobalKey<FormState>();
  bool _revealOk = false;

  static const _items = [1, 2, 3, 4];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

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

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? LocaleKeys.fieldRequired.tr() : null;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code: 'CustomTextField(validator: …) — ShakeOnError',
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _name,
                  labelText: LocaleKeys.showcaseName.tr(),
                  showRequired: true,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? LocaleKeys.fieldRequired.tr()
                      : null,
                ),
                12.heightBox,
                AppButton(
                  text: LocaleKeys.save.tr(),
                  onTap: () => _form.currentState?.validate(),
                ),
              ],
            ),
          ),
        ),
        DemoBlock(
          code: 'AppSelectField<T>',
          child: AppSelectField<int>(
            items: _items,
            labelResolver: _item,
            value: _selected,
            onChanged: (v) => setState(() => _selected = v),
          ),
        ),
        DemoBlock(
          code: 'ChipRow<T>',
          child: ChipRow<int>(
            items: _items,
            labelResolver: _item,
            selectedValue: _chip,
            onSelected: (v) => setState(() => _chip = v ?? _chip),
          ),
        ),
        DemoBlock(
          code: 'AppRadioGroup<T>(onDeselect: …)',
          child: AppRadioGroup<int>(
            options: {for (final n in _items.take(3)) n: _item(n)},
            value: _radio,
            onChanged: (v) => setState(() => _radio = v),
            onDeselect: () => setState(() => _radio = null),
          ),
        ),
        DemoBlock(
          code: 'AppSelectField<T>(mode: AppSelectMode.bottomSheet)',
          child: AppSelectField<int>(
            items: [for (var n = 1; n <= 12; n++) n],
            labelResolver: _item,
            mode: AppSelectMode.bottomSheet,
            hint: LocaleKeys.showcaseDialogsPickTitle.tr(),
            value: _sheetSelected,
            onChanged: (v) => setState(() => _sheetSelected = v),
          ),
        ),
        DemoBlock(
          code: 'ChipRow<T>.multi(selectedValues: …, onChanged: …)',
          child: ChipRow<int>.multi(
            items: _items,
            labelResolver: _item,
            selectedValues: _tags,
            onChanged: (v) => setState(() => _tags = v),
          ),
        ),
        DemoBlock(
          code: 'ListFilterBar(activeFilters: […], onClearAll: …)',
          child: ListFilterBar(
            hint: LocaleKeys.showcaseInputsSearchHint.tr(),
            onSearch: (q) => setState(() => _query = q),
            onClearSearch: () => setState(() => _query = ''),
            // The search term counts as a filter too, and the chips above
            // feed the rest.
            activeFilters: [
              if (_query.isNotEmpty) '"$_query"',
              for (final t in _tags) _item(t),
            ],
            onClearAll: () => setState(() => _tags = const []),
          ),
        ),
        DemoBlock(
          code: 'AppSearchBar(hint: …, onSearch: …, onClear: …, isLoading: …)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchBar(
                hint: LocaleKeys.showcaseInputsSearchHint.tr(),
                isLoading: _searching,
                onSearch: _search,
                onClear: () => setState(() => _searched = null),
              ),
              if (_searched != null) ...[
                8.heightBox,
                Text(
                  LocaleKeys.showcaseInputsSearched.tr(args: [_searched!]),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        DemoBlock(
          code: 'CustomTextField(textInputAction: next) — InputFocusNode',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocaleKeys.showcaseInputsNextHint.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              12.heightBox,
              CustomTextField(labelText: LocaleKeys.showcaseInputsTitle.tr()),
              12.heightBox,
              // Focusable, yet "next" walks past them: only the fields' nodes
              // carry the InputFocusNode tag.
              ChipRow<int>(
                items: _items,
                labelResolver: _item,
                selectedValue: _chip,
                onSelected: (v) => setState(() => _chip = v ?? _chip),
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
          code: 'CustomTextField(maxLines: 4, maxLength: 200)',
          child: CustomTextField(
            labelText: LocaleKeys.showcaseInputsBody.tr(),
            maxLines: 4,
            maxLength: 200,
          ),
        ),
        DemoBlock(
          code: 'formKey.validateAndReveal() — FormReveal',
          child: Form(
            key: _reveal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  LocaleKeys.showcaseInputsRevealHint.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                12.heightBox,
                CustomTextField(
                  labelText: LocaleKeys.showcaseInputsTitle.tr(),
                  showRequired: true,
                  validator: _required,
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
                  validator: _required,
                ),
                12.heightBox,
                AppButton(
                  text: LocaleKeys.save.tr(),
                  onTap: () =>
                      setState(() => _revealOk = _reveal.validateAndReveal()),
                ),
                if (_revealOk) ...[
                  8.heightBox,
                  Text(
                    LocaleKeys.showcaseInputsValid.tr(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.statusSuccessFg,
                    ),
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
