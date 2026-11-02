import 'package:in_app_review/in_app_review.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'kit_log.dart';

/// [AppReview] over `in_app_review` — Play's in-app review, StoreKit's
/// rating prompt.
class StoreReview implements AppReview {
  StoreReview([InAppReview? engine]) : _review = engine ?? InAppReview.instance;

  final InAppReview _review;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _review.isAvailable();
    } catch (e, s) {
      kitLog(e, s);
      return false;
    }
  }

  @override
  Future<void> request() async {
    try {
      if (await _review.isAvailable()) await _review.requestReview();
    } catch (e, s) {
      kitLog(e, s);
    }
  }

  @override
  Future<void> openStore({String? appStoreId}) async {
    try {
      await _review.openStoreListing(appStoreId: appStoreId);
    } catch (e, s) {
      kitLog(e, s);
    }
  }
}
