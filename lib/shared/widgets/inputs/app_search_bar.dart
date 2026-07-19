import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

/// شريط بحث موحّد مع debounce تلقائي.
///
/// ```dart
/// AppSearchBar(
///   hint: 'ابحث عن موظف...',
///   onSearch: (query) => context.read<EmployeesCubit>().search(query),
/// )
///
/// // مع loading خارجي (مثلاً عند جلب نتائج البحث)
/// AppSearchBar(
///   hint: 'ابحث...',
///   isLoading: state is SearchLoading,
///   onSearch: (q) => cubit.search(q),
///   onClear:  ()  => cubit.reset(),
/// )
/// ```
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.hint,
    this.onSearch,
    this.onClear,
    this.debounceDuration = const Duration(milliseconds: 400),
    this.isLoading = false,
    this.autofocus = false,
    this.backgroundColor,
    this.initialValue,
  });

  final String? hint;

  /// يُستدعى بعد انتهاء debounce بالقيمة الحالية للحقل.
  /// يُستدعى أيضاً فور الضغط على Enter.
  final ValueChanged<String>? onSearch;

  /// يُستدعى عند مسح النص (زر X أو حذف النص يدوياً حتى الفراغ).
  final VoidCallback? onClear;

  /// مدة الـ debounce — الافتراضي 400ms.
  final Duration debounceDuration;

  /// يُظهر `CircularProgressIndicator` في مكان زر الـ clear أثناء الجلب.
  final bool isLoading;

  final bool autofocus;

  /// خلفية الحقل — الافتراضي: context.colors.bgCard
  final Color? backgroundColor;

  /// قيمة ابتدائية (تُعيَّن مرة واحدة عند الإنشاء)
  final String? initialValue;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final newHasText = _controller.text.isNotEmpty;
    if (newHasText != _hasText) {
      setState(() => _hasText = newHasText);
    }

    if (_controller.text.isEmpty) {
      _debounce?.cancel();
      widget.onClear?.call();
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onSearch?.call(_controller.text.trim());
    });
  }

  void _onClearTap() {
    _debounce?.cancel();
    _controller.clear(); // يُطلق addListener → onClear يُستدعى تلقائياً
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onSubmitted(String value) {
    _debounce?.cancel();
    if (value.trim().isNotEmpty) {
      widget.onSearch?.call(value.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? context.colors.bgCard;

    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onSubmitted: _onSubmitted,
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colors.textPrimary,
        fontSize: 14,
      ),
      cursorColor: context.colors.primary,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.textMuted,
          fontSize: 14,
        ),
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: _border(context.colors.borderSubtle),
        enabledBorder: _border(context.colors.borderSubtle),
        focusedBorder: _border(context.colors.primary),
        prefixIcon: Icon(Icons.search_rounded, color: context.colors.iconSubtle),
        suffixIcon: _buildSuffix(context),
      ),
    );
  }

  Widget? _buildSuffix(BuildContext context) {
    if (widget.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colors.primary,
          ),
        ),
      );
    }

    if (_hasText) {
      return IconButton(
        icon: Icon(Icons.close_rounded, color: context.colors.iconSubtle),
        onPressed: _onClearTap,
        tooltip: 'مسح',
        splashRadius: 18,
      );
    }

    return null;
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 1),
      );
}
