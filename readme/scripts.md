# Scripts Reference

> **مرجع معماري:** [`core_architecture.md`](core_architecture.md)  
> **يُحدَّث هذا الملف** عند إضافة/تعديل/حذف سكربت في `scripts/`.

All scripts live in `scripts/` and are executed from project root:

```bash
dart run scripts/<script_name>.dart
```

## 1) Mandatory Script for New Projects

### `setup_project.dart`

Run this first when creating a project from template.

```bash
dart run scripts/setup_project.dart
```

It updates:

- App name (EN/AR)
- Bundle ID / namespace
- `pubspec.yaml` package name
- package imports
- Android package folders (`MainActivity` path)
- `.iml` names
- `.vscode/launch.json`

After setup:

```bash
flutter clean
flutter pub get
cd ios && pod install
```

## 2) Daily Commands Menu

### `common_commands.dart`

Interactive command menu for common tasks.

```bash
dart run scripts/common_commands.dart
```

Example input:

```text
1,4,2
```

Runs selected commands in order.

## 3) Feature Generation

### `feature_generator.dart`

Generates a complete clean-architecture feature skeleton and auto-adds its route.

Generates the `data/`, `domain/`, and `presentation/` (cubits + pages) folders with placeholder files.

> **Note:** The generated files are stubs — clean them up and implement your actual API flow
> following the REST pattern in [`rest_api.md`](rest_api.md).

```bash
dart run scripts/feature_generator.dart
```

Then run:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

## 4) Flavors

### `generate_flavors.dart`

Creates multi-environment flavors with safe pre-cleanup.

```bash
dart run scripts/generate_flavors.dart
```

Options:

```bash
dart run scripts/generate_flavors.dart --force
dart run scripts/generate_flavors.dart --dry-run
```

### `delete_flavors.dart`

Safely removes flavors and restores single-environment mode.

```bash
dart run scripts/delete_flavors.dart
```

Options:

```bash
dart run scripts/delete_flavors.dart --force
dart run scripts/delete_flavors.dart --dry-run
```

## 5) Assets, Fonts, Localization, Icons

### Assets

```bash
dart run scripts/asset_yaml_generator.dart
dart run scripts/asset_class_generator.dart
```

### Fonts

```bash
dart run scripts/font_yaml_generator.dart
dart run scripts/font_family_generator.dart
```

### Localization

```bash
dart run scripts/language_generator.dart

# أمران إلزاميان دائماً بعد تعديل ar.json / en.json:
# 1) locale_keys.g.dart — مفاتيح Dart
flutter pub run easy_localization:generate -f keys -O lib/resources -S assets/translations -o locale_keys.g.dart
# 2) codegen_loader.g.dart — runtime reader (CodegenLoader)
flutter pub run easy_localization:generate -f json -O lib/resources -S assets/translations -o codegen_loader.g.dart
```

> **ملاحظة:** التطبيق يستخدم `assetLoader: const CodegenLoader()` — إذا شغّلت الأمر الأول فقط ستظهر المفاتيح الجديدة كـ key في الواجهة لأن `codegen_loader.g.dart` لم يُحدَّث.

### App icon

```bash
dart run scripts/add_app_icon.dart
```

## 6) Code Generation — When to Re-run

Run `dart run build_runner build --delete-conflicting-outputs` after changing:

| Changed file/area | Reason |
|-------------------|--------|
| `*_api_service.dart` | Retrofit generates `.g.dart` |
| `@injectable` / `@module` classes | DI updates `injection.config.dart` |
| `@RoutePage` / router | `router.gr.dart` regenerated |
| `*.freezed.dart` models | State classes rebuilt |

## 7) Export & Codegen

السكربتان المعتمدان للتصدير والكود (تُشغَّلان من جذر المشروع).
التطوير اليومي يتم عبر VS Code مباشرة باستخدام الـ flavor المناسب.

### `codegen.dart` — توليد الكود

```bash
dart run scripts/codegen.dart
```

يُشغّل 3 خطوات بالتسلسل:
1. `build_runner` — Retrofit · Freezed · Injectable · AutoRoute
2. `easy_localization:generate` → `locale_keys.g.dart`
3. `easy_localization:generate` → `codegen_loader.g.dart` (runtime reader)

---

### `export.dart` — تصدير APK للإرسال

```bash
dart run scripts/export.dart [options]
```

| Flag | القيم | الافتراضي |
|---|---|---|
| `--flavor` | dev / staging / prod | dev |
| `--mode` | debug / release | debug |
| `--bump` | build / patch / minor / major | build |
| `--no-bump` | — | off |
| `--clean` | — | off |
| `--no-codegen` | — | off |

**أنواع الـ bump:**

| النوع | مثال قبل | مثال بعد | متى |
|---|---|---|---|
| `build` | 1.2.3+5 | 1.2.3+6 | كل dev build — الافتراضي |
| `patch` | 1.2.3+5 | 1.2.4+6 | bugfix للـ testers |
| `minor` | 1.2.3+5 | 1.3.0+6 | feature جديدة |
| `major` | 1.2.3+5 | 2.0.0+6 | إعادة هيكلة |

يرفع `versionCode` دائماً لمنع `INSTALL_FAILED_VERSION_DOWNGRADE`.
يكتب نتيجة البناء في `.dart_tool/last_build.json` (مُتجاهَل git).

**APK output:** `build/app/outputs/flutter-apk/app-{flavor}-{mode}.apk`

### بناء يدوي (بدون السكربتات)

```bash
# بدون flavors
flutter build apk --split-per-abi
flutter build appbundle -t lib/main.dart

# مع flavors (يدوي فقط إذا اضطررت)
flutter build apk --split-per-abi --flavor <flavor_name>
flutter build appbundle --flavor <flavor_name>
```

> **تحذير:** البناء اليدوي لا يرفع الإصدار ولا يُشغّل codegen — استخدم السكربتات دائماً.

## 8) Troubleshooting

| Issue | Fix |
|-------|-----|
| `*.g.dart` / `*.freezed.dart` errors | Run `dart run build_runner build --delete-conflicting-outputs` |
| Routes not found after `@RoutePage` change | Run `build_runner` |
| iOS build fails after flavors change | `flutter clean` + `cd ios && pod install` |
| DI registration errors | Run `build_runner`, check `injection.config.dart` |
| Localization key shows as raw string at runtime | Run BOTH generate commands (locale_keys.g.dart + codegen_loader.g.dart) |
| `.tr()` text doesn't update on locale switch | Add `context.locale;` at top of `build()` / `BlocBuilder.builder` |
| `injection.config.dart` hash collision (DI fails) | Manually rename duplicate alias (e.g. `_i693` → `_i6931`) in generated file |

## 9) Script Usage Rules

- Use scripts instead of manual config edits whenever possible.
- Re-run code generation after script changes that affect DI/router/API.
- Commit generated files when required by your team workflow.
- Update this file when adding or changing scripts.

## 10) Related Docs

- [`new_developer_guide.md`](new_developer_guide.md) — onboarding + full structure
- [`core_architecture.md`](core_architecture.md) — architecture principles
- [`rest_api.md`](rest_api.md) — REST workflow

*Last updated: 2026-06-29 — fixed localization output path (`-O lib/resources`); added codegen_loader.g.dart command; added troubleshooting entries for locale and DI collision.*
