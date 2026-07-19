# Widgets Placement Guide

> **مرجع معماري:** [`core_architecture.md`](core_architecture.md)  
> **يُحدَّث هذا الملف** عند تغيير قواعد توزيع الـ widgets أو مسارات `shared/`.

## Rule of Thumb

- Used by **one feature** → feature folder
- Used by **multiple features** → `shared/`

## 1) Feature-Only Widgets

```text
lib/Features/<feature_name>/presentation/widgets/
```

Examples: `login_form.dart`, `products_filter_sheet.dart`

## 2) Shared Widgets

```text
lib/shared/widgets/
```

Barrel: `lib/shared/widgets/widgets.dart`

Examples: `primary_button.dart`, `custom_text_field.dart`, `pagination_builder_wdg.dart`, error/loading/empty states.

## 3) Presentation Layer (Not Feature, Not Shared)

Some UI infrastructure lives in `lib/presentation/`:

| Path | Content |
|------|---------|
| `presentation/theme/` | Colors, palette, theme, `ThemeExtensions` |
| `presentation/extensions/` | BuildContext helpers — padding, screen size, dialog, bottom sheet |
| `presentation/error/` | `FailureUiMapper`, `UiAction` |
| `presentation/feedback/` | `AppFeedbackService` (abstract), adapters (MotionToast/SnackBar/Toast), `context.feedback.*` |
| `presentation/locale/` | `LocaleSwitcher` variants, `context.isAr`, `context.changeLocale()` |
| `presentation/shared/connectivity/` | `ConnectivityCubit` |
| `presentation/shared/pagination/` | `PaginationCubit` |

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
  Features/
    users/
      presentation/
        pages/users_screen.dart
        cubits/users_cubit.dart
        widgets/users_header.dart
  shared/
    widgets/
      layout/primary_button.dart
      inputs/custom_text_field.dart
      lists/pagination_builder_wdg.dart
  presentation/
    theme/
    extensions/
    error/
    feedback/             ← AppFeedbackService + adapters
    locale/               ← LocaleSwitcher variants + context.isAr
    shared/
      pagination/
      connectivity/
```

## 7) Related Docs

- [`core_architecture.md`](core_architecture.md) — architecture principles
- [`new_developer_guide.md`](new_developer_guide.md) — onboarding + feedback/locale API
- [`architecture.md`](architecture.md) — project structure index

*Last updated: 2026-06-17 — presentation/feedback/ + presentation/locale/ مضافتان*
