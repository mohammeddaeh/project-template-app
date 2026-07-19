import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/extensions/app_padding_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

@RoutePage()
class TestPredictiveBackDemoScreen extends StatelessWidget {
  const TestPredictiveBackDemoScreen({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleKeys.testPredictiveBackTitle.tr(),
          style: context.textTheme.headlineLarge,
        ),
      ),
      body: ListView(
        padding: 16.allPadding,
        children: [
          _SetupBanner(),
          24.heightBox,
          _ScenarioCard(
            icon: Icons.swipe_left_rounded,
            title: LocaleKeys.backFree.tr(),
            description: LocaleKeys.backFreeDesc.tr(),
            color: context.colorScheme.primary,
            onTap: () => _push(context, const _FreeBackPage()),
          ),
          12.heightBox,
          _ScenarioCard(
            icon: Icons.warning_amber_rounded,
            title: LocaleKeys.backConfirm.tr(),
            description: LocaleKeys.backConfirmDesc.tr(),
            color: context.colorScheme.tertiary,
            onTap: () => _push(context, const _ConfirmBackPage()),
          ),
          12.heightBox,
          _ScenarioCard(
            icon: Icons.edit_note_outlined,
            title: LocaleKeys.backDirtyGuard.tr(),
            description: LocaleKeys.backDirtyGuardDesc.tr(),
            color: context.colorScheme.secondary,
            onTap: () => _push(context, const _DirtyGuardPage()),
          ),
          32.heightBox,
        ],
      ),
    );
  }
}

// ── Setup Banner ──────────────────────────────────────────────────────────────

class _SetupBanner extends StatelessWidget {
  const _SetupBanner();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 22),
          12.widthBox,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.manifestEnabled.tr(),
                  style: context.textTheme.headlineSmall,
                ),
                6.heightBox,
                Text(
                  'android:enableOnBackInvokedCallback="true"',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scenario Card ─────────────────────────────────────────────────────────────

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              16.widthBox,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textTheme.headlineSmall),
                    4.heightBox,
                    Text(
                      description,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              8.widthBox,
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Demo Sub-Pages — pushed via Navigator (internal demo only, no AutoRoute)
// ══════════════════════════════════════════════════════════════════════════════

// ── Page 1: Free Back (canPop: true) ─────────────────────────────────────────

class _FreeBackPage extends StatelessWidget {
  const _FreeBackPage();

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.backFree.tr())),
      body: Center(
        child: Padding(
          padding: 24.allPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swipe_left_rounded,
                size: 80,
                color: context.colorScheme.primary.withValues(alpha: 0.5),
              ),
              24.heightBox,
              Text(
                LocaleKeys.pressBackToTest.tr(),
                style: context.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              16.heightBox,
              Text(
                LocaleKeys.backFreeDesc.tr(),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              32.heightBox,
              Chip(
                avatar: const Icon(Icons.android_rounded, size: 16),
                label: Text(
                  'canPop: true',
                  style: context.textTheme.labelLarge?.copyWith(fontFamily: 'monospace'),
                ),
                backgroundColor: context.colorScheme.primaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page 2: Confirm Back (canPop: false + dialog) ────────────────────────────

class _ConfirmBackPage extends StatefulWidget {
  const _ConfirmBackPage();

  @override
  State<_ConfirmBackPage> createState() => _ConfirmBackPageState();
}

class _ConfirmBackPageState extends State<_ConfirmBackPage> {
  int _attempts = 0;
  int _confirmed = 0;

  Future<void> _handleBack(bool didPop) async {
    if (didPop) return;
    setState(() => _attempts++);
    final ok = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.exitAppTitle,
      messageKey: LocaleKeys.exitAppMessage,
      confirmKey: LocaleKeys.confirm,
      cancelKey: LocaleKeys.cancel,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _confirmed++);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handleBack(didPop),
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleKeys.backConfirm.tr()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBack(false),
          ),
        ),
        body: Center(
          child: Padding(
            padding: 24.allPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: context.colorScheme.tertiary.withValues(alpha: 0.5),
                ),
                24.heightBox,
                Text(
                  LocaleKeys.pressBackToTest.tr(),
                  style: context.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                16.heightBox,
                Text(
                  LocaleKeys.backConfirmDesc.tr(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                32.heightBox,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatBadge(
                      label: 'Attempts',
                      value: _attempts,
                      color: context.colorScheme.error,
                    ),
                    48.widthBox,
                    _StatBadge(
                      label: 'Confirmed',
                      value: _confirmed,
                      color: Colors.green.shade600,
                    ),
                  ],
                ),
                32.heightBox,
                Chip(
                  label: Text(
                    'canPop: false',
                    style: context.textTheme.labelLarge?.copyWith(fontFamily: 'monospace'),
                  ),
                  backgroundColor: context.colorScheme.tertiaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page 3: Dirty Guard (canPop: !_dirty) ────────────────────────────────────

class _DirtyGuardPage extends StatefulWidget {
  const _DirtyGuardPage();

  @override
  State<_DirtyGuardPage> createState() => _DirtyGuardPageState();
}

class _DirtyGuardPageState extends State<_DirtyGuardPage> {
  final _ctrl = TextEditingController();
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final isDirty = _ctrl.text.isNotEmpty;
      if (isDirty != _dirty) setState(() => _dirty = isDirty);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleBack(bool didPop) async {
    if (didPop) return;
    final ok = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.discardChangesTitle,
      messageKey: LocaleKeys.discardChangesMessage,
      confirmKey: LocaleKeys.confirm,
      cancelKey: LocaleKeys.cancel,
      isDestructive: true,
    );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) => _handleBack(didPop),
      child: Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.backDirtyGuard.tr())),
        body: Padding(
          padding: 24.allPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dynamic status chip
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SizeTransition(sizeFactor: anim, child: child),
                  ),
                  child: _dirty
                      ? Chip(
                          key: const ValueKey('dirty'),
                          avatar: Icon(
                            Icons.lock_rounded,
                            size: 16,
                            color: context.colorScheme.onErrorContainer,
                          ),
                          label: Text(
                            LocaleKeys.formChanged.tr(),
                            style: context.textTheme.labelLarge?.copyWith(
                              color: context.colorScheme.onErrorContainer,
                            ),
                          ),
                          backgroundColor: context.colorScheme.errorContainer,
                        )
                      : Chip(
                          key: const ValueKey('clean'),
                          avatar: Icon(
                            Icons.lock_open_rounded,
                            size: 16,
                            color: context.colorScheme.onPrimaryContainer,
                          ),
                          label: Text(
                            LocaleKeys.formUnchanged.tr(),
                            style: context.textTheme.labelLarge?.copyWith(
                              color: context.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          backgroundColor: context.colorScheme.primaryContainer,
                        ),
                ),
              ),
              24.heightBox,
              Text(
                LocaleKeys.editToMakeDirty.tr(),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              20.heightBox,
              TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  labelText: LocaleKeys.fullName.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.edit_outlined),
                ),
              ),
              20.heightBox,
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Chip(
                    key: ValueKey(_dirty),
                    label: Text(
                      'canPop: ${!_dirty}',
                      style: context.textTheme.labelLarge?.copyWith(fontFamily: 'monospace'),
                    ),
                    backgroundColor: _dirty
                        ? context.colorScheme.errorContainer
                        : context.colorScheme.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat Badge ────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: context.textTheme.headlineLarge?.copyWith(
            color: color,
            fontSize: 40,
            fontWeight: FontWeight.w800,
          ),
        ),
        4.heightBox,
        Text(label, style: context.textTheme.bodySmall),
      ],
    );
  }
}
