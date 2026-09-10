import 'package:flutter/material.dart';

import 'package:app_template/ui/widgets/indicators/app_progress.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppProgress.circular(centered: true);
  }
}
