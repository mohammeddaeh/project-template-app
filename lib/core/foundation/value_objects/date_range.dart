import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';

/// Validated date range value object.
///
/// Guarantees that [from] is not after [to] and that [from] is not in the
/// future when [allowFuture] is false (default: `true`).
///
/// Usage:
/// ```dart
/// final result = DateRange.create(from: startDate, to: endDate);
/// result.fold(
///   (failure) => emit(State.error(failure)),
///   (range)   => useCase(ReportParams(range: range)),
/// );
///
/// // Convenience getters:
/// range.duration      // Duration between from and to
/// range.isToday       // true if both dates are today
/// range.daysCount     // number of days in the range (inclusive)
/// ```
final class DateRange {
  const DateRange._({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  /// Validates the range and returns [Right<DateRange>] or
  /// [Left<ValidationFailure>].
  ///
  /// [allowFuture] — when `false`, [from] must not be after today.
  static Either<ValidationFailure, DateRange> create({
    required DateTime from,
    required DateTime to,
    bool allowFuture = true,
  }) {
    final fromDate = _dateOnly(from);
    final toDate = _dateOnly(to);

    if (fromDate.isAfter(toDate)) {
      return Left(
        const ValidationFailure(
          fields: {'dateRange': 'تاريخ البداية يجب أن يكون قبل تاريخ النهاية'},
        ),
      );
    }

    if (!allowFuture && fromDate.isAfter(_dateOnly(DateTime.now()))) {
      return Left(
        const ValidationFailure(
          fields: {'dateRange': 'لا يمكن اختيار تاريخ مستقبلي'},
        ),
      );
    }

    return Right(DateRange._(from: fromDate, to: toDate));
  }

  // ── Convenience API ─────────────────────────────────────────────────────────

  /// Duration between [from] and [to].
  Duration get duration => to.difference(from);

  /// Number of calendar days in the range (inclusive of both ends).
  int get daysCount => duration.inDays + 1;

  /// True when both [from] and [to] fall on today's date.
  bool get isToday {
    final today = _dateOnly(DateTime.now());
    return from == today && to == today;
  }

  /// True when the range spans a single day.
  bool get isSingleDay => from == to;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => '${from.toIso8601String()} → ${to.toIso8601String()}';
}
