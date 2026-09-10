import 'package:flutter/material.dart';
import 'package:app_template/ui/widgets/indicators/app_progress.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  const ProgressIndicatorWidget({super.key, this.value, this.linear = true});

  final double? value;
  final bool linear;

  @override
  Widget build(BuildContext context) {
    if (linear) return AppProgress.linear(value: value);
    return AppProgress.circular(value: value);
  }
}
