import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/Features/test/presentation/widgets/demo_card.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';

@RoutePage()
class TestDashboardScreen extends StatefulWidget {
  const TestDashboardScreen({super.key});

  @override
  State<TestDashboardScreen> createState() => _TestDashboardScreenState();
}

class _TestDashboardScreenState extends State<TestDashboardScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    final scheme = context.colorScheme;

    final cards = [
      _CardData(
        icon: Icons.widgets_outlined,
        titleKey: LocaleKeys.widgetCatalogTitle,
        subtitleKey: LocaleKeys.widgetCatalogSubtitle,
        color: scheme.primary,
        heroTag: 'demo_widgets',
        onTap: () => context.router.push(const WidgetLibraryDemoRoute()),
      ),
      _CardData(
        icon: Icons.edit_note_outlined,
        titleKey: LocaleKeys.testFormsDemoTitle,
        subtitleKey: LocaleKeys.testFormsSubtitle,
        color: scheme.secondary,
        heroTag: 'demo_forms',
        onTap: () => context.router.push(const TestFormsDemoRoute()),
      ),
      _CardData(
        icon: Icons.layers_outlined,
        titleKey: LocaleKeys.testStatesDemoTitle,
        subtitleKey: LocaleKeys.testStatesSubtitle,
        color: scheme.tertiary,
        heroTag: 'demo_states',
        onTap: () => context.router.push(const TestStatesDemoRoute()),
      ),
      _CardData(
        icon: Icons.palette_outlined,
        titleKey: LocaleKeys.testThemeDemoTitle,
        subtitleKey: LocaleKeys.testThemeSubtitle,
        color: scheme.error,
        heroTag: 'demo_theme',
        onTap: () => context.router.push(const TestThemeDemoRoute()),
      ),
      _CardData(
        icon: Icons.tune_outlined,
        titleKey: LocaleKeys.testSettingsDemoTitle,
        subtitleKey: LocaleKeys.testSettingsSubtitle,
        color: scheme.scrim,
        heroTag: 'demo_settings',
        onTap: () => context.router.push(const TestSettingsDemoRoute()),
      ),
      _CardData(
        icon: Icons.checklist_rtl_outlined,
        titleKey: LocaleKeys.testFormValidationTitle,
        subtitleKey: LocaleKeys.testFormValidationSubtitle,
        color: scheme.tertiaryContainer,
        heroTag: 'demo_form_validation',
        onTap: () => context.router.push(const TestFormValidationRoute()),
      ),
      _CardData(
        icon: Icons.view_list_rounded,
        titleKey: LocaleKeys.testPaginationDemoTitle,
        subtitleKey: LocaleKeys.testPaginationSubtitle,
        color: scheme.primaryContainer,
        heroTag: 'demo_pagination',
        onTap: () => context.router.push(const TestPaginationDemoRoute()),
      ),
      _CardData(
        icon: Icons.table_rows_outlined,
        titleKey: LocaleKeys.testCrudDemoTitle,
        subtitleKey: LocaleKeys.testCrudSubtitle,
        color: scheme.secondaryContainer,
        heroTag: 'demo_crud',
        onTap: () => context.router.push(const TestCrudDemoRoute()),
      ),
      _CardData(
        icon: Icons.swipe_left_rounded,
        titleKey: LocaleKeys.testPredictiveBackTitle,
        subtitleKey: LocaleKeys.testPredictiveBackSubtitle,
        color: scheme.inversePrimary,
        heroTag: 'demo_predictive_back',
        onTap: () => context.router.push(const TestPredictiveBackDemoRoute()),
      ),
      _CardData(
        icon: Icons.vibration_rounded,
        titleKey: LocaleKeys.testHapticsDemoTitle,
        subtitleKey: LocaleKeys.testHapticsSubtitle,
        color: scheme.errorContainer,
        heroTag: 'demo_haptics',
        onTap: () => context.router.push(const TestHapticsDemoRoute()),
      ),
      _CardData(
        icon: Icons.auto_awesome_outlined,
        titleKey: LocaleKeys.testFeatureWizardTitle,
        subtitleKey: LocaleKeys.testFeatureWizardSubtitle,
        color: scheme.tertiaryFixed,
        heroTag: 'demo_feature_wizard',
        onTap: () => context.router.push(const TestFeatureWizardRoute()),
      ),
      _CardData(
        icon: Icons.stacked_bar_chart_rounded,
        titleKey: LocaleKeys.testNavStackTitle,
        subtitleKey: LocaleKeys.testNavStackSubtitle,
        color: scheme.surfaceContainerHighest,
        heroTag: 'demo_nav_stack',
        onTap: () => context.router.push(const TestNavStackRoute()),
      ),
      _CardData(
        icon: Icons.electrical_services_outlined,
        titleKey: LocaleKeys.testPlatformServicesDemoTitle,
        subtitleKey: LocaleKeys.testPlatformServicesSubtitle,
        color: scheme.primary,
        heroTag: 'demo_platform_services',
        onTap: () => context.router.push(const TestPlatformServicesRoute()),
      ),
      _CardData(
        icon: Icons.error_outline_rounded,
        titleKey: LocaleKeys.testFailureDemoTitle,
        subtitleKey: LocaleKeys.testFailureDemoSubtitle,
        color: scheme.error,
        heroTag: 'demo_failures',
        onTap: () => context.router.push(const TestFailureDemoRoute()),
      ),
      _CardData(
        icon: Icons.wifi_tethering_rounded,
        titleKey: LocaleKeys.testConnectivityTitle,
        subtitleKey: LocaleKeys.testConnectivitySubtitle,
        color: scheme.tertiary,
        heroTag: 'demo_connectivity',
        onTap: () => context.router.push(const TestConnectivityRoute()),
      ),
      _CardData(
        icon: Icons.cloud_sync_outlined,
        titleKey: LocaleKeys.testSyncQueueTitle,
        subtitleKey: LocaleKeys.testSyncQueueSubtitle,
        color: scheme.secondary,
        heroTag: 'demo_sync_queue',
        onTap: () => context.router.push(const TestSyncQueueRoute()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          LocaleKeys.testDashboard.tr(),
          style: context.textTheme.headlineLarge,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: [
            for (int i = 0; i < cards.length; i++)
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + i * 80),
                tween: Tween(begin: 0.0, end: _visible ? 1.0 : 0.0),
                curve: Curves.easeOut,
                builder: (_, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - value)),
                    child: child,
                  ),
                ),
                child: DemoCard(
                  icon: cards[i].icon,
                  title: cards[i].titleKey.tr(),
                  subtitle: cards[i].subtitleKey.tr(),
                  color: cards[i].color,
                  heroTag: cards[i].heroTag,
                  onTap: cards[i].onTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardData {
  const _CardData({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.color,
    required this.heroTag,
    required this.onTap,
  });

  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final Color color;
  final String heroTag;
  final VoidCallback onTap;
}
