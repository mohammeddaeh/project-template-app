import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/core/platform/storage/adapters/in_memory_storage_adapter.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/sim_notice.dart';
import 'package:app_template/modules/token_inspector/data/inspector_store.dart';
import 'package:app_template/modules/token_inspector/domain/grant_facts.dart';
import 'package:app_template/modules/token_inspector/domain/inspector_event.dart';
import 'package:app_template/modules/token_inspector/integration/inspector_recorder.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/event_card.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/inspector_parts.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/keycloak_checks_card.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/live_session_card.dart';
import 'package:app_template/modules/token_inspector/token_inspector_config.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `modules/token_inspector/` played on the device: a real [InspectorRecorder]
/// over in-memory storage, written to by the buttons here instead of the
/// session observer — so the cards below are the module's own, drawing what
/// they would draw in a dev build.
///
/// The tokens are made up on the spot: unsigned, issued by `example.com`,
/// carrying nothing but their times. The inspector itself speaks English
/// left-to-right, so its titles here are the ones the observer writes.
class TokenInspectorSimDemo extends StatefulWidget {
  const TokenInspectorSimDemo({super.key});

  @override
  State<TokenInspectorSimDemo> createState() => _TokenInspectorSimDemoState();
}

enum _Act { signIn, refresh, offline, refused }

class _TokenInspectorSimDemoState extends State<TokenInspectorSimDemo> {
  final _secure = _MemorySecureStorage();
  late final _recorder = InspectorRecorder(
    InspectorStore(InMemoryStorageAdapter()),
    _secure,
  );
  int _serial = 0;

  /// A sample JWT: readable claims and a placeholder where a signature goes.
  String _sampleToken() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String part(Map<String, Object> json) =>
        base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
    _serial++;
    return [
      part({'alg': 'none'}),
      part({
        'iss': 'https://auth.example.com/realms/demo',
        'typ': 'Bearer',
        'iat': now,
        'exp': now + 300,
      }),
      'unsigned-sample-$_serial',
    ].join('.');
  }

  Future<void> _act(_Act act) async {
    const key = TokenInspectorConfig.accessTokenKey;
    final old = await _secure.read(key);
    if (!mounted) return;
    switch (act) {
      case _Act.signIn || _Act.refresh:
        final token = _sampleToken();
        await _secure.write(key, token);
        final saved = await _recorder.verifySaved(token, null);
        if (!mounted) return;
        _recorder.facts.value = GrantFacts(
          receivedAt: DateTime.now(),
          keycloak: true,
          expiresIn: 300,
          scope: 'openid profile',
        );
        _recorder.record(
          InspectorEventKind.success,
          act == _Act.signIn ? 'Signed in' : 'Token refreshed',
          details: [
            if (act == _Act.refresh) 'Old access: ${_recorder.summary(old)}',
            'Access: ${_recorder.summary(token)}',
            'Saved: $saved',
          ],
        );
      case _Act.offline:
        _recorder.record(
          InspectorEventKind.warning,
          'No network — session KEPT',
          details: const [
            'Reason: connection timeout',
            'Next request retries the refresh',
          ],
        );
      case _Act.refused:
        await _secure.delete(key);
        if (!mounted) return;
        _recorder.record(
          InspectorEventKind.error,
          'Server REFUSED — session cleared',
          details: const ['Status: 401', 'Request: /api/v1/auth/refresh'],
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _act(_Act.signIn);
  }

  @override
  void dispose() {
    _recorder.events.dispose();
    _recorder.facts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;

    String label(_Act a) => switch (a) {
      _Act.signIn => LocaleKeys.showcaseInspectorSignIn.tr(),
      _Act.refresh => LocaleKeys.showcaseInspectorRefresh.tr(),
      _Act.offline => LocaleKeys.showcaseInspectorOffline.tr(),
      _Act.refused => LocaleKeys.showcaseInspectorRefused.tr(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SimNotice(),
        DemoBlock(
          code: 'AuthSessionObserver → InspectorRecorder.record(kind, title)',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in _Act.values)
                AppButton(
                  text: label(a),
                  variant: AppButtonVariant.tonal,
                  onTap: () => _act(a),
                ),
            ],
          ),
        ),
        DemoBlock(
          code:
              'TokenInspectorPanel → LiveSessionCard(recorder:) · '
              'KeycloakChecksCard(recorder:)',
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const InspectorSectionTitle('Session now'),
                LiveSessionCard(recorder: _recorder),
                KeycloakChecksCard(recorder: _recorder),
              ],
            ),
          ),
        ),
        DemoBlock(
          code:
              'InspectorEventCard(event) · InspectorSurface · '
              'InspectorKeyValue · InspectorMuted',
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ValueListenableBuilder<List<InspectorEvent>>(
              valueListenable: _recorder.events,
              builder: (context, events, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (events.isEmpty)
                    InspectorMuted(LocaleKeys.showcaseInspectorEmpty.tr())
                  else
                    for (final e in events) InspectorEventCard(e),
                ],
              ),
            ),
          ),
        ),
        DemoBlock(
          code:
              'AppOverlays → TokenInspectorOverlay(recorder:, navigatorKey:, '
              'child:)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocaleKeys.showcaseInspectorRealNote.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              8.heightBox,
              Icon(Icons.bug_report_outlined, color: colors.iconSubtle),
            ],
          ),
        ),
      ],
    );
  }
}

/// Device storage for the sample tokens — kept in this page, gone with it.
class _MemorySecureStorage implements SecureStorageService {
  final _values = <String, String>{};

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<Map<String, String>> readAll() async => Map.of(_values);

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> clear() async => _values.clear();

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);
}
