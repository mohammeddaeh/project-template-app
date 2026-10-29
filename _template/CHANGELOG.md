# سجلّ إصدارات القالب

> رقم الإصدار بـ`TEMPLATE_VERSION` بجذر المستودع (يصل المشاريع)، وكل إصدارٍ وسمُ
> git `v<الرقم>` على commitه. والمشروع يحفظ الاثنين بـ`.template_manifest.json`
> (`templateRelease` للبشر · `templateVersion` الـcommit الدقيق لـ`template_drift`
> و`template_update`).
>
> **متى يُرفع الرقم:** `x.y.Z` إصلاحٌ لا يغيّر واجهة · `x.Y.0` قدرةٌ أو أداةٌ جديدة ·
> `X.0.0` تغييرٌ يكسر مشروعاً قائماً (اسم واجهةٍ عامة · مسار ملفٍّ مملوك · حذف).
> وكل بندٍ يُضاف أولاً تحت «غير مُصدَر».

## غير مُصدَر

## 1.0.0 — 2026-10-29

أول إصدارٍ مرقّم. ما فيه مقارنةً بالقالب قبله:

- **صيانة القالب بـ`_template/`** — الخطّة والأرشيف وملاحظات المشاريع، لا تُنسخ للمشاريع.
- **لا تاريخ ولا اسم مشروع بما يصل المشاريع** (R38، `audit_template.dart` §٥).
- **كتالوج القدرات** `readme/06_CAPABILITIES.md` وحارسه `C01…C17` (R40).
- **أدوات التاريخ والأرقام**: محرّك أم القرى بدل حزمة `hijri` · `CalendarNames` ·
  `toArabicIndicDigits` · أوصاف `AppDateFormat`/`AppTimeFormat`/`AppNumberFormat`
  وكتالوجها · `AppDateText.format`.
- **الخطوط**: الوزن من الملف (`usWeightClass`) واختباره.
- **SVG**: `svg_inline_styles.dart` وحارسه · `SvgImageWidget.icon`.
- **REST**: الردّ النصّي `Future<String>` · `retrofit: 4.9.1`.
- **الفحوص بالـCI**: التنسيق حاجب · `check_structure` · `check_docs` · `audit_template`.
- **skills القالب** تصل المشاريع (`.claude/skills/`) · `apply-feedback`.
- **حلقة الملاحظات**: `docs/TEMPLATE_FEEDBACK.md` بالمشروع · `template_drift.dart` ·
  `template_update.dart` · `TEMPLATE_VERSION`.
