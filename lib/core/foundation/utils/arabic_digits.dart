/// Latin digits (`0`–`9`) to Arabic-Indic (`٠`–`٩`, U+0660–U+0669); every
/// other character is kept. The **only** converter in the app — dates, times
/// and counts call this rather than mapping code units themselves.
///
/// Whether a text uses Arabic-Indic digits is decided per shape, not per
/// language: one Arabic screen can show a Latin Hijri year next to an
/// Arabic-Indic Gregorian date. That choice lives on each format
/// ([ArabicDigits] in `core/foundation/formatting/`), never here.
String toArabicIndicDigits(String latin) => String.fromCharCodes([
  for (final c in latin.codeUnits)
    c >= 0x30 && c <= 0x39 ? 0x0660 + c - 0x30 : c,
]);
