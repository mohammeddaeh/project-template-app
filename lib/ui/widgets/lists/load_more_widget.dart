import 'package:flutter/material.dart';

import 'package:app_template/ui/widgets/indicators/app_progress.dart';

class LoadMoreWidget extends StatelessWidget {
  const LoadMoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppProgress.circular(
      centered: true,
      padding: EdgeInsets.all(16),
    );
  }
}
