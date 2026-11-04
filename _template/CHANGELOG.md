# سجلّ إصدارات القالب

> رقم الإصدار بـ`TEMPLATE_VERSION` بجذر المستودع (يصل المشاريع)، وكل إصدارٍ وسمُ
> git `v<الرقم>` على commitه. والمشروع يحفظ الاثنين بـ`.template_manifest.json`
> (`templateRelease` للبشر · `templateVersion` الـcommit الدقيق لـ`template_drift`
> و`template_update`).
>
> **متى يُرفع الرقم:** `x.y.Z` إصلاحٌ لا يغيّر واجهة · `x.Y.0` قدرةٌ أو أداةٌ جديدة ·
> `X.0.0` تغييرٌ يكسر مشروعاً قائماً (اسم واجهةٍ عامة · مسار ملفٍّ مملوك · حذف).
> وكل بندٍ يُضاف أولاً تحت «غير مُصدَر».

## غير مُصدَر

- ⚠️ **الألوان من `palettes/*.json`**: `lib/ui/theme/app_palette.dart` حُذف، و`app_palette.g.dart` يولَّد من
  `palettes/standard.json` بـ`gen_code.dart` (خطوة `sync_palettes.dart` بعد `build_runner`) · `AppPalette` صار صنفَ
  نسخ: `AppColors.light(palette)`/`dark(palette)` بدل `AppPalette.x` الثابت · F04 يمنع `AppPalettes.` خارج `app_colors.dart`.
- **ثيماتٌ يختارها المستخدم**: كلُّ ملفٍّ بـ`palettes/` ثيمٌ — `AppThemePresets.all` محورٌ مستقلّ عن الوضع، يُحفظ
  بـ`PersistenceKeys.selectedThemePresetKey`، ومنتقيه بالإعدادات (`SettingsThemePresetSection`) لا يظهر ما دام الثيم
  واحداً · كلُّ بالتٍ بمفاتيح `standard.json` نفسها، والمخالفةُ تُفشل التوليد · `test/color_contrast_test.dart` يمرّ
  على كل ثيم · `test/theme_preset_test.dart` · `test/palette_sync_test.dart`. ألوانٌ فقط — الزوايا والحركة ثابتة.
- ⚠️ **سبعُ هوياتٍ مشحونة**: `standard` · `dawn` · `emerald` · `graphite` · `lilac` · `ocean` · `sand` — كلٌّ بأرضيةٍ فاتحة
  وداكنة مصبوغة (الرماديّاتُ كلُّها بصبغتها وبإضاءة `standard`) وأساسيٍّ وبارز، فمنتقي «ألوان التطبيق»
  ظاهرٌ بالإعدادات — بطاقاتٌ أفقية ترسم التطبيقَ مصغَّراً بألوان كل ثيم (`test/settings_theme_preset_section_test.dart`). كلٌّ يمرّ بفحص التباين بالوضعين.
- **شاشاتُ القالب بحدّ عرضٍ على اللوح**: الدخول والتسجيل وكلمة المرور وتأكيد البريد بـ`ContentWidth.form` (٤٨٠)، والملف
  الشخصي والإعدادات بـ`ContentWidth.content` (٨٤٠) — والهاتفُ بلا تغيير · `test/responsive_template_screens_test.dart`.
- ⚠️ **`textMuted` نصٌّ يُقرأ**: بالفاتح كان `gray500` — ٢٫١–٢٫٦:١ على الصفحة والبطاقة بكل هوية، وهو لونُ ١٥٨ موضعاً
  (تعليقات · تلميحات · أوقات). صار `gray600`، و`gray600` بكل بالتٍ مصبوغة أُغمق بقدر ما يبلغ ٤٫٥:١ ·
  `test/color_contrast_test.dart` يفحصه على `bgPage` · `bgCard` · `bgElevated` لكل هوية بالوضعين.
- **`GuideOverlay` لا يُرسم خطأً**: كان يقرأ `MediaQuery` بـ`initState` فيرمي عند كل فتح — صار
  بـ`didChangeDependencies` · `test/guide_overlay_test.dart`.
- **مقبضُ الورقة السفلية يُرى**: `dividerSubtle` على سطح الورقة ١٫٠٨:١، فصار `outlineVariant`
  (`AppBottomSheet` · `BaseBottomSheet`) · فحصُه بـ`test/color_contrast_test.dart`.
- **لافتاتُ الإعدادات تُقرأ**: الخطوط وألوان التطبيق ورقم الإصدار بـ`textSecondary` لا `textMuted`.
- **فحصُ معاني أدوات الجولة يرى النوعَ المتداخل** (`ChoiceKnob<Map<String, String>?>`)، فوجد
  `showcaseKnobMessageArgs` ناقصاً — أُضيف.
- **مثالُ `AppBentoGrid` بالجولة بخلايا `cellAspectRatio: 1.5`**، و§48 يحذّر من ارتفاع الخليّة الثابت.
- ⚠️ **التبويبُ غير النشط يُقرأ**: `textMuted` على سطح الشريط بالفاتح **٢٫٧٣:١** (دون ٤٫٥)، فصار
  `textSecondary` (٨٫٣٣:١) بـ`AppBottomBar` و`AppTabBar` و`tabBarTheme` و`bottomNavigationBarTheme` ·
  `test/color_contrast_test.dart` يفحص الزوج على كل سطحٍ يرسمه شريط، ويُفشل `textMuted` بملفَّي الشريطين.
- **`ShellAppearance(translucent: true)`** · `AppBottomBar(translucent:)` · `AppColors.bgTranslucent` (٨٢٪):
  شريطٌ سفليّ نافذ بلا تمويه، والمحتوى يمرّ تحته — مطفأ افتراضاً، والاستثناءُ الوحيد لـR15
  (`test/bottom_content_inset_test.dart`) · تباينُه بـ`test/color_contrast_test.dart` · بجولة الـshowcase.
- **`AppBottomSheet.show(detents: […])`**: ورقةٌ تقف بارتفاعات توقّف (`DraggableScrollableSheet` بـ`snap`)،
  وإفلاتُها تحت الأولى يُغلقها · بجولة الـshowcase · `test/app_bottom_sheet_detents_test.dart`.
- **`AppBentoGrid`** · `BentoTile`: شبكةُ بطاقاتٍ بأحجامٍ مختلفة تتراصّ بلا فراغ، أعمدتها من عرضها
  هي (خليّةٌ ≥ ١٥٠) وتتبع اتجاه القراءة · بجولة الـshowcase · `test/app_bento_grid_test.dart`.
- **`AppLargeTitleView`**: عنوانٌ كبير ينكمش عند التمرير (`SliverAppBar.large` + `NestedScrollView`) جسدَ
  `Scaffold` · `PaginationBuilder` يكشف `NestedScrollView` فوقه فيمرّر بمتحكّمه الأساسيّ ويطلب الصفحة التالية
  بـ`PaginationCubit.onScrolled` الجديد · بجولة الـshowcase · `test/app_large_title_view_test.dart`.
- **حركةٌ بنابض**: `AppMotion.springSnappy` · `springGentle` + `controller.springTo(target, spring)` — و`PressableScale`
  يصغر ويرجع بهما بدل `AnimatedScale` بمدّة.
- **اهتزازُ تغيّر الاختيار**: `selectionHaptic()` (`ui/feedback/selection_haptic.dart`) فوق `HapticService` القائم ·
  `ChipRow` · `AppRadioGroup` · `AppBottomBar` · `ThemeSwitcher` · منتقي الثيم يهتزّون حين تتغيّر القيمة وحدها ·
  `test/selection_haptic_test.dart`.
- **تبديلُ الثيم والوضع بدائرةٍ تتّسع من الزرّ**: `ThemeReveal` (`ui/theme/theme_reveal.dart`) مركَّبٌ مرّةً
  بـ`MaterialApp.builder` · `ThemeSwitcher` ومنتقي الثيم يناديان `ThemeReveal.run` · فوريٌّ مع «تقليل الحركة» ·
  `themeAnimationDuration: Duration.zero` بـ`app.dart` كي لا يظهر تدرّجٌ لونيّ داخل الدائرة · `test/theme_reveal_test.dart`.

## 3.0.0 — 2026-11-03

> **ترقيةُ مشروعٍ من 2.1.0**: [`readme/scripts/41_UPGRADING.md`](../readme/scripts/41_UPGRADING.md) §«2.1.0 ⇐ 3.0.0».

- ⚠️ **لا لاحقة `Wdg`**: `PaginationBuilderWdg` ⇐ `PaginationBuilder` (والملف `pagination_builder.dart`) ·
  `ListItemAppearWdg` ⇐ `ListItemEntrance` · وسيطا `itemWdg`/`allItemWdg` ⇐ `itemBuilder`/`allItemsBuilder`. بلا
  أسماءٍ قديمة.
- **R05 تصف الكود**: `@freezed` إلزاميّ بـ`features/`، وحالاتُ الموديولات و`ui/state/sync/` `sealed` مكتوبةٌ
  باليد بسببها، و`RefreshState` بلا مساواة عمداً.
- **شريط «لا اتصال» لا يظهر لحظةَ الإقلاع على جهازٍ متّصل**: `OfflineUxCubit` كان يقرأ حالة المراقب
  الأولى (`unknown`) انقطاعاً؛ صار يتبع `NetworkStateMonitor` المحقون ويتجاهل `unknown` ·
  `SyncGate` يسأل `Connectivity` المحقون مرّةً بدل `ConnectivityService` الثابت · `test/sync/offline_ux_cubit_test.dart`.
- **`intl` بلا `dependency_overrides`**: التجاوز إلى `^0.19.0` كان يناقض `^0.20.2` بلا سبب؛ الحلّ يقع على 0.20.2.

## 2.1.0 — 2026-11-03

- **`template_update` ينقل مفاتيح الترجمة** مفتاحاً مفتاحاً (`scripts/src/translation_merge.dart` ·
  `test/translation_merge_test.dart`): يضيف الجديد ويحدّث ما لم يلمسه المشروع، والتعارضُ بـ`.template_update/`.

## 2.0.0 — 2026-11-03

> **ترقيةُ مشروعٍ من 1.0.0**: [`readme/scripts/41_UPGRADING.md`](../readme/scripts/41_UPGRADING.md) §«1.0.0 ⇐ 2.0.0» —
> كلُّ بندٍ ⚠️ أدناه صفٌّ هناك، بأمر بحثٍ وبديل.

- **دليلُ الترقية** `readme/scripts/41_UPGRADING.md`: الطريق لأي إصدار، وما يكسر البناء، وما يغيّر
  السلوك بصمت، وملفاتُ المشروع التي لا يلمسها `template_update`.
- **إصلاحاتٌ صغيرة من المراجعة**: فاصلٌ عربيّ كان يظهر بالإنجليزية (`listSeparator`) · حوارُ التحديث يُغلق بسياقه،
  و`InAppUpdatesConfig.iosAppId` · رمزُ FCM يُحذف عند الخروج ويُعلَن بعد الدخول التالي · `NotificationCenterSection`
  بالإعدادات · `multi_device` بلا `isPrimary` الميّت (⚠️ `PersistenceKeys.deviceIsPrimary` و`saveSession(isPrimary:)` حُذفا) ·
  سكربتاتٌ برسالةٍ بدل stack trace (`scripts/src/cli.dart` · `runCli`) · `gen_permission_keys --from` بلا وضعٍ يُرفض.
- **المرآة تغطّي كل ودجةٍ عامّة**، لا المكتبة وحدها: `lib/ui/` كلّه والموديولات. خمس صفحاتٍ جديدة بفصل
  «الموديولات» (الأجهزة · القفل · مركز الإشعارات · التحديث الإجباري · التوكن)، وصفحتا الصلاحيات والاستيراد
  تعرضان ودجاتهما الحقيقية (`PermissionMatrix` · `ImportGrid` · `ImportErrorTable` …). `showcase_test` يُفشل أيَّ
  ودجةٍ عامّة بلا مكان (R42). ⚠️ حذفُ موديولٍ يعني حذفَ صفحته من الجولة وسطرِها بالكتالوج.
- ⚠️ **`readme/` بمجلدات**: `start/` (00 · 01 · 02 · 04) · `rules/` (03 · 05 · 06) · `architecture/` (10 · 11 · 12 · 13 ·
  14 · 17 · 23) · `ui/` (20 · 21 · 22 · `widgets/`) · `modules/` (24 · 30–33) · `scripts/` (40). الأرقامُ والأسماءُ
  كما هي، والروابطُ كلّها أُعيد حسابها. مشروعٌ يحدّث بـ`template_update` يرى الملفات محذوفةً من الجذر ومضافةً
  بمجلداتها؛ وروابطُه الخاصة إلى `readme/NN_*.md` يكشفها `check_docs`.
- **خريطةٌ للقادم الجديد**: `README.md` بجذر المستودع (كان نصَّ Flutter الافتراضي) · `readme/modules/30_MODULES.md`
  جدولٌ واحد للموديولات الثلاثة عشر (علَم · افتراض · ما يحتاجه خارج التطبيق · الوثيقة) يحلّ محلّ جدولَي
  `10_ARCHITECTURE` و`00_START_HERE` · `packages/README.md` · سكربتات `40_SCRIPTS.md` مجمّعةٌ بمتى تُحتاج.
  ⚠️ **مداخلُ الموديولات كلّها `<name>_plugin.dart` / `<Name>Plugin`**: `AnalyticsModule` و`CrashReportingModule`
  و`RemoteConfigModule` و`PushNotificationsModule` و`InAppUpdatesModule` صارت `…Plugin` — والأسماء القديمة
  `typedef` مُهمَلة، لكنّ مسارات الاستيراد تبدّلت (`modules_bootstrap.dart` بالمشروع يُحدَّث).
  `scaffold_module` يكتب صفَّ الجدول الواحد وعلامةً ثابتة بـ`ModulesBootstrap` واستثناءَ جردٍ بـ`TODO`.
- **تنظيف**: حُذف `TextThemeEx` (أحجام خطوطٍ مكتوبةٌ باليد، و`baseTextStyle` مكرّر) · `showLoader` ·
  `rSpace`/`rSize` · `dismissKeyboard` · `GlobalKeyExtensions` · `ThemeEx.dividerColor`/`scaffoldBackgroundColor`
  · `AccountContextRefresher`. ⚠️ مشروعٌ يستعمل أيّاً منها يستبدله بـ`context.textTheme` · `context.screen` ·
  `unfocus()`. `NavigationState`/`SettingsState` صارتا `@freezed` (التبويبات داخل الحالة). أربعة `catch`
  صامتة صارت تسجّل. `pubspec`: حُذف `mockito` و`bloc_test` و`http_mock_adapter` و`cupertino_icons`، و`freezed`
  و`flutter_native_splash` إلى `dev_dependencies`.
- **إصلاحاتٌ تكسر المسار الرئيسي**: `setup_project --auth required|optional` لم يعد يُفشل اختباره ·
  `new_project.ps1 -Kits` (كان يحذف كل الـkits بصمت) · `template_update --to` الخاطئ يتوقّف ولا يسقط إلى
  `HEAD`، وينقل اختبارات القالب (`test/` بملفات القالب وحدها) · `in_app_updates` يجلب لقطته مرّةً بلا
  المزامنة · أخطاء الـCubits تصل `LogService` دائماً · `INTERNET` صريحٌ بأندرويد · crash/analytics
  مطفأان بـdebug من `ModulesBootstrap`. ⚠️ SETUP الموديولات الأربعة لـFirebase و`multi_device` أُعيدت
  كتابتها؛ وثيقتا تصميم `multi_device` نُقلتا إلى `_template/archive/`.
- **توقيع release الحقيقي**: `build.gradle.kts` يقرأ `android/key.properties` حين يوجد (وإلا مفتاح debug
  كما كان) · `build_apk.dart` ينبّه ببناء `prod` release بلاه · `.gitignore` الجذر يحجب المفاتيح بأي
  مكان (`*.jks` · `*.keystore` · `*.p12` · `*.p8` · `*.mobileprovision`) · `test/signing_secrets_test.dart`
  يسأل git نفسه. ⚠️ `android/app/build.gradle.kts` تغيّر.

- **أدوات النقل** (`port_inventory.dart` + skill `port-to-template`): إشارةٌ لكل صفٍّ بالكتالوج ولكل kit
  وموديول (`scripts/src/port_signals.dart`)، وتُطابَق على ملفات الاعتماديات لا الكود وحده ·
  `test/port_signals_test.dart` يُفشل الناقص ومشروعٌ وهميّ يثبت التقاط كل إشارة · الـendpoints
  بالـmethod · هويّة المتجر (المعرّف · رقم البناء · التوقيع) · الأذونات بعلَمها · إشارة دخول OAuth/Keycloak.
  والخطّة تحسم قبل M1: fixture wire لكل endpoint · «الباك كما هو» (ما يُطفأ وما يُكيَّف) · ما لا
  ينتقل من جهاز المستخدم.

- **موديول `token_inspector`** (مطفأ): التوكن على الشاشة بلا كونسول. فيه زرٌّ عائم، وحالةُ الجلسة الآن،
  وسجلٌّ يبقى بعد الإغلاق، وفحوصُ Keycloak تظهر حين يأتي التوكن منه. `TokenInspector.mark` · `.snapshot` ·
  `TokenInspectorPanel`. **لا يُرى بنسخة `prod` release**، و`build_apk.dart` يعدّد النداءات المتروكة
  ويسأل قبل البناء (`--allow-token-trace` لـCI). منفذٌ جديد `AuthSessionObserver` + `AuthSessionRelay`
  بالـDI · `AppOverlays` نقطةُ تركيبٍ بـ`MaterialApp.builder` · القاعدة R44 بفاحصها `C20`.
  ⚠️ `lib/app.dart` و`main.dart` و`TokenRefreshInterceptor` و`LoginRepositoryImpl` و
  `TokenRefreshGatewayImpl` و`StartupResolver` تغيّرت (سطرُ إخبارٍ واحد بكلٍّ منها، ووسيطٌ جديد بالبنّاء).
- **`check_structure` F20**: سطرُ `typedef … = Widget Function(` لم يعد يُقرأ دالّةً تبني قسماً.

- **`SignaturePad` داخل صفحةٍ تتمرّر**: الضربةُ تُرسم كاملة (كان التمريرُ يأخذها فتخرج نقطة)، والضربةُ
  الأولى لا تضيع حين يختفي النصّ الإرشاديّ.
- **الخروج من التطبيق لم يكن يعمل قطّ**: الرجوع يُظهر «الخروج من التطبيق؟» و«تأكيد» يُغلق الحوار
  ويبقى التطبيق — القشرة تمنع الإغلاق لتسأل، ولا شيء كان يخرج بعد «نعم». صار `SystemNavigator.pop()`
  (أندرويد يُغلق؛ iOS لا يسمح بالإغلاق الذاتي ولا رجوعَ نظامٍ يصل الحوار) · `test/shell_back_test.dart`.
- **kit `ink` (K6)**: `HandwritingInput` — خطُّ يدٍ يصير نصّاً، والعربية مدعومة (نموذجٌ يُنزَّل مرّة) ·
  **`SignaturePad` + `InkController` بالمكتبة** — توقيعٌ يُحفظ PNG بلا أي kit.
- **kit `system` (K5)**: اختصاراتُ أيقونة التطبيق (`AppShortcuts` — كلُّ اختصارٍ مسار، و`app.dart` يمرّره
  لـ`pushPath`) · ورقةُ تقييم المتجر (`AppReview`). ⚠️ `lib/app.dart` تغيّر — يستمع لضغطات الاختصارات.
- **kit `video` (K4)**: `AppVideoPlayer` (الصورة بشكلها · لمسةٌ تشغّل) · `AttachmentPreview` يشغّل مرفق
  الفيديو بالتطبيق · `CapturedPhoto.isVideo` · `PlaybackBar` شريطٌ واحد لكل مشغّل (استُخرج من `AudioPlayerTile`).
- **kits `scan` · `ocr` (K3)**: `DeviceScan.code` (ورقةٌ بالكاميرا) · `DeviceScan.text` (لاتيني وحده،
  kit مستقلّة لأنها +12MB). لا ماسحَ مستندات — أُلغي بقرار (يحتاج خدمات Google).
  ⚠️ `kit_contracts` صار حزمة Flutter. ⚠️ `kit.json` يحمل `proguard`، و`build.gradle.kts` يضمّ
  `proguard-kits.pro` المولَّد — بلاه تفشل نسخة release.
- **`AppBottomSheet(isScrollable: false)`** يعطي المحتوى سقف الورقة — كان يفيض على شاشةٍ قصيرة.
- **kit `audio` (K2)**: `VoiceNoteRecorder` (ملفٌّ مؤقّت يُنسخ للتخزين الخاص) · `AudioPlayerTile` ·
  `AttachmentPreview` يشغّل المرفق الصوتيّ بورقةٍ داخل التطبيق · `CapturedPhoto.isAudio` ·
  `AppNumberFormats.elapsed` (`03:41`) · `showKitReadiness` مشتركٌ للودجات. ⚠️ مفتاح
  `voiceOpenSettings` صار `kitOpenSettings`. ⚠️ أوّلُ بناء يحتاج الوصول لـ`dl.google.com`.
- **`CustomTextField`**: `onChanged`/`onFieldSubmitted` يصلان الدالّة بوسيطٍ أو بدونه —
  كانا يُناديان بلا وسيط، فالدالّة `(String v) {…}` ترمي ولا تُنادى أبداً.
- **kit `voice` (K1)**: إملاءٌ بالصوت `CustomTextField(dictation: true)` · `DictationButton` ·
  قراءةٌ بصوت `SpeakButton` — لا ترسم شيئاً بلا الـkit. `ensureKitReady` يطلب أذونات أي kit
  بـ`PermissionsService`. أعلامٌ جديدة `speechRecognition` · `textToSpeech`، و
  `sync_platform_permissions` يكتب `<queries>` بأندرويد. فصلُ «الطرفيات» بالمرآة.
  ⚠️ `KitNeedsPermission` صار يحمل قائمة أذونات.
- **حِزَم الأجهزة — البنية (K0)**: `packages/kit_contracts` · `scripts/kit.dart`
  (`list` · `add` · `remove` · `test`) · `lib/core/di/kits.g.dart` مولَّد ويُنادى من
  `configureInjection` · `setup_project --kits` (الافتراضي لا شيء) · `C18`/`C19` · R43 ·
  `readme/modules/24_DEVICE_KITS.md`. لا kit بعد. **ويمسّ كل مشروع**: `kit_contracts` تبعيةُ
  `path` جديدة، و`packages/` صار مملوكاً للقالب · `sync_platform_permissions` يحفظ
  إزاحة `Info.plist` فلا يترك فرقاً بلا تغيير إذن.
- **الشريط السفلي والتباين**: نمط `expanding` يُظهر لافتة التبويب المختار (كانت الحصص المتساوية
  تعصرها إلى لا شيء) · الوضع الداكن: `onPrimaryContainer`/`onSecondaryContainer` صارا داكنين
  فوق حاويتهما الفاتحة (كانا ١٫٩٥ و١٫٩٨:١) — يمسّ الزرّ tonal والتبويب المختار، وبوابة التباين
  تفحص الزوجين · معاني عناصر تحكّم المرآة عادت وعليها اختبار، وإطار الهاتف بالمرآة بلا حشوة النظام.
- **الترجمة**: عناصر تحكّم المرآة تُعرض بالعربية «المعنى · اسمُ الوسيط» (`KnobName`)، وسطر
  الكود يبقى كما هو · نافذة تعارض المزامنة ورسالة «الملف فارغ» بالنقل صارتا مترجمتين.
- **تجديدُ توكنٍ لم يصل لا يُخرج المستخدم**: الطلب يفشل بخطأ النقل لا بالـ401، فلا تقرؤه
  `PaginationCubit`/`FailureUiMapper` «ادخل ثانيةً». ورسالةٌ بإجراء («تراجع») تُعرض سناك
  بار بالمحوّل الافتراضي بدل أن يُسقط زرّها · `CustomTextField` يتبع `isFieldObscure`
  بعد البناء ولا ينهار مع `maxLines` · `KeyValueRow(copyable)` بلا زرّ نسخٍ حين لا خدمة.

- **الشريط السفلي** `AppBottomBar`: أربعة طوابع (`material` · `floating` · `expanding` ·
  `minimal`) و`AppTabSwitcher` بأربعة انتقالات، يُختاران بـ`ShellAppearance` ويتبدّلان
  والتطبيق يعمل. **والقشرة بلا `extendBody`**: جسدُ كل تبويبٍ ينتهي عند الشريط لا خلفه
  (R15 — يُفحص لكل طابع).

- **المرآة — جولة المطوّر** `modules/showcase/` (علَم `showcase`، مُشعَل افتراضاً): تبويب
  الرئيسية يعرض ستّة فصول — أساسات · ودجات · حركة · بيانات · موديولات · منصّة — بالودجات
  الحقيقية، والخادم محاكىً محلّياً، وفوق كل مثالٍ اسمُه بالكود. **R42**: كل ودجةٍ بالمكتبة
  لها مثالٌ بالجولة، واختبارٌ يُفشل الناقص. تُطفأ وتُحذف بخطوات `SETUP.md` الموديول.
- `AppOpenContainer`: زرّ الرجوع بالنظام يُغلق الصفحة المفتوحة (كان لا يفعل شيئاً).
- إصلاحات بالمكتبة كشفتها المرآة: `AppButton` يختصر النصّ الطويل بدل أن يفيض ·
  `AppOpenContainer` يمرّ الرجوعُ فيه بـ`PopScope` · `BadgeWidget` لا يرسم شارةً لعددٍ صفر ·
  `StepProgressIndicator` المرقّم لا يفيض بلافتاتٍ طويلة · `PageLoadingIndicator` يلغي
  مؤقّتاته · `ConnectivityDot(bloc:)` لكيوبتٍ غير المسجَّل · `DashedDivider` مرئيٌّ افتراضاً
  (`borderSubtle`) · لا `Theme.of` بـ`DividerWidget`/`AppText`/`DashedDivider`/`BadgeWidget`.
- ودجتان بالمكتبة: `AppReorderableList` (ترتيبٌ بالسحب، `onReorder` بالموضع النهائيّ) ·
  `AppSwipeActions` + `SwipeAction` (سحبُ صفٍّ لإجراء، بداية/نهاية مع RTL · تأكيد · تراجعٌ بيد المستدعي) — §39 · §40.

- **الحركة**: انتقال الصفحات `PredictiveBack` على أندرويد (كان Cupertino) · صفوف
  `PaginationBuilderWdg`/`PaginatedListView` تظهر متتالية (`itemAppear`) · تبويبات
  القشرة بـ«fade through» · الترحيب يظهر متتالياً · `CustomTextField` يهتزّ لخطأ جديد ·
  ودجات `AppOpenContainer` · `AppStepSwitcher` · `AnimatedCount` · `ShakeOnError` ·
  `AppMotion.of(context)` (صفرٌ مع «تقليل الحركة») وR41. تبعيةٌ جديدة: `animations` (رسمية).

- **دَين `check_structure` صفر** — المخالفات الـ53 المسجَّلة أُصلحت بالكود، و`.structure_baseline.txt`
  لا يحمل شيئاً. صفحاتُ الحساب والإعدادات قُسّمت إلى ودجاتٍ مسمّاة بـ`presentation/widgets/`.
- ⚠️ **تغييرات واجهة عامة** (لا مستدعٍ لها بالقالب، وقد يكون لها بمشروع):
  - `app_padding_extension`: `leftPadding`/`rightPadding` وأخواتها الست صارت
    `startPadding`/`endPadding`… وتُعيد `EdgeInsetsDirectional`.
  - حقولُ البريد وكلمة المرور والرمز **بلا `ltr: true`** — تتبع اتجاه الصفحة (F10).
  - `AppColors`: `feedbackSuccess` · `feedbackError` · `feedbackWarning` · `feedbackInfo`.
  - `AppLocale`: `nativeName` · `shortName` (أسماء اللغات بلغتها).
  - `flavor_banner.dart` يُصدَّر من `widgets.dart`.
  - `AppButtonVariant.onBrand` — زرٌّ فوق سطح العلامة (الترحيب)؛ `tonal` كان يُقرأ معطَّلاً هناك.
  - شريط «لا اتصال» بالوضع الداكن: النصّ `onError` (رماديٌّ داكن) بدل الأبيض — تباينٌ أعلى.

- **أوضاع الدخول** `AppFeatures.authMode` (`none` افتراضاً · `required` · `optional`)،
  تُختار بـ`setup_project.dart --auth` و`new_project.ps1 -Auth`. والقالب **يبدأ بلا
  دخول**: ترحيبٌ ثم الرئيسية. ⚠️ **يغيّر سلوك مشروعٍ قائم** يأخذ التحديث: يرجع إلى
  `required` بسطرٍ واحد بـ`app_features.dart` ليبقى كما كان.
- **`WelcomeScreen`** مرّةً واحدة على الجهاز (`PersistenceKeys.welcomeSeen`)، على
  `AppColors.bgBrand` الجديد (= `splash_background`).
- **`AccountTab`** لوضع `optional`: دعوةٌ للدخول للزائر، والملف الشخصي لمن دخل.
- **الهوية بملفٍّ يُستبدل**: `assets/images/brand/app_logo.svg` و`.png` بدل شعار
  الجهة السابق؛ `gen_splash_assets.dart` يقرأ ألوان الشعار كما هي.

## 1.0.0 — 2026-10-29

أول إصدارٍ مرقّم. ما فيه مقارنةً بالقالب قبله:

- **صيانة القالب بـ`_template/`** — الخطّة والأرشيف وملاحظات المشاريع، لا تُنسخ للمشاريع.
- **لا تاريخ ولا اسم مشروع بما يصل المشاريع** (R38، `audit_template.dart` §٥).
- **كتالوج القدرات** `readme/rules/06_CAPABILITIES.md` وحارسه `C01…C17` (R40).
- **أدوات التاريخ والأرقام**: محرّك أم القرى بدل حزمة `hijri` · `CalendarNames` ·
  `toArabicIndicDigits` · أوصاف `AppDateFormat`/`AppTimeFormat`/`AppNumberFormat`
  وكتالوجها · `AppDateText.format`.
- **الخطوط**: الوزن من الملف (`usWeightClass`) واختباره.
- **SVG**: `svg_inline_styles.dart` وحارسه · `SvgImageWidget.icon`.
- **REST**: الردّ النصّي `Future<String>` · `retrofit: 4.9.1`.
- **الفحوص بالـCI**: التنسيق حاجب · `check_structure` · `check_docs` · `audit_template`.
- **skills القالب** تصل المشاريع (`.claude/skills/`) · `apply-feedback`.
- **حلقة الملاحظات**: `docs/TEMPLATE_FEEDBACK.md` بالمشروع · `template_drift.dart` ·
  `template_update.dart` · `TEMPLATE_VERSION`.
- **أدوات النقل والتنظيف**: `port_inventory.dart` · `device_shot.dart` · skill
  `port-to-template` · `prune_project.dart` (وحُذف به 62 مفتاح ترجمة مهجوراً).
- **`L01`**: `@RestApi` بملفّ `*_api_service.dart` وحده · `domain/services/` و`presentation/services/`.
- **الأخطاء غير الملتقَطة** تمرّ بـ`LogService` (فتصل `crash_reporting`).
