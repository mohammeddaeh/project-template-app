import 'package:flutter/material.dart';

/// الحشوات الجانبية **باتجاه الكتابة** (`start`/`end`): بالعربية `start` يمين.
/// الأسماء المادّية (`left`/`right`) أُزيلت — حشوةٌ «يسار» تقع بالجانب الخطأ بـRTL
/// (F10)، ولم يكن لها مستدعٍ.
extension AppPaddingExtension on num {
  /// EdgeInsets.only with zero padding
  EdgeInsets get zeroPadding => EdgeInsets.zero;

  /// EdgeInsets.only with top padding
  EdgeInsets get topPadding => EdgeInsets.only(top: toDouble());

  /// EdgeInsets.only with bottom padding
  EdgeInsets get bottomPadding => EdgeInsets.only(bottom: toDouble());

  /// EdgeInsetsDirectional.only with start padding
  EdgeInsetsDirectional get startPadding =>
      EdgeInsetsDirectional.only(start: toDouble());

  /// EdgeInsetsDirectional.only with end padding
  EdgeInsetsDirectional get endPadding =>
      EdgeInsetsDirectional.only(end: toDouble());

  /// EdgeInsets.symmetric with horizontal padding
  EdgeInsets get horizontalPadding =>
      EdgeInsets.symmetric(horizontal: toDouble());

  /// EdgeInsets.symmetric with vertical padding
  EdgeInsets get verticalPadding => EdgeInsets.symmetric(vertical: toDouble());

  /// EdgeInsets.all with equal padding on all sides
  EdgeInsets get allPadding => EdgeInsets.all(toDouble());

  /// EdgeInsets.only with left & right padding
  EdgeInsets get leftRightPadding =>
      EdgeInsets.symmetric(horizontal: toDouble());

  /// EdgeInsets.only with top & bottom padding
  EdgeInsets get topBottomPadding =>
      EdgeInsets.only(top: toDouble(), bottom: toDouble());

  /// EdgeInsets.only with left, right, and top padding
  EdgeInsets get leftRightTopPadding =>
      EdgeInsets.fromLTRB(toDouble(), toDouble(), toDouble(), 0);

  /// EdgeInsets.only with left, right, and bottom padding
  EdgeInsets get leftRightBottomPadding =>
      EdgeInsets.fromLTRB(toDouble(), 0, toDouble(), toDouble());

  /// EdgeInsetsDirectional.only with start, top, bottom padding
  EdgeInsetsDirectional get startTopBottomPadding => EdgeInsetsDirectional.only(
    start: toDouble(),
    top: toDouble(),
    bottom: toDouble(),
  );

  /// EdgeInsetsDirectional.only with end, top, bottom padding
  EdgeInsetsDirectional get endTopBottomPadding => EdgeInsetsDirectional.only(
    end: toDouble(),
    top: toDouble(),
    bottom: toDouble(),
  );

  /// EdgeInsetsDirectional.only with start, top padding
  EdgeInsetsDirectional get startTopPadding =>
      EdgeInsetsDirectional.only(start: toDouble(), top: toDouble());

  /// EdgeInsetsDirectional.only with start, bottom padding
  EdgeInsetsDirectional get startBottomPadding =>
      EdgeInsetsDirectional.only(start: toDouble(), bottom: toDouble());

  /// EdgeInsetsDirectional.only with end, top padding
  EdgeInsetsDirectional get endTopPadding =>
      EdgeInsetsDirectional.only(end: toDouble(), top: toDouble());

  /// EdgeInsetsDirectional.only with end, bottom padding
  EdgeInsetsDirectional get endBottomPadding =>
      EdgeInsetsDirectional.only(end: toDouble(), bottom: toDouble());

  SizedBox get widthBox => SizedBox(width: toDouble());
  SizedBox get heightBox => SizedBox(height: toDouble());
}
