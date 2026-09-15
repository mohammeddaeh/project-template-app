# 00 — ابدأ هنا

> **الملف الوحيد الذي تقرأه أولاً.** كل ما تحتاجه بأسبوعك الأول موصول منه.
> **يُحدَّث** عند تغيير خطوات الإعداد أو ترتيب المراحل.

---

## ما هذا المستودع

قالب Flutter **بلا feature تطبيقية واحدة**. ما يصلك جاهزاً:

| جاهز ويعمل | مطفأ ينتظرك |
|---|---|
| دورة حساب كاملة (`auth/`) — دخول · تسجيل · تحقّق بريد · استعادة وتغيير كلمة مرور · بروفايل | إحدى عشر موديولاً بـ`lib/modules/` — كلٌّ بعلَم واحد بـ`AppFeatures` |
| شبكة: Dio + Retrofit + سلسلة interceptors + مسار خطأ موحَّد | مزامنة دون اتصال · صلاحيات · استيراد/تصدير · أجهزة متعدّدة |
| ثيم فاتح/داكن · عربي/إنجليزي · خطوط قابلة للتبديل | تحليلات · تقارير انهيار · إشعارات · تحديثات · إعدادات بعيدة |
| DI (`injectable` + `get_it`) · تنقّل (`auto_route`) · حالة (`bloc`) | |
| 287 اختباراً تحرس البنية التحتية وعقد الـwire | |

**ما لا يصلك**: شريحة CRUD مرجعية، ولا شاشات demo. حُذفت بقصد (2026-09-08) —
[التفصيل](90_archive/README.md).

---

## الرود ماب — خمس مراحل

كل مرحلة لها **معيار «تمّت»** قابل للتحقّق. لا تنتقل قبل أن يتحقّق.

```
م1 يعمل عندك  →  م2 صار مشروعك  →  م3 تفهمه  →  م4 أول feature  →  م5 إصدار
   ساعة           ساعتان            يوم           ٢-٣ أيام          نصف يوم
```

---

### المرحلة 1 — يعمل على جهازك  ⏱ ~ساعة

```bash
flutter pub get
dart run scripts/sync_flavors.dart
```

السكربت يُنشئ `.env.dev.json` و`.env.staging.json` و`.env.prod.json` من
`.env.example.json` **ويطبع أسماءها**. هذه الملفات **لا تصل مع الاستنساخ** —
مُتجاهَلة في git لأنها تحمل روابط API حقيقية.

افتح `.env.dev.json` وضع `BASE_URL` الحقيقي، ثم:

```bash
dart run scripts/gen_code.dart
flutter run --flavor dev --dart-define-from-file=.env.dev.json
```

> ⚠️ **`flutter run` المجرَّد لا يقرأ ملف البيئة** فيصل `Env.baseUrl` فارغاً وكل طلب
> يفشل بلا سبب ظاهر. استعمل `--dart-define-from-file` دائماً، أو شغّل من VSCode
> بإعدادات `launch.json` التي ولّدها السكربت.

**✅ تمّت حين:** التطبيق يفتح على شاشة الدخول، وتبديل اللغة والثيم يعمل.

📖 التفصيل والمزالق: [`01_SETUP.md`](01_SETUP.md)

---

### المرحلة 2 — صار مشروعك أنت  ⏱ ~ساعتان

القالب يصل باسم `app_template` وهوية `com.example.app_template`. **غيّرها قبل أي كود.**

| ما تغيّره | أين |
|---|---|
| اسم التطبيق الظاهر | `flavor_settings.json` → `displayName` لكل flavor |
| مُعرّف التطبيق | `flavor_settings.json` → `applicationId` + `android/app/build.gradle.kts` |
| الأيقونات | `assets/app_icons/icon_{dev,staging,prod}.png` — مربّعة 1024×1024 |
| ألوان الثيم | `lib/ui/theme/app_palette.dart` ثم `app_colors.dart` |
| الخطوط | ضع الملفات بـ`assets/fonts/` ثم `dart run scripts/sync_fonts.dart` |

```bash
dart run scripts/sync_flavors.dart   # يُعيد توليد الأيقونات والأسماء و launch.json
flutter clean && flutter pub get
cd ios && pod install                 # على macOS فقط
```

> ⚠️ **واسمُ الـpackage `app_template` يُبدَّل مرّةً واحدة — أو لا يُبدَّل أبداً.**
> كلُّ `import` بالمستودع يحمله (`package:app_template/…`)، وهو باسمٍ واحد
> بـ`pubspec.yaml` وبـ`CLAUDE.md`. فالتبديلُ **استبدالٌ نصّيٌّ شامل** يُشغَّل بأوّل
> يوم ويُتبَع بـ`dart analyze lib test`، لا تعديلٌ تدريجيّ: مستودعٌ نصفُه
> `app_template` ونصفُه اسمُك يُصرَّف ويعمل — ثم يكسر كلَّ ملفٍّ يُنسخ بينهما.
>
> ```bash
> # بعد تبديل `name:` بـpubspec.yaml
> grep -rl 'package:app_template/' lib test | xargs sed -i 's|package:app_template/|package:your_app/|g'
> ```

**✅ تمّت حين:** التطبيق يظهر باسمك وأيقونتك على الجهاز، بألوانك.

---

### المرحلة 3 — تفهم ما تعمل داخله  ⏱ ~يوم

اقرأ **بهذا الترتيب**، ولا تقفز:

| # | الملف | لماذا الآن |
|---|---|---|
| 1 | [`03_RULES.md`](03_RULES.md) | القواعد الصارمة — كل واحدة وُلدت من عطل حقيقي. أهمّ ملف بالمستودع |
| 2 | [`10_ARCHITECTURE.md`](10_ARCHITECTURE.md) | خريطة `lib/` وحدود الطبقات |
| 3 | [`11_CORE.md`](11_CORE.md) | `core/` بطبقاته الأربع و DI |
| 4 | [`12_REST_API.md`](12_REST_API.md) | رحلة الطلب: Page → Cubit → UseCase → Repository → Dio |
| 5 | [`13_ERROR_FLOW.md`](13_ERROR_FLOW.md) | رحلة الخطأ عبر النصفين — وهي **ليست** انعكاس الأولى |
| 6 | [`22_RESPONSIVE.md`](22_RESPONSIVE.md) | **قبل أن ترسم أي شيء** — كل رقمِ مقاسٍ يمرّ بـ`context.screen`، وجسدُ كل شاشة داخل `ResponsiveContentBox`. الشاشات القائمة كلُّها مبنيّةٌ عليها |

ثم افتح [`02_CHEATSHEET.md`](02_CHEATSHEET.md) **وأبقه مفتوحاً** — لا تحفظه.

**✅ تمّت حين:** تجيب من رأسك: أين يوضع URL جديد؟ من يحوّل `DioException` إلى
رسالة يقرؤها المستخدم؟ لماذا `SafeCubit` لا `Cubit`؟ **وبأي شيء تكتب فراغاً
رأسياً بين عنصرَين؟**

---

### المرحلة 4 — أول feature  ⏱ ~٢-٣ أيام

**لا تنسخ من مشروع آخر.** اتبع [`04_FIRST_FEATURE.md`](04_FIRST_FEATURE.md) — درس
كامل يبني شريحة CRUD مُصفَّحة من الصفر: من `ApiUrls` إلى شاشة تعمل، بـ16 خطوة
مرقّمة، وبمكان كل ملف.

والمرجع الحيّ الذي تنسخ **بنيته** حرفياً: `lib/features/auth/login/` — 12 ملفاً
بالطبقات الثلاث كاملة.

> ⚠️ **قبل أول طلب شبكة**: افتح [`03_RULES.md`](03_RULES.md) §R01 (عقد الـwire).
> خطأ حرف واحد بمفتاح JSON **لا يراه المصرِّف ولا التحليل ولا الاختبارات**، ويصل
> المستخدمَ «حدث خطأ» بينما السيرفر يسجّل `200 OK`. وقع فعلاً بهذا القالب ومنع
> الدخول كلياً.

> ⚠️ **وقبل أول شاشة**: [`22_RESPONSIVE.md`](22_RESPONSIVE.md) §٣‑ب — قالبُ
> شاشةٍ وودجةٍ جاهز، وجدولٌ يقول لكل نوعِ رقمٍ بمَ يُكتب. الشاشات القائمة كلُّها
> مبنيّةٌ عليه، فشاشةٌ تُبنى بأرقامٍ ثابتة تخرج مختلفةً عن بقيّة الواجهة وتُكسر
> على اللوح — وثمّة **فاحصٌ آلي** يردّ نصفَ ذلك (R37 · F37).

**✅ تمّت حين:** الشريحة تعمل على سيرفر حقيقي، و`dart analyze lib test` نظيف،
و`flutter test` أخضر، و`check_structure` بلا مخالفة جديدة، **وجُرِّبت على هاتف
ولوحٍ بالاتجاهين**.

> ⚠️ **ومسارُ شريحتك يُضاف إلى `test/router_contract_test.dart`.** الاختبار يقرأ
> الراوتر ويشهد على أن كل `@RoutePage` له مدخلٌ مسمّى — فشريحةٌ تُبنى بلا صفٍّ فيه
> تمرّ خضراءَ اليوم وتسقط يوم يُعاد توليد الراوتر بعد تبديل اسم.

---

### المرحلة 5 — أول إصدار  ⏱ ~نصف يوم

```bash
dart run scripts/build_apk.dart --flavor staging --mode release --bump minor
```

يرفع الإصدار، ويُشغّل codegen، ويبني، ويسمّي الـAPK باسمك ونسختك.

**قبل أي بناء إنتاجي، تحقّق:**

- [x] ~~`AppFeatures.debugSkipLogin == false`~~ — **مقفولٌ آلياً بـ`kDebugMode` (2026-08-30)**: بدّل `_skipLoginRequested` كما تشاء، فـrelease يُطفئه حتماً
- [ ] `AppFeatures.verboseNetworkLog == false`
- [ ] `.env.prod.json` يحمل الرابط الحقيقي لا قيمة المثال
- [ ] `dart run scripts/sync_platform_permissions.dart` شُغّل بعد آخر تغيير بالأعلام

📖 الخيارات كاملةً: [`40_SCRIPTS.md`](40_SCRIPTS.md) §2

**✅ تمّت حين:** APK مُوقَّع يعمل على جهاز حقيقي مقابل بيئة staging.

---

## بعد المرحلة 5 — تشغيل موديول اختياري

كل موديول بـ`lib/modules/` يُشعَل بعلَم واحد بـ`lib/core/platform/features/app_features.dart`،
وله `SETUP.md` بجواره.

| الموديول | العلَم | الوثيقة |
|---|---|---|
| الصلاحيات والأدوار | `accessControl` | [`31_MODULE_PERMISSIONS.md`](31_MODULE_PERMISSIONS.md) |
| استيراد/تصدير | `dataTransfer` | [`32_MODULE_DATA_TRANSFER.md`](32_MODULE_DATA_TRANSFER.md) |
| مزامنة دون اتصال | `offlineSync` ⛔ **مطفأ** | [`lib/modules/sync/SETUP.md`](../lib/modules/sync/SETUP.md) · [`17_SERVED_CONTRACT.md`](17_SERVED_CONTRACT.md) |
| أجهزة وجلسات | `multiDevice` | `lib/modules/multi_device/SETUP.md` |
| قفل جلسة محلّي (رقم/بصمة) | `sessionGuard` | `lib/modules/session_guard/SETUP.md` |
| مركز إشعارات داخل التطبيق | `notificationCenter` (يحتاج `pushNotifications` أيضاً) | `lib/modules/notification_center/SETUP.md` |
| تحليلات · انهيارات · إشعارات · إعدادات بعيدة | راجع `AppFeatures` | `lib/modules/<name>/SETUP.md` |

> ⚠️ **علَمٌ مُشعَل لا يكفي.** الموديول قد يحتاج نصفاً بالباك وتسجيلاً بالـDI.
> وأخطر ما فيه أنه يفشل **صامتاً**: `offlineSync = true` بلا محوّل feature يترك
> التطبيق يعمل بالكامل على الشبكة، بلا انهيار ولا تحذير ولا اختبار أحمر.

---

## خريطة التوثيق كاملةً

[`README.md`](README.md) — الفهرس، وفيه سطر لكل ملف ومتى يُقرأ.
