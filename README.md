# app_template

قالب Flutter لتطبيقات تتكلّم مع خادم: بنيةٌ بطبقاتٍ صارمة، ونظامُ تصميم، ودورةُ حسابٍ
كاملة، وموديولاتٌ اختيارية تُشعَل بعلَم، وحِزَمٌ لأجهزة الهاتف تُركَّب بأمر.
**بلا feature تطبيقية** — أوّل feature يكتبها مشروعك.

> **أوّل يوم؟** اقرأ [`readme/00_START_HERE.md`](readme/00_START_HERE.md) — رود ماب بخمس
> مراحل، كلٌّ بمعيار «تمّت».

## البدء

```bash
flutter pub get
dart run scripts/gen_code.dart          # كل التوليد بأمرٍ واحد
flutter run --flavor dev --dart-define-from-file=.env.dev.json
```

ومشروعٌ جديد من القالب: `scripts/new_project.ps1` — [`readme/01_SETUP.md`](readme/01_SETUP.md).

## خريطة المستودع

| المجلد | ما فيه | ابدأ من |
|---|---|---|
| `lib/core/` | البنية التحتية: `foundation` (Dart خالص) · `platform` (أغلفة النظام) · `infra` (الشبكة والجلسة) · `di` | [`lib/core/CLAUDE.md`](lib/core/CLAUDE.md) |
| `lib/ui/` | طبقة الواجهة المشتركة: مكتبة الودجات · الثيم · المقاسات · رسائل المستخدم | [`readme/20_WIDGETS.md`](readme/20_WIDGETS.md) |
| `lib/features/` | الشرائح: `auth/` (دورة الحساب) · `home/` · `settings/` · `startup/` | [`readme/04_FIRST_FEATURE.md`](readme/04_FIRST_FEATURE.md) |
| `lib/modules/` | موديولاتٌ اختيارية، كلٌّ بعلَمٍ بـ`AppFeatures` | [`readme/30_MODULES.md`](readme/30_MODULES.md) |
| `packages/` | حِزَم الأجهزة (صوت · فيديو · مسح · كتابة يدوية · أوامر النظام) — تُركَّب بـ`scripts/kit.dart` | [`packages/README.md`](packages/README.md) |
| `scripts/` | التوليد · البناء · إنشاء مشروع · الفاحصات · نقل تطبيقٍ قائم | [`readme/40_SCRIPTS.md`](readme/40_SCRIPTS.md) |
| `readme/` | التوثيق كلّه، مرقّماً بالموضوع | [`readme/README.md`](readme/README.md) |
| `test/` | الاختبارات، ومعها عقدُ الـwire مع الباك (`test/fixtures/wire/`) | — |
| `loadtest/` | سيناريوهات k6 للباك | [`loadtest/README.md`](loadtest/README.md) |

## ثلاث قواعد قبل أي سطر

1. **ابحث قبل أن تكتب أداة** — [`readme/06_CAPABILITIES.md`](readme/06_CAPABILITIES.md): التاريخ والأرقام
   والصور والمشاركة وغيرها مبنيّةٌ ومختبَرة، و`check_structure` يُفشل كتابتها ثانيةً.
2. **القواعد الصارمة بأسبابها** — [`readme/03_RULES.md`](readme/03_RULES.md)، مرقّمةً `R##` للاستشهاد.
3. **قبل التسليم**: `dart analyze` · `flutter test` · `dart run scripts/check_structure.dart` ·
   `dart run scripts/check_docs.dart`.
