import 'dart:convert';

import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

import '../domain/sync_entity_record.dart';
import '../domain/sync_queue_job.dart';
import '../domain/sync_status.dart';

/// Result returned by [SyncConflictResolver.resolve].
sealed class ConflictResolution {
  const ConflictResolution();
}

/// Accept server version — discard local change.
final class ServerWinsResolution extends ConflictResolution {
  const ServerWinsResolution({required this.serverRecord});
  final SyncEntityRecord serverRecord;
}

/// Re-push local version with force flag.
final class ClientWinsResolution extends ConflictResolution {
  const ClientWinsResolution({required this.localRecord});
  final SyncEntityRecord localRecord;
}

/// Merged record — non-conflicting fields from client, conflicting from server.
final class MergedResolution extends ConflictResolution {
  const MergedResolution({required this.mergedRecord});
  final SyncEntityRecord mergedRecord;
}

/// Cannot resolve automatically — emit [ConflictDetected] for UI to handle.
final class ManualResolutionRequired extends ConflictResolution {
  const ManualResolutionRequired({
    required this.localRecord,
    required this.serverSnapshot,
    required this.conflictFields,
  });
  final SyncEntityRecord localRecord;
  final Map<String, dynamic> serverSnapshot;
  final List<String> conflictFields;
}

class SyncConflictResolver {
  ConflictResolution resolve({
    required SyncEntityRecord localRecord,
    required ConflictFailure conflict,
    required SyncQueueJob job,
    required SyncConflictStrategy strategy,
  }) {
    LogService.debug(
      'Resolving conflict for ${job.entityName}/${job.entityId} '
      'using strategy=${strategy.name}',
      tag: 'SYNC',
    );

    return switch (strategy) {
      SyncConflictStrategy.serverWins => _serverWins(localRecord, conflict),
      SyncConflictStrategy.clientWins => ClientWinsResolution(localRecord: localRecord),
      SyncConflictStrategy.lastWriteWins =>
        _lastWriteWins(localRecord, conflict),
      SyncConflictStrategy.merge => _merge(localRecord, conflict),
      SyncConflictStrategy.manual => ManualResolutionRequired(
          localRecord: localRecord,
          serverSnapshot: conflict.serverVersion ?? {},
          conflictFields: conflict.conflictFields,
        ),
    };
  }

  ConflictResolution _serverWins(
    SyncEntityRecord local,
    ConflictFailure conflict,
  ) {
    final sv = conflict.serverVersion;
    if (sv == null) return ServerWinsResolution(serverRecord: local);
    final serverRecord = local.copyWith(
      dataJson: jsonEncode(sv),
      version: (sv['version'] as int?) ?? local.version + 1,
      syncStatus: SyncStatus.synced,
      lastError: null,
    );
    return ServerWinsResolution(serverRecord: serverRecord);
  }

  ConflictResolution _lastWriteWins(
    SyncEntityRecord local,
    ConflictFailure conflict,
  ) {
    final sv = conflict.serverVersion;
    final cv = conflict.clientVersion;
    if (sv == null) return ClientWinsResolution(localRecord: local);
    final serverUpdatedAt = sv['updated_at'];
    final clientUpdatedAt = cv?['updated_at'];
    final serverMs = _parseUpdatedAt(serverUpdatedAt);
    final clientMs = _parseUpdatedAt(clientUpdatedAt);

    if (serverMs >= clientMs) {
      return _serverWins(local, conflict);
    }
    return ClientWinsResolution(localRecord: local);
  }

  ConflictResolution _merge(
    SyncEntityRecord local,
    ConflictFailure conflict,
  ) {
    final sv = conflict.serverVersion;
    if (sv == null || conflict.conflictFields.isEmpty) {
      return ClientWinsResolution(localRecord: local);
    }
    try {
      final localData = jsonDecode(local.dataJson) as Map<String, dynamic>;
      final merged = Map<String, dynamic>.from(localData);
      for (final field in conflict.conflictFields) {
        if (sv.containsKey(field)) {
          merged[field] = sv[field];
        }
      }
      final mergedRecord = local.copyWith(
        dataJson: jsonEncode(merged),
        version: (sv['version'] as int?) ?? local.version + 1,
        syncStatus: SyncStatus.synced,
        lastError: null,
      );
      return MergedResolution(mergedRecord: mergedRecord);
    } catch (e) {
      LogService.warning(
        'Merge failed for ${local.entityName}/${local.localId}: $e — falling back to serverWins.',
        tag: 'SYNC',
      );
      return _serverWins(local, conflict);
    }
  }

  int _parseUpdatedAt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }
}
