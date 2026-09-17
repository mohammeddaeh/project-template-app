import 'package:flutter/material.dart';

/// سلّم انحناء الزوايا الموحَّد.
///
/// يُقنِّن قيماً كانت مبعثرة بـ[app_theme.dart] بالصدفة لا بقرار — `12`
/// بالبطاقة والحقل والزر، `32` بـ`PrimaryButton` الافتراضي، `20` بالورقة
/// السفلية، `8` بالشريحة — تحت أسماء واحدة. لا يخترع قيمة جديدة.
abstract final class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double pill = 32;

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
