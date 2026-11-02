import 'dart:convert';

enum TokenFormat {
  /// لا توكن.
  none,

  /// لا يُفكّ — توكنُ جلسةٍ يعرف الخادم وحده عمرَه.
  opaque,

  /// JWT — الحمولة مقروءة.
  jwt,
}

/// ما يُقرأ من توكنٍ **بلا كشفه**: البصمة والحمولة، لا التوكن نفسه.
///
/// كلُّ ما يُعرض أو يُحفظ يمرّ من هنا — فلا يصل التوكنُ كاملاً إلى شاشةٍ ولا
/// إلى سجلّ.
class TokenReading {
  const TokenReading._(this.format, this.fingerprint, this.claims);

  factory TokenReading.of(String? token) {
    if (token == null || token.isEmpty) {
      return const TokenReading._(TokenFormat.none, '-', {});
    }
    final claims = _claims(token);
    return TokenReading._(
      claims == null ? TokenFormat.opaque : TokenFormat.jwt,
      fingerprintOf(token),
      claims ?? const {},
    );
  }

  final TokenFormat format;
  final String fingerprint;
  final Map<String, dynamic> claims;

  bool get isPresent => format != TokenFormat.none;

  /// `typ` — `Bearer` · `Refresh` · `Offline` عند Keycloak.
  String? get type => claims['typ'] as String?;

  bool get isOffline => type == 'Offline';

  String? get issuer => claims['iss'] as String?;

  /// مُصدِرٌ بمسار `/realms/` — شكلُ Keycloak.
  bool get isKeycloak => issuer?.contains('/realms/') ?? false;

  DateTime? get issuedAt => _at(claims['iat']);

  /// `null` لـJWT بلا `exp` — توكن Offline بلا سقفٍ مطلق مثلاً.
  DateTime? get expiresAt => _at(claims['exp']);

  int? secondsLeft(DateTime now) => expiresAt?.difference(now).inSeconds;

  bool isExpired(DateTime now) => (secondsLeft(now) ?? 1) <= 0;

  /// ما بقي من العمر بين `0` و`1` — `null` بلا ختمين.
  double? fractionLeft(DateTime now) {
    final iat = issuedAt;
    final exp = expiresAt;
    if (iat == null || exp == null) return null;
    final total = exp.difference(iat).inSeconds;
    if (total <= 0) return null;
    return ((secondsLeft(now) ?? 0) / total).clamp(0, 1).toDouble();
  }

  String lifeLabel() {
    final iat = issuedAt;
    final exp = expiresAt;
    if (iat == null || exp == null) return 'no expiry';
    return readableDuration(exp.difference(iat).inSeconds);
  }

  String leftLabel(DateTime now) {
    final left = secondsLeft(now);
    if (left == null) return 'no expiry';
    return left <= 0
        ? 'EXPIRED ${readableDuration(-left)} ago'
        : '${readableDuration(left)} left';
  }

  /// سطرٌ واحد: `Offline · 30.0 d left · exp 12-02 10:00:26 · …LzzLzw`.
  String summary(DateTime now) => switch (format) {
    TokenFormat.none => 'none',
    TokenFormat.opaque => 'opaque · $fingerprint',
    TokenFormat.jwt =>
      '${type ?? 'JWT'} · ${leftLabel(now)} · '
          '${expiresAt == null ? 'no exp' : 'exp ${clockLabel(expiresAt!)}'} · '
          '$fingerprint',
  };

  static DateTime? _at(Object? v) => v is num && v > 0
      ? DateTime.fromMillisecondsSinceEpoch(v.toInt() * 1000)
      : null;

  static Map<String, dynamic>? _claims(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      // ثلاثةُ أجزاءٍ بنقاط ليست حمولةً بالضرورة — توكنٌ معتم بشكلٍ يشبهها.
      return null;
    }
  }
}

/// آخرُ ستّة أحرف — تكفي لرؤية «تغيّر أم لا» بلا كشف التوكن.
String fingerprintOf(String? token) {
  if (token == null || token.length < 6) return '-';
  return '…${token.substring(token.length - 6)}';
}

/// `45 s` · `12 min` · `1.5 h` · `30.0 d`.
String readableDuration(int seconds) {
  if (seconds < 120) return '$seconds s';
  if (seconds < 3600) return '${(seconds / 60).round()} min';
  if (seconds < 86400) return '${(seconds / 3600).toStringAsFixed(1)} h';
  return '${(seconds / 86400).toStringAsFixed(1)} d';
}

/// `12-02 10:00:26` بساعة الجهاز.
String clockLabel(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  final l = t.toLocal();
  return '${two(l.month)}-${two(l.day)} '
      '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
}
