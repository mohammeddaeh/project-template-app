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

- **دَين `check_structure` صفر** — المخالفات الـ53 المسجَّلة أُصلحت بالكود، و`.structure_baseline.txt`
  لا يحمل شيئاً. صفحاتُ الحساب والإعدادات قُسّمت إلى ودجاتٍ مسمّاة بـ`presentation/widgets/`.
- ⚠️ **تغييرات واجهة عامة** (لا مستدعٍ لها بالقالب، وقد يكون لها بمشروع):
  - `app_padding_extension`: `leftPadding`/`rightPadding` وأخواتها الست صارت
    `startPadding`/`endPadding`… وتُعيد `EdgeInsetsDirectional`.
  - حقولُ البريد وكلمة المرور والرمز **بلا `ltr: true`** — تتبع اتجاه الصفحة (F10).
  - `AppColors`: `feedbackSuccess` · `feedbackError` · `feedbackWarning` · `feedbackInfo`.
  - `AppLocale`: `nativeName` · `shortName` (أسماء اللغات بلغتها).
  - `flavor_banner.dart` يُصدَّر من `widgets.dart`.
  - `AppButtonVariant.onBrand` — زرٌّ فوق سطح العلامة (الترحيب)؛ `tonal` كان يُقرأ معطَّلاً هناك.
  - شريط «لا اتصال» بالوضع الداكن: النصّ `onError` (رماديٌّ داكن) بدل الأبيض — تباينٌ أعلى.

- **أوضاع الدخول** `AppFeatures.authMode` (`none` افتراضاً · `required` · `optional`)،
  تُختار بـ`setup_project.dart --auth` و`new_project.ps1 -Auth`. والقالب **يبدأ بلا
  دخول**: ترحيبٌ ثم الرئيسية. ⚠️ **يغيّر سلوك مشروعٍ قائم** يأخذ التحديث: يرجع إلى
  `required` بسطرٍ واحد بـ`app_features.dart` ليبقى كما كان.
- **`WelcomeScreen`** مرّةً واحدة على الجهاز (`PersistenceKeys.welcomeSeen`)، على
  `AppColors.bgBrand` الجديد (= `splash_background`).
- **`AccountTab`** لوضع `optional`: دعوةٌ للدخول للزائر، والملف الشخصي لمن دخل.
- **الهوية بملفٍّ يُستبدل**: `assets/images/brand/app_logo.svg` و`.png` بدل شعار
  الجهة السابق؛ `gen_splash_assets.dart` يقرأ ألوان الشعار كما هي.

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
- **أدوات النقل والتنظيف**: `port_inventory.dart` · `device_shot.dart` · skill
  `port-to-template` · `prune_project.dart` (وحُذف به 62 مفتاح ترجمة مهجوراً).
- **`L01`**: `@RestApi` بملفّ `*_api_service.dart` وحده · `domain/services/` و`presentation/services/`.
- **الأخطاء غير الملتقَطة** تمرّ بـ`LogService` (فتصل `crash_reporting`).
