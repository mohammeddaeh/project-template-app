import 'package:flutter/material.dart';

extension AppPaddingExtension on num {
  /// EdgeInsets.only with zero padding
  EdgeInsets get zeroPadding => EdgeInsets.zero;

  /// EdgeInsets.only with top padding
  EdgeInsets get topPadding => EdgeInsets.only(top: toDouble());

  /// EdgeInsets.only with bottom padding
  EdgeInsets get bottomPadding => EdgeInsets.only(bottom: toDouble());

  /// EdgeInsets.only with left padding
  EdgeInsets get leftPadding => EdgeInsets.only(left: toDouble());

  /// EdgeInsets.only with right padding
  EdgeInsets get rightPadding => EdgeInsets.only(right: toDouble());

  /// EdgeInsets.symmetric with horizontal padding
  EdgeInsets get horizontalPadding =>
      EdgeInsets.symmetric(horizontal: toDouble());

  /// EdgeInsets.symmetric with vertical padding
  EdgeInsets get verticalPadding => EdgeInsets.symmetric(vertical: toDouble());

  /// EdgeInsets.all with equal padding on all sides
  EdgeInsets get allPadding => EdgeInsets.all(toDouble());

  /// EdgeInsets.only with left & right padding
  EdgeInsets get leftRightPadding =>
      EdgeInsets.only(left: toDouble(), right: toDouble());

  /// EdgeInsets.only with top & bottom padding
  EdgeInsets get topBottomPadding =>
      EdgeInsets.only(top: toDouble(), bottom: toDouble());

  /// EdgeInsets.only with left, right, and top padding
  EdgeInsets get leftRightTopPadding =>
      EdgeInsets.only(left: toDouble(), right: toDouble(), top: toDouble());

  /// EdgeInsets.only with left, right, and bottom padding
  EdgeInsets get leftRightBottomPadding =>
      EdgeInsets.only(left: toDouble(), right: toDouble(), bottom: toDouble());

  /// EdgeInsets.only with left, top, and bottom padding
  EdgeInsets get leftTopBottomPadding =>
      EdgeInsets.only(left: toDouble(), top: toDouble(), bottom: toDouble());

  /// EdgeInsets.only with right, top, and bottom padding
  EdgeInsets get rightTopBottomPadding =>
      EdgeInsets.only(right: toDouble(), top: toDouble(), bottom: toDouble());

  /// EdgeInsets.only with left & top padding
  EdgeInsets get leftTopPadding =>
      EdgeInsets.only(left: toDouble(), top: toDouble());

  /// EdgeInsets.only with left & bottom padding
  EdgeInsets get leftBottomPadding =>
      EdgeInsets.only(left: toDouble(), bottom: toDouble());

  /// EdgeInsets.only with right & top padding
  EdgeInsets get rightTopPadding =>
      EdgeInsets.only(right: toDouble(), top: toDouble());

  /// EdgeInsets.only with right & bottom padding
  EdgeInsets get rightBottomPadding =>
      EdgeInsets.only(right: toDouble(), bottom: toDouble());

  SizedBox get widthBox => SizedBox(width: toDouble());
  SizedBox get heightBox => SizedBox(height: toDouble());
}
