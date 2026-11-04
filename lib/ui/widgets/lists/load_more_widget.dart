import 'package:flutter/material.dart';

import 'package:app_template/ui/widgets/indicators/app_progress.dart';
import 'package:app_template/ui/responsive/responsive.dart';

class LoadMoreWidget extends StatelessWidget {
  const LoadMoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProgress.circular(
      centered: true,
      padding: EdgeInsets.all(context.screen.space(16)),
    );
  }
}
