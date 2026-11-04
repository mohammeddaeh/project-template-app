# التخطيط والمسافات

> جزءٌ من دليل الودجات — الفهرس الكامل والاستيراد بـ[`../21_WIDGETS_USAGE.md`](../21_WIDGETS_USAGE.md).

> **Import الوحيد:** `package:app_template/ui/widgets/widgets.dart` — والاستثناءات بـ§DIRECT-IMPORTS بالفهرس.


---

## §9 · AppNavBar — شريط العنوان

> بديل `AppBar` موحَّد. يستنتج زر الرجوع تلقائياً.

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `titleKey` | `String?` | — | مفتاح ترجمة |
| `titleText` | `String?` | — | نص مترجَم مسبقاً |
| `titleWidget` | `Widget?` | — | widget مخصصة (أولوية على الاثنين) |
| `showBackButton` | `bool?` | `null` | `null` = auto من `Navigator.canPop` |
| `onBack` | `VoidCallback?` | — | تجاوز سلوك الرجوع الافتراضي |
| `actions` | `List<Widget>?` | — | أزرار اليمين |
| `bottom` | `PreferredSizeWidget?` | — | TabBar أو شريط إضافي |

**Usage**

```dart
// ── شاشة عادية ──
Scaffold(appBar: AppNavBar(titleKey: LocaleKeys.orderDetails))

// ── شاشة جذر ──
Scaffold(
  appBar: AppNavBar.root(
    titleKey: LocaleKeys.home,
    actions: [
      IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: _open),
    ],
  ),
)

// ── مع TabBar ──
Scaffold(
  appBar: AppNavBar(
    titleKey: LocaleKeys.reports,
    bottom: TabBar(controller: _tabCtrl, tabs: [...]),
  ),
)
```


---

## §10 · AppCard — بطاقة

```dart
final s = context.screen;
AppCard(
  margin: EdgeInsets.symmetric(horizontal: s.gutter, vertical: s.space(8)),
  padding: EdgeInsets.all(s.space(16)),
  elevation: 2,
  child: OrderRowWidget(order: order),
)
```

**ولا `onTap` بـ`AppCard`** — بطاقةٌ تُضغط تُلَفّ، فيبقى الردّ بمكانٍ واحد:

```dart
PressableScale(
  child: GestureDetector(
    onTap: () => context.router.push(OrderDetailsRoute(id: order.id)),
    child: AppCard(child: OrderRowWidget(order: order)),
  ),
)
```


---

## §11 · AppListTile — عنصر قائمة

> بديل `ListTile` يستخدم قيم الثيم الصحيحة.

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `titleKey` / `titleText` | `String?` | مطلوب أحدهما | — |
| `subtitleKey` / `subtitleText` | `String?` | — | سطر ثانٍ |
| `leadingIcon` | `IconData?` | — | أيقونة يسار |
| `leading` | `Widget?` | — | يستبدل `leadingIcon` |
| `trailing` | `Widget?` | — | widget اليمين |
| `onTap` | `VoidCallback?` | — | يُضيف سهم تلقائياً إن لم يكن `trailing` |
| `showDivider` | `bool` | `false` | فاصل أسفل |
| `dense` | `bool` | `false` | يقلل المسافة الرأسية |
| `titleColor` | `Color?` | — | لون العنوان |

**Usage**

```dart
// ── قائمة إعدادات ──
AppListTile(
  titleKey: LocaleKeys.language,
  leadingIcon: Icons.language_rounded,
  trailing: Text(currentLang, style: context.textTheme.bodySmall),
  onTap: _openLanguageSheet,
  showDivider: true,
)

// ── زر حذف ──
AppListTile(
  titleKey: LocaleKeys.logout,
  leadingIcon: Icons.logout_rounded,
  titleColor: context.colors.error,
  onTap: () => context.read<AuthCubit>().logout(),
)
```


---

## §12 · ExpandableSection — قسم قابل للطي

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `titleKey` / `titleText` | `String?` | مطلوب أحدهما | — |
| `child` | `Widget` | مطلوب | المحتوى |
| `subtitleKey` / `subtitleText` | `String?` | — | سطر ثانٍ في الرأس |
| `leading` | `Widget?` | — | أيقونة يسار الرأس |
| `initiallyExpanded` | `bool` | `false` | الحالة الأولية |
| `isExpanded` | `bool?` | `null` | `null` = uncontrolled mode |
| `onToggle` | `VoidCallback?` | — | callback عند التغيير |
| `showDivider` | `bool` | `true` | فاصل أسفل القسم |

**Usage**

```dart
// ── Uncontrolled ──
ExpandableSection(
  titleKey: LocaleKeys.orderItems,
  child: ItemsListWidget(items: order.items),
)

// ── Controlled ──
ExpandableSection(
  titleKey: LocaleKeys.faq,
  isExpanded: _isOpen,
  onToggle: () => setState(() => _isOpen = !_isOpen),
  leading: const Icon(Icons.help_outline_rounded),
  child: const FaqContent(),
)
```


---

## §23 · DividerWidget / DashedDivider / SectionTitle

```dart
// ── فاصل صلب ──
const DividerWidget()
DividerWidget(color: context.colors.borderSubtle, thickness: 1)

// ── فاصل منقط ──
const DashedDivider()
DashedDivider(color: context.colors.dividerSubtle, dashWidth: 6, dashSpace: 3)

// ── عنوان قسم ──
SectionTitle(titleKey: LocaleKeys.contactInfo)
SectionTitle(titleText: 'معلومات التوصيل', action: TextButton(...))
```


---

## §24 · Spacing — مسافات

> **Import مباشر مطلوب:**
> ```dart
> import 'package:app_template/ui/extensions/app_padding_extension.dart';
> ```

```dart
4.widthBox              // SizedBox(width: 4)
16.heightBox            // SizedBox(height: 16)
16.allPadding           // EdgeInsets.all(16)
16.horizontalPadding    // EdgeInsets.symmetric(horizontal: 16)
16.verticalPadding      // EdgeInsets.symmetric(vertical: 16)
```


---

## §27 · GlyphCenter — توسيط بصري للأرقام واللاتيني

> إلزاميّ حول أي رقم/نصّ لاتيني داخل صندوقٍ مقاسُه ثابت (دائرة شارة، مربّع، صفّ بـ`height`). `Center`/`Alignment.center`/`CircleAvatar` تُوسِّط صندوق سطر الخطّ العربي عمودي الثقل، فيبدو الرقم مرتفعاً بلا `GlyphCenter`.

**Usage**

```dart
Container(
  width: 28,
  height: 28,
  alignment: Alignment.center,
  decoration: const BoxDecoration(shape: BoxShape.circle),
  child: GlyphCenter(child: Text('$n', style: context.textTheme.labelSmall)),
)
```

⚠️ **حدّها**: داخل صندوق يلتصق بالنصّ (`Column` بلا ارتفاع ثابت) لا موضع تُزاح إليه — الإزاحة تدفع الحبر خارج حدوده هناك. التفصيل الكامل والسبب البصري: [`lib/CLAUDE.md`](../../../lib/CLAUDE.md) §«توسيط الأرقام».

---

## §35 · `AppOpenContainer` — بطاقةٌ تتمدّد لتصير صفحتها

```dart
AppOpenContainer(
  closedBuilder: (context, open) => OrderCard(order, onTap: open),
  openBuilder: (context, close) => OrderDetailScreen(id: order.id),
)
```

انتقال Material «container transform» (حزمة `animations` الرسمية): العين تتبع
البطاقة وهي تصير الصفحة، فيُقرأ «فتحتُ هذا العنصر». **من قائمةٍ إلى تفاصيل عنصرها
وحده.** ⚠️ الصفحة المفتوحة تُبنى هنا لا بالموجّه — لا رابط عميق يصلها؛ تفاصيلُ يصلها
رابطٌ تُفتح بـ`context.router.push`. المدّة `AppMotion.of(context).slow`.
وزرُّ الرجوع بالنظام (وسحبةُ الرجوع) يُغلقها — `BackButtonListener` بداخلها، فالموجّه
لا يملك مسارَها ولا يصله الحدث وحده.

---

## §36 · `AppStepSwitcher` — خطواتٌ داخل شاشةٍ واحدة

```dart
AppStepSwitcher(
  step: state.step,
  child: switch (state.step) { 0 => EmailStep(), _ => CodeStep() },
)
```

انتقال «shared axis» الأفقي: التقدّم ينزلق باتجاه القراءة والرجوع بعكسه (زيادة
`step` أو نقصه)، والاتجاه يتبع لغة الواجهة. لا يحفظ حالة الخطوة السابقة — مكانُها الـcubit.

## §47 · `AppLargeTitleView` — عنوانٌ كبير ينكمش عند التمرير

```dart
Scaffold(
  body: AppLargeTitleView(
    title: LocaleKeys.orders.tr(),
    actions: [IconButton(icon: const Icon(Icons.search), onPressed: …)],
    body: PaginationBuilder<OrdersCubit, Order>(itemBuilder: …),
  ),
)
```

العنوانُ كبيرٌ أعلى الصفحة، ويصغر حتى يستقرّ بالشريط حين يمرّر القارئ — `SliverAppBar.large`
فوق `NestedScrollView`. **جسدُ `Scaffold` لا `appBar`**: فيبقى للشاشة زرُّها العائم وشريطُها السفليّ.

- [body] يمرّر **بالمتحكّم الأساسيّ**: `ListView` · `CustomScrollView` بلا `controller` · `PaginatedListView` ·
  `PaginationBuilder` (يكشف `NestedScrollView` فوقه وحده — [`14_PAGINATION.md`](../../architecture/14_PAGINATION.md) §5).
- قائمةٌ بـ`controller` خاصّ تمرّر، **لكن العنوان لا ينكمش فوقها**.
- الانكماشُ يتبع الإصبع ولا مدّةَ له، فلا شيء يُطفأ مع «تقليل الحركة».

## §48 · `AppBentoGrid` — بطاقاتٌ بأحجامٍ مختلفة تتراصّ بلا فراغ

```dart
AppBentoGrid(
  tiles: [
    BentoTile(columns: 2, rows: 2, child: HeroCard()),
    BentoTile(child: StatCard(value: '12', labelKey: …)),
    BentoTile(child: StatCard(value: '7', labelKey: …)),
    BentoTile(columns: 2, child: ActivityCard()),
  ],
)
```

- **الأعمدة من عرض الشبكة نفسها لا الشاشة**: كم خليّةً بعرض `AppBentoGrid.minCellWidth` (١٥٠، مضروباً
  بـ`context.screen.size`) تسع — ٢ على الهاتف على الأقلّ، وأكثر كلما اتّسعت، **بلا سطرٍ يسأل عن المقاس**.
  فشبكةٌ داخل عمودٍ ضيّق باللوح لا تُقسَّم بأعمدة الشاشة كلّها فتفيض خلاياها.
- **تتراصّ بأوّل موضعٍ يسعها**، بترتيب `tiles`: صغيرةٌ بعد عريضةٍ لم تجد مكاناً تملأ ما تركته.
  وبطاقةٌ أعرض من الشبكة تُقصّ إلى عرضها.
- **المواضع تتبع اتجاه القراءة** (`PositionedDirectional`).
- الخليّةُ مربّعة افتراضاً (`cellAspectRatio`)، والمسافة `spacing` (١٢).
- ⚠️ **الخليّةُ بارتفاعٍ ثابت** (من عرضها و`cellAspectRatio`): محتوى أطولُ منها يفيض — جرّبها
  بأكبر تكبيرٍ للخطّ. `StatCard` بأيقونته يحتاج خليّةً شبهَ مربّعة؛ و`1.5` تسع الرقمَ ولافتته وحدهما.
- **تُبنى كاملةً لا كسولة** — للوحةٍ أو رئيسية، لا لقائمةٍ طويلة (تلك لـ`PaginationBuilder`).

