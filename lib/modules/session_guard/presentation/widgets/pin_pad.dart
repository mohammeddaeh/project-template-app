import 'package:flutter/material.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// لوحة أرقامٍ للقفل المحلّي — ٠-٩ وحذفٌ للخلف. تُستعمل بشاشتي القفل والإعداد
/// كليهما، فلا تفترض عدد الخانات (يُمرَّر [pinLength] فقط لعرض النقاط).
class PinPad extends StatelessWidget {
  const PinPad({
    required this.enteredLength,
    required this.pinLength,
    required this.onDigit,
    required this.onBackspace,
    super.key,
  });

  final int enteredLength;
  final int pinLength;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dots(entered: enteredLength, total: pinLength),
        const SizedBox(height: 32),
        _Keypad(onDigit: onDigit, onBackspace: onBackspace),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.entered, required this.total});

  final int entered;
  final int total;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(total, (i) {
      final filled = i < entered;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? context.colors.primary : context.colors.dividerSubtle,
        ),
      );
    }),
  );
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: _rows
        .map(
          (row) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row
                .map(
                  (key) => _PinKey(
                    label: key,
                    onDigit: onDigit,
                    onBackspace: onBackspace,
                  ),
                )
                .toList(),
          ),
        )
        .toList(),
  );
}

class _PinKey extends StatelessWidget {
  const _PinKey({
    required this.label,
    required this.onDigit,
    required this.onBackspace,
  });

  final String label;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox(width: 72, height: 64);

    return SizedBox(
      width: 72,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: label == '⌫' ? onBackspace : () => onDigit(label),
          child: Center(
            child: label == '⌫'
                ? Icon(
                    Icons.backspace_outlined,
                    color: context.colors.textMuted,
                  )
                : Text(label, style: context.textTheme.headlineMedium),
          ),
        ),
      ),
    );
  }
}
