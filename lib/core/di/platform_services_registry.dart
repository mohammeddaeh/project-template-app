import 'package:dio/dio.dart';
import 'package:app_template/core/infra/network/security/certificate_pinning_config.dart';
import 'package:app_template/core/platform/biometrics/biometrics_service.dart';
import 'package:app_template/core/platform/biometrics/biometrics_service_impl.dart';
import 'package:app_template/core/platform/clipboard/clipboard_service.dart';
import 'package:app_template/core/platform/clipboard/clipboard_service_impl.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/files/file_service.dart';
import 'package:app_template/core/platform/files/file_service_impl.dart';
import 'package:app_template/core/platform/haptics/haptic_service.dart';
import 'package:app_template/core/platform/haptics/haptic_service_impl.dart';
import 'package:app_template/core/platform/lifecycle/app_lifecycle_service.dart';
import 'package:app_template/core/platform/lifecycle/app_lifecycle_service_impl.dart';
import 'package:app_template/core/platform/share/share_service.dart';
import 'package:app_template/core/platform/share/share_service_impl.dart';
import 'package:get_it/get_it.dart';

/// Registers optional platform services based on [AppFeatures] flags.
///
/// ## How it works
/// 1. Developer sets flags in `lib/core/platform/features/app_features.dart`.
/// 2. `configureDependencies()` calls `PlatformServicesRegistry.configure(getIt)`
///    automatically — no other changes needed.
/// 3. Only enabled services are registered in GetIt — disabled services
///    add zero runtime overhead.
///
/// ## Adding a new optional service
/// 1. Add a flag in [AppFeatures].
/// 2. Add an `if (AppFeatures.x)` block below.
/// 3. That's it.
///
/// ## Disabling a service
/// Set the corresponding [AppFeatures] flag to `false` — done.
abstract final class PlatformServicesRegistry {
  const PlatformServicesRegistry._();

  /// Called once from [configureDependencies] after the main DI setup.
  static void configure(GetIt getIt) {
    _registerBiometrics(getIt);
    _registerClipboard(getIt);
    _registerShare(getIt);
    _registerFileService(getIt);
    _registerAppLifecycle(getIt);
    _registerHaptics(getIt);
    _applyCertificatePinning(getIt);
  }

  // ── P6 — Biometrics ────────────────────────────────────────────────────────

  static void _registerBiometrics(GetIt getIt) {
    if (!AppFeatures.biometrics) return;
    getIt.registerLazySingleton<BiometricsService>(
      () => BiometricsServiceImpl(),
    );
  }

  // ── P7 — Clipboard ─────────────────────────────────────────────────────────

  static void _registerClipboard(GetIt getIt) {
    if (!AppFeatures.clipboard) return;
    getIt.registerLazySingleton<ClipboardService>(
      () => const ClipboardServiceImpl(),
    );
  }

  // ── P8 — Share ─────────────────────────────────────────────────────────────

  static void _registerShare(GetIt getIt) {
    if (!AppFeatures.shareSheet) return;
    getIt.registerLazySingleton<ShareService>(
      () => const ShareServiceImpl(),
    );
  }

  // ── P9 — File operations ───────────────────────────────────────────────────

  static void _registerFileService(GetIt getIt) {
    if (!AppFeatures.fileOperations) return;
    getIt.registerLazySingleton<FileService>(
      // Plain Dio without auth interceptors — for public file downloads only.
      () => FileServiceImpl(Dio()),
    );
  }

  // ── P10 — App lifecycle ────────────────────────────────────────────────────

  static void _registerAppLifecycle(GetIt getIt) {
    if (!AppFeatures.appLifecycle) return;
    // registerSingleton (not lazy) — the observer must be attached immediately
    // so that lifecycle events are not missed before first getIt<> call.
    getIt.registerSingleton<AppLifecycleService>(AppLifecycleServiceImpl());
  }

  // ── P11 — Haptic feedback ─────────────────────────────────────────────────

  static void _registerHaptics(GetIt getIt) {
    if (!AppFeatures.haptics) return;
    getIt.registerLazySingleton<HapticService>(() => const HapticServiceImpl());
  }

  // ── I4 — Certificate pinning ───────────────────────────────────────────────

  static void _applyCertificatePinning(GetIt getIt) {
    if (!AppFeatures.certificatePinning) return;

    // ⚠️  Add your SHA-256 fingerprints here before enabling.
    // How to get the fingerprint:
    //   openssl s_client -connect api.example.com:443 < /dev/null 2>/dev/null \
    //     | openssl x509 -outform DER | openssl dgst -sha256 -hex
    const config = CertificatePinningConfig(
      allowedSha256Fingerprints: {
        // 'your_primary_cert_sha256_here',
        // 'your_backup_cert_sha256_here',
      },
    );

    config.apply(getIt<Dio>());
  }
}
