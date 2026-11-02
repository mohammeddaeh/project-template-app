# عرض البيانات والصور والتاريخ

> جزءٌ من دليل الودجات — الفهرس الكامل والاستيراد بـ[`../21_WIDGETS_USAGE.md`](../21_WIDGETS_USAGE.md).

> **Import الوحيد:** `package:app_template/ui/widgets/widgets.dart` — والاستثناءات بـ§DIRECT-IMPORTS بالفهرس.


---

## §13 · KeyValueRow / KeyValueSection — صفوف بيانات

**KeyValueRow Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `labelKey` | `String` | مطلوب | مفتاح ترجمة التسمية |
| `value` | `String?` | — | القيمة النصية |
| `valueWidget` | `Widget?` | — | widget مخصصة بدل `value` |
| `copyable` | `bool` | `false` | أيقونة نسخ |
| `ltr` | `bool` | `false` | يُجبر النص LTR (IBAN / رقم) |
| `showDivider` | `bool` | `true` | — |

**Usage**

```dart
// ── صف واحد ──
KeyValueRow(
  labelKey: LocaleKeys.orderNumber,
  value: '#${order.id}',
  copyable: true,
  ltr: true,
)

// ── مجموعة داخل بطاقة ──
KeyValueSection(
  rows: [
    KeyValueRow(labelKey: LocaleKeys.name, value: user.fullName),
    KeyValueRow(labelKey: LocaleKeys.phone, value: user.phone, ltr: true),
    KeyValueRow(
      labelKey: LocaleKeys.status,
      valueWidget: AppLabel(
        labelText: order.statusLabel,
        variant: order.statusVariant,
      ),
    ),
  ],
)
```


---

## §14 · StatCard — بطاقة إحصاء

> مصممة للوحات التحكم.

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `value` | `String` | مطلوب | القيمة الرئيسية |
| `labelKey` / `labelText` | `String?` | مطلوب أحدهما | الوصف |
| `icon` | `IconData?` | — | أيقونة اختيارية |
| `color` | `Color?` | `primary` | لون القيمة والأيقونة |
| `onTap` | `VoidCallback?` | — | اضغط لفتح تفصيل |
| `isLoading` | `bool` | `false` | skeleton loading |

**Usage**

```dart
GridView.count(
  crossAxisCount: 2,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  children: [
    StatCard(
      value: stats.total.toString(),
      labelKey: LocaleKeys.totalOrders,
      icon: Icons.receipt_long_outlined,
    ),
    StatCard(
      value: stats.active.toString(),
      labelKey: LocaleKeys.activeOrders,
      icon: Icons.check_circle_outline_rounded,
      color: context.colors.statusSuccessFg,
    ),
    StatCard(
      value: '${stats.revenue} ر.س',
      labelKey: LocaleKeys.revenue,
      onTap: () => context.router.push(const RevenueRoute()),
    ),
    StatCard(value: '', labelKey: LocaleKeys.pending, isLoading: true),
  ],
)
```


---

## §15 · StepProgressIndicator — مؤشر خطوات

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `currentStep` | `int` | مطلوب | 1-based |
| `totalSteps` | `int` | مطلوب | — |
| `type` | `StepIndicatorType` | `numbered` | نوع العرض |
| `activeColor` | `Color?` | `primary` | — |
| `inactiveColor` | `Color?` | `borderSubtle` | — |
| `stepLabelResolver` | `String? Function(int)?` | — | labels مخصصة |

**StepIndicatorType**

| القيمة | الوصف |
|--------|-------|
| `numbered` | دوائر مرقّمة مع خطوط رابطة |
| `dots` | نقاط أفقية (بسيط) |
| `bar` | شريط تقدم خطي مع نسبة مئوية |

**Usage**

```dart
// ── Numbered ──
StepProgressIndicator(currentStep: _step, totalSteps: 4)

// ── مع labels ──
StepProgressIndicator(
  currentStep: _step,
  totalSteps: 3,
  stepLabelResolver: (s) => switch (s) {
    1 => LocaleKeys.personalInfo.tr(),
    2 => LocaleKeys.documents.tr(),
    _ => LocaleKeys.review.tr(),
  },
)

// ── شريط تقدم ──
StepProgressIndicator(
  currentStep: _completedSteps,
  totalSteps: form.totalFields,
  type: StepIndicatorType.bar,
  activeColor: context.colors.statusSuccessFg,
)

// ── Dots ──
StepProgressIndicator(
  currentStep: _pageIndex + 1,
  totalSteps: _pages.length,
  type: StepIndicatorType.dots,
)
```


---

## §16 · AppLabel — شارة حالة دلالية

> بديل `TagWidget` — يستخدم ألوان الثيم الدلالية.
> الفرق عن `BadgeWidget`: AppLabel نص مستقل · BadgeWidget تُغطي فوق widget أخرى.

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `labelKey` / `labelText` | `String?` | مطلوب أحدهما | — |
| `variant` | `AppLabelVariant` | `neutral` | النوع الدلالي |
| `icon` | `IconData?` | — | أيقونة اختيارية |
| `onTap` | `VoidCallback?` | — | يُضيف تأثير ضغط |
| `compact` | `bool` | `false` | padding أصغر للجداول |

**AppLabelVariant**

| القيمة | الاستخدام |
|--------|-----------|
| `success` | نشط / مكتمل / مؤكَّد |
| `warning` | معلّق / قيد المراجعة |
| `error` | مرفوض / ملغى / خطأ |
| `info` | معلومة / ملاحظة |
| `neutral` | مسودة / غير محدد |
| `primary` | مميَّز / علامة تجارية |

**Usage**

```dart
// ── في قائمة أوامر ──
AppLabel(labelText: order.statusLabel, variant: order.statusVariant)

// ── مع أيقونة ──
AppLabel(
  labelKey: LocaleKeys.verified,
  variant: AppLabelVariant.success,
  icon: Icons.verified_rounded,
)

// ── مضغوط في جدول ──
AppLabel(labelKey: LocaleKeys.closed, variant: AppLabelVariant.error, compact: true)

// ── mapping من API enum ──
extension on OrderStatus {
  AppLabelVariant get labelVariant => switch (this) {
    OrderStatus.active   => AppLabelVariant.success,
    OrderStatus.pending  => AppLabelVariant.warning,
    OrderStatus.rejected => AppLabelVariant.error,
    OrderStatus.draft    => AppLabelVariant.neutral,
  };
}
```

> ❌ `TagWidget(labelKey: ..., backgroundColor: Colors.green, ...)`
> ✅ `AppLabel(labelKey: ..., variant: AppLabelVariant.success)`


---

## §25 · BadgeWidget / TagWidget — توافق

> موجودان للتوافق. **للكود الجديد استخدم `AppLabel`.**

```dart
// ── BadgeWidget — عدد فوق widget (لا يُستبدَل) ──
BadgeWidget(
  count: notifications.length,   // 0 ⇐ لا شارة أصلاً، لا «0» حمراء
  child: IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: _open),
)

// ── TagWidget — توافق قديم ──
TagWidget(labelKey: LocaleKeys.active)

// ── الصحيح في الكود الجديد ──
AppLabel(labelKey: LocaleKeys.active, variant: AppLabelVariant.success)
```


---

## §19 · AvatarWidget — صورة مستخدم

```dart
AvatarWidget(
  imageUrl: user.profileImage,
  initial: user.fullName.getFirstAndLast,
  radius: 24,
  backgroundColor: context.colors.avatarBg,
  foregroundColor: context.colors.avatarFg,
)
```


---

## §20-ب · AttachmentView — عرض مرفق

```dart
AttachmentView(attachmentId: attachment.id, height: 180)
```

مكتفٍ بذاته: يحلّ الملف بنفسه ويختفي بلا ضرر حين يكون `AppFeatures.offlineSync`
مطفأً. ويرسم **ثلاث حالات لا اثنتين**:

| الحالة | ما يُعرض |
|---|---|
| على القرص | الصورة |
| غير موجود + إنترنت | يُنزَّل ويُتحقَّق منه ثم يُعرض |
| **غير موجود + offline** | «غير متوفّر دون اتصال» — **بلون محايد لا خطأ** |
| فشلٌ حقيقي (الخادم أجاب وشيءٌ فشل) | بلون الخطأ + إعادة محاولة بالضغط |

> **لماذا الثالثة ليست خطأً:** ملفٌ اختياري أُخلي الأسبوع الماضي على جهازٍ خارج
> التغطية اليوم هو نظامٌ يعمل كما صُمِّم. ورسمُ خطأٍ أحمر له يعلّم المستخدم أن
> التطبيق معطوب — ومن تعلّم ذلك يتوقف عن الإبلاغ عن الأعطال الحقيقية.


---

## §28 · AppDateText — عرض التاريخ الوحيد (هجري · ميلادي · الاثنان)

> ودجة التاريخ **الوحيدة** بالتطبيق. كل محور عرضٍ وسيطٌ: أيّ تقويم، تخطيطهما عند الاثنين (فوق
> بعضٍ أو بسطرٍ واحد بلا قطع نصّ أبداً)، صيغة الشهر (رقماً/مختصراً/كاملاً)،
> واللغة (والأرقام معها). راجع [`_template/roadmap.md`](https://github.com/mohammeddaeh/project-template-app/blob/master/_template/roadmap.md) بند
> #08 للسياق الكامل. **عمداً بلا محاورَ لم تُطلب** — لا ترتيب تقويمين قابلٍ
> للتبديل، لا صيغة سنة، لا اسم يوم، لا نظام أرقام مستقلّ عن اللغة: كل محورٍ
> هنا طُلب صراحةً، لا «قد يُحتاج لاحقاً».

**الطريقة الأولى — شكلٌ مسمّى من الكتالوج** (`core/foundation/formatting/app_formats.dart`):

```dart
AppDateText.format(entity.createdAt, format: AppDateFormats.listDate)
```

الشاشة **تسمّي** الشكل ولا تبنيه: تغييرُ شكل تاريخٍ بكل مواضعه سطرٌ واحد بالكتالوج،
وشاشةٌ تحتاج شكلاً آخر تغيّر الاسم الذي تختاره. والشكل يملك محاورَ لا يملكها
الوسطاء أدناه — اسم اليوم · علامة العصر · تهجئة الأشهر (يناير / كانون الثاني ·
ربيع الآخر / ربيع الثاني) · **سياسة الأرقام مستقلّةً عن اللغة** · ترتيب الشهر
بالإنكليزية. وبناءُ `AppDateFormat(...)` خارج `core/foundation/` يُفشله
`check_structure` C17. ونصٌّ بلا واجهة (إشعار) يستدعي `AppDateFormats.x.apply(date, language:)`.

**الطريقة الثانية — وسطاء مباشرة** (لشكلٍ لم يُسمَّ بعد، أو جدول وتصدير):

```dart
// هجريّ وحده — الافتراضي
AppDateText(entity.createdAt)

// ميلاديّ وحده
AppDateText(entity.createdAt, calendar: AppDateCalendar.gregorian)

// الاثنان معاً، فوق بعض — الهجريّ أوّلاً دوماً
AppDateText(entity.createdAt, calendar: AppDateCalendar.both)

// الاثنان معاً بسطرٍ واحد — يتمدّد ويلتفّ، لا يُقطع أبداً
AppDateText(
  entity.createdAt,
  calendar: AppDateCalendar.both,
  layout: AppDateLayout.inline,
)

// رقماً صرفاً بفاصلة مخصّصة — لجدول أو تصدير
AppDateText(
  entity.createdAt,
  monthFormat: AppDateMonthFormat.numeric,
  partSeparator: '-',
)
```

| الوسيط | الخيارات | الافتراضي |
|---|---|---|
| `calendar` | `hijri` · `gregorian` · `both` | `hijri` |
| `layout` (عند `both`) | `stacked` (فوق بعض، الهجريّ أوّلاً) · `inline` (سطرٌ واحد، لا قطع) | `stacked` |
| `monthFormat` | `numeric` · `nameShort` · `nameFull` | `nameFull` |
| `language` | `auto` (يتبع `context.isAr`، ويقرّر معها الأرقام: شرقية بالعربية، غربية بالإنكليزية) · `arabic` · `english` | `auto` |
| `partSeparator` | أيّ نصّ — بصيغة `numeric` فقط | `'/'` |
| `calendarSeparator` | أيّ نصّ — بتخطيط `inline` فقط | `'  •  '` |
| `style` | — | `context.textTheme.bodyMedium` |

⚠️ **`partSeparator` لا يعمل إلا بصيغة `numeric`**: بصيغة الاسم يبقى الفصل
مسافةً واحدة دوماً («١٥ رجب ١٤٤٦») — القراءة الطبيعية لا تحتمل فاصلةً مخصّصة.

**اختيار تاريخ بتقويم هجري** — نمطٌ رابع لـ`context.showDatePicker` القائم،
لا ودجة منفصلة: النتيجةُ ميلاديّةٌ دائماً (`HijriDateTime.toDateTime()`) كي
لا يفرّق المستدعي بين نمطي الاختيار.

```dart
final picked = await context.showDatePicker(
  mode: DatePickerDisplayMode.hijriSheet,
);
```

⚠️ **الاستيراد المباشر لا يكفي وحده**: `HijriDateX` (`toHijri`/`toHijriString`
على `DateTime`) بـ`core/foundation/utils/hijri_date_extension.dart` — طبقةٌ
منفصلة بلا `BuildContext`، لمن يحتاج النصّ الهجري الخام خارج ودجة (تصدير
Excel، سجلّ نصّي) بلا كل خيارات `AppDateText`. والمحرّك **جدولُ أم القرى الرسمي**
(`UmmAlQura`)، بلا حالةٍ عامّة: اللغة وسيطٌ لكل نداء، و`adjustment` فرقُ الأيام الذي
يختاره المستخدم. وخارج مدى الجدول (أوّل آب 1924 … 16 تشرين الثاني 2077) `toHijri` يرمي
و`tryToHijri` تُعيد `null`.


---

## §34 · `SvgImageWidget` — صورة SVG وأيقونتها المربّعة

```dart
// صورة SVG بمقاسها — الرسم يُحفظ بنسبته
SvgImageWidget(assetPath: Assets.images.vectors.logoSvg, height: 40)

// أيقونة مربّعة بضلعٍ واحد — بصفّ أو زرّ
SvgImageWidget.icon(Assets.images.vectors.logoSvg, size: 18)
```

**`.icon` لأي أيقونة داخل صفّ.** `SvgPicture(width: 18, height: 18)` لا يرسم
مربّعاً: يأخذ الارتفاع ويحفظ نسبة الرسم، فرسمٌ عريض (`viewBox` 41×23) يخرج بعرض
~32 ويدفع ما بجانبه. و`.icon` صندوقٌ ثابت (`SizedBox.square`) والرسم داخله
بـ`BoxFit.contain`.

**والاختبار يقيس المرسوم** (`tester.getSize`) لا الوسطاء — وسطاءٌ صحيحة مع رسمٍ
أعرض مرّت خضراء: `test/svg_image_widget_test.dart`.

⚠️ **و`flutter_svg` لا يطبّق `<style>`**: SVG يلوّن بأصناف CSS يُرسم أسود. أصلحه
مرّةً بـ`dart run scripts/svg_inline_styles.dart <الملف>` — و`test/svg_no_style_test.dart`
يُفشل أي SVG بـ`assets/` بقي فيه `<style>`.

---

## §37 · `AnimatedCount` — رقمٌ يعدّ إلى قيمته

```dart
AnimatedCount(value: state.total, style: context.textTheme.headlineMedium)
AnimatedCount(value: n, format: AppNumberFormats.count)   // الشكل من الكتالوج
```

يعدّ من القيمة السابقة إلى الجديدة بدل أن يقفز — «تغيّر الرقم» يُرى ولو فاتت لحظتُه.
الشكل من `AppNumberFormats` (افتراضاً `count`)، ومع «تقليل الحركة» يظهر الرقم فوراً.

---

## §43 · VoiceNoteRecorder · AudioPlayerTile — التسجيل والتشغيل (`kit_audio`)

> **ودجتا kit**: تعملان حين تكون `kit_audio` مركّبة (`dart run scripts/kit.dart add audio`)،
> **ولا ترسمان شيئاً بدونها**. البنية بـ[`24_DEVICE_KITS.md`](../24_DEVICE_KITS.md).

```dart
// ── ملاحظةٌ صوتية تُرفق ──
VoiceNoteRecorder(
  onRecorded: (r) async {
    final kept = await getIt<PrivateFileIngestService>().ingest(File(r.path));
    cubit.attach(CapturedPhoto(localPath: kept.file.path, mimeType: Recording.mimeType));
  },
)

// ── تشغيلُ ملفٍّ أو رابط https ──
AudioPlayerTile(source: note.localPath)

// ── مرفقٌ صوتيّ بقائمة مرفقات — يُشغَّل بورقةٍ داخل التطبيق ──
AttachmentPreview.open(context, photo: attachment)
```

| القرار | لماذا |
|---|---|
| **`onRecorded` يستلم ملفّاً مؤقّتاً** | كالصورة الخاصة: النظام يفرّغ المؤقّت حين تضيق المساحة، والتقريرُ المنطوق لا يُعاد بنفس الكلمات — انسخه فوراً |
| **مشغّلٌ لكل بلاطة** | `AudioPlayback` مصنعٌ بـget_it: كلُّ بلاطةٍ تملك مشغّلها وتحرّره حين تغادر الشجرة، فقائمةُ ملاحظات لا تحمل مشغّلاتٍ أكثر مما تعرض |
| **طولٌ مجهول ⇐ الموضع وحده** | تسجيلٌ حديث قد لا يذكر طوله بترويسته فيعرفه المشغّل أثناء التشغيل — فلا «/ 00:00» تُوهم أن الملاحظة فارغة، والتقديم معطَّل حتى يصل |
| **الوقت يُقرأ من اليسار** | «الموضع / الطول» — الاتجاه العربي يقلب الرقمين حول الشرطة |
| **`CapturedPhoto.isAudio`** | نوعُ المحتوى أولاً ثم الاسم (`.m4a` · `.mp3` · …)، كـ`isImage` |

يُثبَّت بـ`test/audio_kit_test.dart` عبر `FakeAudioRecorder`/`FakeAudioPlayback`.

---

## §45 · AppVideoPlayer · PlaybackBar — الفيديو وشريط التشغيل (`kit_video`)

> `AppVideoPlayer` ودجةُ kit: لا ترسم شيئاً بلا `kit_video`. و`PlaybackBar` **ليست** من الـkit —
> شريطٌ واحد لكل مشغّلٍ بالتطبيق: `AudioPlayerTile` و`AppVideoPlayer` يرسمانه، ومشغّلٌ يبنيه
> المشروع يرسمه كذلك.

```dart
// ── مقطعٌ — ملفٌّ أو رابط https ──
AppVideoPlayer(source: clip.localPath)

// ── مرفقُ فيديو بقائمة مرفقات — يُشغَّل بورقةٍ داخل التطبيق ──
AttachmentPreview.open(context, photo: attachment)   // CapturedPhoto.isVideo

// ── الشريط وحده لمشغّلٍ خاص ──
PlaybackBar(state: state, length: length, onPlay: play, onPause: pause, onSeek: seek)
```

| القرار | لماذا |
|---|---|
| **الصورة بشكلها** | `VideoInfo.aspectRatio` بعد الدوران — مقطعٌ عموديّ لا يُعصر في ١٦:٩ |
| **لمسةٌ على الصورة تشغّل وتوقف** | الهدفُ الأكبر على الشاشة؛ وزرُّ الشريط للدقّة |
| **شريطٌ واحد للصوت والفيديو** | الطولُ المجهول وانقلابُ الوقت بالعربية يُعالَجان بموضعٍ واحد — لا يُكتبان ثانيةً بكل مشغّل |
| **مشغّلٌ لكل ودجة** | مصنعٌ بـget_it كالصوت — يُحرَّر حين تغادر الشجرة |

يُثبَّت بـ`test/video_kit_test.dart` عبر `FakeVideoPlayback`.
