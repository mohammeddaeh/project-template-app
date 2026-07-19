import 'package:flutter/material.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  const ProgressIndicatorWidget({super.key, this.value, this.linear = true});

  final double? value;
  final bool linear;

  @override
  Widget build(BuildContext context) {
    if (linear) {
      return LinearProgressIndicator(value: value);
    }
    return CircularProgressIndicator(value: value);
  }
}
