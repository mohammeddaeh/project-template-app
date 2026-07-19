import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:app_template/presentation/extensions/screen_sizes_extensions.dart';
import 'package:app_template/presentation/theme/app_theme.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

enum DatePickerDisplayMode { material, calendar, sheet }

extension DatePickerContextExtension on BuildContext {
  Future<DateTime?> showDatePicker({
    DateTime? initDate,
    DateTime? minDate,
    DateTime? maxDate,
    DatePickerDisplayMode mode = DatePickerDisplayMode.material,
    double circular = 16,
  }) async {
    final initial = initDate ?? DateTime.now();
    final first = minDate ?? DateTime(initial.year - 100);
    final last = maxDate ?? DateTime(initial.year + 100);

    switch (mode) {
      case DatePickerDisplayMode.material:
        return await _showMaterialDatePicker(
          initialDate: initial,
          firstDate: first,
          lastDate: last,
        );
      case DatePickerDisplayMode.calendar:
        return await _showCalendarDatePickerDialog(
          initDate: initial,
          minDate: minDate,
          maxDate: maxDate,
          circular: circular,
        );
      case DatePickerDisplayMode.sheet:
        return await _showCalendarDatePickerSheet(
          initDate: initial,
          minDate: minDate,
          maxDate: maxDate,
        );
    }
  }

  Future<DateTime?> _showMaterialDatePicker({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return await material.showDatePicker(
      context: this,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: locale,
    );
  }

  Future<DateTime?> _showCalendarDatePickerDialog({
    DateTime? initDate,
    DateTime? minDate,
    DateTime? maxDate,
    double circular = 16,
  }) async {
    return material.showAdaptiveDialog<DateTime>(
      context: this,
      barrierDismissible: false,
      builder: (_) {
        return material.Center(
          child: material.BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: material.Material(
              color: material.Colors.transparent,
              child: material.Container(
                padding: const material.EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                width: sw,
                clipBehavior: material.Clip.antiAlias,
                margin: const material.EdgeInsets.symmetric(horizontal: 24),
                decoration: material.BoxDecoration(
                  borderRadius: material.BorderRadius.circular(circular),
                  color: cardColor,
                  boxShadow: [
                    material.BoxShadow(
                      color: colors.shadowColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: material.Column(
                  mainAxisSize: material.MainAxisSize.min,
                  children: [
                    SfDateRangePicker(
                      initialDisplayDate: initDate,
                      initialSelectedDate: initDate,
                      minDate: minDate,
                      maxDate: maxDate,
                      onSelectionChanged: (_) {},
                      selectionMode: DateRangePickerSelectionMode.single,
                      showTodayButton: false,
                      backgroundColor: cardColor,
                      rangeSelectionColor: cardColor,
                      cancelText: LocaleKeys.cancel.tr(),
                      confirmText: LocaleKeys.confirm.tr(),
                      onCancel: () => pop(),
                      onSubmit: (date) {
                        final value = date is DateTime ? date : DateTime.now();
                        pop<DateTime?>(value);
                      },
                      navigationMode: DateRangePickerNavigationMode.snap,
                      endRangeSelectionColor: colors.primary,
                      todayHighlightColor: colors.primary,
                      showActionButtons: true,
                      selectionColor: colors.primary,
                      headerStyle: DateRangePickerHeaderStyle(
                        backgroundColor: cardColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<DateTime?> _showCalendarDatePickerSheet({
    DateTime? initDate,
    DateTime? minDate,
    DateTime? maxDate,
  }) async {
    DateTime? selected = initDate ?? DateTime.now();
    return await material.showModalBottomSheet<DateTime?>(
      context: this,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return material.StatefulBuilder(
          builder: (context, setState) {
            return material.Padding(
              padding: material.EdgeInsets.only(
                bottom: material.MediaQuery.of(context).viewPadding.bottom,
              ),
              child: material.Column(
                mainAxisSize: material.MainAxisSize.min,
                children: [
                  SfDateRangePicker(
                    initialDisplayDate: initDate,
                    initialSelectedDate: selected,
                    minDate: minDate,
                    maxDate: maxDate,
                    onSelectionChanged: (details) {
                      if (details.value is DateTime) {
                        setState(() => selected = details.value as DateTime);
                      }
                    },
                    selectionMode: DateRangePickerSelectionMode.single,
                    showTodayButton: true,
                    backgroundColor: material.Theme.of(context).cardColor,
                    cancelText: LocaleKeys.cancel.tr(),
                    confirmText: LocaleKeys.confirm.tr(),
                    onCancel: () => material.Navigator.pop(ctx, null),
                    onSubmit: (date) {
                      material.Navigator.pop(
                        ctx,
                        date is DateTime ? date : selected,
                      );
                    },
                    showActionButtons: true,
                    selectionColor: colors.primary,
                    todayHighlightColor: colors.primary,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
