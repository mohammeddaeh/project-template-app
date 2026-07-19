class SyncContractValidationException implements Exception {
  SyncContractValidationException(this.message);

  final String message;

  @override
  String toString() => 'SyncContractValidationException: $message';
}
