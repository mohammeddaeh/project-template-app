import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// Produces the human-readable label a sign-in attaches to its session, e.g.
/// `Samsung SM-G991B · android · v1.2.0`.
///
/// ## Why this is not part of the multi-device module
///
/// `AppFeatures.multiDevice` is `false` by default. Gating the label on it
/// would leave the server storing the raw `User-Agent` (`Dart/3.9 (dart:io)`)
/// for every session, and a devices screen enabled later could not tell them
/// apart.
///
/// The label costs one platform-channel read at sign-in and is useful whether
/// or not the client ever renders a devices list — the server-side session
/// list, an audit trail, and a security email all read it. So it is
/// unconditional infrastructure, and the module governs only the screen.
///
/// ## Never trusted for a decision
///
/// Free text supplied by the client, stored verbatim, parsed by nobody. The
/// server's `device_info` column is `varchar(500)` and its schema comment says
/// the same thing. Anything that must be trusted travels in the session row,
/// which the client cannot write.
@lazySingleton
class DeviceLabelService {
  /// Resolved once per process — neither the hardware nor the installed
  /// version can change while it is alive, and both reads cross a platform
  /// channel.
  String? _cached;

  Future<String> label() async {
    if (_cached != null) return _cached!;

    final parts = <String>[];
    try {
      parts.add(await _deviceName());
      parts.add(Platform.isIOS ? 'ios' : 'android');
      parts.add('v${(await PackageInfo.fromPlatform()).version}');
    } catch (e) {
      LogService.warning('Device label incomplete: $e', tag: 'DEVICE');
      // A label is a convenience for a screen the user may never open.
      // Failing to build it must never cost them the ability to sign in, so
      // whatever was gathered before the failure is what gets sent — and an
      // empty result is answered by the server's User-Agent fallback.
    }

    return _cached = parts.join(' · ');
  }

  Future<String> _deviceName() async {
    final info = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final ios = await info.iosInfo;
      return ios.utsname.machine;
    }
    final android = await info.androidInfo;
    return '${android.manufacturer} ${android.model}';
  }
}
