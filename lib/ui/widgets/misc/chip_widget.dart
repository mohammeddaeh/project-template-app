import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ChipWidget extends StatelessWidget {
  const ChipWidget({
    super.key,
    required this.labelKey,
    this.selected = false,
    this.onSelected,
    this.onDeleted,
  });

  final String labelKey;
  final bool selected;
  final void Function(bool)? onSelected;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(labelKey.tr()),
      selected: selected,
      onSelected: onSelected,
      onDeleted: onDeleted,
    );
  }
}
