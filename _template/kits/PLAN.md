# حِزَم الأجهزة (Device Kits) — الخطة

> **الحالة: ◐ K0 · K1 · K2 · K3 ✅ (2026-11-01) — `voice` · `audio` · `scan` · `ocr` مركّبة بالقالب. التالي K4 video.** البند #17 بـ[`../roadmap.md`](../roadmap.md).
> الهدف: الصوت والفيديو والمسح والكتابة اليدوية وأوامر النظام — **كلٌّ في حزمةٍ
> منفصلة يركّبها المشروع حين يحتاجها**، لا تبعياتٌ تُشحن مع كل مشروع.

---

## ١. لماذا حزمٌ منفصلة لا خدماتٌ بـ`core/platform/`

خدمات المنصّة اليوم (`MediaService` · `FileService` · `BiometricsService` …) خلف
علَمٍ بـ`AppFeatures` — **والعلَم يُطفئ التسجيل لا الحزمة**. `local_auth` و
`geolocator` و`image_picker` بـ`pubspec.yaml` في كل مشروع، مطفأةً أو لا:

| الكلفة | مع الحزمة مُثبَّتةً بلا استعمال |
|---|---|
| حجم التطبيق | كودها الأصلي يُبنى ويُشحن |
| مراجعة iOS | واجهاتٌ حسّاسة مرتبطة بالثنائي ← سؤالُ «لماذا تستعمل الميكروفون؟» بلا جواب |
| 16KB بأندرويد | كلُّ `.so` إضافي احتمالُ رفضٍ من Play |
| الترقية | تعارضُ تبعياتٍ لحزمةٍ لا يستعملها المشروع أصلاً |

الدفعة الجديدة أثقل بكثير (ML Kit بنماذجه · محرّك صوت · كاميرا حيّة). إضافتُها
بنفس النمط تجعل **كل مشروع** يحمل الطرفيات كلها. فالقاعدة الجديدة:

> **ما يجرّ كوداً أصلياً ثقيلاً يعيش بحزمة، ويدخل المشروعَ بأمرٍ واحد ويخرج بأمرٍ
> واحد.** وما هو قائمٌ يبقى كما هو — نقلُه refactor واسع لا يُبدأ بلا موافقة.

---

## ٢. البنية

```
app_template/
├── packages/
│   ├── kit_contracts/          ← العقود + أنواع النتائج + Fakes — Flutter بلا plugin (`Widget` وحده)
│   ├── kit_voice/              ← speech_to_text · flutter_tts
│   ├── kit_audio/              ← record · just_audio
│   ├── kit_scan/               ← mobile_scanner · ML Kit (مستند · نصّ)
│   ├── kit_video/              ← video_player
│   ├── kit_system/             ← quick_actions · home_widget · in_app_review
│   └── kit_ink/                ← ML Kit digital ink · لوحة توقيع
├── lib/
│   ├── core/di/kits.g.dart     ← سطرُ تسجيلٍ لكل kit مركَّبة — يكتبه السكربت وحده
│   ├── ui/widgets/kits/        ← الودجات: تعرف العقد وحده
│   └── modules/showcase/…/kits/← صفحةٌ لكل kit، تعمل بها أو بدونها
└── scripts/kit.dart            ← add · remove · list
```

### اتجاه التبعية — صارم

```
kit_contracts   → Flutter وحده (بلا أي plugin)
kit_<x>         → kit_contracts + حزم المنصّة
lib/ (التطبيق)  → kit_contracts دائماً
lib/core/di/kits.g.dart → kit_<x>   ← الملف الوحيد الذي يستورد kit
```

| ممنوع ❌ | لماذا |
|---|---|
| `import 'package:kit_voice/…'` بأي ملف بـ`lib/` غير `kits.g.dart` | إزالةُ الـkit تكسر البناء بعشرة أماكن بدل سطرٍ واحد |
| `import 'package:speech_to_text/…'` (أو أي حزمة منصّة) خارج `packages/kit_*` | الحزمة تعود تبعيةً للتطبيق فيضيع الفصل كلّه |
| kit تستورد `package:app_template/…` | دورةُ تبعية — الـkit لا تعرف التطبيق |
| kit تحمل نصّاً معروضاً أو لوناً أو ودجة | الواجهة والترجمة والثيم ملكُ التطبيق |
| kit تستورد kit أخرى | كلٌّ منها يُركَّب وحده |

**والفاحص**: قاعدتان جديدتان بـ`check_structure.dart` (`C18` استيراد kit خارج
`kits.g.dart` · `C19` استيراد حزمة منصّةٍ مسجّلة لـkit خارج حزمتها) — بنفس جدول
`_capabilities` القائم.

### كيف يرى التطبيقُ kit غير مركّبة

بنفس نمط `KeyValueRow` مع `ClipboardService` القائم:

```dart
// الودجة لا تعرف هل الـkit موجودة — تسأل.
if (!getIt.isRegistered<SpeechInput>()) return const SizedBox.shrink();
```

فحقلٌ يطلب الإملاء (`CustomTextField(dictation: true)`) يعمل في مشروعٍ بلا
`kit_voice` — **بلا زرّ ميكروفون، وبلا خطأ**.

### العقد — شكلٌ واحد لكل kit

```dart
// packages/kit_contracts/lib/src/voice/speech_input.dart
abstract interface class SpeechInput {
  Future<KitAvailability> availability();          // ready · noPermission · unsupported
  Stream<SpeechChunk> listen({required String localeId});
  Future<void> stop();
}

sealed class KitAvailability { … }                 // لا استثناءات تعبر الحدّ
```

- **لا استثناء يعبر الحدّ**: كل فشلٍ نوعٌ مختوم (`sealed`)، والتطبيق يحوّله
  `Failure` ← `FailureUiMapper` كما يفعل اليوم.
- **الإذن**: العقد يُرجع `noPermission`، والطلب نفسه بـ`PermissionsService`
  القائم بالتطبيق — فلا يصير للإذن مساران.
- **Fake لكل عقد** بـ`kit_contracts/testing.dart` — اختباراتُ التطبيق لا تلمس
  حزمة منصّة أبداً.

---

## ٣. `scripts/kit.dart` — مدخلٌ واحد ومخرجٌ واحد

```
dart run scripts/kit.dart list            # المتاح · المركَّب · أعلامُ الأذونات لكلٍّ
dart run scripts/kit.dart add voice       # يركّب
dart run scripts/kit.dart remove voice    # يزيل
```

`add` يكتب، **بنفس الأمر**:

1. سطرَ `kit_voice: {path: packages/kit_voice}` بـ`pubspec.yaml`
2. سطرَ التسجيل بـ`lib/core/di/kits.g.dart`
3. أعلامَ الأذونات بـ`AppFeatures` (`microphone = true`) ثم `sync_platform_permissions.dart`
4. `flutter pub get` · `gen_code.dart`

و`remove` عكسُه حرفاً بحرف، **والجولة `add` ثم `remove` تترك `git diff` فارغاً**
— وهذا اختبارُ السكربت نفسه. ⛔ ولا تعديلَ يدوياً لـ`kits.g.dart`.

وعند إنشاء مشروع: `setup_project.dart --kits voice,scan` — **والافتراضي لا شيء**.

---

## ٤. الربط بما هو قائم

| الـkit | تتّصل بـ | كيف |
|---|---|---|
| voice | `CustomTextField` | وسيطٌ `dictation` يضيف زرّ ميكروفون، يملأ الحقل حيّاً · وزرّ «اقرأ» لأي نصّ |
| audio | `AttachmentFileStore` · مرفقات `sync` | الملاحظة الصوتية مرفقٌ كالصورة: تخزينٌ خاص · checksum · رفعٌ بالمحرّك نفسه |
| scan | `MediaService.capturePrivate` · المرفقات | المستند الممسوح يدخل نفس سلسلة الصورة الخاصة؛ الـQR يمرّ بـ`resolveDeepLink` |
| video | `AttachmentPreview` · `CachedImageWidget` | مرفقُ فيديو يُفتح بالمعاينة القائمة بدل تطبيقٍ خارجي |
| system | `deep_link_resolver.dart` · `in_app_updates` | اختصارُ الأيقونة وودجة الشاشة الرئيسية رابطان عميقان لا مساران جديدان |
| ink | `CustomTextField` · المرفقات | الخطّ المعروف نصٌّ بالحقل؛ التوقيع صورةٌ خاصة كأي مرفق |
| الكل | `PermissionsService` · `AppFeatures` · `FailureUiMapper` · المرآة | لا مسارَ إذنٍ ولا أخطاءٍ ثانٍ |

---

## ٥. المراحل

> كل مرحلة تُغلق بـ: اختبارات الـkit (Fake للمنصّة) · اختبارات الودجات بالـFake ·
> صفحة مرآة حيّة · **تشغيلٌ على جهاز حقيقي** · `kit.dart add/remove` بجولةٍ نظيفة ·
> فحص 16KB (`zipalign -c -P 16 -v 4`) · **فرقُ حجم الـAPK مسجّلاً هنا** ·
> صفٌّ بـ`06_CAPABILITIES.md` + `C##` · سطرٌ بـ`CHANGELOG.md`.

| # | المرحلة | المحتوى | يعتمد على |
|---|---|---|---|
| **K0** ✅ | البنية | `packages/` · `kit_contracts` · `kit.dart` (`list`/`add`/`remove`/`test`) · `kits.g.dart` · `C18`/`C19` · `setup_project --kits` · `readme/24_DEVICE_KITS.md` + R43 · `packages/` يملكه القالب بـ`template_drift`/`template_update` · خطوةٌ بالـCI. **فصلُ «الطرفيات» بالمرآة نُقل إلى K1** — بلا kit لا شيء يُعرض | — |
| **K1** ✅ | voice | `SpeechInput` · `SpeechOutput` · `CustomTextField(dictation:)` · `DictationButton` · `SpeakButton` · `ensureKitReady` · فصلُ «الطرفيات» بالمرآة | K0 |
| **K2** ✅ | audio | `AudioRecorder` · `AudioPlayback` · `VoiceNoteRecorder` · `AudioPlayerTile` · الربط بالمرفقات (`AttachmentPreview` · `CapturedPhoto.isAudio`) | K0 |
| **K3** ✅ | scan · ocr | `CodeScanner` · `DocumentScanner` (kit `scan`) · `TextRecognizer` (kit `ocr` — انفصلت للحجم) · `DeviceScan` | K0 |
| **K4** | video | `VideoPlayback` · `AppVideoPlayer` · المعاينة | K0 |
| **K5** | system | `AppShortcuts` · `HomeWidgetBridge` · `ReviewPrompt` | K0 · deep links |
| **K6** | ink | `InkRecognizer` · `SignaturePad` | K0 |

K1…K6 مستقلّةٌ عن بعضها — **أيُّ ترتيبٍ بعد K0 يصحّ**، والمقترح أعلاه بحسب الطلب
المتوقَّع.

### خارج هذه الخطة — بقرارٍ منفصل لكلٍّ

| البند | لماذا ليس هنا |
|---|---|
| Passkeys | يمسّ `features/auth` و`backend_template` (WebAuthn) — عقد wire، لا kit جهاز |
| `app_intents` (Siri · AppFunctions) | أندرويد 16+ و iOS 17+ والحزمة غير مستقرّة الإصدارات |
| ذكاءٌ على الجهاز (`flutter_gemma`) | موديولٌ بعقد «مزوّد» واحد سحابي/محلي — تصميمٌ مستقلّ |
| Liquid Glass (iOS 26) | لا رسمٌ له بفلاتر بعد، والحزم المتاحة dev |
| نقلُ `MediaService`/`FileService`… إلى kits | refactor واسع — يُفتح بموافقةٍ صريحة بعد أن تثبت K0…K2 |

---

## ٦. القرارات — محسومة (2026-11-01)

| # | القرار | المحسوم |
|---|---|---|
| D1 | مكان الحزم | `packages/` بمستودع القالب، تبعيةُ `path` |
| D2 | المركَّب بمستودع القالب نفسه | **كلُّها** — المرآة والاختبارات والتجربة على الجهاز تعمل عليها، و`setup_project` يزيل غير المختار |
| D3 | الافتراضي بمشروعٍ جديد | **لا kit** — يُختار بـ`--kits` أو بـ`kit.dart add` لاحقاً |
| D4 | pub workspace أم `path` | **`path` وحده** — لا يتغيّر `pubspec.lock` القائم |
| D5 | أول kit بعد K0 | **K1 voice** |

---

## ٧. سجلّ المراحل

### K0 — البنية ✅ (2026-11-01)

- **جولةُ `add` ثم `remove` جُرِّبت بـkit تجريبية حقيقية** (`kit_probe`، حُذفت بعدها):
  `pubspec.yaml` · `kits.g.dart` · علَمُ `microphone` · `AndroidManifest.xml` ·
  `Info.plist` — `git diff` فارغ بعدها.
- **وكشفت عطلاً سابقاً بـ`sync_platform_permissions.dart`**: كان يعيد كتابة علامتي
  `Info.plist` بأربع مسافات بدل tabs، فكلُّ تشغيلٍ يترك فرقاً بلا تغيير إذن. أُصلح:
  الكتلة تأخذ إزاحة العلامة بالملف.
- `C18`/`C19` جُرِّبا بمخالفاتٍ متعمَّدة (استيرادُ kit من `lib/` · kit تستورد التطبيق ·
  حزمةُ منصّةٍ خارج حزمتها) — الثلاث تُفشل.
- ⚠️ **حزمةُ منصّةٍ يعلنها `kit.json` ويستعملها التطبيق أصلاً تُفشل `C19` بكل
  موضع** (جُرِّب بـ`uuid`) — فاختيارُ حزم الـkit يمرّ بفحص `lib/` أولاً.

### K1 — voice ✅ (2026-11-01)

- `speech_to_text` 7.4.0 · `flutter_tts` 4.2.5. الإذن بالتطبيق: `availability()` تُرجع
  `KitNeedsPermission([microphone, speechRecognition])` قبل `initialize` — لأن
  `initialize` يطلب الإذن بنفسه لو سُبق.
- **العقد تغيّر**: `KitNeedsPermission` صار يحمل قائمة — iOS يطلب الميكروفون
  ومُعرِّف الكلام معاً.
- **أعلامٌ جديدة بالتطبيق**: `speechRecognition` (`AppPermission` + `Permission.speech`
  + `NSSpeechRecognitionUsageDescription`) و`textToSpeech` (بلا إذن). و**`<queries>`
  صار يُكتب بـ`sync_platform_permissions`** — الحزمتان تطلبانه بأندرويد 11+ ولا
  تعلنانه بملفّهما.
- `flutter_tts` يرفع `minSdk` إلى 24 — يطابق `flutter.minSdkVersion` اليوم.
- **حجم APK debug: +99KB** (201,239,247 ⇐ 201,338,551). نسخة release لم تُقَس بعد.
- ✅ **جُرِّب على جهاز أندرويد (2026-11-01)**: طلبُ الإذن نافذةٌ واحدة من `PermissionsService`
  · الإملاءُ يكتب بالحقل والأيقونة تتلوّن أثناء الاستماع · القراءةُ بالعربية والإنجليزية
  تبدأ وتكتمل، وزرُّها يصير «إيقاف» أثناءها.
- **وكشفت التجربةُ عطلاً بالمكتبة لا بالـkit**: `CustomTextField` كان ينادي `onChanged`
  و`onFieldSubmitted` **بلا وسيط** وهما `Function` — فكلُّ دالّةٍ بوسيط ترمي داخل معالج
  الحقل، ويتغيّر النصّ على الشاشة ولا يسمع به أحد (ملعبُ `TextKnob` بالمرآة كلُّه كان
  معطّلاً بصمت). صار ينادي كلَّ شكلٍ بما يأخذه، وعليه اختبار.

### K2 — audio ✅ (2026-11-01)

- `record` 6.2.1 (`record_android` 1.5.2) · `just_audio` 0.10.6. `record` 7 يطلب Flutter 3.44.
- **`record_android` يثبّت AGP `8.12.3` بـ`buildscript` الخاص به**، و`dl.google.com` يردّ 404
  من شبكة التطوير لكل إصدار — حتى المحفوظة. بُني مرّةً عبر VPN فحُفظ. موثَّقٌ بـ`24_DEVICE_KITS.md`.
- **جُرِّب على الجهاز**: التسجيلُ يعدّ الوقت ومؤشّرُ المستوى يتحرّك · الإيقافُ يُخرج ملفّاً
  يُشغَّل بالبلاطة وبورقة المرفق.
- **وكشفت التجربة ثلاثة**: ① التسجيلُ الحديث قد لا يذكر طوله بترويسته (ExoPlayer يعرفه
  أثناء التشغيل) — فكان `open()` يردّ طولاً صفراً وكاد يُقرأ «لا يُشغَّل»؛ صار العقد يميّز
  «طولٌ مجهول» (`Duration.zero`) من «لا يُشغَّل» (`null`). ② «الموضع / الطول» انقلب
  بالاتجاه العربي فقرئ «3 من 0». ③ نصّ ترجمةٍ بـ`%s` لا `{}` — easy_localization لا يعرف `%s`.
- `showKitReadiness` استُخرج لكل الودجات بدل نسخةٍ بكل واحدة، ومفتاح «الإعدادات» صار
  `kitOpenSettings`.
- **حجم APK debug: +337KB** (201,338,551 ⇐ 201,675,928).

### K3 — scan · ocr ✅ (2026-11-01)

- `mobile_scanner` 7.4.3 · `google_mlkit_document_scanner` 0.5.0 · `google_mlkit_text_recognition` 0.16.0.
- **`kit_contracts` صار Flutter** (بلا plugin): سطحُ الكاميرا `Widget` يرسمه النظام والتطبيق يضعه.
- **`mobile_scanner` لا يملك فحص إذنٍ بلا طلب** — فـ`kit_scan` يقرأ حالة الإذن بـ`permission_handler`
  (نفسُ إصدار التطبيق) ولا يطلب.
- **نسخة release فشلت بـR8** (ML Kit يشير لأصناف خطوطٍ أخرى لا يشحنها) و debug سليم —
  فصار لـ`kit.json` حقلُ `proguard`، و`kit.dart` يولّد `android/app/proguard-kits.pro`.
- **الحجم قسَمَ الـkit**: release arm64 — بلا kit 30.3MB · voice+audio +0.4 · scan +6.5 ·
  **ocr +12MB** ⇐ `ocr` kit وحدها بقرار المستخدم. والنماذج **مضمَّنة** لا من Play services:
  تعمل على جهازٍ بلا خدمات Google وعلى شبكةٍ تحجبها.
- **وكشفت الاختبارات عطلاً بالمكتبة**: `AppBottomSheet(isScrollable: false)` لم يكن يعطي المحتوى
  سقفاً، فمربّعُ الكاميرا يفيض على شاشةٍ قصيرة. صار `Flexible(loose)` كالقابل للتمرير.
- **على الجهاز**: مسحُ الرمز ✅ (قرأ DataMatrix وأغلق الورقة). ⬜ **ماسح المستندات** — Play services
  فشل بتنزيل وحدته («حدث خطأ ما»)، **ومع VPN على الجهاز أيضاً** (HONOR · GMS 26.25 · متجر Play
  موجود) — الأرجح خدماتٌ غير معتمدة تُرفض وحداتُها الاختيارية. والتطبيق عاد بلا انهيار. يُعاد على جهازٍ آخر. ⬜ **قراءة النص**
  على الجهاز تنتظر صفحةً من الماسح. ⬜ **ربطُ رمز QR بـ`resolveDeepLink`** — `ui/` لا تستورد
  `routes/`؛ مكانه شاشةُ المشروع لا المكتبة.
