import 'package:flutter/material.dart';

import 'package:app_template/ui/widgets/indicators/app_progress.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppProgress.circular(centered: true);
  }
}
