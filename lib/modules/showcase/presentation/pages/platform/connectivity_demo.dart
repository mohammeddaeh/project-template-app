import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/platform/connectivity/network_state_monitor.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/state/connectivity/connectivity_cubit.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The connectivity widgets. [ConnectivityDot] shows the app's live state;
/// the overlay and its three phases run on a local, simulated connection —
/// toggling it never touches the real network or the app's cubit.
class ConnectivityDemo extends StatefulWidget {
  const ConnectivityDemo({super.key});

  @override
  State<ConnectivityDemo> createState() => _ConnectivityDemoState();
}

class _ConnectivityDemoState extends State<ConnectivityDemo> {
  final _monitor = _SimulatedMonitor();
  late final ConnectivityCubit _cubit = ConnectivityCubit(_monitor);

  @override
  void dispose() {
    _cubit.close();
    _monitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    Widget hint(String text) => Text(
      text,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colors.textSecondary,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The dots follow the simulation switch below — the same cubit.
        DemoBlock(
          code: 'ConnectivityDot(size: …, bloc: …)',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ConnectivityDot(bloc: _cubit),
              ConnectivityDot(size: 12, bloc: _cubit),
              ConnectivityDot(size: 16, bloc: _cubit),
            ],
          ),
        ),
        DemoBlock(
          code: 'ConnectivityOverlay() — BlocProvider<ConnectivityCubit>',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hint(LocaleKeys.showcaseConnectivityOverlayHint.tr()),
              8.heightBox,
              BlocBuilder<ConnectivityCubit, NetworkState>(
                bloc: _cubit,
                builder: (context, state) => SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    LocaleKeys.showcaseConnectivitySimulate.tr(),
                    style: context.textTheme.bodyMedium,
                  ),
                  value: state.isOffline,
                  onChanged: (offline) => _monitor.set(
                    offline ? NetworkState.offline : NetworkState.online,
                  ),
                ),
              ),
              8.heightBox,
              _Frame(
                children: [
                  Positioned.fill(
                    child: BlocProvider<ConnectivityCubit>.value(
                      value: _cubit,
                      child: const ConnectivityOverlay(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const DemoBlock(
          code: 'SubtleOfflineDot()',
          child: _Frame(children: [SubtleOfflineDot()]),
        ),
        const DemoBlock(
          code: 'OfflineBanner()',
          child: _Frame(children: [OfflineBanner()]),
        ),
        const DemoBlock(
          code: 'ReconnectCountdownChip(seconds: 30)',
          child: _Frame(
            children: [OfflineBanner(), ReconnectCountdownChip(seconds: 30)],
          ),
        ),
      ],
    );
  }
}

/// A miniature screen: the overlay pieces are [Positioned] children meant for
/// a full-screen [Stack], so each one is drawn inside one of these.
class _Frame extends StatelessWidget {
  const _Frame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadius.mdRadius,
    child: SizedBox(
      height: 120,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: context.colors.bgNeutral,
                child: Center(
                  child: Text(
                    LocaleKeys.showcaseScreenContent.tr(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    ),
  );
}

/// A connection the page switches by hand.
class _SimulatedMonitor implements NetworkStateMonitor {
  final _controller = StreamController<NetworkState>.broadcast();
  NetworkState _state = NetworkState.online;

  void set(NetworkState state) {
    _state = state;
    _controller.add(state);
  }

  @override
  NetworkState get currentState => _state;

  @override
  Stream<NetworkState> get stateStream => _controller.stream;

  @override
  void dispose() => _controller.close();
}
