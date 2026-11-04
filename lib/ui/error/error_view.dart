import 'package:auto_route/auto_route.dart';
import 'package:app_template/ui/extensions/screen_sizes_extensions.dart';
import 'package:app_template/ui/widgets/misc/app_text.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/locale/locale.dart';
import 'package:app_template/ui/responsive/responsive.dart';

@RoutePage(name: 'ErrorRoute')
class ErrorView extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;

  final String? message;

  const ErrorView({super.key, this.errorDetails, this.message});

  String get _displayText {
    if (errorDetails != null) return errorDetails!.exceptionAsString();
    if (message != null && message!.isNotEmpty) return message!;
    return LocaleKeys.errorOccurred.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.router.pop();
          },
          icon: context.isAr
              ? const Icon(Icons.arrow_back_ios)
              : const Icon(Icons.arrow_forward_ios),
        ),
      ),
      body: SizedBox(
        height: context.sh,
        width: context.sw,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.screen.space(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: context.colors.error, size: 40),
              const ResponsiveGap(10),
              AppText(
                _displayText,
                style: context.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
