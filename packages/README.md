# `packages/` — حِزَم الأجهزة (kits)

كل ما يجرّ كوداً أصلياً ثقيلاً — صوت · فيديو · كاميرا حيّة · تعرّف — يعيش هنا
حزمةً منفصلة، **ولا يدخل التطبيق إلا حين يُركَّب**. والتطبيق لا يعرف إلا العقد
بـ`kit_contracts/`. التفصيل كاملاً: [`readme/modules/24_DEVICE_KITS.md`](../readme/modules/24_DEVICE_KITS.md).

```bash
dart run scripts/kit.dart list            # ما المركَّب
dart run scripts/kit.dart add scan        # تبعية · تسجيل · أذونات · قواعد R8 — بأمرٍ واحد
dart run scripts/kit.dart remove scan     # والعكس، بلا فرقٍ بـgit
```

| المجلد | يوفّر بالتطبيق | يضيف للحجم |
|---|---|---|
| `kit_contracts/` | العقود وحدها — **الحزمة الوحيدة التي يستوردها `lib/`** | — |
| `kit_voice/` | إملاءٌ بالصوت `CustomTextField(dictation:)` · قراءةٌ بصوت `SpeakButton` | مع `audio`: +0.4MB |
| `kit_audio/` | تسجيلُ صوت `VoiceNoteRecorder` · تشغيلُه `AudioPlayerTile` | (أعلاه) |
| `kit_scan/` | مسحُ QR/باركود `DeviceScan.code` | +6.5MB |
| `kit_ocr/` | نصٌّ من صورة `DeviceScan.text` — لاتينيٌّ وحده | +12MB |
| `kit_video/` | تشغيلُ فيديو `AppVideoPlayer` | لم يُقَس |
| `kit_system/` | اختصاراتُ أيقونة التطبيق `AppShortcuts` · ورقةُ تقييم المتجر `AppReview` | لم يُقَس |
| `kit_ink/` | كتابةٌ يدوية ⇐ نصّ `HandwritingInput` | النموذجُ يُنزَّل عند أوّل استعمال |

**مستودعُ القالب يحمل السبعة مركّبةً** لأن جولة المطوّر تعرضها. ومشروعٌ جديد يختار
ما يبقى: `setup_project.dart --kits voice,scan` (أو `new_project.ps1 -Kits …`)،
**والافتراضي لا شيء**. والمجلّدات تبقى هنا فتُركَّب لاحقاً بأمرٍ واحد.

⛔ **لا تستورد `kit_<name>` من `lib/`** — `check_structure` يُفشله (`C18`)، ولا حزمةَ
منصّتها (`C19`). والتسجيلُ بـ`lib/core/di/kits.g.dart` المولَّد وحده.
