import 'package:flutter/foundation.dart';

import 'sync_write_gateway.dart';

abstract class SyncableRepository {
  SyncableRepository(this._syncWriteGateway);

  final SyncWriteGateway _syncWriteGateway;

  @protected
  Future<void> syncWrite(SyncWriteCommand command) {
    return _syncWriteGateway.write(command);
  }
}
