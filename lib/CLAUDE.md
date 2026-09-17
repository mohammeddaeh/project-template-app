# lib/CLAUDE.md — UI Rules, Imports, Localization

> يُحمَّل تلقائياً عند العمل في أي ملف داخل `lib/`.
> **اسم الـ package:** `app_template` — بدّله مرّةً واحدة أو لا تبدّله ([`readme/01_SETUP.md`](../readme/01_SETUP.md) §٣).
>
> **هذا الملف أوامر.** «لماذا» وراء كل قاعدة أدناه — والعطل الذي وُلدت منه —
> بـ[`readme/03_RULES.md`](../readme/03_RULES.md)، مرقّمةً `R##` للاستشهاد بمراجعة
> الكود. والمرجع السريع للأوامر والمسارات: [`readme/02_CHEATSHEET.md`](../readme/02_CHEATSHEET.md).
>
> **وللقرار البصري** (متى Card، أين focal point، كيف hierarchy — لا الصحّة
> بل الجودة) راجع skill `.claude/skills/flutter-ui-design/SKILL.md`.

---

## Correct Import Paths

| Resource | Correct Path |
|---|---|
| Feature ApiService | `package:app_template/features/{feature}/data/datasources/{feature}_api_service.dart` |
| ApiUrls | `package:app_template/core/infra/network/rest/api_urls.dart` |
| ApiResponse | `package:app_template/core/foundation/contracts/api_response.dart` |
| Failure | `package:app_template/core/foundation/errors/failure.dart` |
| BaseRepository | `package:app_template/core/infra/network/boundary/base_repository.dart` |
| HandleBodyResponse | `package:app_template/core/infra/network/rest/handle_body_response.dart` |
| PersistenceKeys | `package:app_template/core/platform/storage/persistence_keys.dart` |
| Extensions barrel (UI) | `package:app_template/ui/extensions/extensions.dart` |
| Widgets barrel | `package:app_template/ui/widgets/widgets.dart` |
| PaginationCubit | `package:app_template/ui/state/pagination/pagination_cubit.dart` |
| BaseUseCase | `package:app_template/core/foundation/domain/base_usecase.dart` |
| UseCaseParams | `package:app_template/core/foundation/domain/use_case_params.dart` |
| NoParams | `package:app_template/core/foundation/domain/no_params.dart` |
| LocaleKeys | `package:app_template/resources/locale_keys.g.dart` |
| Router | `package:app_template/routes/router.gr.dart` |

## Extensions imported directly (NOT in barrel)

```dart
import 'package:app_template/ui/responsive/responsive.dart';
// context.screen → space(24) · size(115) · gutter · isTablet · pick(...)
// ResponsiveContentBox · ResponsiveGap · ResponsiveBuilder

import 'package:app_template/ui/extensions/screen_sizes_extensions.dart';
// ⚠️ قياسُ الشاشة فقط — لا مسافةً ولا مقاساً (راجع §Responsive أدناه)
// context.sw, context.sh, context.bottomPadding, context.topPadding

import 'package:app_template/ui/extensions/byte_size_extension.dart';
// bytes.asFileSize → «٢٫٤ ميغابايت» · "2.4 MB" — مترجَمة، وتقرأ لغة السياق

import 'package:app_template/ui/extensions/app_padding_extension.dart';
// 16.allPadding, 16.horizontalPadding, 16.verticalPadding / 4.widthBox, 4.heightBox

import 'package:app_template/ui/theme/theme_extensions.dart';
// context.colors, context.textTheme, context.colorScheme

// ⚠️ feedback — لا يُصدَّر من extensions.dart — مطلوب صراحةً في كل ملف
import 'package:app_template/ui/feedback/feedback_extension.dart';
```

> **محذوف:** `context.showToast(...)` و`context.showSimpleToast(...)` — استخدم `context.feedback.*`

> **وحجمُ ملفٍّ يُعرض للمستخدم يمرّ بـ`asFileSize`، لا بحسابٍ محلّي.** حسبةٌ
> بيدها تكتب `'KB'`/`'MB'` نصّاً لاتينياً جامداً وسط واجهةٍ مترجَمة — وتمرّ لأنها
> «وحدة قياس» بالنظر السريع. ثم تحتاجها شاشةٌ ثانية بلغةٍ أخرى، فيصير للمشروع
> مقياسان لشيءٍ واحد.

---

## Feedback API

```dart
context.feedback.success('msg');
context.feedback.error('msg');
context.feedback.warning('msg', title: 'title');
context.feedback.toast('msg');
```

## Locale API

```dart
context.isAr         // bool
context.isRtl        // bool
context.appLocale    // AppLocale enum
context.changeLocale(AppLocale.english);
context.toggleLocale();
```

---

## Typography — قواعد النصوص (صارمة)

| Style | fontSize | weight | الاستخدام |
|---|---|---|---|
| `displayLarge` | 24 | w800 | أكبر عنوان hero |
| `headlineLarge` | 26 | w700 | page title |
| `headlineMedium` | 20 | w700 | section title |
| `headlineSmall` | 14 | w700 | card title |
| `bodyMedium` | 14 | w500 | default body |
| `bodySmall` | 12 | w400 | secondary body |
| `labelLarge` | 14 | w400 | button, chip |

**ممنوع ❌:** `TextStyle(fontSize: 16)` · `fontFamily: 'NotoSansArabic'` hardcoded · `TextStyle(color: Color(...))`
→ استخدم: `context.textTheme.bodyMedium` + `.copyWith(color: context.colors.X)`

## Colors — قواعد الاستخدام (صارمة)

```
Figma hex → AppPalette (raw) → AppColors.light/dark (semantic) → context.colors.X
```

**ممنوع ❌:** `Color(0xFF...)` في الـ UI · `AppPalette.X` خارج `app_colors.dart` · `Colors.blue`

---

## Localization — 4 خطوات إلزامية دائماً

```
1. assets/translations/ar.json   ← أضف المفتاح
2. assets/translations/en.json   ← أضف المفتاح
3. شغّل الأمرَين:
   flutter pub run easy_localization:generate -f keys -O lib/resources -S assets/translations -o locale_keys.g.dart
   flutter pub run easy_localization:generate -f json -O lib/resources -S assets/translations -o codegen_loader.g.dart
4. في الـ UI: LocaleKeys.myKey.tr()
```

> لماذا أمران؟ التطبيق يقرأ من `codegen_loader.g.dart` وقت التشغيل — إهمال الأمر الثاني يجعل الترجمة تظهر كـ key.

**ممنوع ❌:** `Text('نص عربي')` hardcoded · `locale.languageCode == 'ar'` · مفتاح في ar.json فقط بدون en.json

## Locale-Reactive Widgets — قاعدة إلزامية

`.tr()` لا تُسجِّل الـ element تلقائياً — يجب الوصول لـ `context.locale` في نفس `build()`:

```dart
// ✅ StatelessWidget
@override
Widget build(BuildContext context) {
  // ignore: unnecessary_statements — EasyLocalization dependency
  context.locale;
  return Text(LocaleKeys.title.tr());
}

// ✅ BlocBuilder
BlocBuilder<MyCubit, MyState>(
  builder: (context, state) {
    context.locale; // ignore: unnecessary_statements
    return Text(LocaleKeys.label.tr());
  },
)

// ✅ إذا استخدمت context.isAr في نفس build() — كافٍ (يُسجِّل تلقائياً)
```

---

## بنية الصفحة — صارمة (F19…F23)

`*_screen.dart` **ينسّق ويصل، ولا يرسم**. السقف: `build()` ≤ ٥٠ سطراً · الملف ≤ ٢٠٠.

| بالصفحة ✅ | ممنوع بالصفحة ❌ |
|---|---|
| `Scaffold` · `AppBar` · `SafeArea` · تمرير | أي `Container` بـ`decoration` |
| `BlocProvider` · `BlocConsumer` · `listener` | `Row`/`Column` بأكثر من ٥ أبناء |
| `initState`/`dispose` · `_submit()` · التنقّل | `BoxShadow` · `LinearGradient` · `BorderRadius` |
| تركيب ودجات **مسمّاة** | `Text` بـ`style: ...copyWith(...)` |

```dart
// ❌ دالة — تُعاد بناؤها كاملةً مع كل rebuild للأب، ولا const يوقفها
Widget _buildHeader(BuildContext context) => Container(...);

// ✅ ودجة — لها اسم بشجرة الأخطاء، وconst، وحدّ rebuild خاص بها
class _ProfileHeader extends StatelessWidget { ... }
```

**أين تسكن الودجة:** يستعملها feature ثانية (أو ستفعل) ⇒ `lib/ui/widgets/<group>/`
+ تصدير بـ`widgets.dart` + صفّ بـ`readme/21_WIDGETS_USAGE.md` — **الثلاثة معاً**.
وإلا ⇒ `lib/features/<f>/presentation/widgets/`.

**والودجة العامة لا تستورد `features/…` أبداً** — تُمرَّر إليها البيانات وسائطَ.

التفصيل والأسباب: [`readme/05_FIGMA_TO_PAGE.md`](../readme/05_FIGMA_TO_PAGE.md) §ز.

---

## Responsive — مقياسٌ واحد لكل مقاسٍ (صارمة)

**كلُّ رقمٍ يعتمد على الشاشة يمرّ بـ`context.screen`.**

```dart
final s = context.screen;
SizedBox(height: s.space(24))        // مسافة التصميم، محمولةً · أو ResponsiveGap(24)
Container(width: s.size(115))        // مقاس التصميم (قطر · ارتفاع · أيقونة)
EdgeInsets.symmetric(horizontal: s.gutter)
s.pick(compact: 1, expanded: 2, large: 3)
```

**وجسدُ كل شاشة يُلَفّ بـ`ResponsiveContentBox`** — بلا حدِّ عرضٍ يصير النموذج
على اللوح حقلاً تفصل لافتتَه عن قيمته ثلثُ شاشة:

```dart
body: ResponsiveContentBox(
  width: ContentWidth.form,   // ٤٨٠ · content ٨٤٠ · full بلا حدّ
  child: ...,
)
```

**ممنوع ❌:**

| ❌ | ✅ |
|---|---|
| `context.sh * 0.08` فراغاً رأسياً | `ResponsiveGap(24)` + `minHeight` من `LayoutBuilder` |
| `MediaQuery.of(context).size` بشاشة | `context.screen` |
| `if (width > 600)` مكتوبةً بالشاشة | `s.isTablet` · `s.pick(...)` |
| `textScaleFactor: 1.0` لإسكات كسرٍ بالتخطيط | `ResponsiveScope` يقيّده أصلاً (٠٫٩–١٫٣) — أصلح التخطيط |
| `setPreferredOrientations` بشاشة | `OrientationPolicy` — الهاتف عموديٌّ واللوح بالاتجاهين، ويُقرَّر مركزياً |

النِّسبةُ من الارتفاع **لا تتقلّص مع الكيبورد**، فتدفع الزرَّ خارج الحدّ على
الشاشات القصيرة. والتفصيل والأسباب:
[`readme/22_RESPONSIVE.md`](../readme/22_RESPONSIVE.md).

> ⬜ **وشاشاتُ القالب لم تُنقل بعد** — الطبقة موصولة، والنقلُ شاشةً شاشةً.
> فما تكتبه **أنت** يتبع القاعدة من أوّل سطر، وما هو قائمٌ يُنقل حين يُلمَس.

## Input — حقل واحد لا غير (R36 · F36 — فاحص آلي)

```dart
CustomTextField(controller: _c, labelText: LocaleKeys.x.tr())
```

**ممنوع ❌:** `TextField(` · `TextFormField(` مباشرةً.

ولا تغلّف الشاشة بـ`KeyboardDismissWidget` لإغلاق الكيبورد: الحقل يُغلقه بنفسه
(`onTapOutsideDismissTheKeyboard` افتراضُها `true`). Flutter لا يفعلها على
أندرويد وiOS عند لمسة إصبع — **قرارٌ متعمَّد بالإطار لا سهو**.

و`textInputAction` يُشتقّ تلقائياً: `next` لسطرٍ واحد · `newline` لمتعدّد
الأسطر — **والانتقال يتخطّى الأزرار والشرائح إلى الحقل التالي وحده**
(`InputFocusNode`؛ و`nextFocus()` العاديّ يقف عند أوّل زرٍّ بينهما).

> **العطل**: كان بالقالب **حلّان ولا يعمل أيٌّ منهما** — علَمٌ افتراضُه `false`
> لم يشغّله أحدٌ من ٢٧ ملفاً يحمل إدخالاً، وودجةٌ غلّفت شاشةً واحدة.
> **والدرس هو درس R35 نفسه: ما يُطلب تذكّره عند كل موضع لا يُتذكَّر** — فانتقل
> القرار إلى داخل الحقل.

## Progress — مؤشّر واحد لا غير (R35 · F35 — فاحص آلي)

```dart
const AppProgress.circular()                                  // تحميل
const AppProgress.circular(size: AppProgressSize.xs)          // داخل شارة أو حقل
const AppProgress.circular(centered: true)                    // وسط الشاشة
AppProgress.linear(value: p, tone: AppProgressTone.accent, label: '52 / 80')
AppProgress.circular(value: p, dimension: 54, center: Text('65%'))
```

`value: null` ⇒ غير محدّد · `0.0–1.0` ⇒ محدّد ويتحرّك — **نفس الويدجت**.
النغمات: `brand` (افتراضي) · `accent` · `success` · `warning` · `danger` ·
`neutral` · `onBrand`. المقاسات: `xs` · `sm` · `md` · `lg`.

**ممنوع ❌:** `CircularProgressIndicator` · `LinearProgressIndicator` ·
`CupertinoActivityIndicator` مباشرةً.

> **العطل**: كان بالقالب **٢٨ موضعاً** يبني مؤشّره بيده — ثلاثةُ سُمُك
> (`2` · `2.5` · `4`) وألوانُ جذعٍ مختلفة وشريطٌ بلا قرار تصميمٍ واحد وراءه.
> **ولا `dart analyze` يراه ولا اختبار**: كلُّها استدعاءات سليمة، والفرق بالبكسل
> لا بالسلوك. و`progressIndicatorTheme` لم يكفِ — يوحّد اللونَ الافتراضيَّ وحده،
> فكان كلُّ موضعٍ يتجاوزه بـ`color:` صريح.

## Text — Overflow & Expansion (صارمة)

- كل `Text` داخل `Row` أفقي → `Expanded` + `overflow: TextOverflow.ellipsis`
- كل `Text` قابل للنمو (body/card/list) → `maxLines` + `overflow: TextOverflow.ellipsis`
- **ممنوع ❌:** `Text` بدون `Expanded` داخل `Row` → RenderFlex overflow في runtime

## توسيط الأرقام — `GlyphCenter` إلزاميّ بالشارات

```dart
Container(
  width: 28, height: 28,
  alignment: Alignment.center,
  decoration: const BoxDecoration(shape: BoxShape.circle),
  child: GlyphCenter(child: Text('$n', style: context.textTheme.labelSmall)),
)
```

**متى تلزم:** رقمٌ أو نصٌّ لاتينيٌّ داخل **صندوقٍ مقاسُه ثابت** — دائرة، أو
مربّع، أو صفٌّ بـ`height`.

**ولماذا:** `Center` و`Alignment.center` و`CircleAvatar` تركّز **صندوقَ السطر**
الذي يبنيه الخطّ، لا الشكلَ المرسومَ داخله. والخطُّ العربي يبني صندوقاً
**علويَّ الثقل** عمداً — صعودٌ طويلٌ للتشكيل ونزولٌ قصير — فالنصُّ العربيّ يملؤه
فيبدو مركزيّاً، بينما الأرقامُ واللاتيني بلا نوازل فيتجمّع حبرُها بالنصف
الأعلى **وتبدو مرتفعة**.

⛔ **ولا شيء في `TextStyle` يصلح هذا**: `height` و`leadingDistribution`
و`StrutStyle` توزّع الـ`leading` حول نسبة الصعود/النزول ولا تغيّر النسبة،
فالإزاحةُ ثابتةٌ تحتها جميعاً. والمقدارُ **مقيسٌ لا مقدَّر** — من جداول الخطّ
نفسِه بـ`AppFonts.opticalCenterCorrectionFor`.

⚠️ **وحدُّها**: داخل صندوقٍ يلتصق بالنصّ (`Column` بلا ارتفاع) لا موضعَ يُزاح
إليه، فالإزاحةُ تدفع الحبرَ خارج حدوده.

## Skeletons — الهيكلُ هو الشاشةُ نفسُها (R34)

```dart
// نفسُ الجسد، بعلَمٍ واحد.
Skeletonized(enabled: state.isLoading, child: AccountBody(...))
```

**ولا ملفَّ هيكلٍ ثانٍ.** نسخةٌ ثانية من الشاشة **تكذب بالتعريف**: الجسدُ يتبدّل
ولا يتبدّل معها، فتُقرأ شاشةُ الانتظار كأنها شاشةٌ ثالثة لا كأنها الشاشةُ نفسُها
قبل أن تصل بياناتُها.

| ✅ | ❌ |
|---|---|
| `Skeletonized` فوق الجسد الحقيقي | `AccountSkeleton` بمقاساتٍ مكتوبةٍ عدداً |
| `ShimmerText(value)` للبيانة | `Text` داخل هيكلٍ منفصل |
| `Bone.circle(child: …)` لسطحٍ دائريّ | مستطيلٌ رماديٌّ يحاكيه |

**والمقاسُ يُقاس ولا يُقدَّر**: [Bone] تُخطّط طفلَها الحقيقيَّ **شفّافاً**
(`Opacity(0)`) ثم تملأ صندوقَه — فلا تقفز الصفحة لمّا يصل الجواب.

⚠️ **والبيانةُ وحدها تُلبَس.** لافتةٌ ثابتة معروفةٌ قبل الطلب وبعده، وسترُها
يُخفي ما نعرفه. و`AppListTile` يعرف الفرقَ بواجهته: `titleKey` يُعرض،
و`titleText` يُلبَس.

**وموجةُ الوميض واحدةٌ للشجرة كلِّها** — ولو ملك كلُّ عظمٍ وميضَه لبدأت
المؤقّتات بلحظاتٍ مختلفة، فتُقرأ الشاشة أشرطةً كلٌّ يومض وحده. **والسطحُ لا
يومض**: البطاقةُ وظلُّها تُرسم كما هي.

## Images — قواعد السلامة

| الحالة | الحل |
|---|---|
| صورة شخص / أفاتار | `AvatarWidget(initial: name.isNotEmpty ? name[0] : '?', imageUrl: url)` |
| صورة محتوى من شبكة | `NetworkImageWidget(url: url ?? '')` |
| صورة عامة مع cache | `CachedImageWidget(url: url ?? '')` |
| **مرفَق ميداني** (صورة أو ملف) | `CapturedPhotoTile` للبطاقة · `CapturedPhotoImage` للبايتات وحدها · `AttachmentPreview.open(...)` للفتح — و`canPreview` **قبل رسم الزرّ** |
| **ملفّ يملكه الخادم** (مسارُ تخزينٍ لا رابط) | مرّره بـ`CapturedPhoto.remotePath` — لا تُنادِ `ServerFileCache` من شاشة، ولا تمرّر `download: true` لمصغَّرة: التنزيل بضغطةٍ وحدها |
| **ممنوع ❌** | `Image.file(...)` خاماً بشاشة — يفوتها ترتيبُ المصادر و`cacheWidth`، وستُّ صورٍ بلا `cacheWidth` ≈ ٧٥ ميغابايت مقيمة **لحظةَ** تذهب العمليةُ للخلفية |
| **ممنوع ❌** | `Image.network(url)` مباشرة — لا cache، لا error widget، لا placeholder |

- `imageUrl: null` → crash في runtime — **دائماً** `url ?? ''` قبل التمرير

## context.mounted — إلزامي بعد كل await

بعد أي `await` → تحقق من `context.mounted` قبل أي استخدام لـ `context`:

```dart
await _someService.call();
if (!context.mounted) return;
context.router.push(...);
context.feedback.success(...);
```

**متى يُطبَّق؟** كل مرة تستخدم `context` بعد `await` داخل `StatefulWidget` أو listener أو initState.

## context.textTheme — ممنوع Theme.of(context)

```dart
// ✅ صحيح
context.textTheme.bodyMedium
context.textTheme.headlineLarge?.copyWith(color: context.colorScheme.primary)

// ❌ ممنوع
Theme.of(context).textTheme.bodyMedium
```

## Feedback — التمييز بين الأنواع

| الحالة | الأداة |
|---|---|
| رسالة عابرة (toast / snackbar) | `context.feedback.success/error/warning/toast` |
| حالة ثابتة في الشاشة (نجاح) | `SuccessStateWidget(messageKey: ...)` |
| قائمة فارغة | `EmptyStateWidget(titleKey: ..., icon: ...)` |
| خطأ مع retry | `ErrorStateWidget(messageKey: ..., onRetry: ...)` |
| لا إنترنت | `NoInternetWidget(onRetry: ...)` |
| صيانة | `const MaintenanceWidget()` |

**ممنوع ❌:** `context.feedback.error` لحالة ثابتة في الشاشة — استخدم `ErrorStateWidget`.

---

## Optional Platform Services

```dart
// تفعيل خدمة — خطوة واحدة فقط في app_features.dart:
static const biometrics = true;  // → يسجّل BiometricsService تلقائياً
```

| Flag | الخدمة |
|---|---|
| `biometrics = true` | `BiometricsService` |
| `clipboard = true` | `ClipboardService` |
| `shareSheet = true` | `ShareService` |
| `fileOperations = true` | `FileService` |
| `appLifecycle = true` | `AppLifecycleService` |
| `certificatePinning = true` | `CertificatePinningConfig` on Dio |
