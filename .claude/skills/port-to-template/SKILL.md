---
name: port-to-template
description: Use when porting an existing app (any stack — Capacitor/Ionic, React Native, native Android/iOS, an older Flutter app) into a project built on this template, or when asked to analyse an old app and write the port plan. Inventories the old app, maps every concern to a template capability before any code is written, and writes docs/PORT_PLAN.md with phases and runnable acceptance criteria. Trigger on "انقل التطبيق", "port this app", "حلّل المشروع القديم وضع الخطة", "migrate to the template".
---

# port-to-template — نقلُ تطبيقٍ قائم إلى القالب

**الخطأ الذي يمنعه هذا الـskill**: خطّةٌ تصف التطبيق القديم وحده، فيُكتب عند التنفيذ
ما يملكه القالب أصلاً — دوالّ تاريخٍ وأرقامٍ وخطوطٍ متفرّقة بجانب أدواتٍ مبنيّة لا
يستعملها أحد. **فكلُّ مهمةٍ بالخطّة تسمّي القدرة التي تستعملها من القالب.**

يعمل **بالمشروع الجديد** (المبنيّ على القالب بـ`new_project.ps1`)، والتطبيق القديم
مستودعٌ آخر يُقرأ ولا يُكتب فيه.

## ١ · الجرد — آليّ

```bash
dart run scripts/port_inventory.dart <مسار التطبيق القديم>
```

يكتب `docs/port/inventory.md`: المنصّة · الشاشات · الـendpoints · الترجمات · الخطوط
بأوزانها من الملف · SVG بـ`<style>` · **إشارات القدرات** وما يقابلها بالقالب. اقرأه
كاملاً، ثم افتح ما يحتاج تفصيلاً بالمستودع القديم (عقد الـAPI · منطق المجال · الحالات
الحدّية). الجرد يعدّ؛ لا يفهم.

## ٢ · المطابقة — قبل أي سطر

اقرأ [`readme/06_CAPABILITIES.md`](../../../readme/06_CAPABILITIES.md) كاملاً. لكل إشارةٍ
بالجرد، ولكل ما رأيته بالمستودع القديم، قرّر واحداً:

| الحكم | المعنى | يذهب إلى |
|---|---|---|
| ✅ موجود | القالب يملكه كما هو | المهمة تسمّيه: «`AppDateFormats.listDate` لتاريخ القائمة» |
| ◐ موجودٌ ناقص | القالب يملك الأساس وتنقصه حالة | **يُوسَّع بمكانه بالقالب** + بندٌ بـ`docs/TEMPLATE_FEEDBACK.md` |
| ❌ غير موجود | قدرةٌ عامّة لا يملكها القالب | تُبنى بمكانها بالطبقات + بندٌ بـ`TEMPLATE_FEEDBACK.md` |
| 🏷 مجال | منطقٌ يخصّ هذا التطبيق وحده | `lib/features/<f>/` أو `lib/modules/<m>/` بشكل الشريحة |

**أشكال العرض كلّها إلى الكتالوج أولاً**: كل تاريخٍ ووقتٍ وعدٍّ بالتطبيق القديم يصير
سطراً بـ`lib/core/foundation/formatting/app_formats.dart` باسم موضعه — قبل أول شاشة.
**وسياسة الأرقام لكل شكل** (`ArabicDigits.latin` / `indic`) من التطبيق القديم كما هو،
لا من قاعدة «العربية = هندي».

## ٣ · الخطّة — `docs/PORT_PLAN.md`

```markdown
# خطّة نقل <التطبيق>

> المصدر: <المستودع @ commit> · الجرد: docs/port/inventory.md · القالب: <TEMPLATE_VERSION>

## المطابقة
| القدرة | بالتطبيق القديم | بالقالب | الحكم |
|---|---|---|---|

## المراحل
### M1 · الأساس — <معيار القبول أمرٌ يُشغَّل>
- [ ] الهوية والألوان والخطوط (`sync_fonts.dart` — الوزن من الملف)
- [ ] الأصول (`svg_inline_styles.dart` لكل SVG بـ`<style>`) · `gen_code.dart`
- [ ] الكتالوج: كل أشكال التاريخ والوقت والأرقام بـ`app_formats.dart`
- [ ] العقد: كل endpoint ثابتٌ بـ`ApiUrls` · نصٌّ بضجيج ⇐ `Future<String>`
### M2 … (شاشةً شاشة، أو موديولاً موديولاً)
```

**وكل مرحلة لها معيار قبول قابل للتشغيل** — أمرٌ يُنفَّذ فيعطي نعم أو لا (اختبار ·
لقطة مقارنة · `check_structure` بلا مخالفة). «تمّت مراجعتها» ليس معياراً.

## ٤ · التنفيذ

- كل شاشة: لقطةٌ من التطبيق القديم مرجعاً، ثم بعد البناء:
  ```bash
  dart run scripts/device_shot.dart <الشاشة> --ref docs/port/reference/<الشاشة>.png
  ```
  ويُقارَن على جهازٍ واحد (العرض المنطقيّ يُطبع مع كل لقطة).
- بعد كل مرحلة: `dart analyze` · `flutter test` · `check_structure` · `check_docs` ·
  و`dart run scripts/template_drift.dart` — **كل ◌ يصير بنداً بـ`TEMPLATE_FEEDBACK.md`
  أو يُعلَّم تخصيصاً**.
- بعد آخر مرحلة: `dart run scripts/prune_project.dart` ثم `--apply` لما يُحذف.

## ما لا يُفعل

- لا أداةٌ بالشريحة لما بالكتالوج (`check_structure` C01…C17 يُفشلها).
- لا نسخٌ لتعليقات التطبيق القديم وتواريخه — R38.
- لا كتابة بالمستودع القديم.
