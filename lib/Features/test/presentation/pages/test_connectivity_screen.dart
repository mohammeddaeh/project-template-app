import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:app_template/core/platform/connectivity/network_state.dart';
import 'package:app_template/core/platform/connectivity/network_state_monitor.dart';
import 'package:app_template/core/platform/lifecycle/app_lifecycle_service.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

@RoutePage()
class TestConnectivityScreen extends StatefulWidget {
  const TestConnectivityScreen({super.key});

  @override
  State<TestConnectivityScreen> createState() => _TestConnectivityScreenState();
}

class _TestConnectivityScreenState extends State<TestConnectivityScreen> {
  late final NetworkStateMonitor _networkMonitor;
  late final AppLifecycleService _lifecycleService;

  StreamSubscription<NetworkState>? _networkSub;
  StreamSubscription<AppLifecycleState>? _lifecycleSub;

  NetworkState _networkState = NetworkState.unknown;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  final List<_LogEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _networkMonitor = GetIt.I<NetworkStateMonitor>();
    _lifecycleService = GetIt.I<AppLifecycleService>();

    _networkState = _networkMonitor.currentState;
    _lifecycleState = _lifecycleService.currentState;

    _networkSub = _networkMonitor.stateStream.listen((state) {
      setState(() {
        _networkState = state;
        _addEvent('network', state.name);
      });
    });

    _lifecycleSub = _lifecycleService.stateStream.listen((state) {
      setState(() {
        _lifecycleState = state;
        _addEvent('lifecycle', state.name);
      });
    });
  }

  void _addEvent(String type, String value) {
    _events.insert(0, _LogEvent(type: type, value: value, time: DateTime.now()));
    if (_events.length > 50) _events.removeLast();
  }

  @override
  void dispose() {
    _networkSub?.cancel();
    _lifecycleSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.testConnectivityTitle.tr()),
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Network State Card ──────────────────────────────────────────────
          SliverToBoxAdapter(child: _NetworkStateCard(state: _networkState)),

          // ── App Lifecycle Card ──────────────────────────────────────────────
          SliverToBoxAdapter(child: _AppLifecycleCard(state: _lifecycleState)),

          // ── Usage Pattern ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SectionTitle(titleKey: LocaleKeys.usagePattern),
            ),
          ),
          const SliverToBoxAdapter(child: _CodePatternSection()),

          // ── Event Log header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SectionTitle(
                titleKey: LocaleKeys.eventLog,
                trailing: TextButton.icon(
                  onPressed: () => setState(() => _events.clear()),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: Text(LocaleKeys.clearLog.tr()),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
          ),

          // ── Event Log entries ────────────────────────────────────────────────
          if (_events.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  LocaleKeys.noEventsYet.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.outline,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) =>
                    _EventRow(event: _events[index]),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Network State Card ─────────────────────────────────────────────────────────

class _NetworkStateCard extends StatelessWidget {
  const _NetworkStateCard({required this.state});

  final NetworkState state;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements
    context.locale;
    final (color, icon, label) = switch (state) {
      NetworkState.online => (
          Colors.green.shade600,
          Icons.wifi_rounded,
          'online',
        ),
      NetworkState.offline => (
          context.colorScheme.error,
          Icons.wifi_off_rounded,
          'offline',
        ),
      NetworkState.unknown => (
          Colors.orange.shade600,
          Icons.wifi_find_outlined,
          'unknown',
        ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(titleKey: LocaleKeys.networkState),
          AppCard(
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'NetworkState.${state.name}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    label,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: color.withValues(alpha: 0.12),
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── App Lifecycle Card ─────────────────────────────────────────────────────────

class _AppLifecycleCard extends StatelessWidget {
  const _AppLifecycleCard({required this.state});

  final AppLifecycleState state;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements
    context.locale;
    final (icon, color) = switch (state) {
      AppLifecycleState.resumed => (Icons.play_arrow_rounded, Colors.green.shade600),
      AppLifecycleState.paused => (Icons.pause_rounded, Colors.orange.shade700),
      AppLifecycleState.inactive => (Icons.bedtime_outlined, context.colorScheme.primary),
      AppLifecycleState.detached => (Icons.stop_rounded, context.colorScheme.outline),
      AppLifecycleState.hidden => (Icons.visibility_off_outlined, context.colorScheme.outline),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(titleKey: LocaleKeys.appLifecycle),
          AppCard(
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'AppLifecycleState.${state.name}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
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

// ── Code Pattern Section ───────────────────────────────────────────────────────

class _CodePatternSection extends StatelessWidget {
  const _CodePatternSection();

  static const _networkSnippet = '''// In a Cubit:
_sub = getIt<NetworkStateMonitor>()
    .stateStream
    .listen((state) {
  if (state.isOffline) emit(MyState.offline());
  if (state.isOnline)  loadData();
});''';

  static const _lifecycleSnippet = '''// In a Cubit:
_sub = getIt<AppLifecycleService>()
    .stateStream
    .listen((state) {
  if (state == AppLifecycleState.resumed) _startPolling();
  if (state == AppLifecycleState.paused)  _stopPolling();
});''';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _CodeBlock(
            label: 'NetworkStateMonitor',
            code: _networkSnippet,
          ),
          const SizedBox(height: 8),
          _CodeBlock(
            label: 'AppLifecycleService',
            code: _lifecycleSnippet,
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.label, required this.code});

  final String label;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: context.colorScheme.outline.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: context.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (!context.mounted) return;
                    context.feedback.toast(LocaleKeys.codeCopied.tr());
                  },
                  icon: const Icon(Icons.copy, size: 14),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              code,
              style: context.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: context.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event Row ──────────────────────────────────────────────────────────────────

class _LogEvent {
  const _LogEvent({
    required this.type,
    required this.value,
    required this.time,
  });

  final String type;
  final String value;
  final DateTime time;
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final _LogEvent event;

  @override
  Widget build(BuildContext context) {
    final isNetwork = event.type == 'network';
    final badgeColor =
        isNetwork ? context.colorScheme.primary : context.colorScheme.tertiary;
    final timeStr =
        '${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')}:${event.time.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            timeStr,
            style: context.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: context.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.type,
              style: context.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: badgeColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.value,
              style: context.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
