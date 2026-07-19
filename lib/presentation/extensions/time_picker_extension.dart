import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;

import 'package:app_template/presentation/extensions/extensions.dart';
import 'package:app_template/shared/widgets/layout/primary_button.dart';
import 'package:app_template/resources/locale_keys.g.dart';

enum TimePickerDisplayMode { material, sheet }

extension TimePickerContextExtension on BuildContext {
  void showTimePicker({
    DateTime? initDate,
    DateTime? minimumDate,
    TimePickerDisplayMode mode = TimePickerDisplayMode.material,
    required void Function(DateTime date) onSelect,
  }) {
    final initial = initDate ?? DateTime.now();
    switch (mode) {
      case TimePickerDisplayMode.material:
        _showMaterialTimePicker(initial: initial, onSelect: onSelect); // async
        break;
      case TimePickerDisplayMode.sheet:
        _showSheetTimePicker(
          initDate: initial,
          minimumDate: minimumDate,
          onSelect: onSelect,
        );
        break;
    }
  }

  Future<void> _showMaterialTimePicker({
    required DateTime initial,
    required void Function(DateTime date) onSelect,
  }) async {
    final timeOfDay = material.TimeOfDay(
      hour: initial.hour,
      minute: initial.minute,
    );
    final picked = await material.showTimePicker(
      context: this,
      initialTime: timeOfDay,
      builder: (context, child) {
        return material.Theme(
          data: material.Theme.of(this).copyWith(),
          child: child!,
        );
      },
    );
    if (!mounted || picked == null) return;
    final result = DateTime(
      initial.year,
      initial.month,
      initial.day,
      picked.hour,
      picked.minute,
    );
    onSelect(result);
  }

  void _showSheetTimePicker({
    DateTime? initDate,
    DateTime? minimumDate,
    required void Function(DateTime date) onSelect,
  }) {
    final picked = <DateTime?>[initDate ?? DateTime.now()];
    showAppBottomSheet(
      size: AppBottomSheetSize.compact,
      showTopLine: true,
      actions: [
        material.Column(
          mainAxisSize: material.MainAxisSize.min,
          children: [
            material.SizedBox(
              height: 200,
              width: sw,
              child: CupertinoDatePicker(
                initialDateTime: initDate,
                dateOrder: DatePickerDateOrder.dmy,
                mode: CupertinoDatePickerMode.time,
                minimumDate: minimumDate,
                onDateTimeChanged: (t) => picked[0] = t,
              ),
            ),
            material.SizedBox(
              width: sw,
              child: PrimaryButton(
                text: LocaleKeys.done.tr(),
                onTap: () {
                  material.Navigator.pop(this);
                  onSelect(picked[0] ?? initDate ?? DateTime.now());
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
