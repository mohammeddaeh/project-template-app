import 'sync_mode.dart';

class SyncSettings {
  const SyncSettings({
    required this.mode,
    required this.syncEnabled,
    required this.wifiOnly,
    required this.periodicIntervalSeconds,
    this.mediaWifiOnly = true,
    this.mediaOverMobileApproved = false,
  });

  final SyncMode mode;
  final bool syncEnabled;
  final bool wifiOnly;
  final int? periodicIntervalSeconds;

  /// **«لا تنزّل الصور والملفّات إلا على Wi‑Fi» — ومُشعَلٌ افتراضياً.**
  ///
  /// ولا يناقض [wifiOnly] المطفأ: ذاك يحكم **الدفع**، وحمولتُه كتابةُ مستخدمٍ
  /// لا تصل الخادمَ إن لم تُرفع — فحجزُها على Wi‑Fi غيرُ مقبول. وهذا يحكم
  /// **السحب**، وحمولتُه مئاتُ الميغابايتات من ملفّاتٍ يملكها الخادم أصلاً،
  /// وتأخيرُها ساعةً لا يُضيّع شيئاً.
  ///
  /// **والافتراضان معكوسان لأن السؤالين معكوسان.**
  final bool mediaWifiOnly;

  /// **«نزّلها الآن على بيانات الجوّال» — إذنٌ صريح من صاحب الحزمة.**
  ///
  /// يُرفع بضغطة «تنزيل الآن» ويسقط بضغطة «تأجيل» — فيبقى القرارُ قرارَه بين
  /// الجلسات، ولا يُسأل عنه بكل دورة.
  final bool mediaOverMobileApproved;

  bool get isDisabledMode => mode == SyncMode.disabled;
  bool get isPassiveMode => mode == SyncMode.passive;
  bool get isActiveMode => mode == SyncMode.active;
}
