part of 'session_guard_cubit.dart';

@freezed
abstract class SessionGuardState with _$SessionGuardState {
  /// أوّل لحظة بعد بناء الـcubit — تسأل مخزن الرقم قبل أن تقرر شيئاً.
  const factory SessionGuardState.checking() = SessionGuardChecking;

  /// الجلسة مرئية — لا شيء يحجبها.
  const factory SessionGuardState.unlocked() = SessionGuardUnlocked;

  /// الموديول مفعَّل ولا رقم قفلٍ مسجَّلٌ بعد — يُعرض إعداده أولاً.
  const factory SessionGuardState.needsSetup() = SessionGuardNeedsSetup;

  /// محجوبة خلف شاشة القفل. [wrongAttempt] تعرض رسالة خطأ بعد محاولة فاشلة
  /// دون إخفاء لوحة الأرقام.
  const factory SessionGuardState.locked({@Default(false) bool wrongAttempt}) =
      SessionGuardLocked;
}
