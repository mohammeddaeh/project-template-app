import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/sections/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The text field with its validation shake, the select field, chips and
/// radio options.
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

  static const _items = [1, 2, 3, 4];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _item(int n) => LocaleKeys.showcaseItem.tr(args: ['$n']);

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
      ],
    );
  }
}
