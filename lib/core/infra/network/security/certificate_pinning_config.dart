import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// Configures SSL/TLS certificate pinning on a [Dio] instance.
///
/// ## What it does
/// Rejects TLS handshakes whose server certificate SHA-256 fingerprint is NOT
/// in [allowedSha256Fingerprints]. This defeats MITM attacks even when the
/// attacker holds a CA-signed certificate.
///
/// ## Setup (per project)
/// 1. Obtain the server certificate SHA-256 DER fingerprint:
///    ```bash
///    openssl s_client -connect api.example.com:443 < /dev/null 2>/dev/null \
///      | openssl x509 -outform DER \
///      | openssl dgst -sha256 -hex
///    ```
/// 2. Add the hex string (lowercase, no colons) to [allowedSha256Fingerprints].
/// 3. Call [apply] after [Dio] is created in [InjectionModule]:
///    ```dart
///    if (AppFeatures.certificatePinning) {
///      CertificatePinningConfig(allowedSha256Fingerprints: {
///        'a1b2c3...', // production cert
///        'd4e5f6...', // backup / rotation cert
///      }).apply(dio);
///    }
///    ```
///
/// ## ⚠️  Important operational notes
/// - Always include at least **two** fingerprints (primary + backup) to allow
///   seamless certificate rotation without forcing an app update.
/// - When the certificate changes on the server, ship a new app version with
///   the updated fingerprints **before** rotating the cert.
/// - Certificate pinning is OFF by default in the template because it requires
///   project-specific fingerprints. Enable via [AppFeatures.certificatePinning].
///
/// ## Platform support
/// Uses [IOHttpClientAdapter] — works on Android, iOS, macOS, Linux, Windows.
/// Does NOT work on Flutter Web (no socket access).
class CertificatePinningConfig {
  const CertificatePinningConfig({required this.allowedSha256Fingerprints});

  /// SHA-256 fingerprints of allowed server certificates (hex, lowercase).
  /// Example: `{'a1b2c3d4e5f6...', 'backup_fingerprint...'}`
  final Set<String> allowedSha256Fingerprints;

  /// Applies certificate pinning to [dio] by replacing its HTTP client adapter.
  ///
  /// Must be called AFTER [Dio] is fully configured (interceptors, base options).
  void apply(Dio dio) {
    if (allowedSha256Fingerprints.isEmpty) {
      LogService.warning(
        'CertificatePinningConfig.apply() called with empty fingerprints — '
        'pinning is disabled.',
        tag: 'CERT-PINNING',
      );
      return;
    }

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();

      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        final certDer = cert.der;
        // Compute SHA-256 of the DER-encoded certificate
        final fingerprint = _sha256Hex(certDer);

        final allowed = allowedSha256Fingerprints.contains(fingerprint);

        if (!allowed) {
          LogService.error(
            'Certificate REJECTED — host=$host, fingerprint=$fingerprint',
            tag: 'CERT-PINNING',
          );
        }

        // Returning `false` rejects the certificate (Dio raises BadCertificateFailure)
        return allowed;
      };

      return client;
    };

    LogService.info(
      'Certificate pinning active — ${allowedSha256Fingerprints.length} fingerprint(s).',
      tag: 'CERT-PINNING',
    );
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static String _sha256Hex(List<int> bytes) {
    final digest = sha256.convert(bytes);
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
