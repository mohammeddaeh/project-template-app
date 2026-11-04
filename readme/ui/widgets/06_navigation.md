# التنقّل والحوارات والإرشاد

> جزءٌ من دليل الودجات — الفهرس الكامل والاستيراد بـ[`../21_WIDGETS_USAGE.md`](../21_WIDGETS_USAGE.md).

> **Import الوحيد:** `package:app_template/ui/widgets/widgets.dart` — والاستثناءات بـ§DIRECT-IMPORTS بالفهرس.


---

## §20 · AppTabBar — شريط تبويبات

```dart
DefaultTabController(
  length: tabs.length,
  child: Scaffold(
    appBar: AppNavBar(
      titleKey: LocaleKeys.reports,
      bottom: AppTabBar(
        tabs: tabs.map((t) => Tab(text: t.label.tr())).toList(),
      ),
    ),
    body: TabBarView(children: tabs.map((t) => t.content).toList()),
  ),
)
```


---

## §21 · Dialogs — حوارات

```dart
// ── تأكيد الحذف (إلزامي قبل كل حذف) ──
AppConfirmDialog.show(
  context,
  titleKey: LocaleKeys.deleteConfirmTitle,
  messageKey: LocaleKeys.deleteConfirmMessage,
  isDestructive: true,
  onConfirm: () => context.read<OrdersCubit>().delete(order.id),
);

// ── تأكيد عادي (await للنتيجة) ──
final confirmed = await AppConfirmDialog.show(
  context,
  titleKey: LocaleKeys.confirmAction,
  messageKey: LocaleKeys.areYouSure,
);
if (confirmed == true && context.mounted) _proceed();

// ── رسالة تحمل رقماً — `messageArgs` ──
// «لديك تغييرات غير مُرسَلة» يُتجاهَل؛ «٣٧ تغييراً لم يصل» لا يُتجاهَل.
// المفتاح بالترجمة يحمل `{count}`.
await AppConfirmDialog.show(
  context,
  titleKey: LocaleKeys.logoutPendingWorkTitle,
  messageKey: LocaleKeys.logoutPendingWorkMessage,
  messageArgs: {'count': '$pendingOperations'},
  isDestructive: true,
);

// ── ورقة سفلية ──
context.showAppBottomSheet(
  title: LocaleKeys.selectDate.tr(),
  child: DatePickerWidget(onSelected: _onDateSelected),
  size: AppBottomSheetSize.large,
);

// ── ورقة بارتفاعات توقّف — تُفتح بـ٤٠٪ وتُسحب إلى ٩٠٪ ──
await AppBottomSheet.show<void>(
  context,
  title: LocaleKeys.history.tr(),
  detents: const [0.4, 0.9],
  child: HistoryList(),
);

// ── فلترة ──
AppFilterSheet(
  filters: activeFilters,
  onApply: (filters) => context.read<OrdersCubit>().applyFilters(filters),
  onClear: () => context.read<OrdersCubit>().clearFilters(),
)
```


**`detents`** (نِسَبٌ تصاعدية من ارتفاع الشاشة): الورقةُ تُفتح بأولاها، وتقف
بأقربها حين تُفلت، ولا تعلو آخرَها — **وإفلاتُها تحت الأولى يُغلقها**. الورقةُ
كلُّها تُسحب (المقبضُ والعنوانُ مع المحتوى)، ومعها يُتجاهل `maxHeightFraction`
و`isScrollable`: ارتفاعُها من التوقّف لا من محتواها. لقائمةٍ تُقرأ لمحةً ثم
تُفتح كاملة؛ ولخياراتٍ قليلة تبقى الورقةُ بمقاس محتواها بلا `detents`.

---

## §32 · GuideOverlay — onboarding coach-mark

> يظلّل الشاشة ويترك فتحةً حول عنصرٍ مُشارٍ إليه بـ`GlobalKey`، مع فقاعة شرح.
> الفتحة تُحسب من `RenderBox` **حالي** للعنصر — يجب أن يكون مبنيّاً فعلاً حين
> يُستدعى `show`. دخول الفقاعة بـ`AppMotion.emphasizedCurve`. يحترم "تقليل
> الحركة" — تظهر كاملةً فوراً بلا دخولٍ متحرّك.

**Usage**

```dart
final addButtonKey = GlobalKey();

IconButton(key: addButtonKey, onPressed: ..., icon: const Icon(Icons.add));

// عند لحظة التعريف (أول تشغيل مثلاً):
await GuideOverlay.show(
  context,
  targetKey: addButtonKey,
  title: LocaleKeys.guideAddTitle.tr(),
  message: LocaleKeys.guideAddMessage.tr(),
  actionLabel: LocaleKeys.guideGotIt.tr(),
);
```

⚠️ **`title`/`message`/`actionLabel` نصوصٌ جاهزة لا مفاتيح** — القرار نفسه
كـ`AppProgress.label` (§26): الودجة عامّة، والنصّ مسؤولية موضع الاستدعاء —
لا نصّ خامٍ افتراضي بالودجة نفسها (يخالف قاعدة الترجمة بـ`lib/CLAUDE.md`).

⬜ **بالمكتبة بلا مستهلكٍ بعد** — مرشَّحٌ لأوّل جولة تعريفٍ بميزةٍ جديدة.

---

## §41 · `AppBottomBar` · `AppTabSwitcher` · `ShellAppearance` — الشريط السفلي

```dart
// القشرة تقرؤهما — الافتراضُ سطرٌ واحد بـShellAppearance:
const ShellAppearance(
  style: AppBottomBarStyle.floating,      // material · floating · expanding · minimal
  transition: AppTabTransition.sharedAxis, // fadeThrough · sharedAxis · fade · none
)

// وتبديلُهما والتطبيق يعمل (شاشة إعدادات · المرآة):
ShellAppearance.notifier.value = ShellAppearance.notifier.value
    .copyWith(style: AppBottomBarStyle.expanding);
```

| الطابع | يرسم |
|---|---|
| `material` | `NavigationBar` بكل اللافتات وحبّةٍ خلف الأيقونة النشطة |
| `floating` | شريطٌ مستديرٌ مرفوعٌ عن الحافّة، والحبّة تنزلق بين التبويبات |
| `expanding` | أيقوناتٌ وحدها، والنشطُ يتمدّد حبّةً بلافتته |
| `minimal` | أيقوناتٌ وحدها ونقطةٌ تحت النشط — واللافتة لقارئ الشاشة |

كلُّ طابعٍ يحشو شريطَ إيماءات النظام تحته، ويُظهر `NavItem.badgeCount` (`0` نقطة)،
وكلُّ تبويبٍ زرٌّ مسمّى لقارئ الشاشة ولو لم تُرسم لافتته. و`AppTabSwitcher` يلفّ
`IndexedStack` فلا يفقد تبويبٌ حالته، والاتجاه بـ`sharedAxis` يتبع لغة الواجهة.
**والجسدُ ينتهي عند الشريط لا خلفه** (R15).

**`translucent: true`** — الشريطُ بلونٍ نافذٍ قليلاً (`context.colors.bgTranslucent`،
٨٢٪ من سطح البطاقة)، والمحتوى يمرّ تحته فيُرى من خلاله. **لونٌ لا تمويه**: لا
يكلّف إطاراً، وتباينُه يُفحص لكل بالت فوق أسوأ ما يمرّ تحته (F07).

```dart
const ShellAppearance(style: AppBottomBarStyle.floating, translucent: true)
```

⚠️ **وهو الاستثناءُ الوحيد لـR15**: شاشةُ تبويبٍ تحدّد `padding` بنفسها أو تثبّت
زرّاً بأسفلها تضيف `context.bottomContentInset`، وإلا اختفى آخرُها خلف الشريط.
