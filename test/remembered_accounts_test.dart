import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/features/auth/shared/entities/auth_user.dart';
import 'package:app_template/features/auth/shared/remembered_accounts_repository.dart';
import 'package:app_template/core/platform/storage/adapters/in_memory_storage_adapter.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';

/// Guards the saved-account picker on the login screen.
///
/// Everything here fails **silently** when it breaks: the login screen simply
/// renders the plain email+password form, which is exactly what a device with
/// nothing saved is supposed to render. There is no exception, no red banner,
/// no failing widget — the feature just stops existing, and the user concludes
/// they never saved their address in the first place.
///
/// Each case proves its opposite too, because the "working" outcome here is
/// mostly *absence of a card*, and absence passes for many wrong reasons.
void main() {
  AuthUser user({required String email, String? fullName = 'Test User'}) =>
      AuthUser(
        id: 1,
        fullName: fullName,
        email: email,
        createdAt: DateTime(2026),
      );

  group('consent is the only way in', () {
    test('remember() saves; touch() alone never does', () async {
      final storage = InMemoryStorageAdapter();
      final repo = RememberedAccountsRepository(storage);
      await repo.ensureLoaded();

      // "Not now" — the login path still calls touch() to keep saved cards
      // fresh. It must do nothing at all for an account that was declined.
      await repo.touch(user(email: 'declined@example.com'));
      expect(
        repo.accounts,
        isEmpty,
        reason:
            'touch() added an account the user never agreed to save — '
            'a consent bug that looks identical to working software',
      );

      // And the opposite: the same call after an explicit yes does save.
      await repo.remember(user(email: 'saved@example.com'));
      expect(repo.accounts.single.email, 'saved@example.com');
    });

    test('touch() refreshes a card that IS saved', () async {
      final repo = RememberedAccountsRepository(InMemoryStorageAdapter());
      await repo.remember(user(email: 'a@example.com', fullName: 'Old Name'));

      await repo.touch(user(email: 'a@example.com', fullName: 'New Name'));

      expect(repo.accounts, hasLength(1));
      expect(repo.accounts.single.fullName, 'New Name');
    });
  });

  // The template's `AuthUser.fullName` is nullable (a project that identifies
  // people by email never fills it). A card with an empty label draws an
  // avatar with no letter and a blank caption — it looks like a rendering bug,
  // not a saved account.
  group('an account without a name', () {
    test('is labelled by its address, not by an empty string', () async {
      final repo = RememberedAccountsRepository(InMemoryStorageAdapter());
      await repo.remember(user(email: 'noname@example.com', fullName: null));
      expect(repo.accounts.single.fullName, 'noname@example.com');
    });

    test('a real name still wins over the address', () async {
      final repo = RememberedAccountsRepository(InMemoryStorageAdapter());
      await repo.remember(user(email: 'n@example.com', fullName: '  '));
      await repo.touch(user(email: 'n@example.com', fullName: 'Sam'));
      expect(repo.accounts.single.fullName, 'Sam');
    });
  });

  test('the same address in different case is ONE account', () async {
    final repo = RememberedAccountsRepository(InMemoryStorageAdapter());
    await repo.remember(user(email: 'Sam@Example.com'));
    await repo.remember(user(email: 'sam@example.com'));

    expect(
      repo.accounts,
      hasLength(1),
      reason:
          'two cards for one person, and the save prompt reappears every '
          'sign-in for an address that is already saved',
    );
    expect(repo.isRemembered('SAM@EXAMPLE.COM'), isTrue);
    expect(repo.isRemembered('other@example.com'), isFalse);
  });

  test('forget() removes exactly one, and leaves the rest', () async {
    final repo = RememberedAccountsRepository(InMemoryStorageAdapter());
    await repo.remember(user(email: 'a@example.com'));
    await repo.remember(user(email: 'b@example.com'));

    await repo.forget('A@EXAMPLE.COM');

    expect(repo.accounts.map((a) => a.email), ['b@example.com']);
  });

  test('the cap drops the least recently used, never the newest', () async {
    final repo = RememberedAccountsRepository(InMemoryStorageAdapter());
    for (var i = 0; i <= RememberedAccountsRepository.maxAccounts; i++) {
      await repo.remember(user(email: 'u$i@example.com'));
    }

    expect(repo.accounts, hasLength(RememberedAccountsRepository.maxAccounts));
    // u0 signed in first, so it is the one that goes.
    expect(repo.accounts.map((a) => a.email), isNot(contains('u0@example.com')));
    expect(repo.accounts.first.email, 'u5@example.com');
  });

  group('it survives a restart — and a corrupted store', () {
    test(
      'a second repository over the same storage sees the accounts',
      () async {
        final storage = InMemoryStorageAdapter();
        await RememberedAccountsRepository(
          storage,
        ).remember(user(email: 'a@example.com', fullName: 'Sam'));

        // A fresh process: new repository instance, same on-disk payload.
        final restored = RememberedAccountsRepository(storage);
        await restored.ensureLoaded();

        expect(restored.accounts.single.fullName, 'Sam');
        expect(restored.isRemembered('a@example.com'), isTrue);
      },
    );

    test('most recent first after a reload, not insertion order', () async {
      final storage = InMemoryStorageAdapter();
      final repo = RememberedAccountsRepository(storage);
      await repo.remember(user(email: 'first@example.com'));
      await repo.remember(user(email: 'second@example.com'));
      await repo.touch(user(email: 'first@example.com'));

      final restored = RememberedAccountsRepository(storage);
      await restored.ensureLoaded();

      expect(restored.accounts.first.email, 'first@example.com');
    });

    test('garbage in storage means "nothing saved", never a crash', () async {
      final storage = InMemoryStorageAdapter();
      await storage.writeString(
        PersistenceKeys.rememberedAccounts,
        'not json at all',
      );

      final repo = RememberedAccountsRepository(storage);
      await repo.ensureLoaded();

      // This runs on the app's first screen — throwing here is a launch
      // failure, not a missing feature.
      expect(repo.accounts, isEmpty);
      // And it recovers: the next save overwrites the bad payload.
      await repo.remember(user(email: 'a@example.com'));
      expect(repo.accounts, hasLength(1));
    });

    test('one malformed row does not discard the valid ones', () async {
      final storage = InMemoryStorageAdapter();
      await storage.writeString(
        PersistenceKeys.rememberedAccounts,
        jsonEncode([
          {'full_name': 'No Email At All'},
          {
            'email': 'good@example.com',
            'full_name': 'Good',
            'last_login_at': '2026-08-11T10:00:00.000Z',
          },
        ]),
      );

      final repo = RememberedAccountsRepository(storage);
      await repo.ensureLoaded();

      expect(repo.accounts.map((a) => a.email), ['good@example.com']);
    });
  });

  test('no credential is ever written to storage', () async {
    final storage = InMemoryStorageAdapter();
    final repo = RememberedAccountsRepository(storage);
    await repo.remember(user(email: 'a@example.com'));

    final raw = await storage.readString(PersistenceKeys.rememberedAccounts);

    // The whole security posture of this feature in one assertion: the payload
    // is identity, and adding a password/token field to RememberedAccount to
    // "skip one more step" must fail here rather than ship.
    expect(raw, isNotNull);
    expect(raw!.toLowerCase(), isNot(contains('password')));
    expect(raw.toLowerCase(), isNot(contains('token')));
    expect(
      jsonDecode(raw) as List<dynamic>,
      everyElement(
        predicate<dynamic>(
          (e) => (e as Map<String, dynamic>).keys.toSet().difference({
            'email',
            'full_name',
            'image_url',
            'last_login_at',
          }).isEmpty,
          'carries identity fields only',
        ),
      ),
    );
  });
}
