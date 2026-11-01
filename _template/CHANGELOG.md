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

- **kit `audio` (K2)**: `VoiceNoteRecorder` (ملفٌّ مؤقّت يُنسخ للتخزين الخاص) · `AudioPlayerTile` ·
  `AttachmentPreview` يشغّل المرفق الصوتيّ بورقةٍ داخل التطبيق · `CapturedPhoto.isAudio` ·
  `AppNumberFormats.elapsed` (`03:41`) · `showKitReadiness` مشتركٌ للودجات. ⚠️ مفتاح
  `voiceOpenSettings` صار `kitOpenSettings`. ⚠️ أوّلُ بناء يحتاج الوصول لـ`dl.google.com`.
- **`CustomTextField`**: `onChanged`/`onFieldSubmitted` يصلان الدالّة بوسيطٍ أو بدونه —
  كانا يُناديان بلا وسيط، فالدالّة `(String v) {…}` ترمي ولا تُنادى أبداً.
- **kit `voice` (K1)**: إملاءٌ بالصوت `CustomTextField(dictation: true)` · `DictationButton` ·
  قراءةٌ بصوت `SpeakButton` — لا ترسم شيئاً بلا الـkit. `ensureKitReady` يطلب أذونات أي kit
  بـ`PermissionsService`. أعلامٌ جديدة `speechRecognition` · `textToSpeech`، و
  `sync_platform_permissions` يكتب `<queries>` بأندرويد. فصلُ «الطرفيات» بالمرآة.
  ⚠️ `KitNeedsPermission` صار يحمل قائمة أذونات.
- **حِزَم الأجهزة — البنية (K0)**: `packages/kit_contracts` · `scripts/kit.dart`
  (`list` · `add` · `remove` · `test`) · `lib/core/di/kits.g.dart` مولَّد ويُنادى من
  `configureInjection` · `setup_project --kits` (الافتراضي لا شيء) · `C18`/`C19` · R43 ·
  `readme/24_DEVICE_KITS.md`. لا kit بعد. **ويمسّ كل مشروع**: `kit_contracts` تبعيةُ
  `path` جديدة، و`packages/` صار مملوكاً للقالب · `sync_platform_permissions` يحفظ
  إزاحة `Info.plist` فلا يترك فرقاً بلا تغيير إذن.
- **الشريط السفلي والتباين**: نمط `expanding` يُظهر لافتة التبويب المختار (كانت الحصص المتساوية
  تعصرها إلى لا شيء) · الوضع الداكن: `onPrimaryContainer`/`onSecondaryContainer` صارا داكنين
  فوق حاويتهما الفاتحة (كانا ١٫٩٥ و١٫٩٨:١) — يمسّ الزرّ tonal والتبويب المختار، وبوابة التباين
  تفحص الزوجين · معاني عناصر تحكّم المرآة عادت وعليها اختبار، وإطار الهاتف بالمرآة بلا حشوة النظام.
- **الترجمة**: عناصر تحكّم المرآة تُعرض بالعربية «المعنى · اسمُ الوسيط» (`KnobName`)، وسطر
  الكود يبقى كما هو · نافذة تعارض المزامنة ورسالة «الملف فارغ» بالنقل صارتا مترجمتين.
- **تجديدُ توكنٍ لم يصل لا يُخرج المستخدم**: الطلب يفشل بخطأ النقل لا بالـ401، فلا تقرؤه
  `PaginationCubit`/`FailureUiMapper` «ادخل ثانيةً». ورسالةٌ بإجراء («تراجع») تُعرض سناك
  بار بالمحوّل الافتراضي بدل أن يُسقط زرّها · `CustomTextField` يتبع `isFieldObscure`
  بعد البناء ولا ينهار مع `maxLines` · `KeyValueRow(copyable)` بلا زرّ نسخٍ حين لا خدمة.

- **الشريط السفلي** `AppBottomBar`: أربعة طوابع (`material` · `floating` · `expanding` ·
  `minimal`) و`AppTabSwitcher` بأربعة انتقالات، يُختاران بـ`ShellAppearance` ويتبدّلان
  والتطبيق يعمل. **والقشرة بلا `extendBody`**: جسدُ كل تبويبٍ ينتهي عند الشريط لا خلفه
  (R15 — يُفحص لكل طابع).

- **المرآة — جولة المطوّر** `modules/showcase/` (علَم `showcase`، مُشعَل افتراضاً): تبويب
  الرئيسية يعرض ستّة فصول — أساسات · ودجات · حركة · بيانات · موديولات · منصّة — بالودجات
  الحقيقية، والخادم محاكىً محلّياً، وفوق كل مثالٍ اسمُه بالكود. **R42**: كل ودجةٍ بالمكتبة
  لها مثالٌ بالجولة، واختبارٌ يُفشل الناقص. تُطفأ وتُحذف بخطوات `SETUP.md` الموديول.
- `AppOpenContainer`: زرّ الرجوع بالنظام يُغلق الصفحة المفتوحة (كان لا يفعل شيئاً).
- إصلاحات بالمكتبة كشفتها المرآة: `AppButton` يختصر النصّ الطويل بدل أن يفيض ·
  `AppOpenContainer` يمرّ الرجوعُ فيه بـ`PopScope` · `BadgeWidget` لا يرسم شارةً لعددٍ صفر ·
  `StepProgressIndicator` المرقّم لا يفيض بلافتاتٍ طويلة · `PageLoadingIndicator` يلغي
  مؤقّتاته · `ConnectivityDot(bloc:)` لكيوبتٍ غير المسجَّل · `DashedDivider` مرئيٌّ افتراضاً
  (`borderSubtle`) · لا `Theme.of` بـ`DividerWidget`/`AppText`/`DashedDivider`/`BadgeWidget`.
- ودجتان بالمكتبة: `AppReorderableList` (ترتيبٌ بالسحب، `onReorder` بالموضع النهائيّ) ·
  `AppSwipeActions` + `SwipeAction` (سحبُ صفٍّ لإجراء، بداية/نهاية مع RTL · تأكيد · تراجعٌ بيد المستدعي) — §39 · §40.

- **الحركة**: انتقال الصفحات `PredictiveBack` على أندرويد (كان Cupertino) · صفوف
  `PaginationBuilderWdg`/`PaginatedListView` تظهر متتالية (`itemAppear`) · تبويبات
  القشرة بـ«fade through» · الترحيب يظهر متتالياً · `CustomTextField` يهتزّ لخطأ جديد ·
  ودجات `AppOpenContainer` · `AppStepSwitcher` · `AnimatedCount` · `ShakeOnError` ·
  `AppMotion.of(context)` (صفرٌ مع «تقليل الحركة») وR41. تبعيةٌ جديدة: `animations` (رسمية).

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
