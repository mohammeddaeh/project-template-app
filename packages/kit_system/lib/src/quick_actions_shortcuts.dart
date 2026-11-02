import 'dart:async';

import 'package:kit_contracts/kit_contracts.dart';
import 'package:quick_actions/quick_actions.dart';

import 'kit_log.dart';

/// [AppShortcuts] over `quick_actions` — Android launcher shortcuts, iOS home
/// screen quick actions.
class QuickActionsShortcuts implements AppShortcuts {
  QuickActionsShortcuts([QuickActions? engine])
    : _actions = engine ?? const QuickActions() {
    _launches = StreamController<String>.broadcast(onListen: _flush);
    // Initialised at once: a cold start through a shortcut is delivered here,
    // before any screen exists to listen.
    unawaited(
      _actions.initialize(_onLaunch).catchError((Object e, StackTrace s) {
        kitLog(e, s);
      }),
    );
  }

  final QuickActions _actions;
  late final StreamController<String> _launches;
  String? _pending;

  /// Android delivers a cold start twice — once when the plugin initialises,
  /// again through `onNewIntent` — and a second push stacks the page twice.
  /// A tap is never repeated this fast, so a repeat inside the window is the
  /// same launch.
  static const _sameLaunch = Duration(seconds: 2);
  String? _lastPath;
  DateTime? _lastAt;

  void _onLaunch(String path) {
    final now = DateTime.now();
    final last = _lastAt;
    if (path == _lastPath &&
        last != null &&
        now.difference(last) < _sameLaunch) {
      return;
    }
    _lastPath = path;
    _lastAt = now;
    if (_launches.hasListener) {
      _launches.add(path);
    } else {
      _pending = path;
    }
  }

  void _flush() {
    final pending = _pending;
    _pending = null;
    if (pending != null) scheduleMicrotask(() => _launches.add(pending));
  }

  @override
  Future<void> setShortcuts(List<AppShortcut> shortcuts) async {
    try {
      await _actions.setShortcutItems([
        for (final s in shortcuts)
          ShortcutItem(type: s.path, localizedTitle: s.title, icon: s.icon),
      ]);
    } catch (e, s) {
      kitLog(e, s);
    }
  }

  @override
  Stream<String> get launches => _launches.stream;
}
