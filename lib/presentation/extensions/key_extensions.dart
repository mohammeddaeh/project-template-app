import 'package:flutter/material.dart';

extension GlobalKeyExtensions on GlobalKey {
  Offset get offset {
    if (currentContext == null) return Offset.zero;
    final RenderBox renderBox = currentContext!.findRenderObject() as RenderBox;
    return renderBox.localToGlobal(Offset.zero);
  }
}
