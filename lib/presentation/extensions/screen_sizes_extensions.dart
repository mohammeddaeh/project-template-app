import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  double get sw => MediaQuery.of(this).size.width;

  double get sh => MediaQuery.of(this).size.height;

  EdgeInsets get screenPadding => MediaQuery.of(this).padding;

  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;

  double get bottomPadding => MediaQuery.of(this).viewPadding.bottom;

  double get bottomInsetsPadding => MediaQuery.of(this).viewInsets.bottom;

  double get topPadding => MediaQuery.of(this).viewPadding.top;

  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  EdgeInsets get topEdgeInsetsPaddings =>
      EdgeInsets.only(top: MediaQuery.of(this).viewPadding.top);

  EdgeInsets get bottomEdgeInsetsPaddings =>
      EdgeInsets.only(bottom: MediaQuery.of(this).viewPadding.bottom);

  EdgeInsets get safeAreaEdgeInsetsPaddings => EdgeInsets.only(
    top: MediaQuery.of(this).viewPadding.top,
    bottom: MediaQuery.of(this).viewPadding.bottom,
  );
}
