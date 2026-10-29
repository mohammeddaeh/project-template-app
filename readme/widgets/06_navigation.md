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

// ── فلترة ──
AppFilterSheet(
  filters: activeFilters,
  onApply: (filters) => context.read<OrdersCubit>().applyFilters(filters),
  onClear: () => context.read<OrdersCubit>().clearFilters(),
)
```


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
