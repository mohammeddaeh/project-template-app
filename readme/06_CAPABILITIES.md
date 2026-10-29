# 06 · كتالوج قدرات القالب — ابحث هنا قبل أن تكتب أداة

> **القاعدة:** قبل أن تكتب دالّة تنسيق، أو غلافاً لحزمة، أو ودجة حالة — ابحث بهذا
> الملف بـCtrl+F عن الحاجة نفسها («تاريخ» · «رقم» · «صورة» · «مشاركة»). ما تجده هنا
> **مبنيٌّ ومختبَر**، وكتابتُه ثانيةً تفقد ما يحمله الأول: تسجيلُ الخطأ · الترجمة ·
> العلَم الذي يُطفئ الخدمة · الاختبار.
>
> **والحارس:** عمود «الحارس» يسمّي قاعدةً بـ`check_structure.dart` تُفشل البناء
> حين يُنادى الشيءُ الخامّ خارج غلافه. ما لا حارس له يُراجَع بالعين (👁).
>
> **ونقصُ قدرة ليس إذناً بتجاوزها**: إن كانت ناقصةً حالةً تحتاجها، **وسّعها في
> مكانها** بالقالب — ثم سجّل ذلك ملاحظةً للقالب (راجع «أين تذهب التحسينات» بالأسفل).

## التاريخ والوقت

| الحاجة | استعمل | لا تكتب | الحارس |
|---|---|---|---|
| ★ **عرض تاريخ بشكلٍ مسمّى** | `AppDateText.format(date, format: AppDateFormats.x)` — الكتالوج بـ[`core/foundation/formatting/app_formats.dart`](../lib/core/foundation/formatting/app_formats.dart) · [`21_WIDGETS_USAGE.md`](21_WIDGETS_USAGE.md) §28 | `DateFormat(...)` بشاشة · `AppDateFormat(...)` بشاشة | C01 · C17 |
| شكلٌ جديد (اسم اليوم · العصر · تهجئة الشهر · أرقام هندية أو لاتينية) | سطرٌ بـ`AppDateFormats` من أجزاء `AppDateFormat` — [`core/foundation/formatting/app_date_format.dart`](../lib/core/foundation/formatting/app_date_format.dart) | دالّة تنسيقٍ بالشريحة | C17 |
| تاريخ بلا واجهة (إشعار · مشاركة) | `AppDateFormats.x.apply(date, language: 'ar')` | `'${d.day}/${d.month}'` | 👁 |
| عرض تاريخ بوسطاء مباشرة (هجري · ميلادي · الاثنان · مكدّس/سطر) | `AppDateText(date, calendar: …)` — [`ui/widgets/dates/app_date_text.dart`](../lib/ui/widgets/dates/app_date_text.dart) | `DateFormat(...)` بشاشة | C01 |
| تاريخ هجري كنصّ أو كائن (تقويم أم القرى) | `date.toHijri({adjustment})` · `date.tryToHijri()` · `date.toHijriString()` — `HijriDateX` بـ[`core/foundation/utils/hijri_date_extension.dart`](../lib/core/foundation/utils/hijri_date_extension.dart) | `UmmAlQura.` · حزمة هجرية ثانية | C03 |
| أسماء الأيام والأشهر | `CalendarNames` — [`core/foundation/utils/calendar_names.dart`](../lib/core/foundation/utils/calendar_names.dart) — وعبر الكتالوج لا مباشرةً من شاشة | قائمة أشهرٍ بالشريحة | C17 |
| أرقام هندية (`١٢٣`) | `ArabicDigits.indic` على الشكل؛ والمحوّل الوحيد `toArabicIndicDigits` — [`core/foundation/utils/arabic_digits.dart`](../lib/core/foundation/utils/arabic_digits.dart) | `0x0660 + …` بالشريحة | C17 |
| وقت بشكلٍ مسمّى (12/24 · ص/م) | `AppTimeFormats.x.apply(h, m, language:, h24:)` | `'${t.hour}:${t.minute}'` | C17 |
| «منذ ٥ دقائق» | `date.timeAgo()` — [`core/platform/extensions/datetime_extensions.dart`](../lib/core/platform/extensions/datetime_extensions.dart) | حساب الفرق يدوياً | 👁 |
| `2026/01/05` · وقتٌ مختصر | `date.getFormattedDate` · `date.getFormattedTime` — الملف نفسه | `padLeft` على اليوم والشهر | 👁 |
| اختيار تاريخ (Material · تقويم · ورقة · ورقة هجرية) | `context.showDatePicker(mode: DatePickerDisplayMode.x)` — [`ui/extensions/date_picker_extension.dart`](../lib/ui/extensions/date_picker_extension.dart) | `showDatePicker` الإطار مباشرةً | 👁 |
| اختيار وقت | `context.showTimePicker(mode: …, onSelect: …)` — [`ui/extensions/time_picker_extension.dart`](../lib/ui/extensions/time_picker_extension.dart) | `material.showTimePicker` | 👁 |
| مدى تاريخين صالح | `DateRange` — [`core/foundation/value_objects/date_range.dart`](../lib/core/foundation/value_objects/date_range.dart) | فحص «البداية قبل النهاية» بكل شاشة | 👁 |

## الأرقام والأحجام والترتيب

| الحاجة | استعمل | لا تكتب | الحارس |
|---|---|---|---|
| عدّ بفواصل · مسافة م/كم · عدّ تنازلي | `AppNumberFormats.count` · `.distance` · `.countdown` — `.apply(...)` — [`core/foundation/formatting/app_number_format.dart`](../lib/core/foundation/formatting/app_number_format.dart) | `toStringAsFixed` بالشاشة | C17 |
| ثوانٍ ⇐ `05:12` أو `1:05:12` (بلا ساعات حين الصفر) | `seconds.getTimeFromIntSeconds` — [`core/foundation/extensions/num_extensions.dart`](../lib/core/foundation/extensions/num_extensions.dart) | `Duration` و`padLeft` يدوياً | 👁 |
| شارة عدّ `+99` | `count.getPlus()` — الملف نفسه | شرط `> 99` بكل شارة | 👁 |
| حجم ملف مترجَم («٢ ميغابايت») | `bytes.asFileSize` — [`ui/extensions/byte_size_extension.dart`](../lib/ui/extensions/byte_size_extension.dart) | قسمة على 1024 | 👁 |
| أي تنسيق رقمٍ آخر | شكلٌ جديد بـ`AppNumberFormats` | `NumberFormat` بشاشة | C02 |
| ترتيب معرّفات مرقّمة (`٩١/٢` قبل `٩١/١٠`) | `NaturalOrder.compare` — [`core/foundation/utils/natural_order.dart`](../lib/core/foundation/utils/natural_order.dart) | `compareTo` على النصّ | 👁 |

## النصوص والتحقق

| الحاجة | استعمل | لا تكتب | الحارس |
|---|---|---|---|
| الأحرف الأولى · الوسوم · اتجاه النصّ · تنظيف الأسطر | `s.initials` · `s.hashtags` · `s.isRtl` · `s.cleaned` — [`core/platform/extensions/string_extensions.dart`](../lib/core/platform/extensions/string_extensions.dart) | `split(' ')[0][0]` | 👁 |
| بريد · هاتف صالح | `Email` · `PhoneNumber` ⇒ `Either<ValidationFailure, T>` — [`core/foundation/value_objects/`](../lib/core/foundation/value_objects/) | `RegExp` بالشاشة | 👁 |
| أنماط تحقق مشتركة (اسم · كلمة مرور) | `CustomRegex` — [`core/foundation/utils/validators.dart`](../lib/core/foundation/utils/validators.dart) | نمطٌ ثانٍ لنفس الحقل | 👁 |
| نصّ معروض | `LocaleKeys.x.tr()` — [`03_RULES.md`](03_RULES.md) R10 | نصّاً عربياً بالكود | F13 |

## الواجهة

| الحاجة | استعمل | لا تكتب | الحارس |
|---|---|---|---|
| رسالة نجاح · خطأ · تنبيه · توست | `context.feedback.success/error/warning/info/toast` — [`ui/feedback/`](../lib/ui/feedback/) | `ScaffoldMessenger.of(context).showSnackBar` | C09 |
| عرض `Failure` للمستخدم | `FailureUiMapper.toAction` · `ErrorView` · `FailureStateView` — [`ui/error/`](../lib/ui/error/) · [`13_ERROR_FLOW.md`](13_ERROR_FLOW.md) | قراءة `failure.diagnosticMessage` بواجهة | 👁 |
| حالات الشاشة (فارغ · لا اتصال · صيانة · إعادة) | `EmptyStateWidget` · `NoInternetWidget` · `MaintenanceWidget` · `RetryWidget` — [`ui/widgets/states/`](../lib/ui/widgets/states/) | `Center(Column(Icon, Text))` | 👁 |
| مؤشّر تحميل أو تقدّم | `AppProgress.circular/linear` — [`ui/widgets/indicators/app_progress.dart`](../lib/ui/widgets/indicators/app_progress.dart) | `CircularProgressIndicator` | F35 |
| حقل إدخال | `CustomTextField` — [`21_WIDGETS_USAGE.md`](21_WIDGETS_USAGE.md) §5 | `TextField` / `TextFormField` | F36 |
| التمرير لأول حقل ناقص | `formKey.validateAndReveal()` — [`ui/widgets/inputs/form_reveal.dart`](../lib/ui/widgets/inputs/form_reveal.dart) | `Scrollable.ensureVisible` يدوياً | 👁 |
| صورة شبكة · صورة شخص · SVG · أصل | `CachedImageWidget` · `NetworkImageWidget` · `AvatarWidget` · `SvgImageWidget` · `AppAssetImage` — [`ui/widgets/images/`](../lib/ui/widgets/images/) | `Image.network(...)` | C05 |
| حوار · تأكيد · ورقة سفلية | `context.showCustomDialog` · `showConfirmDialog` · `showLoadingDialog` · `context.showAppBottomSheet` — [`ui/extensions/`](../lib/ui/extensions/) | `showDialog` / `showModalBottomSheet` الإطار | 👁 |
| قائمة مرقّمة بصفحات | `PaginationCubit` + `PaginationBuilderWdg` / `PaginatedListView` — [`14_PAGINATION.md`](14_PAGINATION.md) | `ScrollController` يحسب نهاية القائمة | 👁 |
| مقاس · مسافة · لوح · تكبير خط | `context.screen` — [`22_RESPONSIVE.md`](22_RESPONSIVE.md) | `MediaQuery.of(context).size.height * 0.3` | F37 |
| لون · خط · زاوية · حركة · ظلّ | `context.colors.x` · `context.textTheme.x` · `AppRadius` · `AppMotion` · `AppElevation` — [`20_WIDGETS.md`](20_WIDGETS.md) §3 | `Color(0xFF…)` · `Colors.x` | F04 |
| اتجاه حشوة أو محاذاة | `EdgeInsetsDirectional` · `AlignmentDirectional` | `EdgeInsets.only(left:)` | F10 |

## السجلّ

| الحاجة | استعمل | لا تكتب | الحارس |
|---|---|---|---|
| سطر تشخيص | `LogService.debug/info/warning/error(…, tag:)` — [`core/platform/logging/log_service.dart`](../lib/core/platform/logging/log_service.dart). يصل `crash_reporting` حين يُشعَل | `print` / `debugPrint` | C04 |

> **استثناءٌ واحد:** `_onError` بـ`main.dart` — معالجُ الخطأ غير الملتقَط — يمرّ
> بـ`LogService.error` **ثم** يطبع بـ`debugPrint`: المفوَّض الافتراضي يكتب عبر
> `dart:developer`، ولا تعرضه كل طرفيّة.

## المنصّة — خدمات خلف علَم

كلٌّ منها واجهةٌ بـ`core/platform/` تُحقن بـ`getIt<XService>()`، ولا تُسجَّل حين
يكون علَمها مطفأً. **العلَم وطريقة التفعيل والأذونات لكلٍّ منها** بـ
[`lib/core/platform/PLATFORM_SERVICES.md`](../lib/core/platform/PLATFORM_SERVICES.md).

| الحاجة | استعمل | لا تكتب | الحارس |
|---|---|---|---|
| تخزين إعدادات · توكن | `StorageService` · `SecureStorageService` — R22 · R23 | `SharedPreferences.getInstance` · `FlutterSecureStorage()` | C06 |
| فتح رابط · هاتف · بريد | `UrlLauncherService` | `launchUrl` | C07 |
| مشاركة | `ShareService` | `SharePlus.instance` | C08 |
| الموقع | `DeviceLocationService` | `Geolocator.` | C10 |
| اهتزاز | `HapticService` — و`context.feedback.*` يهتزّ وحده | `HapticFeedback.` | C11 |
| نسخ ولصق | `ClipboardService` | `Clipboard.setData` | C12 |
| كاميرا · معرض | `MediaService` | `ImagePicker()` | C13 |
| اختيار ملف · فتحه | `FileService` | `FilePicker.` | C14 |
| بصمة · وجه | `BiometricsService` | `LocalAuthentication()` | C15 |
| إشعار محلّي | `LocalNotificationsService` | `FlutterLocalNotificationsPlugin()` | C16 |
| إذن نظام | `PermissionsService.request(AppPermission.x)` | `Permission.camera.request()` | 👁 |
| حالة الشبكة | `NetworkStateMonitor` · `ConnectivityDot` | `Connectivity()` | 👁 |

## الشبكة والبيانات والموديولات

| الحاجة | استعمل | لا تكتب | الحارس |
|---|---|---|---|
| مسار endpoint | `ApiUrls` — [`17_SERVED_CONTRACT.md`](17_SERVED_CONTRACT.md) | نصّ مسارٍ بالخدمة | 👁 |
| قراءة ردّ الخادم | `HandleBodyResponse` · `BaseRepository` — [`12_REST_API.md`](12_REST_API.md) | `response.data['data']` بالمستودع | 👁 |
| ردٌّ نصّيّ أو JSON بضجيج | خدمة Retrofit تُعيد `Future<String>` بـ`ResponseType.plain` — [`12_REST_API.md`](12_REST_API.md) §Step B′ | `HttpResponse<dynamic>` مع `ResponseType.plain` (يُتجاهل بصمت) | 👁 |
| إخفاء ما لا يملكه المستخدم | `Can(permission: PermKeys.x)` — [`31_MODULE_PERMISSIONS.md`](31_MODULE_PERMISSIONS.md) | مفتاحاً نصّياً خامّاً | 🔒 R24 |
| استيراد · تصدير | `DataTransferSheet.show(context, resource:)` — [`32_MODULE_DATA_TRANSFER.md`](32_MODULE_DATA_TRANSFER.md) | شاشة رفع ملف لكل feature | 👁 |
| عمل دون اتصال | `modules/sync/` — [`lib/modules/sync/STATUS.md`](../lib/modules/sync/STATUS.md) **قبل أي شيء** | طابوراً محلّياً ثانياً | 👁 |

---

## إضافة قدرة

قدرةٌ جديدة تُبنى بمكانها بالطبقات ([`10_ARCHITECTURE.md`](10_ARCHITECTURE.md))، ثم
**بنفس التغيير**:

1. **صفٌّ هنا** بالقسم الذي يبحث فيه من يحتاجها.
2. **قاعدة `C##`** بجدول `_capabilities` بـ`scripts/check_structure.dart` إن كان
   للنداء الخامّ نمطٌ لا يحتمل زيفاً — اسمُ الحزمة أو صنفُها. وإلا فـ👁.
3. **اختبارٌ** يثبّت سلوكها.

## أين تذهب التحسينات

قدرةٌ وسّعتها بمشروعٍ مبنيّ على القالب تُوسَّع **بمكانها نفسه** (لا نسخةً بجانبها
بـ`features/`)، وتُسجَّل ملاحظةً لتعود إلى القالب — فلا يبنيها المشروع التالي ثانيةً.
