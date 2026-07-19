/// تحديد نوع الـ adapter المستخدم لعرض الـ feedback.
///
/// مُرَّر كـ `style:` في الدوال الاختصارية للـ [AppFeedbackService]
/// لتجاوز الـ adapter الافتراضي المُسجَّل في الـ DI لهذه العملية فقط.
///
/// ```dart
/// // الافتراضي: MotionToast (محدد في injection_module.dart)
/// context.feedback.success('تم الحفظ');
///
/// // تجاوز إلى Snackbar لرسالة مع زر retry
/// context.feedback.error(
///   'فشل الاتصال',
///   style: FeedbackStyle.snackbar,
/// );
///
/// // toast مبسط للنسخ أو الإشعارات السريعة
/// context.feedback.toast('تم النسخ', style: FeedbackStyle.simpleToast);
/// ```
enum FeedbackStyle {
  /// MotionToast — toast منزلق من الأعلى (styled, مع أيقونة وعنوان)
  motionToast,

  /// SnackBar — شريط سفلي مع زر action اختياري
  snackbar,

  /// SimpleToast — toast دائري مبسط من الأسفل (بدون أيقونة أو عنوان)
  simpleToast,
}
