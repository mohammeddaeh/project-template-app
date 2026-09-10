import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../resources/assets.dart';
import '../images/app_asset_image.dart';

/// عقدةُ تركيزٍ **موسومة** — بها وحدها يعرف الحقلُ من هو الحقلُ التالي.
///
/// و العاديّ يمشي على **كلّ** ما يقبل التركيز: زرٌّ, شريحةٌ,
/// عنصرُ قائمة. فالانتقالُ من حقلٍ إلى حقلٍ يمرّ بما بينهما، ويقف عند زرٍّ
/// فيُغلق الكيبوردَ من حيث لا يقصد أحد. والوسمُ يجعل المشيَ على الحقول وحدها.
class InputFocusNode extends FocusNode {}

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    this.controller,
    this.isFieldObscure = false,
    this.isFieldSearch = false,
    this.showOption = false,
    this.showRequired = false,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.labelText,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.expands = false,
    this.labelTextStyle,
    this.enabled = true,
    this.ltr,
    this.suffix,
    this.prefixIcon,
    this.onTapOutsideDismissTheKeyboard = true,
    super.key,
    this.onChanged,
    this.onFieldSubmitted,
    this.maxLines,
    this.maxLength,
    this.backgroundColor,
    this.inputFormatters,
    this.scrollPadding = const EdgeInsets.only(bottom: 120),
  });

  final TextEditingController? controller;
  final bool isFieldObscure;
  final bool isFieldSearch;
  final bool showOption;
  final bool showRequired;
  final String? hint;
  final String? labelText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool expands;
  final bool? ltr;
  final AutovalidateMode autovalidateMode;
  final TextStyle? labelTextStyle;
  final bool enabled;
  final Widget? suffix;
  final Widget? prefixIcon;
  final bool onTapOutsideDismissTheKeyboard;
  final Function? onChanged;
  final Function? onFieldSubmitted;
  final int? maxLines;
  final int? maxLength;
  final Color? backgroundColor;
  final List<TextInputFormatter>? inputFormatters;

  /// مسافة التمرير لضمان ظهور الحقل فوق الكيبورد.
  /// القيمة الافتراضية 120 كافية لمعظم الشاشات.
  final EdgeInsets scrollPadding;

  /// عقدةٌ يملكها المستدعي. وحين تُمرَّر، **يسقط المشيُ إلى الحقل التالي**
  /// ويحلّ محلَّه إغلاقُ الكيبورد: العقدةُ الخارجية ليست [InputFocusNode]،
  /// وتخمينُ جارٍ لها يكون خطأً.
  final FocusNode? focusNode;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final _borderRadius = 12.0;
  final _borderWidth = 1.0;
  var _obscure = false;

  /// تُبنى هنا لا تُترَك لـ`TextFormField`، كي تحمل وسمَ [InputFocusNode].
  InputFocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= InputFocusNode());

  /// Enter يُدخل سطراً بحقلٍ متعدّد الأسطر — و«التالي» تجعل فقرةً لا تُكتب.
  bool get _isMultiline => widget.expands || (widget.maxLines ?? 1) != 1;

  TextInputAction? get _action =>
      widget.textInputAction ??
      (_isMultiline ? TextInputAction.newline : TextInputAction.next);

  /// ينتقل إلى الحقل التالي بالنطاق، ويُغلق الكيبورد إن كان هذا آخرَها.
  void _advance() {
    final scope = _node.enclosingScope;
    final inputs = <FocusNode>[
      ...?scope?.traversalDescendants.whereType<InputFocusNode>(),
    ];
    final index = inputs.indexOf(_node);
    if (index != -1 && index + 1 < inputs.length) {
      inputs[index + 1].requestFocus();
    } else {
      _node.unfocus();
    }
  }

  @override
  void initState() {
    super.initState();
    _obscure = widget.isFieldObscure;
  }

  @override
  void dispose() {
    _ownNode?.dispose();
    super.dispose();
  }

  void _toggleObscure() {
    if (!widget.isFieldObscure) {
      return;
    }
    _obscure = !_obscure;
    setState(() {});
  }

  void _onTapIconClose() {
    widget.controller?.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller?.text,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      builder: (state) {
        final errorBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(
            width: _borderWidth,
            color: context.colors.error,
          ),
        );
        final enabledBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(
            width: _borderWidth,
            color: context.colors.borderSubtle,
          ),
        );
        final focusedBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(
            width: _borderWidth,
            color: context.colors.primary,
          ),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.labelText != null &&
                (widget.labelText?.isNotEmpty ?? false))
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.labelText ?? '',
                    style:
                        widget.labelTextStyle ??
                        context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (widget.showOption) ...[
                    const SizedBox(width: 5),
                    Text(
                      "(${LocaleKeys.option.tr()})",
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  if (widget.showRequired) ...[
                    const SizedBox(width: 5),
                    Text(
                      "*",
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            if (widget.labelText != null &&
                (widget.labelText?.isNotEmpty ?? false))
              const SizedBox(height: 8),
            Flexible(
              child: Builder(
                builder: (_) {
                  final fieldContainer = Container(
                    decoration: widget.backgroundColor == null
                        ? null
                        : BoxDecoration(
                            borderRadius: BorderRadius.circular(_borderRadius),
                            color: widget.backgroundColor!,
                          ),
                    child: TextFormField(
                      scrollPadding: widget.scrollPadding,
                      inputFormatters: widget.inputFormatters,
                      maxLength: widget.maxLength,
                      controller: widget.controller,
                      obscureText: _obscure,
                      expands: widget.expands,
                      onTapOutside: widget.onTapOutsideDismissTheKeyboard
                          ? (event) =>
                                FocusManager.instance.primaryFocus?.unfocus()
                          : null,
                      keyboardType: widget.keyboardType,
                      focusNode: _node,
                      textInputAction: _action,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: widget.expands ? null : widget.maxLines ?? 1,
                      onSaved: (newValue) {
                        state.didChange(newValue);
                      },
                      onFieldSubmitted: (newValue) {
                        state.didChange(newValue);
                        if (widget.onFieldSubmitted != null) {
                          widget.onFieldSubmitted!();
                        }
                        if (_action == TextInputAction.next) _advance();
                      },
                      onChanged: (value) {
                        state.didChange(value);
                        if (widget.onChanged != null) {
                          widget.onChanged!();
                        }
                      },
                      enabled: widget.enabled,
                      cursorColor: context.colors.primary,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        contentPadding:
                            _obscure && (state.value?.isNotEmpty ?? false)
                            ? const EdgeInsets.only(
                                top: 20,
                                left: 16,
                                right: 16,
                              )
                            : const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                        enabledBorder: state.hasError
                            ? errorBorder
                            : enabledBorder,
                        border: state.hasError ? errorBorder : enabledBorder,
                        focusedBorder: state.hasError
                            ? errorBorder
                            : focusedBorder,
                        errorBorder: errorBorder,
                        focusedErrorBorder: errorBorder,
                        disabledBorder: state.hasError
                            ? errorBorder
                            : enabledBorder,
                        prefixIcon: widget.prefixIcon,
                        suffixIcon: widget.isFieldObscure
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: _toggleObscure,
                                    child: !_obscure
                                        ? Icon(
                                            Icons.remove_red_eye_outlined,
                                            color: context.colors.primary,
                                          )
                                        : Icon(
                                            Icons.visibility_off,
                                            color: context.colors.primary,
                                          ),
                                  ),
                                ],
                              )
                            : widget.isFieldSearch
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (widget.controller!.text.isNotEmpty)
                                    IconButton(
                                      highlightColor: Colors.transparent,
                                      onPressed: _onTapIconClose,
                                      icon: Icon(
                                        Icons.close,
                                        color: context.colors.textMuted,
                                      ),
                                    ),
                                ],
                              )
                            : widget.suffix != null
                            ? Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 16,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [widget.suffix!],
                                ),
                              )
                            : null,
                      ),
                    ),
                  );

                  // widget.ltr == null  → Flutter's Directionality (from locale) handles direction automatically
                  // widget.ltr == true  → force LTR (e.g. email, password, phone number)
                  // widget.ltr == false → force RTL explicitly
                  if (widget.ltr != null) {
                    return Directionality(
                      textDirection: widget.ltr!
                          ? TextDirection.ltr
                          : TextDirection.rtl,
                      child: fieldContainer,
                    );
                  }
                  return fieldContainer;
                },
              ),
            ),
            if (state.hasError) const SizedBox(height: 8),
            Offstage(
              offstage: !state.hasError,
              child: Row(
                children: [
                  AppAssetImage(Assets.images.vectors.errorIconSvg, height: 16),
                  Expanded(
                    child: Text(
                      state.errorText ?? '',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
