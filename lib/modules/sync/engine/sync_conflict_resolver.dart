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

/// Keep the local content and retry it **rebased onto [rebaseToVersion]**.
///
/// The version is the server's current one, taken from the 409 body. Re-queuing
/// the job with its original base version instead would hit the same optimistic
/// check and produce the same 409 — a loop that ends in `failed` and looks, from
/// the outside, exactly like a server that keeps rejecting a valid write.
///
/// `null` means the server sent no `server_version`, so there is nothing to
/// rebase onto and the engine escalates to manual resolution.
final class ClientWinsResolution extends ConflictResolution {
  const ClientWinsResolution({required this.localRecord, this.rebaseToVersion});
  final SyncEntityRecord localRecord;
  final int? rebaseToVersion;
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
      SyncConflictStrategy.clientWins => _clientWins(localRecord, conflict),
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

  /// Local content, server base.
  ///
  /// Without `server_version` there is no base to rebase onto — and re-queuing
  /// the job unchanged would repeat the conflict until the job dies. Escalating
  /// to manual is the only honest answer: the client cannot win a race it has
  /// no way to re-enter.
  ConflictResolution _clientWins(
    SyncEntityRecord local,
    ConflictFailure conflict,
  ) {
    final serverVersion = conflict.serverVersion?['version'] as int?;
    if (serverVersion == null) {
      LogService.warning(
        'clientWins for ${local.entityName}/${local.localId} has no '
        'server_version to rebase onto — escalating to manual rather than '
        'retrying into the same conflict.',
        tag: 'SYNC',
      );
      return ManualResolutionRequired(
        localRecord: local,
        serverSnapshot: conflict.serverVersion ?? const {},
        conflictFields: conflict.conflictFields,
      );
    }
    return ClientWinsResolution(
      localRecord: local,
      rebaseToVersion: serverVersion,
    );
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
    // No server snapshot means no basis for the comparison this strategy is —
    // and no base to rebase onto either. Hand it to a person.
    if (sv == null) return _clientWins(local, conflict);
    final serverUpdatedAt = sv['updated_at'];
    final clientUpdatedAt = cv?['updated_at'];
    final serverMs = _parseUpdatedAt(serverUpdatedAt);
    final clientMs = _parseUpdatedAt(clientUpdatedAt);

    if (serverMs >= clientMs) {
      return _serverWins(local, conflict);
    }
    // The client wrote later, so its content stands — but it still has to be
    // rebased, or the retry hits the same optimistic check it just failed.
    return _clientWins(local, conflict);
  }

  ConflictResolution _merge(
    SyncEntityRecord local,
    ConflictFailure conflict,
  ) {
    final sv = conflict.serverVersion;
    if (sv == null || conflict.conflictFields.isEmpty) {
      // Nothing to merge — either the server sent no snapshot, or it named no
      // conflicting field, which means the local content stands as it is. It
      // still needs a rebase to get past the optimistic check.
      return _clientWins(local, conflict);
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
