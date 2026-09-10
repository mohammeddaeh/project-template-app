import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/modules/in_app_updates/data/app_update_settings_store.dart';
import 'package:app_template/modules/in_app_updates/domain/app_update_settings.dart';
import 'package:app_template/modules/in_app_updates/in_app_updates_module.dart';

/// Checks the local snapshot on mount and again whenever a sync refreshes it.
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  StreamSubscription<AppUpdateSettings>? _subscription;

  @override
  void initState() {
    super.initState();
    final di = GetIt.instance;
    if (!di.isRegistered<AppUpdateSettingsStore>()) return;
    final store = di<AppUpdateSettingsStore>();
    _subscription = store.changes.listen((_) => _check());
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (!mounted) return;
    await InAppUpdatesModule.checkAndPrompt(context);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
