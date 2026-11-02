import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';
import 'package:app_template/modules/token_inspector/data/inspector_store.dart';
import 'package:app_template/modules/token_inspector/domain/grant_facts.dart';
import 'package:app_template/modules/token_inspector/domain/inspector_event.dart';
import 'package:app_template/modules/token_inspector/domain/token_reading.dart';
import 'package:app_template/modules/token_inspector/token_inspector_config.dart';

/// حالةُ الموديول الحيّة: السجلّ، ووقائع آخر ردّ، ورسائلُ الـtoast.
///
/// تسمعه الطبقة المرئية؛ ويكتب فيه المستمع على الجلسة ونداءاتُ المطوّر
/// (`TokenInspector.mark` · `snapshot`).
class InspectorRecorder {
  InspectorRecorder(this._store, this._secure);

  final InspectorStore _store;
  final SecureStorageService _secure;

  static const tag = 'TOKEN-INSPECTOR';

  /// الأحدث أوّلاً.
  final events = ValueNotifier<List<InspectorEvent>>(const []);

  /// آخر ما رُصد من نقطة الاعتماد — منه تُحسب فحوص Keycloak.
  final facts = ValueNotifier<GrantFacts?>(null);

  final _notices = StreamController<String>.broadcast();

  /// رسائلُ قصيرة — تعرضها الطبقة toast.
  Stream<String> get notices => _notices.stream;

  /// يستعيد المحفوظ — ويُبقي ما سُجّل قبله بهذا الإقلاع.
  Future<void> restore() async {
    try {
      final saved = await _store.readEvents();
      events.value = [
        ...events.value,
        ...saved,
      ].take(TokenInspectorConfig.maxEvents).toList();
      facts.value ??= await _store.readFacts();
    } on Object catch (e) {
      LogService.warning('Token inspector history unreadable: $e', tag: tag);
    }
  }

  void record(
    InspectorEventKind kind,
    String title, {
    List<String> details = const [],
    String? notice,
  }) {
    final event = InspectorEvent(
      at: DateTime.now(),
      kind: kind,
      title: title,
      details: details,
    );
    events.value = [
      event,
      ...events.value,
    ].take(TokenInspectorConfig.maxEvents).toList();
    // `debugPrint` لا `LogService`: هذا يمرّ إلى Crashlytics متى أُشعل.
    if (kDebugMode) debugPrint('[$tag] $title · ${details.join(' · ')}');
    if (notice != null) _notices.add(notice);
    unawaited(_persistEvents());
  }

  void updateFacts(GrantFacts next) {
    facts.value = next;
    unawaited(
      _store.writeFacts(next).catchError((Object e) {
        LogService.warning('Token facts not saved: $e', tag: tag);
      }),
    );
  }

  /// التوكنان بالتخزين الآن.
  Future<(String?, String?)> storedTokens() async {
    final refreshKey = TokenInspectorConfig.refreshTokenKey;
    return (
      await _secure.read(TokenInspectorConfig.accessTokenKey),
      refreshKey == null ? null : await _secure.read(refreshKey),
    );
  }

  /// يقرأ ما بالتخزين ويقارنه بما يُفترض أنه حُفظ — `access ✓ · refresh ✓`.
  Future<String> verifySaved(String access, String? refresh) async {
    try {
      final (storedAccess, storedRefresh) = await storedTokens();
      final parts = ['access ${storedAccess == access ? '✓' : '✗'}'];
      if (TokenInspectorConfig.refreshTokenKey != null && refresh != null) {
        parts.add('refresh ${storedRefresh == refresh ? '✓' : '✗'}');
      }
      return parts.join(' · ');
    } on Object catch (e) {
      return 'read failed ✗ ($e)';
    }
  }

  /// يطبع التوكن كاملاً — **بنسخة التطوير وحدها، وبـ`debugPrint` وحده**.
  void printFull(String label, String? token) {
    if (!kDebugMode || token == null || token.isEmpty) return;
    debugPrint('[$tag] $label (full): $token');
  }

  /// سطرُ قراءةٍ لتوكن بلا كشفه.
  String summary(String? token) =>
      TokenReading.of(token).summary(DateTime.now());

  Future<void> clear() async {
    events.value = const [];
    facts.value = null;
    await _store.clear();
  }

  Future<void> _persistEvents() async {
    try {
      await _store.writeEvents(events.value);
    } on Object catch (e) {
      LogService.warning('Token inspector history not saved: $e', tag: tag);
    }
  }
}
