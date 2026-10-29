---
name: flutter-ui-design
description: Use when implementing a new Flutter screen or widget in this project without an explicit visual spec, or when reviewing an existing screen's UI composition quality. Applies visual judgment (hierarchy, focal point, depth, density) on top of the project's existing Design System — never invents new colors, fonts, spacing, or components.
---

# Flutter UI Design — Design Intelligence

هذا الـskill يملأ فجوة موثّقة بـ[`_template/roadmap.md`](https://github.com/mohammeddaeh/project-template-app/blob/master/_template/roadmap.md)
بند #16: التيمب يملك Design System صارم (`AppColors`/`context.textTheme`/
`context.screen`/`AppRadius`/`AppMotion`/`AppElevation`) يحكم **صحة**
الاستخدام، لكن صفر شيء يحكم **جودته البصرية** — متى Card، أين focal point،
كيف يُبنى hierarchy. هذا الملف يسدّ ذاك الفراغ، لا يستبدل القواعد الموجودة.

## القيد الصلب — لا يُخالَف أبداً

كل قرار هنا يتّخذ **داخل** حدود ما هو موجود، لا خارجها:

- ألوان: `context.colors.X` وحده — أبداً `Color(0xFF...)` (R12).
- خط: `context.textTheme.X` وحده.
- مسافة تعتمد على الشاشة: `context.screen.space()`/`.gutter` (R37) — لا رقم خام.
- زوايا/ظل/حركة: `AppRadius`/`AppElevation`/`AppMotion` (`lib/ui/theme/`) —
  لا قيمة مكتوبة يدوياً جديدة.
- ودجات: **افحص [`lib/ui/widgets/widgets.dart`](../../../lib/ui/widgets/widgets.dart)
  أولاً** (R34) — الأغلب أن ما تحتاجه موجود وناقصه قدرة صغيرة، لا معدوم.
- حقل إدخال/مؤشّر تقدّم: `CustomTextField`/`AppProgress` حصراً (R35/R36).

**لو قرارٌ بصري يحتاج مخالفة أيٍّ ممّا سبق — القرار خطأ، لا القاعدة.**

## السياق — نبرة التطبيق

النبرة يحدّدها المشروع لا القالب. المرجع البصري الافتراضي
([`_template/roadmap.md`](https://github.com/mohammeddaeh/project-template-app/blob/master/_template/roadmap.md) بند #16): ميكانيكا حديثة
(عمق، صورة كمحتوى، رأس ملوّن، badges) **بلا** الألوان الصاخبة (تدرّجات
أزرق/برتقالي/تركواز) — هادئ وموثوق، لا startup/SaaS. اللوحة من `AppColors` المشروع
(`primaryMain` · `secondaryMain`) — لا لون يُسمّى هنا.

## المنهج — Plan → Critique → Build → Review

مقتبسٌ من منهج skill Anthropic الرسمي `frontend-design`، مكيَّفاً لقيود هذا
المشروع (Design System موجود مسبقاً، لا يُخترع من الصفر).

### 1) Plan — قبل أي سطر كود

لكل شاشة/ودجة جديدة، أجب أولاً:

- **المحتوى الحقيقي ما هو؟** لا نص placeholder — استخدم أسماء/حقول حقيقية
  من الطلب نفسه.
- **أين focal point؟** أوّل عنصرٍ يُرسم يجب أن يكون الأهمّ بصرياً (اسم/حالة/
  صورة)، لا عنوان صغير يتبعه نص أصغر.
- **Card واحدة، أقسام منفصلة، أم سطح مفرد؟** راجع
  [`composition-guide.md`](composition-guide.md) §Card-vs-Surface.
- **رأس ملوّن (`onBrand`) يناسب هنا، أم سطح محايد؟** راجع نفس الملف §Brand-Surface.
- **كثافة المحتوى:** أكثر من ٥-٧ عناصر متجاورة بلا تجميع ⇒ قسّمها بعناوين
  (`SectionTitle` بالمكتبة موجود).

### 2) Critique — قبل الكتابة، ضد الطلب لا ضد الذوق

اقرأ [`anti-patterns.md`](anti-patterns.md) وقارن خطتك بقائمة "Generic UI".
كل بند بها **مصداقٌ فعلي بالمستودع** (`login_screen.dart` الحالي) — ليس
افتراضاً نظرياً. لو خطّتك تطابق أياً منها بلا مبرّر واعٍ (لا شاشة placeholder
مقصودة)، عدّلها قبل الكود لا بعده.

### 3) Build

نفّذ باستخدام التوكنات والودجات الموجودة فقط (راجع «القيد الصلب» أعلاه).
ودجة مشتركة جديدة فعلاً؟ اتّبع قاعدة مكانها بـ
[`lib/features/CLAUDE.md`](../../../lib/features/CLAUDE.md) §بنية الصفحة —
تُسمّى، لا دالّة.

### 4) Review — screenshot لا افتراض

شاشة غير تافهة (أكثر من تعديل نصّي بسيط)؟ شغّل التطبيق فعلياً (skill `run`)
وخذ screenshot، قارنه بخطة §1 والمرجع البصري بـ`_template/roadmap.md` #16. عدّل مرّة
واحدة إن لزم، ثم سلّم. **لا تدّعِ جودة بصرية بلا رؤية الناتج فعلياً** — نفس
مبدأ "شغّل التطبيق قبل الإبلاغ عن نجاح" بالتعليمات العامة.

## مراجع هذا الـskill

| الملف | يُقرأ متى |
|---|---|
| [`composition-guide.md`](composition-guide.md) | عند تخطيط شاشة/قسم جديد (مرحلة Plan) — قرارات Card/رأس ملوّن/density/focal point |
| [`anti-patterns.md`](anti-patterns.md) | عند نقد خطة جديدة أو مراجعة شاشة موجودة (مرحلة Critique) |

لا تُقرأ الاثنتان دائماً — فقط عند الحاجة الفعلية لكلٍّ منهما، حفاظاً على
tokens (نفس قرار "Token Strategy" الموثَّق بـ`_template/roadmap.md` #16).
