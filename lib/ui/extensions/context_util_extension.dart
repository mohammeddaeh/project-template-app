import 'package:flutter/material.dart';

extension ContextUtilExtension on BuildContext {
  /// يُغلق الكيبورد ويُزيل التركيز من أي حقل نشط.
  /// استخدمه قبل إرسال أي form أو عند الانتقال بين الشاشات.
  void unfocus() => FocusScope.of(this).unfocus();

  /// alias واضح لـ [unfocus] — مُفضَّل داخل شاشات الـ Form.
  void dismissKeyboard() => FocusScope.of(this).unfocus();
}
