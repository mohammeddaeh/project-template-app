# حِزَم الأجهزة (Device Kits)

> **ما يجرّ كوداً أصلياً ثقيلاً — محرّكَ صوت · كاميرا حيّة · نماذجَ تعرّف — يعيش
> بحزمةٍ تحت `packages/`، يدخل المشروعَ بأمرٍ واحد ويخرج بأمرٍ واحد.** والتطبيق
> يعرف عقدها وحده.

---

## ١. لماذا ليست خدمةً بـ`core/platform/`

خدمات المنصّة خلف علَمٍ بـ`AppFeatures`، **والعلَم يُطفئ التسجيل لا الحزمة**:
الحزمة تُبنى وتُشحن في كل مشروع، مستعمَلةً أو لا.

| الكلفة | حزمةٌ مُثبَّتة بلا استعمال |
|---|---|
| حجم التطبيق | كودها الأصلي بالثنائي |
| مراجعة iOS | واجهاتٌ حسّاسة مرتبطة ← سؤالُ «لماذا الميكروفون؟» بلا جواب |
| 16KB بأندرويد | كلُّ `.so` إضافي احتمالُ رفضٍ من Play |
| الترقية | تعارضُ تبعياتٍ لما لا يستعمله المشروع |

فالحزمة الثقيلة **لا تكون** بـ`pubspec.yaml` إلا حين يركّبها المشروع.

## ٢. البنية

```
packages/
├── kit_contracts/      ← Dart صرف: العقود وأنواع النتائج — التطبيق يعتمد عليه دائماً
└── kit_<name>/         ← kit واحدة: تنفيذُ العقد بحزم المنصّة
    ├── kit.json        ← البيان
    └── lib/kit_<name>.dart  ← تصدّر register<Name>Kit(GetIt)
lib/core/di/kits.g.dart ← مولَّد: المركَّب وتسجيله — الملف الوحيد بـlib/ الذي يستورد kit
```

### اتجاه التبعية

```
kit_contracts            → لا شيء
kit_<name>               → kit_contracts + حزم المنصّة
lib/ (كله، بالموديولات)  → kit_contracts
lib/core/di/kits.g.dart  → kit_<name>
```

| ممنوع ❌ | الحارس |
|---|---|
| `import 'package:kit_<name>/…'` بأي ملف بـ`lib/` | `C18` |
| kit تستورد `package:app_template/…` أو kit أخرى | `C18` |
| حزمةُ منصّةٍ يعلنها `kit.json` تُستورد خارج حزمتها | `C19` |
| kit تحمل نصّاً معروضاً أو لوناً أو ودجة | 👁 — الواجهة والترجمة والثيم ملكُ التطبيق |
| تعديل `kits.g.dart` باليد | 👁 — `kit.dart` يكتبه كاملاً |

### البيان — `kit.json`

```json
{
  "name": "voice",
  "register": "registerVoiceKit",
  "permissions": ["microphone"],
  "platformPackages": ["speech_to_text", "flutter_tts"]
}
```

| الحقل | يُستعمل في |
|---|---|
| `permissions` | أعلامُ `AppFeatures` التي يُشعلها التركيب، ثم `sync_platform_permissions.dart` |
| `platformPackages` | `C19` — ما لا يُستورد إلا داخل الـkit |

## ٣. الأوامر

```bash
dart run scripts/kit.dart list            # المتاح · المركَّب · أذوناتُ كلٍّ
dart run scripts/kit.dart add voice       # يركّب
dart run scripts/kit.dart remove voice    # يزيل
dart run scripts/kit.dart test            # اختباراتُ kit_contracts وكلِّ kit مركَّبة
```

`add` يكتب بنفس الأمر: تبعيةَ `path` بـ`pubspec.yaml` · سطرَ التسجيل بـ`kits.g.dart`
· أعلامَ الأذونات · ثم `flutter pub get` ومزامنةَ الأذونات.

`remove` عكسُه، **وجولةُ `add` ثم `remove` لا تترك فرقاً بـgit**:

- يُطفئ **ما أشعله التركيب وحده** — `kits.g.dart` يسجّله بسطر `// kit:<name> enabled <flag>`.
  علَمٌ كان مُشعلاً قبل التركيب (الكاميرا لخدمةٍ أخرى) يبقى كما هو.
- وعلَمٌ أشعلته kit تُزال وتحتاجه kit باقية **ينتقل سجلُّه إليها** ولا يُطفأ.

ومجلد الـkit يبقى بـ`packages/` بعد إزالتها — فتُركَّب ثانيةً بأمرٍ واحد.

**وعند إنشاء مشروع**: `setup_project.dart --kits voice,scan` يُبقي المذكور ويزيل
الباقي — **والافتراضي لا شيء**.

## ٤. التطبيق والـkit الغائبة

الشاشة لا تعرف هل الـkit مركَّبة — **تسأل**:

```dart
if (!getIt.isRegistered<SpeechInput>()) return const SizedBox.shrink();
```

فالتطبيق يُبنى ويعمل بالـkit وبدونها، ولا يتغيّر سطرٌ بـ`lib/` حين تُزال.

## ٥. العقد

- **لا استثناء يعبر الحدّ**: كل عقدٍ يجيب `KitAvailability` (`KitReady` ·
  `KitNeedsPermission` · `KitUnsupported`) قبل أن يعمل، والفشل أنواعٌ مختومة
  يحوّلها التطبيق `Failure` ⇐ `FailureUiMapper`.
- **الإذن يُطلب بالتطبيق**: `KitNeedsPermission(KitPermission.microphone)` ⇐
  `PermissionsService` — فلا يصير للإذن مساران.
- **اختباراتُ التطبيق لا تلمس حزمة منصّة**: تسجّل تنفيذاً مزيَّفاً للعقد.

## ٦. kit جديدة

1. `packages/kit_<name>/` بـ`pubspec.yaml` (`publish_to: none` · `kit_contracts: {path: ../kit_contracts}` · `get_it`) و`kit.json` و`analysis_options.yaml` خاصٍّ بها — وإلا ورثت ملفَّ الجذر وهو يطلب `flutter_lints` الذي لا تملكه.
2. العقد بـ`kit_contracts/lib/src/<name>/` ويُصدَّر من `kit_contracts.dart`.
3. `lib/kit_<name>.dart` يصدّر `register<Name>Kit(GetIt getIt)`.
4. اختباراتها بـ`packages/kit_<name>/test/` — `kit.dart test` يشغّلها.
5. `dart run scripts/kit.dart add <name>` · صفٌّ بـ`06_CAPABILITIES.md` · صفحةٌ بالمرآة.

وحزمةٌ خفيفة بلا كود أصلي، أو يحتاجها كل مشروع، **ليست kit** — مكانها
`core/platform/` كباقي الخدمات.
