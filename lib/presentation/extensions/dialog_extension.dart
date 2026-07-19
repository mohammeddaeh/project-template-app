import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:app_template/shared/widgets/misc/app_text.dart';
import 'package:app_template/presentation/theme/app_theme.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

extension DialogContextExtension on BuildContext {
  void showLoader() {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator.adaptive()),
    );
  }

  Future<void> showLoadingDialog() {
    return showCustomDialog(
      child: PopScope(
        canPop: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(color: liteGrayHeadLineText.color),
            const SizedBox(width: 10),
            AppText(
              LocaleKeys.loading,
              style: liteGrayHeadLineText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      width: 120,
      barrierDismissible: false,
    );
  }

  Future<T?> showCustomDialog<T>({
    required Widget child,
    double width = 400,
    double maxHeight = 500,
    double opacity = 0.9,
    double circular = 16,
    bool barrierDismissible = true,
    Color barrierColor = Colors.transparent,
    bool transparentBackground = false,
  }) {
    return showAdaptiveDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      builder: (ctx) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: width,
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                constraints: BoxConstraints(maxHeight: maxHeight),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(circular),
                  color: transparentBackground
                      ? Colors.transparent
                      : cardColor.withValues(alpha: opacity),
                  boxShadow: transparentBackground
                      ? null
                      : [
                          BoxShadow(
                            color: colors.shadowColor.withValues(alpha: 0.2),
                            blurRadius: 20,
                          ),
                        ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    final result = await showCustomDialog<bool>(
      barrierDismissible: barrierDismissible,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                this,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(this).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(this, false);
                    onCancel?.call();
                  },
                  child: Text(cancelText ?? LocaleKeys.cancel.tr()),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(this, true);
                    onConfirm?.call();
                  },
                  child: Text(confirmText ?? LocaleKeys.confirm.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  void dismissDialog<T>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }
}
