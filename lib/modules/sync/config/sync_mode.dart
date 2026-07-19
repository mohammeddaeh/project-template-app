enum SyncMode {
  disabled,
  passive,
  active;

  static SyncMode fromRaw(String? raw) {
    switch (raw) {
      case 'disabled':
        return SyncMode.disabled;
      case 'passive':
        return SyncMode.passive;
      case 'active':
        return SyncMode.active;
      default:
        return SyncMode.active;
    }
  }

  String get raw => name;
}
