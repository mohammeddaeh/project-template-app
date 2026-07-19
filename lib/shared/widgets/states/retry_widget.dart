import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class RetryWidget extends StatelessWidget {
  const RetryWidget({
    super.key,
    required this.onRetry,
    this.labelKey = 'retry',
  });

  final VoidCallback onRetry;
  final String labelKey;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(onPressed: onRetry, child: Text(labelKey.tr()));
  }
}
