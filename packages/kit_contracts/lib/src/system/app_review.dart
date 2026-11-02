/// The store's own rating sheet, inside the app.
///
/// Provided by `kit_system`. The store decides whether the sheet appears —
/// it holds a quota per user and says nothing when it is spent — so ask at a
/// moment of success (a task finished), never from a button the user expects
/// to work every time. That button is [openStore].
abstract interface class AppReview {
  /// Whether the sheet can appear on this device (a store is present).
  Future<bool> isAvailable();

  /// Asks the store to show its rating sheet; returns without telling whether
  /// it did.
  Future<void> request();

  /// The app's page in the store — always works where a store exists.
  /// [appStoreId] is required on iOS.
  Future<void> openStore({String? appStoreId});
}
