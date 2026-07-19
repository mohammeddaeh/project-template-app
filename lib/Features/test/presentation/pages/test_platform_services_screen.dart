import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/haptics/haptic_service.dart';
import 'package:app_template/core/platform/lifecycle/app_lifecycle_service.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

@RoutePage()
class TestPlatformServicesScreen extends StatelessWidget {
  const TestPlatformServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.testPlatformServicesDemoTitle.tr()),
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Optional Platform Services ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SectionTitle(titleKey: LocaleKeys.optionalPlatformServices),
          ),
          _HapticsCard(),
          _ClipboardCard(),
          _SimpleServiceCard(
            icon: Icons.share_outlined,
            name: 'ShareService',
            flag: 'shareSheet',
            enabled: AppFeatures.shareSheet,
          ),
          _SimpleServiceCard(
            icon: Icons.folder_open_outlined,
            name: 'FileService',
            flag: 'fileOperations',
            enabled: AppFeatures.fileOperations,
          ),
          _SimpleServiceCard(
            icon: Icons.fingerprint_outlined,
            name: 'BiometricsService',
            flag: 'biometrics',
            enabled: AppFeatures.biometrics,
          ),
          _LifecycleCard(),
          const SizedBox(height: 8),

          // ── Optional Modules ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SectionTitle(titleKey: LocaleKeys.optionalModules),
          ),
          _SimpleServiceCard(
            icon: Icons.sync_outlined,
            name: 'offlineSync',
            flag: 'offlineSync',
            enabled: AppFeatures.offlineSync,
          ),
          _SimpleServiceCard(
            icon: Icons.devices_outlined,
            name: 'multiDevice',
            flag: 'multiDevice',
            enabled: AppFeatures.multiDevice,
          ),
          _SimpleServiceCard(
            icon: Icons.notifications_outlined,
            name: 'localNotifications',
            flag: 'localNotifications',
            enabled: AppFeatures.localNotifications,
          ),
          const SizedBox(height: 8),

          // ── Firebase Modules ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SectionTitle(titleKey: LocaleKeys.firebaseModules),
          ),
          _SimpleServiceCard(
            icon: Icons.bug_report_outlined,
            name: 'crashReporting',
            flag: 'crashReporting',
            enabled: AppFeatures.crashReporting,
          ),
          _SimpleServiceCard(
            icon: Icons.bar_chart_outlined,
            name: 'analytics',
            flag: 'analytics',
            enabled: AppFeatures.analytics,
          ),
          _SimpleServiceCard(
            icon: Icons.cloud_sync_outlined,
            name: 'remoteConfig',
            flag: 'remoteConfig',
            enabled: AppFeatures.remoteConfig,
          ),
          const SizedBox(height: 8),

          // ── Platform Permissions ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SectionTitle(titleKey: LocaleKeys.platformPermissions),
          ),
          const _PermissionsGrid(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Haptics Card ───────────────────────────────────────────────────────────────

class _HapticsCard extends StatelessWidget {
  _HapticsCard();

  final bool _enabled = AppFeatures.haptics &&
      GetIt.I.isRegistered<HapticService>();

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements
    context.locale;
    final haptics = _enabled ? GetIt.I<HapticService>() : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ServiceHeader(
            icon: Icons.vibration_rounded,
            name: 'HapticService',
            flag: 'haptics',
            enabled: _enabled,
          ),
          if (_enabled) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HapticButton(
                  label: 'light()',
                  onTap: () => haptics!.light(),
                ),
                _HapticButton(
                  label: 'medium()',
                  onTap: () => haptics!.medium(),
                ),
                _HapticButton(
                  label: 'heavy()',
                  onTap: () => haptics!.heavy(),
                ),
                _HapticButton(
                  label: 'selection()',
                  onTap: () => haptics!.selection(),
                ),
              ],
            ),
          ] else
            _DisabledHint(flag: 'haptics'),
        ],
      ),
    );
  }
}

class _HapticButton extends StatelessWidget {
  const _HapticButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: context.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}

// ── Clipboard Card ─────────────────────────────────────────────────────────────

class _ClipboardCard extends StatelessWidget {
  const _ClipboardCard();

  static const bool _enabled = AppFeatures.clipboard;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements
    context.locale;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ServiceHeader(
            icon: Icons.content_copy_outlined,
            name: 'ClipboardService',
            flag: 'clipboard',
            enabled: _enabled,
          ),
          if (_enabled) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  const ClipboardData(text: 'Hello from app_template!'),
                );
                if (!context.mounted) return;
                context.feedback.toast(LocaleKeys.codeCopied.tr());
              },
              icon: const Icon(Icons.copy, size: 16),
              label: Text(LocaleKeys.testService.tr()),
            ),
          ] else
            _DisabledHint(flag: 'clipboard'),
        ],
      ),
    );
  }
}

// ── Lifecycle Card ─────────────────────────────────────────────────────────────

class _LifecycleCard extends StatelessWidget {
  _LifecycleCard();

  final bool _enabled = AppFeatures.appLifecycle &&
      GetIt.I.isRegistered<AppLifecycleService>();

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements
    context.locale;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ServiceHeader(
            icon: Icons.play_circle_outline_rounded,
            name: 'AppLifecycleService',
            flag: 'appLifecycle',
            enabled: _enabled,
          ),
          if (_enabled) ...[
            const SizedBox(height: 12),
            StreamBuilder<AppLifecycleState>(
              stream: GetIt.I<AppLifecycleService>().stateStream,
              initialData: GetIt.I<AppLifecycleService>().currentState,
              builder: (context, snapshot) {
                final state = snapshot.data ?? AppLifecycleState.resumed;
                final (icon, color) = _lifecycleStyle(context, state);
                return Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      state.name,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else
            _DisabledHint(flag: 'appLifecycle'),
        ],
      ),
    );
  }

  (IconData, Color) _lifecycleStyle(
      BuildContext context, AppLifecycleState state) =>
      switch (state) {
        AppLifecycleState.resumed => (
            Icons.play_arrow_rounded,
            Colors.green.shade600,
          ),
        AppLifecycleState.paused => (
            Icons.pause_rounded,
            Colors.orange.shade700,
          ),
        AppLifecycleState.inactive => (
            Icons.bedtime_outlined,
            context.colorScheme.primary,
          ),
        AppLifecycleState.detached => (
            Icons.stop_rounded,
            context.colorScheme.outline,
          ),
        AppLifecycleState.hidden => (
            Icons.visibility_off_outlined,
            context.colorScheme.outline,
          ),
      };
}

// ── Simple Service Card ────────────────────────────────────────────────────────

class _SimpleServiceCard extends StatelessWidget {
  const _SimpleServiceCard({
    required this.icon,
    required this.name,
    required this.flag,
    required this.enabled,
  });

  final IconData icon;
  final String name;
  final String flag;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements
    context.locale;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ServiceHeader(
            icon: icon,
            name: name,
            flag: flag,
            enabled: enabled,
          ),
          if (!enabled) _DisabledHint(flag: flag),
        ],
      ),
    );
  }
}

// ── Service Header ─────────────────────────────────────────────────────────────

class _ServiceHeader extends StatelessWidget {
  const _ServiceHeader({
    required this.icon,
    required this.name,
    required this.flag,
    required this.enabled,
  });

  final IconData icon;
  final String name;
  final String flag;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements
    context.locale;
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: enabled
              ? context.colorScheme.primary
              : context.colorScheme.outline,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: context.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Chip(
          label: Text(
            enabled
                ? LocaleKeys.serviceEnabled.tr()
                : LocaleKeys.serviceDisabled.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: enabled
                  ? Colors.green.shade700
                  : context.colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: enabled
              ? Colors.green.withValues(alpha: 0.12)
              : context.colorScheme.surfaceContainerHighest,
          side: BorderSide.none,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

// ── Disabled Hint ──────────────────────────────────────────────────────────────

class _DisabledHint extends StatelessWidget {
  const _DisabledHint({required this.flag});

  final String flag;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements
    context.locale;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        LocaleKeys.enableHint.tr(namedArgs: {'flag': flag}),
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.outline,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ── Permissions Grid ───────────────────────────────────────────────────────────

class _PermissionsGrid extends StatelessWidget {
  const _PermissionsGrid();

  static const _permissions = <(String, IconData, bool)>[
    ('camera', Icons.camera_alt_outlined, AppFeatures.camera),
    ('microphone', Icons.mic_outlined, AppFeatures.microphone),
    ('location', Icons.location_on_outlined, AppFeatures.location),
    ('photos', Icons.photo_library_outlined, AppFeatures.photos),
    ('fileStorage', Icons.folder_outlined, AppFeatures.fileStorage),
    ('contacts', Icons.contacts_outlined, AppFeatures.contacts),
    ('bluetooth', Icons.bluetooth_outlined, AppFeatures.bluetooth),
    ('pushNotifications', Icons.notifications_outlined,
        AppFeatures.pushNotifications),
  ];

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements
    context.locale;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _permissions.map((p) {
          final (name, icon, enabled) = p;
          return _PermissionChip(
            name: name,
            icon: icon,
            enabled: enabled,
          );
        }).toList(),
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({
    required this.name,
    required this.icon,
    required this.enabled,
  });

  final String name;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements
    context.locale;
    final color =
        enabled ? Colors.green.shade700 : context.colorScheme.outline;
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        name,
        style: context.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: color,
        ),
      ),
      backgroundColor: enabled
          ? Colors.green.withValues(alpha: 0.10)
          : context.colorScheme.surfaceContainerHighest,
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
