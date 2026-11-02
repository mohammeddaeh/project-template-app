import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/foundation/contracts/auth_session_observer.dart';
import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/token_inspector/data/inspector_store.dart';
import 'package:app_template/modules/token_inspector/domain/grant_facts.dart';
import 'package:app_template/modules/token_inspector/domain/inspector_event.dart';
import 'package:app_template/modules/token_inspector/integration/inspector_recorder.dart';
import 'package:app_template/modules/token_inspector/integration/inspector_session_observer.dart';
import 'package:app_template/modules/token_inspector/presentation/token_inspector_overlay.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/keycloak_checks_card.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/live_session_card.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/app_theme.dart';

/// The overlay is drawn over every screen by a flag nobody flips in CI, so the
/// first sign of a broken sheet would otherwise be a developer on a device.
/// These pump it the way `AppOverlays` mounts it: above the navigator.
void main() {
  late _MemoryStorage storage;
  late _MemorySecure secure;
  late InspectorRecorder recorder;

  setUp(() {
    storage = _MemoryStorage();
    secure = _MemorySecure();
    recorder = InspectorRecorder(InspectorStore(storage), secure);
  });

  Widget host(Widget Function(GlobalKey<NavigatorState> key) overlay) {
    final key = GlobalKey<NavigatorState>();
    return MaterialApp(
      navigatorKey: key,
      theme: AppThemeData.light(const Locale('en'), AppFonts.available.first),
      builder: (context, child) => ResponsiveScope(
        child: TokenInspectorOverlay(
          recorder: recorder,
          navigatorKey: key,
          child: child!,
        ),
      ),
      home: Scaffold(body: overlay(key)),
    );
  }

  testWidgets('the bubble counts events and opens the history', (tester) async {
    recorder.record(InspectorEventKind.success, 'Signed in');
    await tester.pumpWidget(host((_) => const SizedBox()));

    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.key));
    await tester.pumpAndSettle();

    expect(find.text('History — newest first'), findsOneWidget);
    expect(find.text('Signed in'), findsOneWidget);
  });

  testWidgets('history outlives the recorder (an app restart)', (tester) async {
    InspectorSessionObserver(recorder).onRefreshDeferred('connectionError');
    await tester.pumpAndSettle();

    final reopened = InspectorRecorder(InspectorStore(storage), secure);
    await reopened.restore();
    expect(reopened.events.value.single.title, 'No network — session KEPT');
  });

  testWidgets('the session card and the Keycloak checks render', (
    tester,
  ) async {
    await secure.write(PersistenceKeys.token, 'opaque-session-token-abcdef');
    recorder.updateFacts(
      GrantFacts.from(
        TokenGrant(
          accessToken: 'x.eyJpc3MiOiJodHRwczovL3Nzby9yZWFsbXMvYXBwIn0.sig123',
          receivedAt: DateTime(2026),
        ),
        renewal: false,
      ),
    );

    await tester.pumpWidget(
      host(
        (_) => SingleChildScrollView(
          child: Column(
            children: [
              LiveSessionCard(recorder: recorder),
              KeycloakChecksCard(recorder: recorder),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('known to the server only'), findsOneWidget);
    expect(find.text('Keycloak checks'), findsOneWidget);
    expect(find.text('Revoke Refresh Token'), findsOneWidget);
    // No KEYCLOAK_EXPECT_* defined in tests — the card says why there is no verdict.
    expect(find.textContaining('KEYCLOAK_EXPECT_OFFLINE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _MemoryStorage implements StorageService {
  final Map<String, Object?> _values = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> writeString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<String?> readString(String key) async => _values[key] as String?;

  @override
  Future<void> writeStringList(String key, List<String> values) async =>
      _values[key] = values;

  @override
  Future<List<String>?> readStringList(String key) async =>
      _values[key] as List<String>?;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

class _MemorySecure implements SecureStorageService {
  final Map<String, String> _values = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async => _values.remove(key);
}
