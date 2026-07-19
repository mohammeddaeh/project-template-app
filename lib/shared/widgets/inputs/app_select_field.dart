import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/app_colors.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import '../../../resources/assets.dart';
import '../images/app_asset_image.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppSelectMode — كيفية عرض قائمة الخيارات
// ─────────────────────────────────────────────────────────────────────────────

/// طريقة عرض قائمة الخيارات.
enum AppSelectMode {
  /// قائمة منسدلة inline — للقوائم القصيرة (< 8 عناصر)
  dropdown,

  /// ورقة سفلية — للقوائم الطويلة أو العناصر ذات النص الطويل
  bottomSheet,
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSelectField<T> — حقل اختيار موحَّد
// ─────────────────────────────────────────────────────────────────────────────

/// حقل اختيار عام يتكامل مع [Form] ويتطابق بصرياً مع [CustomTextField].
///
/// **Generic:** اجعل [T] النوع الذي تريد تخزينه (enum، كيان، int، إلخ).
/// مرر [labelResolver] لتحويل [T] → نص قابل للعرض.
///
/// ```dart
/// // Enum بسيط
/// AppSelectField<Gender>(
///   labelText: LocaleKeys.gender.tr(),
///   hint: LocaleKeys.selectGender.tr(),
///   items: Gender.values,
///   labelResolver: (g) => g.label.tr(),
///   value: _selectedGender,
///   onChanged: (g) => setState(() => _selectedGender = g),
///   validator: (v) => v == null ? LocaleKeys.fieldRequired.tr() : null,
///   showRequired: true,
/// )
///
/// // قائمة من الـ API (mode = bottomSheet للقوائم الطويلة)
/// AppSelectField<City>(
///   labelText: LocaleKeys.city.tr(),
///   hint: LocaleKeys.selectCity.tr(),
///   mode: AppSelectMode.bottomSheet,
///   items: cities,
///   labelResolver: (c) => c.name,
///   value: _selectedCity,
///   onChanged: (c) => setState(() => _selectedCity = c),
/// )
/// ```
class AppSelectField<T> extends StatefulWidget {
  const AppSelectField({
    super.key,
    required this.items,
    required this.labelResolver,
    this.value,
    this.onChanged,
    this.labelText,
    this.hint,
    this.validator,
    this.mode = AppSelectMode.dropdown,
    this.showRequired = false,
    this.showOption = false,
    this.enabled = true,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.prefixIcon,
  });

  /// قائمة الخيارات
  final List<T> items;

  /// محوّل من [T] إلى نص معروض
  final String Function(T) labelResolver;

  /// القيمة المحددة حالياً (null = لم يُختر شيء)
  final T? value;

  /// callback عند تغيير الاختيار
  final ValueChanged<T?>? onChanged;

  /// نص التسمية فوق الحقل (مُترجَم مسبقاً)
  final String? labelText;

  /// نص التلميح عند عدم وجود اختيار
  final String? hint;

  /// دالة التحقق — تُستدعى من [Form.validate()]
  final String? Function(T?)? validator;

  /// طريقة عرض الخيارات (الافتراضي: [AppSelectMode.dropdown])
  final AppSelectMode mode;

  final bool showRequired;
  final bool showOption;
  final bool enabled;
  final AutovalidateMode autovalidateMode;

  /// أيقونة اختيارية تسبق المحتوى
  final Widget? prefixIcon;

  @override
  State<AppSelectField<T>> createState() => _AppSelectFieldState<T>();
}

class _AppSelectFieldState<T> extends State<AppSelectField<T>> {
  final _formKey = GlobalKey<FormFieldState<T>>();
  late T? _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant AppSelectField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _currentValue) {
      _currentValue = widget.value;
      _formKey.currentState?.didChange(widget.value);
    }
  }

  void _onSelect(T? value) {
    setState(() => _currentValue = value);
    _formKey.currentState?.didChange(value);
    widget.onChanged?.call(value);
  }

  Future<void> _openBottomSheet(BuildContext context) async {
    if (!widget.enabled) return;
    final selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SelectBottomSheet<T>(
        items: widget.items,
        labelResolver: widget.labelResolver,
        selectedValue: _currentValue,
      ),
    );
    if (selected != null) _onSelect(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return FormField<T>(
      key: _formKey,
      initialValue: _currentValue,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      builder: (state) {
        final hasError = state.hasError;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Label ────────────────────────────────────────────────────────
            if (widget.labelText != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.labelText!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.showOption) ...[
                    const SizedBox(width: 5),
                    Text(
                      '(${LocaleKeys.option.tr()})',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  if (widget.showRequired) ...[
                    const SizedBox(width: 5),
                    Text(
                      '*',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],

            // ── Input ─────────────────────────────────────────────────────────
            if (widget.mode == AppSelectMode.dropdown)
              _buildDropdown(context, state)
            else
              _buildTapField(context, state),

            // ── Error ─────────────────────────────────────────────────────────
            if (hasError) ...[
              const SizedBox(height: 8),
              Offstage(
                offstage: !hasError,
                child: Row(
                  children: [
                    AppAssetImage(
                        Assets.images.vectors.errorIconSvg, height: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        state.errorText ?? '',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ── dropdown ─────────────────────────────────────────────────────────────────

  Widget _buildDropdown(BuildContext context, FormFieldState<T> state) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final hasError = state.hasError;

    return InputDecorator(
      decoration: _inputDecoration(colors, hasError: hasError, focused: false),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: _currentValue,
          isExpanded: true,
          isDense: true,
          hint: widget.hint != null
              ? Text(
                  widget.hint!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                )
              : null,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: widget.enabled ? colors.iconSubtle : colors.textMuted,
            size: 20,
          ),
          dropdownColor: colors.bgCard,
          onChanged: widget.enabled ? _onSelect : null,
          items: widget.items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(widget.labelResolver(item)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // ── bottomSheet tap field ─────────────────────────────────────────────────────

  Widget _buildTapField(BuildContext context, FormFieldState<T> state) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final hasValue = _currentValue != null;
    final hasError = state.hasError;

    return GestureDetector(
      onTap: () => _openBottomSheet(context),
      child: InputDecorator(
        decoration:
            _inputDecoration(colors, hasError: hasError, focused: false),
        child: Row(
          children: [
            if (widget.prefixIcon != null) ...[
              widget.prefixIcon!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                hasValue
                    ? widget.labelResolver(_currentValue as T)
                    : (widget.hint ?? ''),
                style: textTheme.bodyMedium?.copyWith(
                  color: hasValue ? colors.textPrimary : colors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: widget.enabled ? colors.iconSubtle : colors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration(
    AppColors colors, {
    required bool hasError,
    required bool focused,
  }) {
    final radius = BorderRadius.circular(12);
    final borderColor = hasError
        ? colors.error
        : focused
            ? colors.primary
            : colors.borderSubtle;
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(width: 1, color: borderColor),
    );
    return InputDecoration(
      contentPadding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      errorBorder: border,
      focusedErrorBorder: border,
      disabledBorder: border,
      prefixIcon: widget.prefixIcon != null && widget.mode == AppSelectMode.dropdown
          ? widget.prefixIcon
          : null,
      isDense: true,
      errorStyle: const TextStyle(height: 0, fontSize: 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SelectBottomSheet<T> — ورقة خيارات داخلية
// ─────────────────────────────────────────────────────────────────────────────

class _SelectBottomSheet<T> extends StatelessWidget {
  const _SelectBottomSheet({
    required this.items,
    required this.labelResolver,
    this.selectedValue,
  });

  final List<T> items;
  final String Function(T) labelResolver;
  final T? selectedValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final scheme = context.colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Options
          ...items.map(
            (item) {
              final isSelected = item == selectedValue;
              return InkWell(
                onTap: () => Navigator.of(context).pop(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          labelResolver(item),
                          style: textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? scheme.primary
                                : colors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_rounded,
                            size: 18, color: scheme.primary),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
