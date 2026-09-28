// `validateAndReveal` تفشل **بصمت**: التوست يظهر كما كان، والحقل يصير أحمر
// كما كان، والشاشة وحدها لا تتحرك — وهي بالضبط الحالة التي وُجدت الدالة
// لإنهائها. لا استثناء ولا سجل، وخلاصة المستخدم تبقى «يقول مطلوب ولا أرى أين».
//
// ولذلك كل حالة مع نقيضها: إثبات أن النموذج الفاشل يُمرَّر لا يُثبت شيئاً وحده
// — دالةٌ تُمرّر دائماً تنجح فيه، وتلك تقفز بالقارئ من فوق حقلٍ صحيح.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/ui/widgets/inputs/form_reveal.dart';

/// نموذج أطول من الشاشة: الحقل الأول والثاني يفصلهما فراغ 1200px، فلا يمكن أن
/// يكون أحدهما مرئياً مع الآخر.
Widget _tallForm(GlobalKey<FormState> formKey, {required bool firstValid, required bool secondValid}) {
  return MaterialApp(
    home: Scaffold(
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(key: const Key('first'), validator: (_) => firstValid ? null : 'مطلوب'),
              const SizedBox(height: 1200),
              TextFormField(key: const Key('second'), validator: (_) => secondValid ? null : 'مطلوب'),
              const SizedBox(height: 1200),
              const SizedBox(key: Key('bottom'), height: 80),
            ],
          ),
        ),
      ),
    ),
  );
}

/// هل الحقل داخل الشاشة فعلاً؟ `find.byKey` تجده ولو كان ممرَّراً خارجها:
/// الودجت بالشجرة، والسؤال هنا سؤال موضع لا وجود.
bool _onScreen(WidgetTester tester, Key key) {
  final rect = tester.getRect(find.byKey(key));
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  return rect.bottom > 0 && rect.top < screen.height;
}

Future<void> _scrollToBottom(WidgetTester tester) async {
  await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -2000));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('النموذج السليم يُرجع true ولا يُحرّك الشاشة', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(_tallForm(formKey, firstValid: true, secondValid: true));
    await _scrollToBottom(tester);
    final before = tester.getTopLeft(find.byKey(const Key('bottom'))).dy;

    expect(formKey.validateAndReveal(), isTrue);
    await tester.pumpAndSettle();

    // لا قفزة لحقلٍ لا خطأ فيه — التمرير حيث تركه القارئ.
    expect(tester.getTopLeft(find.byKey(const Key('bottom'))).dy, before);
  });

  testWidgets('الحقل الناقص خارج الشاشة يُعاد إليها', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(_tallForm(formKey, firstValid: false, secondValid: true));
    await _scrollToBottom(tester);
    expect(_onScreen(tester, const Key('first')), isFalse);

    expect(formKey.validateAndReveal(), isFalse);
    await tester.pumpAndSettle();

    expect(_onScreen(tester, const Key('first')), isTrue);
  });

  testWidgets('يُظهر الأول من حقلين ناقصين لا الأخير', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(_tallForm(formKey, firstValid: false, secondValid: false));
    await _scrollToBottom(tester);

    expect(formKey.validateAndReveal(), isFalse);
    await tester.pumpAndSettle();

    // القارئ يُصلح من الأعلى للأسفل، والقفز للأخير يُخفي ما قبله.
    expect(_onScreen(tester, const Key('first')), isTrue);
    expect(_onScreen(tester, const Key('second')), isFalse);
  });

  testWidgets('النقص أسفل الشاشة يُعرض أيضاً — لا يُفترض أنه فوقها', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(_tallForm(formKey, firstValid: true, secondValid: false));
    expect(_onScreen(tester, const Key('second')), isFalse);

    expect(formKey.validateAndReveal(), isFalse);
    await tester.pumpAndSettle();

    expect(_onScreen(tester, const Key('second')), isTrue);
  });

  testWidgets('نموذج لم يُبنَ بعد يُرجع false ولا يرمي', (tester) async {
    final formKey = GlobalKey<FormState>();
    expect(formKey.validateAndReveal(), isFalse);
  });
}
