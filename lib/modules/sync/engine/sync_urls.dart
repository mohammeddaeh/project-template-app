/// مسارات `modules/sync/` — **بجوار الموديول لا بـ`ApiUrls`**.
///
/// `ApiUrls` مقصورٌ على ما يخدمه الباك فعلاً، والموديول مطفأ
/// (`AppFeatures.offlineSync == false`).
///
/// ⚠️ **طابِق كل مسارٍ هنا بباك مشروعك قبل التفعيل.** مسارات السحب بعلامة المياه
/// (`records` · `parcels`) مثالُ مجالٍ بعينه، لا عقدٌ يخدمه `backend_template`.
///
/// وتبقى هنا لأن المحرّك مبنيٌّ فوقها ويُشحن مطفأً (R28): سطحُ قالبٍ ينتظر
/// باكاً، لا سلسلةٌ انقطعت بالخطأ.
abstract class SyncUrls {
  // ── المرفقات ───────────────────────────────────────────────────────────────

  /// موردٌ واحد لكل مرفقات التطبيق — **لا مسارَ رفعٍ لكل شريحة**.
  ///
  /// > ⚠️ **عقد wire (R01)**: الرفع `multipart/form-data` بمفاتيح
  /// > `attachmentFormData` — `file` · `attachment_id` · `entity_name` ·
  /// > `entity_id` · `role` · `checksum` · `checksum_algo`. والردّ مغلّفٌ
  /// > عادي يحمل `data.id`: **تأكيدُ الخادم لا إيصالُ إرسال**.
  static const String attachments = '/attachments';

  /// بايتات مرفقٍ واحد — **لا مغلّف**. يُبنى من معرّف الخادم لا المحلي.
  static String attachmentContent(String attachmentId) =>
      '/attachments/$attachmentId/content';
  static const String attachmentContentPath =
      '/attachments/{attachmentId}/content';

  // ── السحبُ بعلامة المياه — `heads` ثم `bundle` ─────────────────────────────
  //
  // **ثلاثُ طبقاتٍ تنزل بالتدريج**، بدل ثلاث دلتات مستقلّة:
  //
  // ```
  // ١ · GET /records/heads                  ← معرّف + ختم لكل محضر (صغير)
  // ٢ · GET /records/{id}/parcels/heads     ← لمحضرٍ تغيّر ختمُه وحده
  // ٣ · GET /parcels/{id}/bundle            ← لمقسمٍ تغيّر ختمُه وحده
  // ```
  //
  // والحذف يُستنتج بالغياب، وهو آمنٌ لأن كل قائمةٍ **كاملةٌ بحكم بنيتها**.
  // ⛔ **ولذلك لا تُقطَّع هذه المسارات أبداً**: ترقيمُ صفحاتٍ يُضاف يوماً لأن
  //    القائمة طالت **يمحو من الأجهزة كلَّ ما لم تحمله الصفحة الأولى**.

  static const String recordHeads = '/records/heads';

  static String recordParcelHeads(String recordLocalId) =>
      '/records/$recordLocalId/parcels/heads';
  static const String recordParcelHeadsPath =
      '/records/{recordLocalId}/parcels/heads';

  /// المقسم وسجلاتُه وميتاداتا مرفقاته بردٍّ واحد.
  static String parcelBundle(String parcelLocalId) =>
      '/parcels/$parcelLocalId/bundle';
  static const String parcelBundlePath = '/parcels/{parcelLocalId}/bundle';
}
