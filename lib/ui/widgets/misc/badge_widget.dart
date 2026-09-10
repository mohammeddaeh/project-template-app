import 'package:flutter/material.dart';

class BadgeWidget extends StatelessWidget {
  const BadgeWidget({
    super.key,
    required this.child,
    this.count,
    this.label,
    this.backgroundColor,
    this.textColor,
  });

  final Widget child;
  final int? count;
  final String? label;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.error;
    final fg = textColor ?? scheme.onError;

    return Badge(
      backgroundColor: bg,
      textColor: fg,
      label: count != null
          ? Text('${count! > 99 ? '99+' : count}')
          : label != null
          ? Text(label!)
          : null,
      child: child,
    );
  }
}
