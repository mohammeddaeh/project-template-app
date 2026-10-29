import 'package:app_template/core/foundation/formatting/app_date_format.dart';
import 'package:app_template/core/foundation/utils/arabic_digits.dart';

/// **A count shape** — see `AppDateFormat`; the catalog is `AppNumberFormats`.
class AppNumberFormat {
  const AppNumberFormat({
    this.grouping = true,
    this.digits = ArabicDigits.latin,
  });

  /// `1,234` rather than `1234`.
  final bool grouping;

  final ArabicDigits digits;

  String apply(int n, {required String language}) {
    final raw = n.abs().toString();
    final out = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < raw.length; i++) {
      if (grouping && i > 0 && (raw.length - i) % 3 == 0) out.write(',');
      out.write(raw[i]);
    }
    final text = out.toString();
    return language == 'ar' && digits == ArabicDigits.indic
        ? toArabicIndicDigits(text)
        : text;
  }
}

/// **A distance shape**: metres (rounded) under a kilometre, else kilometres
/// to one decimal. The unit's word is the caller's translation key, chosen
/// by [AppDistance.meters].
class AppDistanceFormat {
  const AppDistanceFormat({this.approximate = false});

  /// `≈ 850` rather than `850`.
  final bool approximate;

  /// `null` for no distance or ≤ 0 (nothing is shown).
  AppDistance? apply(double? km) {
    if (km == null || !(km > 0)) return null;
    final prefix = approximate ? '≈ ' : '';
    if (km < 1) {
      return AppDistance('$prefix${(km * 1000).round()}', meters: true);
    }
    return AppDistance('$prefix${km.toStringAsFixed(1)}', meters: false);
  }
}

/// A formatted distance: the figures and whether they are metres.
class AppDistance {
  const AppDistance(this.value, {required this.meters});

  final String value;
  final bool meters;
}

/// **A countdown shape**: `HH:MM:SS`, or `MM:SS` with minutes past 59.
class AppDurationFormat {
  const AppDurationFormat({this.hours = true});

  final bool hours;

  String apply(int seconds) {
    String p(int n) => n.toString().padLeft(2, '0');
    if (!hours) return '${p(seconds ~/ 60)}:${p(seconds % 60)}';
    return '${p(seconds ~/ 3600)}:${p(seconds % 3600 ~/ 60)}:${p(seconds % 60)}';
  }
}
