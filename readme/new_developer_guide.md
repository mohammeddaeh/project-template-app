# New Developer Guide

> **ابدأ هنا:** [`core_architecture.md`](core_architecture.md) — المبادئ الإلزامية قبل أي تعديل.  
> **يُحدَّث هذا الملف** عند تغيير هيكل المشروع أو سير العمل الأساسي.

## 1) First-Time Setup

```bash
flutter pub get
dart run scripts/setup_project.dart
dart run build_runner build --delete-conflicting-outputs
```

After identity/flavor changes:

```bash
flutter clean
flutter pub get
cd ios && pod install
```

## 2) Project Structure

```text
lib/
  core/                 infrastructure (foundation/, platform/, infra/, di/)
  modules/              optional runtime modules (sync/)
  Features/<name>/      data / domain / presentation (cubits, pages)
  presentation/         theme, UI extensions, error UI, feedback, locale, pagination
  shared/               reusable widgets (barrel: widgets.dart)
  routes/               auto_route
  resources/            locale keys, assets helpers
new/                    optional alternate stacks (GraphQL backup, reference patterns)
readme/                 documentation — keep in sync with code changes
scripts/
```

| Folder | Role |
|--------|------|
| `core/foundation/` | Pure Dart — Failure types, BaseUseCase, contracts, extensions, validators |
| `core/platform/` | Flutter/OS wrappers — locale, connectivity, permissions, notifications, logging... |
| `core/infra/` | Implementation — network, env, errors, session |
| `core/di/` | Composition root (injectable/GetIt) — يستورد كل شيء |
| `modules/sync/` | Offline sync engine — entry: `SyncSDK.initialize(config, getIt)` |
| `Features/` | Isolated business modules — لا استيراد بين Features |
| `presentation/` | Theme, UI extensions, `FailureUiMapper`, `AppFeedbackService`, `LocaleSwitcher`, `PaginationCubit` |
| `shared/` | Cross-feature widgets |
| `tools/` | Dev-time tools only — لا يُستخدم runtime |
| `new/` | Optional stacks not wired to template (e.g. GraphQL) |

## 3) Layer Flow (REST)

```text
Page -> Cubit -> UseCase -> Repository -> RemoteDataSource -> ApiService -> Dio
Errors: Exception -> FailureMapperRegistry -> Failure -> FailureUiMapper -> UiAction
```

- Presentation does not call DataSource directly.
- Domain does not import Flutter UI.
- `core/` (foundation, platform, infra) does not import Features.

## 4) REST API (Summary)

1. URL → `lib/core/infra/network/rest/api_urls.dart`
2. Retrofit → `lib/Features/<x>/data/datasources/<x>_api_service.dart`
3. `dart run build_runner build --delete-conflicting-outputs`
4. RemoteDataSource → Repository (`handle()`) → UseCase → Cubit

Full guide: [`rest_api.md`](rest_api.md)

### Repository pattern

```dart
return handle(() async {
  final result = await _remote.login(...);
  if (result.error == null && result.data != null) {
    return Right(LoginResult(accessToken: result.data!.accessToken));
  }
  return Left(BusinessFailure(
    statusCode: result.error?.code ?? 400,
    serverMessage: result.message.isNotEmpty ? result.message : null,
  ));
});
```

## 5) Feedback & Locale (Presentation Infrastructure)

### Feedback
Show toasts/snackbars via `context.feedback`:
```dart
context.feedback.success('تمت العملية');
context.feedback.error('حدث خطأ');
context.feedback.warning('تنبيه', title: 'انتبه');
context.feedback.toast('رسالة بسيطة');
```
تبديل الـ adapter (motion_toast / SnackBar / fluttertoast): سطر واحد في `injection_module.dart`.

### Locale
```dart
context.isAr          // bool — بدلاً من context.locale.languageCode == 'ar'
context.isRtl         // bool
context.appLocale     // AppLocale enum

LocaleSwitcher.tile()         // في صفحة الإعدادات
LocaleSwitcher.iconButton()   // في AppBar
LocaleSwitcher.segmented()    // في الأونبوردينج
LocaleSwitcher.textToggle()   // inline
```

## 6) GraphQL (Optional — Not in Template)

GraphQL is **not** in `lib/`. Backup stack: `new/09_graphql/README.md`.

Template default: **REST only**.

## 7) Pagination

1. Domain page entity + paginated API model
2. Cubit extends `PaginationCubit<T>` in `presentation/cubits/`
3. Page uses `PaginationBuilderWdg`

Reference:

- `lib/Features/users/presentation/cubits/users_cubit.dart`
- `lib/Features/users/presentation/pages/users_screen.dart`

Guide: [`pagination.md`](pagination.md)

## 8) Scripts

| Script | Purpose |
|--------|---------|
| `setup_project.dart` | App identity, bundle ID, package name |
| `feature_generator.dart` | New feature skeleton |
| `generate_flavors.dart` / `delete_flavors.dart` | Flavor management |
| `common_commands.dart` | Interactive command menu |

Details: [`scripts.md`](scripts.md)

## 9) Widgets Placement

- Feature-only → `lib/Features/<x>/presentation/widgets/`
- Shared → `lib/shared/widgets/`
- UI infrastructure → `lib/presentation/theme/`, `lib/presentation/error/`, `lib/presentation/extensions/`
- Feedback (toast/snackbar) → `lib/presentation/feedback/` — استخدام: `context.feedback.success(...)`
- Language switcher → `lib/presentation/locale/` — استخدام: `LocaleSwitcher.tile()`

Guide: [`widgets.md`](widgets.md)

## 10) New Feature

```bash
dart run scripts/feature_generator.dart
dart run build_runner build --delete-conflicting-outputs
dart analyze lib
```

Then implement business logic following [`core_architecture.md`](core_architecture.md).

## 11) Documentation Sync (Mandatory)

When you change code, update the matching readme:

| If you changed… | Update… |
|-----------------|---------|
| Core structure / principles | `core_architecture.md` |
| REST / API pattern | `rest_api.md` |
| Pagination | `pagination.md` |
| Widgets rules | `widgets.md` |
| Scripts / workflow | `scripts.md` |
| Onboarding / structure | this file + `architecture.md` |

Cursor rule `.cursor/rules/core-architecture.mdc` enforces this automatically.

## 12) Team Rules

- Follow `core_architecture.md` for every architectural change
- Use scripts for repetitive setup
- Keep business logic out of widgets
- Regenerate after API/router/DI/Freezed changes
- One feature must not import another feature
- Update readme when behavior or paths change

## 13) Related Docs

- [`core_architecture.md`](core_architecture.md) — **primary reference**
- [`architecture.md`](architecture.md) — index
- [`rest_api.md`](rest_api.md) — REST flow + import paths
- [`scripts.md`](scripts.md) — scripts + build/release + troubleshooting
- [`new/09_graphql/README.md`](../new/09_graphql/README.md)

*Last updated: 2026-06-17*
