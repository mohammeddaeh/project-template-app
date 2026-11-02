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
├── kit_contracts/      ← العقود وأنواع النتائج — Flutter بلا أي plugin (لنوع `Widget` وحده)، والتطبيق يعتمد عليه دائماً
└── kit_<name>/         ← kit واحدة: تنفيذُ العقد بحزم المنصّة
    ├── kit.json        ← البيان
    └── lib/kit_<name>.dart  ← تصدّر register<Name>Kit(GetIt)
lib/core/di/kits.g.dart ← مولَّد: المركَّب وتسجيله — الملف الوحيد بـlib/ الذي يستورد kit
android/app/proguard-kits.pro ← مولَّد: قواعد R8 للمركَّب — build.gradle.kts يضمّه لنسخة release
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
  "permissions": ["microphone", "speechRecognition", "textToSpeech"],
  "platformPackages": ["speech_to_text", "flutter_tts"]
}
```

| الحقل | يُستعمل في |
|---|---|
| `permissions` | أعلامُ `AppFeatures` التي يُشعلها التركيب، ثم `sync_platform_permissions.dart` |
| `platformPackages` | `C19` — ما لا يُستورد إلا داخل الـkit |
| `proguard` | قواعد R8 تحتاجها مكتبةٌ تشير لأصنافٍ لا تشحنها — تُكتب بـ`proguard-kits.pro`، **وبدونها تفشل نسخة release وحدها** (debug سليم) |

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
الباقي — **والافتراضي لا شيء**. ومستودعُ القالب نفسه يحمل الـkits السبع مركّبةً،
لأن جولة المطوّر (`modules/showcase/`) تعرض كلّاً منها.

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

## ٦. المتاح

| الـkit | العقود | بالتطبيق | الأعلام |
|---|---|---|---|
| `voice` | `SpeechInput` · `SpeechOutput` | `CustomTextField(dictation:)` · `DictationButton` · `SpeakButton` — [§42](widgets/02_inputs.md) | `microphone` · `speechRecognition` · `textToSpeech` |
| `audio` | `AudioRecorder` · `AudioPlayback` (مصنع: مشغّلٌ لكل طالب) | `VoiceNoteRecorder` · `AudioPlayerTile` · `AttachmentPreview` يشغّل المرفق الصوتيّ بالتطبيق — [§43](widgets/04_display.md) | `microphone` |
| `scan` | `CodeScanner` | `DeviceScan.code` — [§44](widgets/02_inputs.md) | `camera` |
| `ocr` | `TextRecognizer` | `DeviceScan.text` — **لاتينيّ وحده، لا عربي** | — |
| `video` | `VideoPlayback` (مصنع) | `AppVideoPlayer` · `AttachmentPreview` يشغّل مرفق الفيديو بالتطبيق — [§45](widgets/04_display.md) | — |
| `system` | `AppShortcuts` · `AppReview` | العقدان مباشرةً — §٧ | — |
| `ink` | `InkRecognizer` (نموذجٌ لكل لغة يُنزَّل مرّة — `ar` · `en`) | `HandwritingInput` — [§46](widgets/02_inputs.md) | — |

**والتوقيعُ ليس kit**: `SignaturePad` رسمٌ بـFlutter وحده — بالمكتبة، ويعمل بلا أي kit.

**والحجم يقرّر الحدود** — release arm64، تطبيقُ القالب بلا kit = 30.3MB:

| الـkit | تضيف | لماذا |
|---|---|---|
| `voice` + `audio` | +0.4MB | المحرّكات من النظام |
| `scan` | +6.5MB | نموذجُ الباركود مضمَّنٌ بالتطبيق — يعمل بلا خدمات Google وبلا شبكة |
| `ocr` | +12MB | نموذجُ النص اللاتيني مضمَّن — **ولهذا هو kit وحده**: من يمسح الرموز لا يحمله |
| `video` · `system` · `ink` | لم تُقَس | `ink` تُنزّل نموذجَها عند أوّل استعمال، فلا يدخل التطبيق |

**ولا ماسحَ مستنداتٍ بالقالب — بقرار.** ماسحُ Google (ML Kit) وحدةٌ تُنزَّل عبر Play services ورفضها جهازُ
التجربة حتى عبر VPN؛ والبديلُ الوحيد السليم بلا خدمات Google (`flutter_edge_detection`: OpenCV 4.13 ·
WeScan) يطلب Flutter أحدث، وتصونه يدٌ واحدة. التفصيل بخطّة الـkits بمستودع القالب.

**وأعلامٌ بلا إذن**: `textToSpeech` لا يطلب شيئاً من المستخدم، لكن أندرويد 11+ لا
يُري التطبيقَ محرّكاً لم يُعلَن بـ`<queries>` — فيُقال «لا محرّك» والمحرّك مثبَّت.
`sync_platform_permissions.dart` يكتب `<queries>` بنفس الكتلة المُدارة.

**وحزمةٌ تطلب AGP لا يُحمَّل من شبكتك** — `record_android` يثبّت إصداراً بعينه بـ`buildscript`
الخاص به، و`dl.google.com` محجوبٌ ببعض الشبكات (حتى لإصداراتٍ موجودة). الحلّ بناءٌ واحد
عبر VPN فيُحفظ بـ`~/.gradle` ثم يعمل بلا شبكة. ⚠️ لا تثبيتَ لإصدارٍ أقدم من الحزمة لتفاديه.

## ٧. أوامر النظام — `system`

**اختصارُ الأيقونة مسارٌ لا أمر.** `AppShortcut(path: '/orders/new', title: …)` — والضغطةُ تصل
`lib/app.dart` فيمرّرها لـ`pushPath` **فوق الشاشة الحالية**: تمرّ بحرّاس الموجّه كأي رابطٍ عميق، والرجوعُ يعيد للتطبيق.
وإقلاعٌ باردٌ من اختصارٍ ينتظر أن يضع الموجّه شاشتَه الأولى — و`quick_actions` يسلّمه مرّتين على
أندرويد، فالـkit يُسقط التكرار. ⛔ **لا `navigatePath`**: يعيد بناء المكدّس فيُغلق القشرة، وحارسُها
يسأل «الخروج من التطبيق؟».

```dart
await getIt<AppShortcuts>().setShortcuts([
  AppShortcut(path: '/orders/new', title: LocaleKeys.newOrder.tr()),
]);
```

- **العنوان مترجَمٌ وقت الضبط** — المشغّل يعرضه كما وصله، فتبديلُ اللغة يعيد الضبط.
- **الأيقونة موردٌ أصليّ** (drawable بأندرويد · asset بـiOS) أو لا شيء — المشروع يضيفه.

**وطلبُ التقييم يقرّره المتجر لا التطبيق**: حصّةٌ لكل مستخدم ولا جوابَ إن نفدت. فـ`request()`
**بلحظة نجاح** (مهمّةٌ انتهت)، لا من زرٍّ ينتظر المستخدمُ أن يعمل كل مرّة — ذاك `openStore()`.
وعلى أندرويد عبر Google Play: جهازٌ بلا متجر يردّ `isAvailable() == false` بلا انهيار.

**وودجةُ الشاشة الرئيسية ليست هنا بقصد**: تصميمُها XML أندرويد وامتدادُ WidgetKit بـiOS، **مكتوبان
لكل مشروع** — قالبٌ يشحن ودجةً بعينها يشحن مثالاً لا قدرة.

## ٨. kit جديدة

1. `packages/kit_<name>/` بـ`pubspec.yaml` (`publish_to: none` · `kit_contracts: {path: ../kit_contracts}` · `get_it`) و`kit.json` و`analysis_options.yaml` خاصٍّ بها — وإلا ورثت ملفَّ الجذر وهو يطلب `flutter_lints` الذي لا تملكه.
2. العقد بـ`kit_contracts/lib/src/<name>/` ويُصدَّر من `kit_contracts.dart`.
3. `lib/kit_<name>.dart` يصدّر `register<Name>Kit(GetIt getIt)`.
4. اختباراتها بـ`packages/kit_<name>/test/` — `kit.dart test` يشغّلها.
5. `dart run scripts/kit.dart add <name>` · صفٌّ بـ`06_CAPABILITIES.md` · صفحةٌ بالمرآة.

وحزمةٌ خفيفة بلا كود أصلي، أو يحتاجها كل مشروع، **ليست kit** — مكانها
`core/platform/` كباقي الخدمات.
