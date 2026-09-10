import 'package:geolocator/geolocator.dart';

import 'device_location_service.dart';

/// يُسجَّل من [PlatformServicesRegistry] تحت `AppFeatures.location` — **لا
/// بـ`injectable`**: القالب يَعِد بصفر أثرٍ عند الإطفاء، ووسمٌ غيرُ مشروط يُسجّل
/// الخدمةَ بكل مشروعٍ سواءٌ أراد موقعاً أم لا.
class DeviceLocationServiceImpl implements DeviceLocationService {
  @override
  Future<DeviceLocationFix> captureCurrent() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DeviceLocationException(
        DeviceLocationFailure.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const DeviceLocationException(
        DeviceLocationFailure.permissionDenied,
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
        DeviceLocationFailure.permissionDeniedForever,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return DeviceLocationFix(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        capturedAt: position.timestamp,
      );
    } on DeviceLocationException {
      rethrow;
    } catch (_) {
      throw const DeviceLocationException(DeviceLocationFailure.unavailable);
    }
  }
}
