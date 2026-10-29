/// Weekday and month names — the **only** tables in the app. Pure Dart, so
/// domain code (notification texts, schedules) and the UI (`AppDateText`) read
/// the same lists.
///
/// Arabic writes the same month more than one way (يناير / كانون الثاني ·
/// ربيع الآخر / ربيع الثاني). Each spelling is its own named list: pick the one
/// the design uses — never re-type one.
abstract final class CalendarNames {
  /// Indexed by Dart's ISO weekday − 1 (Monday first).
  static const weekdaysAr = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  static const weekdaysEn = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// [weekday] is Dart's ISO weekday (Monday = 1).
  static String weekday(int weekday, {required bool arabic}) =>
      (arabic ? weekdaysAr : weekdaysEn)[weekday - 1];

  /// Levantine Gregorian months — what `ar-SY` / `ar-LB` date formatters write.
  static const gregorianMonthsLevantAr = [
    'كانون الثاني',
    'شباط',
    'آذار',
    'نيسان',
    'أيار',
    'حزيران',
    'تموز',
    'آب',
    'أيلول',
    'تشرين الأول',
    'تشرين الثاني',
    'كانون الأول',
  ];

  /// Gregorian months as `Intl`'s plain `ar` writes them.
  static const gregorianMonthsAr = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const gregorianMonthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// `en-US` `MMM`.
  static const gregorianMonthsEnShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// `en-GB` `month: short` — note `Sept`.
  static const gregorianMonthsEnShortGb = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sept',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Hijri months, the spelling `AppDateText` uses: «ربيع الآخر», «جمادى الآخرة».
  static const hijriMonthsAr = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const hijriMonthsEn = [
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhul-Qa'dah",
    'Dhul-Hijjah',
  ];

  /// Hijri months, the alternate spelling: «ربيع الثاني», «جمادى الثانية».
  static const hijriMonthsAltAr = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الثانية',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const hijriMonthsAltEn = [
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];
}
