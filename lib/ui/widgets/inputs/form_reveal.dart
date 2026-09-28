import 'package:flutter/material.dart';

/// «أين النقص؟» — يُجاب بالتمرير إليه، لا بتوست فوق زر الحفظ.
///
/// `Form.validate()` تُعلِّم كل حقل ناقص بالأحمر وتترك الشاشة حيث هي: بنموذج
/// أطول من شاشة، القارئ يرى جملة «هذا الحقل مطلوب» ولا يرى الحقل — فيقرأ
/// الرفض عطلاً. هذا الامتداد يستدعي `validate()` ثم يمشي شجرة النموذج نفسها
/// ليجد **أول** `FormFieldState` فاشل بترتيب الرسم، فيُظهره ويضع المؤشر فيه
/// إن كان حقل كتابة.
///
/// بلا مفاتيح لكل حقل: كل حقول المكتبة (`CustomTextField` · `AppSelectField`)
/// تبني `FormField` داخلها، فالمشي عليها يكفي — ومفتاحٌ يدوي لكل حقل كان
/// سيعني قائمة تُنسى بأول حقل يُضاف.
///
/// ⚠️ النموذج داخل `SingleChildScrollView` لا `ListView`: الثاني لا يبني
/// الحقل البعيد أصلاً، فلا يُتحقَّق منه ولا يُعثر عليه.
///
/// المستهلكون: شاشات `features/auth/` الست. نُقل من قرطاس 2026-09-28 (#54).
extension FormReveal on GlobalKey<FormState> {
  /// تتحقق، وتُرجع `true` حين لا نقص. عند النقص تُظهر أول حقل ناقص.
  bool validateAndReveal({double alignment = 0.1}) {
    final form = currentState;
    if (form == null) return false;
    if (form.validate()) return true;
    revealFirstInvalid(alignment: alignment);
    return false;
  }

  /// تُظهر أول حقل معلَّم بالخطأ الآن — بلا إعادة تحقق.
  /// تُستعمل حين يكون النقص خارج حقول النموذج (قائمة فارغة مثلاً) فتُستدعى
  /// بعد أن يُعلّم المستدعي حقله بنفسه.
  void revealFirstInvalid({double alignment = 0.1}) {
    final context = currentContext;
    if (context == null) return;
    final target = _firstInvalidField(context);
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: alignment,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    // حقل الكتابة يأخذ المؤشر أيضاً: التمرير يُري الحقل، والمؤشر يجعل الإصلاح
    // الخطوة التالية بلا لمسة ثانية. المنتقي لا focusNode له فيُكتفى بالتمرير.
    _firstEditableFocus(target)?.requestFocus();
  }
}

/// أول عنصر بالشجرة حالتُه `FormFieldState.hasError`.
/// `visitChildElements` يمشي بترتيب الأبناء، وهو ترتيب الرسم نفسه — فأول ما
/// يُعثر عليه هو أعلى حقل ناقص على الصفحة.
BuildContext? _firstInvalidField(BuildContext root) {
  BuildContext? found;
  void visit(Element element) {
    if (found != null) return;
    if (element is StatefulElement) {
      final state = element.state;
      if (state is FormFieldState && state.hasError) {
        found = element;
        return;
      }
    }
    element.visitChildren(visit);
  }

  (root as Element).visitChildren(visit);
  return found;
}

/// عقدة التركيز لأول `EditableText` داخل الحقل — `null` للمنتقيات والأزرار.
FocusNode? _firstEditableFocus(BuildContext field) {
  FocusNode? found;
  void visit(Element element) {
    if (found != null) return;
    final widget = element.widget;
    if (widget is EditableText) {
      found = widget.focusNode;
      return;
    }
    element.visitChildren(visit);
  }

  (field as Element).visitChildren(visit);
  return found;
}
