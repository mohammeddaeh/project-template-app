---
name: apply-feedback
description: Use inside the template repository (it has `_template/`) to apply a project's feedback file `_template/feedback/<project>.md` to the template, item by item — read the evidence in the project, port it generically, guard it, document it, and record each item's status with its commit. Trigger on "طبّق ملاحظات المشروع", "apply the feedback", "انقل تحسينات <مشروع> للقالب", or when a project's TEMPLATE_FEEDBACK.md has just been copied into `_template/feedback/`.
---

# apply-feedback — ملاحظات مشروعٍ إلى القالب، بنداً بنداً

**يعمل بمستودع القالب وحده** (فيه `_template/`). المدخل ملفُّ مشروعٍ بـ
`_template/feedback/<project>.md`، نُسخ من `docs/TEMPLATE_FEEDBACK.md` بالمشروع.
والمستودع المصدر مذكورٌ بأعلى الملف — اقرأ منه الدليل، ولا تكتب فيه.

## قبل أي بند

1. اقرأ `CLAUDE.md` الجذري و`_template/CLAUDE.md` — جدول التزامن والقواعد R38
   (لا تاريخ ولا اسم مشروع بما يصل المشاريع) وR40 (الكتالوج).
2. اقرأ ملفّ الملاحظات كاملاً، وانسخ جدول «ملخّص» قائمةَ مهام: بندٌ لكل صفّ ⏳ أو 🔄.
3. **رتّب بالترابط لا بالرقم**: بنودٌ تمسّ مجلداً واحداً (مثل التاريخ والأرقام) تُنقل معاً.

## لكل بند

1. **اقرأ الدليل بالمشروع** — الـcommit والملفات المذكورة، لا الوصف وحده. والمشروع
   قد يكون غيّر الشيء بعد كتابة البند: ما بمستودعه اليوم هو المرجع.
2. **قرّر**: ينطبق على القالب العام؟ إن لم ينطبق (القالب لا يحمل الشيء أصلاً) ⇐
   ✖️ بسببه بسطر، ولا تبنِ سطحاً بلا مستهلك (R28).
3. **انقل عامّاً**:
   - أزل كل اسم مشروع أو جهة أو مثال مجالٍ بعينه من الكود والتعليقات والوثائق —
     أسماءٌ محايدة (`orders` · `items` · `com.example.*`). `audit_template.dart` §٥ يفحص.
   - غيّر اسم الحزمة إلى `app_template`.
   - **لا محاور لم يطلبها البند** — انقل ما أثبته المشروع وحده.
   - أعد تسمية ما يحمل اسم شاشةٍ أو كيانٍ بالمشروع باسمٍ يقول موضعه العامّ (`listDate` · `detailHijri`).
4. **احرسه**: قاعدة `C##`/`L##` بـ`check_structure.dart` إن كان للخطأ نمطٌ لا يحتمل
   زيفاً، وإلا اختبار. **والاختبار يقيس السلوك** (الحجم المرسوم · النصّ الناتج ·
   الكود المولَّد)، لا الوسطاء.
5. **وثّقه** بنفس التغيير: صفّ بـ`readme/06_CAPABILITIES.md` لكل قدرة، والملفات التي
   يسمّيها جدول التزامن بـ`CLAUDE.md` لما لمسته.
6. **تحقّق**:
   ```bash
   dart format lib test scripts
   dart analyze lib test scripts
   flutter test
   dart run scripts/check_structure.dart
   dart run scripts/check_docs.dart
   dart run scripts/audit_template.dart
   ```
7. **commit للبند** (أو للبنود المترابطة) — الرسالة تسمّي البنود: `(feedback T01, T02)`،
   ولا تسمّي المشروع بما يصل المشاريع.
8. **سجّل الحالة** بملف الملاحظات: ✅ بالتاريخ والـcommit بجدول «ملخّص» وبعنوان
   البند، وسطر «**طُبِّق (التاريخ، `commit`):**» تحت البند يقول ما نُقل **وما لم يُنقل
   ولماذا**. و✖️ بالسبب نفسه.

## بعد آخر بند

- حدّث صفّ المشروع بـ`_template/feedback/README.md` (التاريخ · كم طُبِّق · كم رُفض · ما بقي).
- أضف ما يستحقّ إلى `_template/CHANGELOG.md` تحت «غير مُصدَر»، ورقم الإصدار
  (`TEMPLATE_VERSION`) يُرفع حين يُصدَر القالب.
- ما بقي ⏳ لسببٍ خارجي (يحتاج أداةً لم تُبنَ) يُذكر بسببه.

## ما لا يفعله

- لا يكتب بمستودع المشروع — المشروع يأخذ التحسين لاحقاً بـ`template_update.dart`.
- لا ينقل منطق المجال — القالب يحمل الميكانيكا، والمشروع يسمّيها.
