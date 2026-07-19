import 'package:app_template/resources/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

extension TimeAgo on DateTime {
  String timeAgo() {
    final Duration difference = DateTime.now().difference(this);
    if (difference.inMinutes < 1) {
      return LocaleKeys.justNow.tr();
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${LocaleKeys.minAgo.tr()}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}  ${LocaleKeys.hAgo.tr()}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}  ${LocaleKeys.dAgo.tr()}';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}  ${LocaleKeys.wAgo.tr()}';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}  ${LocaleKeys.moAgo.tr()}';
    } else {
      return '${(difference.inDays / 365).floor()}  ${LocaleKeys.yAgo.tr()}';
    }
  }

  String get getFormattedDate {
    return "$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}";
  }

  String get getFormattedTime {
    int hour = this.hour;
    int minute = this.minute;
    int formattedHour = hour > 12 ? hour - 12 : hour;
    if (formattedHour == 0) {
      formattedHour = 12;
    }
    String period = hour >= 12 ? "PM" : "AM";
    String formattedMinute = minute.toString().padLeft(2, '0');
    return "$formattedHour:$formattedMinute $period";
  }

  String get getFormattedTime24Mode {
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }

  bool isTheSameDate(DateTime? o) {
    if (o == null) return false;
    return (day == o.day && month == o.month && year == o.year);
  }

  String get eEEMMMDFormat => DateFormat('EEEE, MMM d, h:mm a').format(this);

  String get eEEMMMDFormatWithOutTime =>
      DateFormat('EEEE, MMM d ,y').format(this);

  String get lastSeenAgo {
    final now = DateTime.now();
    final difference = now.difference(this);
    if (difference.inMinutes < 1) {
      return LocaleKeys.lastSeenAgo_now.tr();
    } else if (difference.inMinutes < 60) {
      return LocaleKeys.lastSeenAgo_minutes.tr(
        namedArgs: {"minutes": "${difference.inMinutes}"},
      );
    } else if (difference.inHours < 24) {
      return LocaleKeys.lastSeenAgo_hours.tr(
        namedArgs: {"hours": "${difference.inHours}"},
      );
    } else if (difference.inDays == 1) {
      return LocaleKeys.lastSeenAgo_yesterday.tr();
    } else if (difference.inDays < 7) {
      return LocaleKeys.lastSeenAgo_days.tr(
        namedArgs: {"days": "${difference.inDays}"},
      );
    } else if (difference.inDays < 30) {
      final weeksAgo = (difference.inDays / 7).floor();
      return weeksAgo == 1
          ? LocaleKeys.lastSeenAgo_week.tr()
          : LocaleKeys.lastSeenAgo_weeks.tr(namedArgs: {"weeks": "$weeksAgo"});
    } else if (difference.inDays < 365) {
      final monthsAgo = (difference.inDays / 30).floor();
      return monthsAgo == 1
          ? LocaleKeys.lastSeenAgo_month.tr()
          : LocaleKeys.lastSeenAgo_months.tr(
              namedArgs: {"months": "$monthsAgo"},
            );
    } else {
      return LocaleKeys.lastSeenAgo_longTime.tr();
    }
  }
}
