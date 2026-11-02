/// ما يمرّ على اعتماد الجلسة — **لمن يريد أن يرى، لا لمن يقرّر.**
///
/// النواة تُخبر هنا بكل لحظةٍ يتبدّل فيها التوكن أو يُسأل عنه: الاستعادة عند
/// الإقلاع، والدخول، و`401` يبدأ التجديد، ونجاحُه، وتأجيلُه لانقطاع، ورفضُه من
/// الخادم. ولا تعرف من يسمع.
///
/// ## ولماذا يسكن `foundation/` لا الموديول
///
/// المُخبِرون يعيشون بـ`core/infra/network/` و`features/auth/` و
/// `features/startup/`، وكلُّها لا تستورد `modules/`. فالتبعية تُقلَب: الواجهة
/// تُعلَن هنا، والموديول `token_inspector` يسمع حين يُشعَل. نفس شكل
/// [LocalDataWiper] وللسبب نفسه.
///
/// ## العقد مع كل مستمع
///
/// - **لا يرمي.** فشلُ التتبّع لا يمسّ الجلسة؛ المستمع يلفّ معالجاته ويسجّل.
/// - **لا يُنتظر.** كلُّها `void`: التجديد لا يتأخّر لأن أحداً يكتب سجلّاً.
/// - **لا يقرّر.** لا جواب يعود إلى المُخبِر، فلا مستمع يغيّر مصير جلسة.
abstract interface class AuthSessionObserver {
  /// الإقلاع قرأ ما بالتخزين — `access == null` يعني «لا جلسة».
  void onSessionRestored(String? access, String? refresh);

  /// الدخول نجح وحُفظ الاعتماد.
  void onSignedIn(TokenGrant grant);

  /// `401` على [requestPath] بدأ تجديداً.
  void onRefreshStarted(
    String requestPath, {
    String? oldAccess,
    String? oldRefresh,
  });

  /// التجديد نجح وحُفظ الاعتماد الجديد.
  void onRefreshSucceeded(
    TokenGrant grant, {
    String? oldAccess,
    String? oldRefresh,
  });

  /// لم يُجب خادم — **والجلسة باقية**.
  void onRefreshDeferred(String reason);

  /// أجاب خادمٌ بالرفض — **والجلسة مُسحت**.
  void onRefreshRefused(int? status, String? body, String requestPath);

  /// الطلب الأصلي أُعيد بالاعتماد الجديد وعاد `401` مرّةً أخرى.
  void onUnauthorizedAfterRefresh(String requestPath);
}

/// ردُّ نقطة الاعتماد **كما أرسله الخادم** — قيمةٌ خالصة.
///
/// الحقول بعد [accessToken] اختيارية، لأن الخوادم لا تتّفق عليها: توكن جلسةٍ
/// معتم لا يحمل غير نفسه، وخادم OAuth (Keycloak وأمثاله) يرسل الأعمار والنطاق.
/// وما يصل يُمرَّر كما هو: فحصُ الإعدادات يحتاج `expires_in` و
/// `refresh_expires_in` و`scope` بالقيمة التي أرسلها الخادم، لا بقيمةٍ محسوبة.
class TokenGrant {
  const TokenGrant({
    required this.accessToken,
    required this.receivedAt,
    this.refreshToken,
    this.expiresIn,
    this.refreshExpiresIn,
    this.scope,
  });

  /// من ردٍّ بأسماء OAuth 2.0 المعيارية (`access_token` · `refresh_token` ·
  /// `expires_in` · `refresh_expires_in` · `scope`) — `null` بلا `access_token`.
  static TokenGrant? fromOAuthJson(
    Map<String, dynamic> json, {
    required DateTime receivedAt,
  }) {
    final access = json['access_token'];
    if (access is! String || access.isEmpty) return null;
    int? seconds(Object? v) => v is num ? v.toInt() : null;
    final refresh = json['refresh_token'];
    final scope = json['scope'];
    return TokenGrant(
      accessToken: access,
      receivedAt: receivedAt,
      refreshToken: refresh is String ? refresh : null,
      expiresIn: seconds(json['expires_in']),
      refreshExpiresIn: seconds(json['refresh_expires_in']),
      scope: scope is String ? scope : null,
    );
  }

  final String accessToken;
  final String? refreshToken;

  /// عمرُ الـaccess بالثواني كما أرسله الخادم.
  final int? expiresIn;

  /// عمرُ الـrefresh بالثواني كما أرسله الخادم — `0` عند Keycloak تعني «بلا سقف».
  final int? refreshExpiresIn;

  final String? scope;

  /// ساعةُ **الجهاز** لحظةَ وصول الردّ — تُقارن بـ`iat` لكشف فرق الساعة.
  final DateTime receivedAt;
}

/// لا أحد يسمع — الافتراضيّ ما دام لا موديول مُشعَل.
class NoAuthSessionObserver implements AuthSessionObserver {
  const NoAuthSessionObserver();

  @override
  void onSessionRestored(String? access, String? refresh) {}

  @override
  void onSignedIn(TokenGrant grant) {}

  @override
  void onRefreshStarted(
    String requestPath, {
    String? oldAccess,
    String? oldRefresh,
  }) {}

  @override
  void onRefreshSucceeded(
    TokenGrant grant, {
    String? oldAccess,
    String? oldRefresh,
  }) {}

  @override
  void onRefreshDeferred(String reason) {}

  @override
  void onRefreshRefused(int? status, String? body, String requestPath) {}

  @override
  void onUnauthorizedAfterRefresh(String requestPath) {}
}

/// **ما يُسجَّل بالـDI** — يمرّر كل حدثٍ إلى مستمعٍ يُعلَّق لاحقاً.
///
/// ولماذا لا يُستبدل التسجيل كما يُستبدل [LocalDataWiper]: `TokenRefreshInterceptor`
/// يُبنى مع `Dio` **قبل** أن تُقلع الموديولات، فيمسك المرجعَ الذي وجده يومها.
/// استبدالُ التسجيل بعدها يترك المعترض يُخبر الافتراضيَّ الصامت للأبد. والمرحِّل
/// مرجعٌ ثابت يتبدّل ما خلفه.
class AuthSessionRelay implements AuthSessionObserver {
  AuthSessionObserver _target = const NoAuthSessionObserver();

  /// يُنادى من الموديول عند إقلاعه — مستمعٌ واحد، والأخير يفوز.
  void attach(AuthSessionObserver observer) => _target = observer;

  @override
  void onSessionRestored(String? access, String? refresh) =>
      _target.onSessionRestored(access, refresh);

  @override
  void onSignedIn(TokenGrant grant) => _target.onSignedIn(grant);

  @override
  void onRefreshStarted(
    String requestPath, {
    String? oldAccess,
    String? oldRefresh,
  }) => _target.onRefreshStarted(
    requestPath,
    oldAccess: oldAccess,
    oldRefresh: oldRefresh,
  );

  @override
  void onRefreshSucceeded(
    TokenGrant grant, {
    String? oldAccess,
    String? oldRefresh,
  }) => _target.onRefreshSucceeded(
    grant,
    oldAccess: oldAccess,
    oldRefresh: oldRefresh,
  );

  @override
  void onRefreshDeferred(String reason) => _target.onRefreshDeferred(reason);

  @override
  void onRefreshRefused(int? status, String? body, String requestPath) =>
      _target.onRefreshRefused(status, body, requestPath);

  @override
  void onUnauthorizedAfterRefresh(String requestPath) =>
      _target.onUnauthorizedAfterRefresh(requestPath);
}
