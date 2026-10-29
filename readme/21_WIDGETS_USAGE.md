# Widget Library — دليل الاستخدام

> **هذا الملف فهرس.** شرح كل ودجة بملف فئتها تحت [`widgets/`](widgets/) — رقم القسم
> (`§28`) ثابتٌ أينما ذُكر، والرابط بالجدول يفتح ملفّه:
>
> | الملف | الفئة |
> |---|---|
> | [`widgets/01_buttons.md`](widgets/01_buttons.md) | الأزرار والتفاعل |
> | [`widgets/02_inputs.md`](widgets/02_inputs.md) | الإدخال والنماذج |
> | [`widgets/03_layout.md`](widgets/03_layout.md) | التخطيط والمسافات |
> | [`widgets/04_display.md`](widgets/04_display.md) | عرض البيانات والصور والتاريخ |
> | [`widgets/05_states.md`](widgets/05_states.md) | الحالات والتحميل والرسائل |
> | [`widgets/06_navigation.md`](widgets/06_navigation.md) | التنقّل والحوارات والإرشاد |
>
> **ودجةٌ جديدة**: قسمٌ بملف فئتها برقمٍ تالٍ، وصفٌّ بالجدول أدناه — بنفس التغيير.

> **Import الوحيد لجميع الـ widgets:**
> ```dart
> import 'package:app_template/ui/widgets/widgets.dart';
> ```
> استثناءات في §DIRECT-IMPORTS.

---

## فهرس

| الـ Widget | النوع | القسم |
|-----------|-------|-------|
| `AppButton` | زر | [§1](widgets/01_buttons.md) |
| `PrimaryButton` | زر (توافق) | [§2](widgets/01_buttons.md) |
| `AppStateWidget` | حالات الشاشة | [§3](widgets/05_states.md) |
| `context.feedback.*` | Toast / Snackbar | [§4](widgets/05_states.md) |
| `CustomTextField` | إدخال | [§5](widgets/02_inputs.md) |
| `AppSearchBar` | إدخال | [§6](widgets/02_inputs.md) |
| `AppSelectField<T>` | إدخال | [§7](widgets/02_inputs.md) |
| `ChipRow<T>` | إدخال | [§8](widgets/02_inputs.md) |
| `AppNavBar` | تخطيط | [§9](widgets/03_layout.md) |
| `AppCard` | تخطيط | [§10](widgets/03_layout.md) |
| `AppListTile` | تخطيط | [§11](widgets/03_layout.md) |
| `ExpandableSection` | تخطيط | [§12](widgets/03_layout.md) |
| `KeyValueRow / KeyValueSection` | عرض بيانات | [§13](widgets/04_display.md) |
| `StatCard` | عرض بيانات | [§14](widgets/04_display.md) |
| `StepProgressIndicator` | عرض بيانات | [§15](widgets/04_display.md) |
| `AppLabel` | تصنيف | [§16](widgets/04_display.md) |
| `PaginationBuilderWdg` | قوائم | [§17](widgets/05_states.md) |
| `ShimmerLoadingWidget / SkeletonWidget` | تحميل | [§18](widgets/05_states.md) |
| `AvatarWidget` | صور | [§19](widgets/04_display.md) |
| `AppTabBar` | تنقل | [§20](widgets/06_navigation.md) |
| `Dialogs` | حوارات | [§21](widgets/06_navigation.md) |
| `Connectivity` | اتصال | [§22](widgets/05_states.md) |
| `DividerWidget / DashedDivider / SectionTitle` | تقسيم | [§23](widgets/03_layout.md) |
| `Spacing` | مسافات | [§24](widgets/03_layout.md) |
| `BadgeWidget / TagWidget` | توافق | [§25](widgets/04_display.md) |
| `AppProgress` | تحميل | [§26](widgets/05_states.md) |
| `GlyphCenter` | توسيط | [§27](widgets/03_layout.md) |
| `AppDateText` | تاريخ | [§28](widgets/04_display.md) |
| `ErrorBoundary` / `ErrorFallback` | بنية تحتية | [§29](widgets/05_states.md) |
| `PressableScale` | تفاعل | [§30](widgets/01_buttons.md) |
| `StatusFeedbackIndicator` | تفاعل | [§31](widgets/05_states.md) |
| `GuideOverlay` | onboarding | [§32](widgets/06_navigation.md) |
| `validateAndReveal` | نماذج | [§33](widgets/02_inputs.md) |
| `SvgImageWidget` / `.icon` | صور | [§34](widgets/04_display.md) |

### §DIRECT-IMPORTS — imports مباشرة (غير موجودة في barrel)

```dart
import 'package:app_template/ui/extensions/screen_sizes_extensions.dart';
// context.sw, context.sh, context.bottomPadding, context.topPadding

import 'package:app_template/ui/extensions/app_padding_extension.dart';
// 16.allPadding / 16.horizontalPadding / 16.verticalPadding
// 4.widthBox / 4.heightBox

import 'package:app_template/ui/theme/theme_extensions.dart';
// context.colors / context.textTheme / context.colorScheme

import 'package:app_template/ui/feedback/feedback_extension.dart';
// context.feedback.* — إلزامي في كل ملف يستخدمه
```

---
