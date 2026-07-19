import 'dart:convert';

import 'package:get_it/get_it.dart';

import '../automation/sync_feature_contract.dart';
import 'sync_contract_validation_exception.dart';

class SyncMigrationResult {
  const SyncMigrationResult({
    required this.payloadJson,
    required this.contractVersion,
    this.migrated = false,
  });

  final String payloadJson;
  final int contractVersion;
  final bool migrated;
}

class SyncContractMigrator {
  SyncContractMigrator(this._di);

  final GetIt _di;

  SyncMigrationResult migratePayloadToLatest({
    required String entityName,
    required String payloadJson,
    required int fromVersion,
  }) {
    final contract = _findContractByEntityName(entityName);
    if (contract == null) {
      throw SyncContractValidationException(
        'missing sync feature contract for entity "$entityName".',
      );
    }

    if (!contract.supportedContractVersions.contains(fromVersion)) {
      throw SyncContractValidationException(
        'unsupported contract version $fromVersion for entity "$entityName". '
        'Supported: ${contract.supportedContractVersions.toList()}.',
      );
    }

    if (fromVersion == contract.contractVersion) {
      return SyncMigrationResult(
        payloadJson: payloadJson,
        contractVersion: fromVersion,
      );
    }

    final decoded = jsonDecode(payloadJson);
    if (decoded is! Map<String, dynamic>) {
      throw SyncContractValidationException(
        'invalid payload for migration on entity "$entityName".',
      );
    }

    final migrated = contract.migratePayload(
      decoded,
      fromVersion,
      contract.contractVersion,
    );

    return SyncMigrationResult(
      payloadJson: jsonEncode(migrated),
      contractVersion: contract.contractVersion,
      migrated: true,
    );
  }

  SyncFeatureContractBase? _findContractByEntityName(String entityName) {
    if (!_di.isRegistered<SyncFeatureContractBase>()) {
      return null;
    }
    final contracts = _di.getAll<SyncFeatureContractBase>();
    for (final contract in contracts) {
      if (contract.entityName == entityName) {
        return contract;
      }
    }
    return null;
  }
}
