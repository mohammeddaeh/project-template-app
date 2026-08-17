import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:app_template/core/infra/session/auth_event_bus.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/access_control/data/models/access_control_models.dart';
import 'package:app_template/modules/access_control/domain/ability_set.dart';
import 'package:app_template/modules/access_control/domain/access_control_repository.dart';

/// Holds the current [AbilitySet] and keeps it in step with who is signed in.
///
/// Every gate in the app reads this one object — `Can`, `context.can()`, the
/// route guard — so there is a single answer to "what may this user do" and a
/// single place it changes.
///
/// ## Why it listens to the session rather than to the login screen
///
/// The set is *per account*, so it must be discarded the moment the account
/// does. Hooking the login feature would work and would put a module import
/// inside `Features/auth/`; hooking [SessionRepository.tokenStream] gets the
/// same two events — a token appeared, a token was cleared — from the layer a
/// module is allowed to depend on.
///
/// It also gets one the login screen could not give it: a 401 that clears the
/// session mid-use. Without that, a revoked session would keep its abilities in
/// memory and keep drawing controls that every request refuses.
///
/// ## The cache is a bridge, never the source of truth
///
/// The set is written to [StorageService] on every refresh and restored before
/// the first frame. Without it, a relaunch with a valid token starts at
/// [AbilitySet.none] — every gate shut — and the user watches their own
/// controls appear a moment later, which reads as a broken app. The server is
/// re-read immediately either way, so a stale cache lives for one network
/// round trip.
class AbilitiesStore {
  AbilitiesStore(this._repository, this._storage, this._session);

  final AccessControlRepository _repository;
  final StorageService _storage;
  final SessionRepository _session;

  static const String _tag = 'ACCESS_CONTROL';

  AbilitySet _abilities = AbilitySet.none;
  final _controller = StreamController<AbilitySet>.broadcast();
  StreamSubscription<String?>? _sessionSub;
  StreamSubscription<AuthEvent>? _authSub;

  /// Guards two triggers firing at once — a sign-in that coincides with a
  /// refusal would otherwise send two identical requests.
  bool _inFlight = false;

  /// Keys already reported by [debugWarnIfUnknown], so one mistyped key in a
  /// list that rebuilds sixty times a second logs once and not sixty times.
  final Set<String> _warnedKeys = <String>{};

  AbilitySet get abilities => _abilities;

  /// Emits on every change. `Can` listens to it, which is why a screen updates
  /// itself when an administrator changes what the user may do.
  Stream<AbilitySet> get stream => _controller.stream;

  /// Subscribes to sign-in and sign-out. Called once by the bootstrap.
  void bindToSession() {
    _sessionSub ??= _session.tokenStream.listen((token) {
      if (token == null || token.isEmpty) {
        clear();
      } else {
        unawaited(refresh());
      }
    });

    // The server refused something this app drew, so the set held here is out
    // of date. The refusal itself is the trigger — no poll, no push channel,
    // and no request at all until the two sides actually disagree.
    _authSub ??= AuthEventBus.instance.stream.listen((event) {
      if (event == AuthEvent.permissionsStale) unawaited(refresh());
    });
  }

  /// Re-reads `/authz/me`.
  ///
  /// Failures are **logged and swallowed**, keeping whatever set is already
  /// held. The alternative — falling back to [AbilitySet.none] on a dropped
  /// connection — would empty the user's screen of controls because their wifi
  /// blinked, which is a worse outcome than briefly trusting a set the server
  /// issued a minute ago. The server refuses the action regardless; this only
  /// decides what is drawn.
  Future<void> refresh() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      await _refresh();
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _refresh() async {
    final result = await _repository.myAbilities(
      // Debug builds ask the server for its full key list so the module can
      // shout about a key nothing declares. Never requested in release.
      includeDeclared: kDebugMode,
    );

    result.fold(
      (failure) => LogService.debug(
        'Abilities refresh failed (${failure.runtimeType}) — keeping the set already held.',
        tag: _tag,
      ),
      (abilities) {
        _emit(abilities);
        unawaited(_persist(abilities));
      },
    );
  }

  /// Restores the persisted snapshot. Called before the first frame.
  ///
  /// Never throws: a corrupt entry is treated as "nothing cached", because
  /// failing here would turn a stale cache into a startup crash while
  /// [refresh] already covers the gap.
  Future<void> restoreFromCache() async {
    try {
      final raw = await _storage.readString(PersistenceKeys.cachedAbilities);
      if (raw == null || raw.isEmpty) return;
      _emit(abilitySetFromJson(jsonDecode(raw) as Map<String, dynamic>));
    } catch (_) {
      // Corrupted cache entry — treat as "not cached", never crash startup.
    }
  }

  /// Back to nothing granted. Called on sign-out and on a cleared session.
  void clear() {
    _emit(AbilitySet.none);
    _warnedKeys.clear();
    unawaited(_storage.delete(PersistenceKeys.cachedAbilities));
  }

  /// **The check that would have caught the defect this module was rebuilt
  /// after.**
  ///
  /// `Can(key: 'invoice.approve')` for `invoices.approve` is a typo that
  /// produces a control hidden from everyone, forever, with no error anywhere —
  /// indistinguishable from a permission nobody was granted. A gate that is
  /// always shut reads in code exactly like a gate that works.
  ///
  /// So in debug builds the module asks the server for every key it declares
  /// and complains loudly about anything not in that list. In release the list
  /// is absent, [AbilitySet.isKnown] answers `true`, and this costs one map
  /// lookup.
  void debugWarnIfUnknown(String key) {
    if (!kDebugMode) return;
    if (_abilities.declaredKeys == null) return;
    if (_abilities.isKnown(key)) return;
    if (!_warnedKeys.add(key)) return;

    LogService.error(
      'Unknown permission key "$key" — no server declares it, so this gate is '
      'shut for every user including super admins. Check the spelling against '
      'GET /api/v1/authz/catalog.',
      tag: _tag,
    );
    assert(
      false,
      'Unknown permission key "$key". See GET /api/v1/authz/catalog for the '
      'keys this server declares.',
    );
  }

  void dispose() {
    unawaited(_sessionSub?.cancel());
    unawaited(_authSub?.cancel());
    unawaited(_controller.close());
  }

  void _emit(AbilitySet next) {
    _abilities = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  Future<void> _persist(AbilitySet set) => _storage.writeString(
    PersistenceKeys.cachedAbilities,
    jsonEncode(abilitySetToJson(set)),
  );
}
