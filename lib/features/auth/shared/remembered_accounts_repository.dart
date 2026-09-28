import 'dart:convert';

import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/features/auth/shared/entities/auth_user.dart';
import 'package:app_template/features/auth/shared/entities/remembered_account.dart';
import 'package:injectable/injectable.dart';

/// The addresses this device offers on the login screen
/// (`AppFeatures.rememberedAccounts`).
///
/// ## What this does and does not hold
/// Identity only — name, address, recency. **No password, no token.** The
/// saved account skips the email field and nothing else; the password is still
/// typed in full every time. See [RememberedAccount].
///
/// ## Why it outlives the session
/// `SessionRepository` and `CurrentUserRepository` are both wiped on logout —
/// they describe *who is signed in*. This one describes *who has signed in on
/// this device before*, which is precisely the fact that must survive signing
/// out. Nothing in the logout path touches it (its key is deliberately absent
/// from `AccountDataCleaner`); entries leave only through [forget].
///
/// ## Why in-memory, loaded once
/// The login screen decides its layout from this list on its first frame. An
/// async read there would draw the form and then insert the row above it, so
/// [ensureLoaded] runs in `main()` before `runApp` and the getter is
/// synchronous afterwards.
///
/// Ported from Qirtas, where it was pinned by the same tests after shipping
/// (`test/remembered_accounts_test.dart`).
@singleton
class RememberedAccountsRepository {
  RememberedAccountsRepository(this._storage);

  final StorageService _storage;

  /// How many accounts one device keeps.
  ///
  /// A cap, not a limit anyone is expected to reach: without it a shared
  /// terminal accumulates every person who ever signed in, and the picker turns
  /// into a staff directory drawn on the login screen. Least-recently-used is
  /// dropped, so the people actually using the device stay.
  static const int maxAccounts = 5;

  List<RememberedAccount> _accounts = const [];
  Future<void>? _loading;

  /// Most recent sign-in first. Empty until [ensureLoaded] completes — which is
  /// also the correct answer for "no accounts saved", so a caller that forgets
  /// to await simply gets the plain login form rather than a wrong one.
  List<RememberedAccount> get accounts => List.unmodifiable(_accounts);

  /// Memoised — safe to call from `main()` and again from the login screen.
  Future<void> ensureLoaded() => _loading ??= _load();

  bool isRemembered(String email) {
    final key = _key(email);
    return _accounts.any((a) => _key(a.email) == key);
  }

  /// Adds the account, or refreshes an existing one. Called only after the user
  /// answers yes — never as a side effect of signing in.
  Future<void> remember(AuthUser user) =>
      _upsert(user.email, _label(user), null, addIfMissing: true);

  /// Refreshes name/recency for an account **already** saved, and does nothing
  /// otherwise.
  ///
  /// Separate from [remember] so a successful sign-in can keep a saved card
  /// current without that path ever being able to save an account the user
  /// declined — a single "upsert on login" would quietly do both.
  Future<void> touch(AuthUser user) =>
      _upsert(user.email, _label(user), null, addIfMissing: false);

  Future<void> forget(String email) async {
    final key = _key(email);
    _accounts = _accounts.where((a) => _key(a.email) != key).toList();
    await _persist();
  }

  /// `AuthUser.fullName` is nullable here (a project that identifies people by
  /// email never fills it), and the card needs *something* to show.
  String _label(AuthUser user) {
    final name = user.fullName?.trim();
    return name == null || name.isEmpty ? user.email : name;
  }

  Future<void> _upsert(
    String email,
    String fullName,
    String? imageUrl, {
    required bool addIfMissing,
  }) async {
    await ensureLoaded();

    final key = _key(email);
    final existing = _accounts.where((a) => _key(a.email) == key).firstOrNull;
    if (existing == null && !addIfMissing) return;

    final entry =
        existing?.copyWith(
          fullName: fullName,
          imageUrl: imageUrl,
          lastLoginAt: DateTime.now(),
        ) ??
        RememberedAccount(
          email: email,
          fullName: fullName,
          imageUrl: imageUrl,
          lastLoginAt: DateTime.now(),
        );

    final next = [entry, ..._accounts.where((a) => _key(a.email) != key)];
    _accounts = next.length > maxAccounts ? next.sublist(0, maxAccounts) : next;
    await _persist();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.readString(PersistenceKeys.rememberedAccounts);
      if (raw == null || raw.isEmpty) return;

      // Stored order is already most-recent-first (every write prepends), so
      // this sort only repairs a payload that is not — and it keeps the stored
      // order for ties. Dart's sort is NOT stable, so without the index
      // tie-break two accounts stamped in the same instant would come back in
      // an arbitrary order: the picker would reshuffle itself between launches
      // with nothing having changed.
      final rows =
          (jsonDecode(raw) as List<dynamic>)
              .map(
                (e) => RememberedAccount.tryFromJson(e as Map<String, dynamic>),
              )
              .nonNulls
              .toList()
              .asMap()
              .entries
              .toList()
            ..sort((a, b) {
              final byRecency = b.value.lastLoginAt.compareTo(
                a.value.lastLoginAt,
              );
              return byRecency != 0 ? byRecency : a.key.compareTo(b.key);
            });

      _accounts = rows.map((e) => e.value).toList();
    } catch (_) {
      // A corrupted entry means "no saved accounts", never a crash on the very
      // first screen of the app. The user signs in normally and the next
      // successful save overwrites the bad payload.
      _accounts = const [];
    }
  }

  Future<void> _persist() async {
    await _storage.writeString(
      PersistenceKeys.rememberedAccounts,
      jsonEncode(_accounts.map((a) => a.toJson()).toList()),
    );
  }

  String _key(String email) => email.trim().toLowerCase();
}
