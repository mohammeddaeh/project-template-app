import 'package:flutter/material.dart';

class RefreshWrapper extends StatelessWidget {
  const RefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: onRefresh, child: child);
  }
}
