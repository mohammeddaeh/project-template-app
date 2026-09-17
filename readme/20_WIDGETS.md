# Widgets Placement Guide

> **مرجع معماري:** [`11_CORE.md`](11_CORE.md)  
> **يُحدَّث هذا الملف** عند تغيير قواعد توزيع الـ widgets أو مسارات `shared/`.

## Rule of Thumb

- Used by **one feature** → feature folder
- Used by **multiple features** → `shared/`

## 1) Feature-Only Widgets

```text
lib/features/<feature_name>/presentation/widgets/
```

Examples: `login_form.dart`, `products_filter_sheet.dart`

## 2) Shared Widgets

```text
lib/ui/widgets/
```

Barrel: `lib/ui/widgets/widgets.dart`

Examples: `primary_button.dart`, `custom_text_field.dart`, `pagination_builder_wdg.dart`, error/loading/empty states.

## 3) Presentation Layer (Not Feature, Not Shared)

Some UI infrastructure lives in `lib/ui/`:

| Path | Content |
|------|---------|
| `ui/theme/` | Colors, palette, theme, `ThemeExtensions`, `AppRadius`/`AppMotion`/`AppElevation` (design tokens — راجع [`41_ROADMAP.md`](41_ROADMAP.md) بند #16) |
| `ui/extensions/` | BuildContext helpers — padding, screen size, dialog, bottom sheet |
| `ui/error/` | `FailureUiMapper`, `UiAction` |
| `ui/feedback/` | `AppFeedbackService` (abstract), adapters (MotionToast/SnackBar/Toast), `context.feedback.*` |
| `ui/locale/` | `LocaleSwitcher` variants, `context.isAr`, `context.changeLocale()` |
| `ui/state/connectivity/` | `ConnectivityCubit` |
| `ui/state/pagination/` | `PaginationCubit` |

Do not put these in `core/`.

### Feedback — Quick Reference
```dart
// استخدام (في أي Widget/Cubit):
context.feedback.success('تمت العملية بنجاح');
context.feedback.error('حدث خطأ');
context.feedback.warning('تنبيه', title: 'انتبه', duration: Duration(seconds: 5));
context.feedback.toast('رسالة خفيفة');
```

### Locale Switcher — Quick Reference
```dart
LocaleSwitcher.tile()         // ListTile + bottom-sheet picker (صفحة الإعدادات)
LocaleSwitcher.iconButton()   // أيقونة في AppBar
LocaleSwitcher.segmented()    // SegmentedButton (الأونبوردينج)
LocaleSwitcher.textToggle()   // العربية | English (inline)
```

## 4) What Not To Do

- Do not put feature-specific widgets in `shared` too early
- Do not duplicate widgets across features
- Do not add business logic in shared widgets
- Do not put widgets in `core/`
- Do not put `PaginationCubit`, `AppFeedbackService`, `LocaleSwitcher`, or theme/extensions in `core/` (they belong in `presentation/`)
- Do not use `context.locale.languageCode == 'ar'` — use `context.isAr` instead
- Do not use `context.showToast(...)` — that extension was removed; use `context.feedback.success(...)` instead

## 5) Decision Checklist

- Will another feature use this soon?
- Does it contain feature-specific business terms?
- Is it a design-system component?

If unsure → start in feature, promote to `shared` when reuse is real.

## 6) Example Structure

```text
lib/
  features/
    users/
      presentation/
        pages/users_screen.dart
        cubits/users_cubit.dart
        widgets/users_header.dart
  ui/
    widgets/
      layout/primary_button.dart
      inputs/custom_text_field.dart
      lists/pagination_builder_wdg.dart
    theme/
    extensions/
    error/
    feedback/             ← AppFeedbackService + adapters
    locale/               ← LocaleSwitcher variants + context.isAr
    state/
      pagination/
      connectivity/
```

## 7) Related Docs

- [`11_CORE.md`](11_CORE.md) — architecture principles
- [`00_START_HERE.md`](00_START_HERE.md) — onboarding + feedback/locale API
- [`10_ARCHITECTURE.md`](10_ARCHITECTURE.md) — project structure index

*Last updated: 2026-09-16 — إضافة `AppRadius`/`AppMotion`/`AppElevation` بـ`ui/theme/` (§3)*

*2026-09-10 — §6 مطابَقة لبنية `lib/ui/` الحالية (كانت تُظهر `lib/shared/`/`lib/presentation/` المدمَجَين فيها)*
