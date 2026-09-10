/// قراءةُ موقعٍ واحدة من الجهاز — **غلافُ نظامٍ لا خدمةُ شريحة**.
///
/// كان هذا المنطق يعيش كاملاً بـ`features/units/data/services/`، فبقيت كل
/// شريحةٍ أخرى بلا موقع: شريحةٌ لا تستورد شريحة (قاعدة الطبقات)، فصورة الزيارة
/// الميدانية كانت تُختم بوقتها وتُترك بلا إحداثيات — والصورة الميدانية بلا
/// موضعٍ **نصفُ إثبات**.
///
/// وموضعُه الصحيح `core/platform/`: غلافٌ لواجهة نظام التشغيل، لا رأيَ له بما
/// يُفعل بالقراءة. والشريحتان تقرآن منه، ولا تعرف إحداهما بالأخرى.
class DeviceLocationFix {
  const DeviceLocationFix({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime? capturedAt;
}

enum DeviceLocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.failure);
  final DeviceLocationFailure failure;
}

abstract interface class DeviceLocationService {
  /// يرمي [DeviceLocationException] — ولا يجيب `null`: «لا موقع» له أربعة
  /// أسباب مختلفة العلاج (الخدمة مطفأة · الإذن مرفوض · مرفوضٌ نهائياً · تعذّر)،
  /// وقيمةٌ فارغة واحدة تمحوها كلّها.
  Future<DeviceLocationFix> captureCurrent();
}
