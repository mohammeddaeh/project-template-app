/// مسارات `modules/data_transfer/` — **بجوار الموديول لا بـ`ApiUrls`**.
///
/// نفسُ قاعدة `AccessControlUrls`: موديولٌ اختياريٌّ يملك مساراتِه، فلا يحمل
/// `ApiUrls` ما لا يُنادى حين يكون العلَم مطفأً.
/// راجع `readme/32_MODULE_DATA_TRANSFER.md`.
abstract class DataTransferUrls {
  /// Everything this backend can import or export, with its columns.
  ///
  /// The module's screens are built entirely from this response — a feature
  /// that becomes transferable server-side needs **no** Dart change.
  static const String transferResources = '/data-transfer/resources';

  /// ⚠️ **Answers file bytes, not the `{status, message, data}` envelope.**
  ///
  /// Never call this through a repository that runs `HandleBodyResponse`: it
  /// parses every body as JSON and would report "something went wrong" over a
  /// perfectly good CSV — with a `200 OK` in the server log. Use
  /// `TransferFileDownloader`, which reads it as bytes.
  static String transferExport(String resource) =>
      '/data-transfer/$resource/export';

  /// Empty file with the importer's expected header. Bytes, like
  /// [transferExport].
  static String transferTemplate(String resource) =>
      '/data-transfer/$resource/template';

  /// Both import phases. `?mode=validate` (multipart) then `?mode=commit`
  /// (`{token}`). Ordinary envelope in both directions.
  static String transferImport(String resource) =>
      '/data-transfer/$resource/import';
}
