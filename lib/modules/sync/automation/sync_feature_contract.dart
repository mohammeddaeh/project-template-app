import 'package:injectable/injectable.dart';
import 'package:get_it/get_it.dart';

import '../domain/sync_status.dart';

/// Declarative manifest used by code-generation to build sync adapters.
/// Feature teams should only provide entity <-> json mapping metadata.
abstract class SyncFeatureContractBase {
  const SyncFeatureContractBase();

  String get entityName;
  Type get repositoryContractType;
  Object resolveRepository(GetIt di);
  bool get requiresExecutor => true;
  int get contractVersion => 1;
  Set<int> get supportedContractVersions => {contractVersion};

  /// Conflict resolution strategy for this entity type.
  ///
  /// Override in feature contracts where server authority is not appropriate:
  /// - Shared/admin data         → [SyncConflictStrategy.serverWins] (default)
  /// - Client-owned preferences  → [SyncConflictStrategy.clientWins]
  /// - Peer records              → [SyncConflictStrategy.lastWriteWins]
  /// - Rich documents            → [SyncConflictStrategy.merge]
  /// - High-stakes user data     → [SyncConflictStrategy.manual]
  SyncConflictStrategy get conflictStrategy => SyncConflictStrategy.serverWins;

  /// Validate queue payload shape before persistence.
  /// Return true when payload is acceptable for this entity.
  bool isValidQueuePayload(Map<String, dynamic> payload) => true;

  /// Migrate payload between schema versions.
  /// Default behavior keeps payload unchanged.
  Map<String, dynamic> migratePayload(
    Map<String, dynamic> oldPayload,
    int fromVersion,
    int toVersion,
  ) {
    return oldPayload;
  }
}

abstract class SyncFeatureContract<TEntity> extends SyncFeatureContractBase {
  const SyncFeatureContract();

  Map<String, dynamic> toJson(TEntity entity);
  TEntity fromJson(Map<String, dynamic> json);
  String localIdOf(TEntity entity);
}

@Named('sync_feature_contracts')
class SyncFeatureContractsToken {
  const SyncFeatureContractsToken();
}
