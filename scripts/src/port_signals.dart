/// إشاراتُ الجرد — **ما يكشف قدرةً بالمشروع القديم، وما يقابلها بالقالب.**
///
/// تسكن هنا لا بـ`port_inventory.dart` ليقرأها `test/port_signals_test.dart`: كلُّ
/// صفٍّ بـ`readme/rules/06_CAPABILITIES.md`، وكلُّ kit تحت `packages/`، وكلُّ موديولٍ تحت
/// `lib/modules/`، يجب أن تغطّيه إشارةٌ هنا ([PortSignal.covers]) أو يُستثنى
/// بسبب ([portSignalExemptions]). فقدرةٌ تُضاف إلى القالب بلا إشارة تُفشل
/// الاختبار، بدل أن تمرّ بالنقل بلا مطابقة فتُبنى من جديد.
///
/// ## مفاتيح [PortSignal.covers]
///
/// | الشكل | يغطّي |
/// |---|---|
/// | `AppDateFormats` · `context.showDatePicker` | صفّاً بـ`06_CAPABILITIES.md` — أوّلُ رمزٍ بعمود «استعمل» (المقطع الأول إن بدأ بحرفٍ كبير، وإلا مقطعان) |
/// | `kit:voice` | `packages/kit_voice/` |
/// | `module:access_control` | `lib/modules/access_control/` |
///
/// والأنماط تُطابَق على الكود **وملفات الاعتماديات** (`package.json` · `pubspec.yaml`
/// · `build.gradle` · `Podfile` · `AndroidManifest.xml` · `Info.plist`) والأنماط
/// (`.scss` · `.css`) — فاسمُ الحزمة وحده يكفي ليُلتقط.
library;

class PortSignal {
  const PortSignal(
    this.name,
    this.pattern,
    this.target, {
    this.covers = const [],
  });

  /// ما يُرى بالمشروع القديم، بكلمتين.
  final String name;

  /// يُطابَق على كل ملفٍّ مقروء — أسماء حزم npm/pub/gradle/pods وأنماط كود.
  final String pattern;

  /// ما يقابلها بالقالب: قسمٌ بـ`06_CAPABILITIES.md`، أو kit بـ`scripts/kit.dart`،
  /// أو موديول.
  final String target;

  /// ما تغطّيه من الكتالوج — راجع رأس الملف.
  final List<String> covers;
}

/// ما لا يُنتظر أن يحمله تطبيقٌ قديم — وسببُه.
const portSignalExemptions = <String, String>{
  'module:showcase': 'جولة المطوّر بالقالب نفسه — لا يحملها تطبيقٌ يُنقل',
  'ensureKitReady':
      'سباكةُ أذونات الـkits — تأتي مع الـkit، لا مقابل لها بالقديم',
  'AuthSessionObserver': 'منفذٌ داخليّ بالنواة — لا مقابل له بالقديم',
  'AppOverlays': 'نقطةُ تركيبٍ داخلية للموديولات — لا مقابل لها بالقديم',
};

String _kit(String name, String what) =>
    '`dart run scripts/kit.dart add $name` — $what (24_DEVICE_KITS.md)';

const _backendNote = '⚠️ يحتاج نقاطه بالباك — راجع «الباك كما هو» بالخطّة';

/// بترتيب الكتالوج: التاريخ · الأرقام · النصوص · الواجهة · الحركة · السجلّ ·
/// المنصّة · الـkits · الشبكة · الموديولات.
final portSignals = <PortSignal>[
  // ── التاريخ والوقت ─────────────────────────────────────────────────────────
  const PortSignal(
    'التاريخ والوقت',
    r'moment\(|dayjs|date-fns|Intl\.DateTimeFormat|toLocaleDateString|toLocaleTimeString|DateFormat\(|SimpleDateFormat|DateFormatter|hijri|ummalqura|umalqura',
    '§التاريخ والوقت — AppDateFormats · AppDateText · HijriDateX (أم القرى) · AppTimeFormats',
    covers: [
      'AppDateText',
      'AppDateFormats',
      'date.toHijri',
      'CalendarNames',
      'AppTimeFormats',
      'date.getFormattedDate',
    ],
  ),
  const PortSignal(
    '«منذ …»',
    r'fromNow\(|timeago|formatDistance|timeAgo|RelativeTimeFormat|getRelativeTimeSpanString',
    '§التاريخ والوقت — date.timeAgo()',
    covers: ['date.timeAgo'],
  ),
  const PortSignal(
    'اختيار تاريخ',
    r'ion-datetime|DateTimePicker|datepicker|DatePicker|showDatePicker|UIDatePicker|dateRange|DateRange',
    '§التاريخ والوقت — context.showDatePicker · DateRange',
    covers: ['context.showDatePicker', 'DateRange'],
  ),
  const PortSignal(
    'اختيار وقت',
    r'TimePicker|timepicker|showTimePicker|presentation="time"',
    '§التاريخ والوقت — context.showTimePicker',
    covers: ['context.showTimePicker'],
  ),
  const PortSignal(
    'أرقام هندية',
    r'toArabicDigits|arabic-?numbers|numberingSystem|ar-EG|\\u066[0-9]',
    '§التاريخ والوقت — ArabicDigits.indic/latin لكل شكل',
    covers: ['ArabicDigits'],
  ),

  // ── الأرقام والأحجام والترتيب ──────────────────────────────────────────────
  const PortSignal(
    'الأرقام',
    r'Intl\.NumberFormat|\.toFixed\(|toLocaleString\(|NumberFormat\(|DecimalFormat',
    '§الأرقام — AppNumberFormats',
    covers: ['AppNumberFormats'],
  ),
  const PortSignal(
    'مدّة `05:12`',
    r'formatDuration|secondsTo\w*|mm:ss|HH:mm:ss|DateUtils\.formatElapsedTime',
    '§الأرقام — seconds.getTimeFromIntSeconds',
    covers: ['seconds.getTimeFromIntSeconds'],
  ),
  const PortSignal(
    'شارة عدّ',
    r'99\+|ion-badge|badgeCount|BadgeDrawable|setBadge',
    '§الأرقام — count.getPlus()',
    covers: ['count.getPlus'],
  ),
  const PortSignal(
    'حجم ملف',
    r'formatBytes|prettyBytes|filesize|formatFileSize|Formatter\.formatFileSize|/\s*1024\b',
    '§الأرقام — bytes.asFileSize',
    covers: ['bytes.asFileSize'],
  ),
  const PortSignal(
    'ترتيب طبيعيّ',
    r'numeric:\s*true|naturalSort|natural-orderby|natsort|localizedStandardCompare',
    '§الأرقام — NaturalOrder.compare',
    covers: ['NaturalOrder'],
  ),

  // ── النصوص والتحقق ─────────────────────────────────────────────────────────
  const PortSignal(
    'الأحرف الأولى',
    r'initials|getInitials',
    '§النصوص — s.initials',
    covers: ['s.initials'],
  ),
  const PortSignal(
    'تحقّق النماذج',
    r'Validators\.|\byup\b|\bzod\b|Formik|react-hook-form|isEmail|EMAIL_REGEX|Patterns\.EMAIL_ADDRESS|validator\.|FormGroup',
    '§النصوص — Email · PhoneNumber · CustomRegex · formKey.validateAndReveal()',
    covers: ['Email', 'CustomRegex', 'formKey.validateAndReveal'],
  ),
  const PortSignal(
    'ترجمة',
    r'i18next|react-intl|vue-i18n|ngx-translate|easy_localization|\$t\(|\.tr\(\)|strings\.xml|Localizable\.strings',
    '§النصوص — LocaleKeys.x.tr() (R10)',
    covers: ['LocaleKeys'],
  ),

  // ── الواجهة ─────────────────────────────────────────────────────────────────
  const PortSignal(
    'توست · رسالة عابرة',
    r'ToastController|Toastify|react-native-toast|Toast\.makeText|Snackbar|SnackBar|MatSnackBar|showToast',
    '§الواجهة — context.feedback.*',
    covers: ['context.feedback'],
  ),
  const PortSignal(
    'معالجة أخطاء الطلب',
    r'HttpErrorResponse|catchError\(|error\.response|DioException|DioError|HttpException|onErrorResumeNext',
    '§الواجهة — FailureUiMapper · ErrorView (13_ERROR_FLOW.md)',
    covers: ['FailureUiMapper'],
  ),
  const PortSignal(
    'حالة فارغة · لا اتصال',
    r'empty-?state|no-?data|NoData|ListEmptyComponent|emptyView|offline-?page|no-?internet',
    '§الواجهة — EmptyStateWidget · NoInternetWidget · RetryWidget',
    covers: ['EmptyStateWidget'],
  ),
  const PortSignal(
    'مؤشّر تحميل · هيكل',
    r'ion-spinner|LoadingController|ActivityIndicator|ProgressBar|CircularProgressIndicator|ion-skeleton-text|[Ss]keleton|[Ss]himmer',
    '§الواجهة — AppProgress · Skeletonized (R34 · R35)',
    covers: ['AppProgress'],
  ),
  const PortSignal(
    'حقل إدخال',
    r'ion-input|<input|TextInput|EditText|TextField|UITextField|mat-form-field',
    '§الواجهة — CustomTextField (R36)',
    covers: ['CustomTextField'],
  ),
  const PortSignal(
    'أيقونات SVG',
    r'ion-icon|\.svg[\x27"]|react-native-svg|SvgPicture|vector-?drawable|lucide|fontawesome',
    '§الواجهة — SvgImageWidget.icon',
    covers: ['SvgImageWidget'],
  ),
  const PortSignal(
    'صور شبكة',
    r'<img|ion-img|FastImage|Image\.network|Glide|Picasso|coil|cached_network_image|SDWebImage|Kingfisher',
    '§الواجهة — CachedImageWidget · NetworkImageWidget · AvatarWidget',
    covers: ['CachedImageWidget'],
  ),
  const PortSignal(
    'حوار · ورقة سفلية',
    r'AlertController|ModalController|ActionSheetController|Alert\.alert|<Modal|showDialog|AlertDialog|BottomSheet|UIAlertController|MatDialog',
    '§الواجهة — context.showCustomDialog · showConfirmDialog · showAppBottomSheet',
    covers: ['context.showCustomDialog'],
  ),
  const PortSignal(
    'قائمة بصفحات',
    r'ion-infinite-scroll|onEndReached|InfiniteScroll|infinite-scroll|loadMore|per_page|perPage|pageSize|PagingSource',
    '§الواجهة — PaginationCubit + PaginationBuilderWdg (14_PAGINATION.md)',
    covers: ['PaginationCubit', 'PaginationBuilderWdg'],
  ),
  const PortSignal(
    'مقاس الشاشة',
    r'@media|Dimensions\.get|useWindowDimensions|MediaQuery|screen\.width|ion-col|breakpoint',
    '§الواجهة — context.screen (22_RESPONSIVE.md)',
    covers: ['context.screen'],
  ),
  const PortSignal(
    'ألوان · ثيم',
    r'--ion-color|:root\s*\{|colors\.xml|ThemeData|createTheme|tailwind|<color name=',
    '§الواجهة — context.colors · AppPalette (01_SETUP.md)',
    covers: ['context.colors'],
  ),
  const PortSignal(
    'اتجاه RTL',
    r'dir=[\x27"]rtl|I18nManager|margin-left|padding-left|marginLeft|paddingLeft|layoutDirection',
    '§الواجهة — EdgeInsetsDirectional · AlignmentDirectional (F10)',
    covers: ['EdgeInsetsDirectional'],
  ),
  const PortSignal(
    'تنقّل بين الشاشات',
    r'NavController|router\.navigate|navigation\.navigate|Navigator\.push|startActivity|pushViewController|createStackNavigator|ion-router-outlet',
    'auto_route بـroutes/router.dart · انتقال الصفحات من الثيم (§الحركة)',
    covers: ['PredictiveBack'],
  ),

  // ── الحركة ─────────────────────────────────────────────────────────────────
  const PortSignal(
    'حركة',
    r'@angular/animations|createAnimation|Animated\.|react-native-reanimated|framer-motion|lottie|AnimationController|ObjectAnimator|UIView\.animate|@keyframes',
    '§الحركة — AppMotion · AnimatedCount · ShakeOnError · PressableScale · AppOpenContainer (R41)',
    covers: [
      'AppMotion',
      'AnimatedCount',
      'ShakeOnError',
      'PressableScale',
      'AppOpenContainer',
    ],
  ),
  const PortSignal(
    'خطوات · شرائح',
    r'ion-slides|swiper|Stepper|stepper|wizard|ViewPager|PageView',
    '§الحركة — AppStepSwitcher',
    covers: ['AppStepSwitcher'],
  ),
  const PortSignal(
    'ترتيب بالسحب',
    r'ion-reorder|DraggableFlatList|ItemTouchHelper|ReorderableListView|cdkDrag|sortablejs',
    '§الحركة — AppReorderableList',
    covers: ['AppReorderableList'],
  ),
  const PortSignal(
    'سحب صفّ',
    r'ion-item-sliding|Swipeable|Dismissible|swipe-list|SwipeAction',
    '§الحركة — AppSwipeActions',
    covers: ['AppSwipeActions'],
  ),

  // ── السجلّ ─────────────────────────────────────────────────────────────────
  const PortSignal(
    'سجلّ',
    r'console\.(log|error|warn)|Log\.[dewi]\(|NSLog|debugPrint',
    '§السجلّ — LogService (C04)',
    covers: ['LogService'],
  ),

  // ── المنصّة ─────────────────────────────────────────────────────────────────
  const PortSignal(
    'تخزين محلّي',
    r'localStorage|sessionStorage|@capacitor/preferences|Preferences\.(get|set)|AsyncStorage|SharedPreferences|indexedDB',
    '§المنصّة — StorageService',
    covers: ['StorageService'],
  ),
  const PortSignal(
    'تخزين آمن',
    r'SecureStorage|Keychain|flutter_secure_storage|EncryptedSharedPreferences',
    '§المنصّة — SecureStorageService',
    covers: ['StorageService'],
  ),
  const PortSignal(
    'إشعارات محلّية',
    r'LocalNotifications|flutter_local_notifications|scheduleNotification|NotificationCompat',
    '§المنصّة — LocalNotificationsService',
    covers: ['LocalNotificationsService'],
  ),
  const PortSignal(
    'الموقع',
    r'Geolocation|navigator\.geolocation|geolocator|FusedLocation|CLLocationManager',
    '§المنصّة — DeviceLocationService',
    covers: ['DeviceLocationService'],
  ),
  const PortSignal(
    'كاميرا · معرض',
    r'@capacitor/camera|Camera\.getPhoto|ImagePicker|image_picker|getUserMedia|UIImagePickerController',
    '§المنصّة — MediaService',
    covers: ['MediaService'],
  ),
  const PortSignal(
    'مشاركة',
    r'@capacitor/share|Share\.share|navigator\.share|share_plus|ACTION_SEND',
    '§المنصّة — ShareService',
    covers: ['ShareService'],
  ),
  const PortSignal(
    'حافظة',
    r'@capacitor/clipboard|Clipboard\.|navigator\.clipboard',
    '§المنصّة — ClipboardService',
    covers: ['ClipboardService'],
  ),
  const PortSignal(
    'اهتزاز',
    r'@capacitor/haptics|Haptics\.|navigator\.vibrate|HapticFeedback|Vibrator',
    '§المنصّة — HapticService',
    covers: ['HapticService'],
  ),
  const PortSignal(
    'فتح رابط',
    r'window\.open|Browser\.open|InAppBrowser|launchUrl|Linking\.openURL|ACTION_VIEW',
    '§المنصّة — UrlLauncherService',
    covers: ['UrlLauncherService'],
  ),
  const PortSignal(
    'بصمة · وجه',
    r'FaceID|BiometricAuth|NativeBiometric|local_auth|BiometricPrompt|LAContext',
    '§المنصّة — BiometricsService',
    covers: ['BiometricsService'],
  ),
  const PortSignal(
    'ملفات',
    r'@capacitor/filesystem|Filesystem\.|FilePicker|file_picker|DocumentPicker|ACTION_OPEN_DOCUMENT',
    '§المنصّة — FileService',
    covers: ['FileService'],
  ),
  const PortSignal(
    'إذن نظام',
    r'requestPermissions|PermissionsAndroid|permission_handler|Permissions\.request|requestAccess',
    '§المنصّة — PermissionsService · علَم بـAppFeatures',
    covers: ['PermissionsService'],
  ),
  const PortSignal(
    'حالة الشبكة',
    r'@capacitor/network|Network\.getStatus|NetInfo|navigator\.onLine|connectivity_plus|ConnectivityManager|NWPathMonitor',
    '§المنصّة — NetworkStateMonitor · ConnectivityDot',
    covers: ['NetworkStateMonitor'],
  ),
  const PortSignal(
    'توقيع',
    r'signature_pad|signature-pad|SignatureCanvas|signature-canvas|SignaturePad|flutter_signature',
    '§المنصّة — SignaturePad + InkController.toPng (بلا kit)',
    covers: ['SignaturePad'],
  ),

  // ── الـkits — تُركَّب بـscripts/kit.dart لا بـlib/ ──────────────────────────
  PortSignal(
    'إملاء · قراءة بصوت',
    r'speech_to_text|speech-recognition|SpeechRecognition|webkitSpeechRecognition|SpeechRecognizer|react-native-voice|flutter_tts|text-to-speech|TextToSpeech|react-native-tts|AVSpeechSynthesizer',
    _kit(
      'voice',
      'CustomTextField(dictation:) · DictationButton · SpeakButton',
    ),
    covers: const ['kit:voice'],
  ),
  PortSignal(
    'تسجيل · تشغيل صوت',
    r'MediaRecorder|cordova-plugin-media|@capacitor-community/media|audio-recorder|AVAudioRecorder|AVAudioPlayer|just_audio|\brecord:|expo-av|MediaPlayer',
    _kit('audio', 'VoiceNoteRecorder · AudioPlayerTile · PlaybackBar'),
    covers: const ['kit:audio', 'VoiceNoteRecorder', 'PlaybackBar'],
  ),
  PortSignal(
    'مسح QR · باركود',
    r'mobile_scanner|[Bb]arcode[Ss]canner|barcode-scanning|html5-qrcode|zxing|qr_code_scanner|code-scanner|BarcodeDetector',
    _kit('scan', 'DeviceScan.code'),
    covers: const ['kit:scan', 'DeviceScan'],
  ),
  PortSignal(
    'نصّ من صورة (OCR)',
    r'TextRecognizer|text-recognition|text_recognition|tesseract|[Oo]cr\b|VNRecognizeTextRequest',
    _kit('ocr', 'DeviceScan.text'),
    covers: const ['kit:ocr'],
  ),
  PortSignal(
    'فيديو',
    r'video_player|<video|react-native-video|VideoPlayer|ExoPlayer|AVPlayer|chewie|VideoView',
    _kit('video', 'AppVideoPlayer · PlaybackBar'),
    covers: const ['kit:video', 'AppVideoPlayer', 'PlaybackBar'],
  ),
  PortSignal(
    'اختصارات الأيقونة · تقييم المتجر',
    r'quick_actions|app-shortcuts|ShortcutManager|UIApplicationShortcutItem|in_app_review|in-app-review|rate-app|react-native-rate|StoreReview|SKStoreReviewController|ReviewManager',
    _kit('system', 'AppShortcuts · AppReview'),
    covers: const ['kit:system', 'AppShortcuts', 'AppReview'],
  ),
  PortSignal(
    'كتابة يدوية ⇐ نصّ',
    r'DigitalInkRecognizer|digital_ink|digital-ink|handwriting|myscript',
    _kit('ink', 'HandwritingInput'),
    covers: const ['kit:ink', 'HandwritingInput'],
  ),

  // ── الشبكة والبيانات ───────────────────────────────────────────────────────
  const PortSignal(
    'شبكة',
    r'axios|fetch\(|HttpClient|Dio\(|Retrofit|URLSession|OkHttp|Alamofire',
    '§الشبكة — ApiUrls · Retrofit · HandleBodyResponse (ونصٌّ بضجيج: Future<String>)',
    covers: ['ApiUrls', 'HandleBodyResponse', 'Future'],
  ),
  const PortSignal(
    'قاعدة بيانات محلّية · عمل دون اتصال',
    r'sqlite|SQLite|@capacitor-community/sqlite|Realm|WatermelonDB|sqflite|\bRoom\b|offline-?queue|syncQueue',
    '§الشبكة — modules/sync (STATUS.md أولاً) · $_backendNote',
    covers: ['modules/sync', 'module:sync'],
  ),
  const PortSignal(
    'روابط عميقة',
    r'appUrlOpen|deeplink|deep_link|universal link|intent-filter',
    '23_STARTUP_SPLASH.md §٥ — resolveDeepLink',
  ),

  // ── المصادقة ────────────────────────────────────────────────────────────────
  const PortSignal(
    'دخول بتوكن · OAuth · Keycloak',
    r'keycloak|Keycloak|flutter_appauth|react-native-app-auth|angular-oauth2-oidc|oidc-client|openid-client|AppAuth|openid-connect|grant_type|refresh_token|jwt-decode|jwt_decoder',
    'features/auth يُكيَّف للباك (الخطّة «ج») · TokenRefreshGateway + '
        'TokenGrant.fromOAuthJson · Keycloak: scope «openid offline_access» · '
        'token_inspector يفحص الجلسة على الجهاز (33_MODULE_TOKEN_INSPECTOR.md §٦)',
    covers: ['module:token_inspector', 'TokenInspector'],
  ),

  // ── الموديولات ─────────────────────────────────────────────────────────────
  const PortSignal(
    'أدوار · صلاحيات',
    r'hasRole|hasPermission|ngx-permissions|@casl|canActivate|isAdmin|userRoles|permissions\s*[:=]',
    'Can(permission:) · modules/access_control — $_backendNote (/authz)',
    covers: ['Can', 'module:access_control'],
  ),
  const PortSignal(
    'استيراد · تصدير ملفات',
    r'\bxlsx\b|exceljs|papaparse|SheetJS|json2csv|exportToExcel|apache\.poi|\.csv[\x27"]',
    'DataTransferSheet.show · modules/data_transfer — $_backendNote (/data-transfer)',
    covers: ['DataTransferSheet', 'module:data_transfer'],
  ),
  const PortSignal(
    'الأجهزة والجلسات',
    r'/sessions|activeSessions|revokeSession|logoutAll|logout-all|otherDevices',
    'modules/multi_device — $_backendNote (/auth/sessions)',
    covers: ['module:multi_device'],
  ),
  const PortSignal(
    'قفل التطبيق (رقم · خمول)',
    r'pin-?code|PinCode|passcode|lock-?screen|LockScreen|AppLock|ng-idle|inactivity|idleTimeout',
    'modules/session_guard',
    covers: ['module:session_guard'],
  ),
  const PortSignal(
    'إشعارات push',
    r'PushNotifications|firebase/messaging|FirebaseMessaging|firebase_messaging|onesignal|OneSignal',
    'modules/push_notifications',
    covers: ['module:push_notifications'],
  ),
  const PortSignal(
    'مركز إشعارات',
    r'notifications?-?(list|center|inbox)|NotificationCenter|unreadCount|unread_count|markAsRead',
    'modules/notification_center (فوق push_notifications)',
    covers: ['module:notification_center'],
  ),
  const PortSignal(
    'تحديث إجباري',
    r'in_app_update|app-update|appUpdate|forceUpdate|force_update|upgrader|minVersion|min_version|latest_version',
    'modules/in_app_updates — نقطة الإعدادات تُربط بما يعيده الباك',
    covers: ['module:in_app_updates'],
  ),
  const PortSignal(
    'إعدادات بعيدة',
    r'remote-config|remoteConfig|remote_config|RemoteConfig',
    'modules/remote_config',
    covers: ['module:remote_config'],
  ),
  const PortSignal(
    'تحليلات',
    r'firebase/analytics|firebase_analytics|logEvent|gtag\(|mixpanel|amplitude|FirebaseAnalytics',
    'modules/analytics',
    covers: ['module:analytics'],
  ),
  const PortSignal(
    'تقارير الانهيار',
    r'[Cc]rashlytics|@sentry|sentry_flutter|Sentry\.|bugsnag',
    'modules/crash_reporting',
    covers: ['module:crash_reporting'],
  ),

  // ── بلا مقابل ──────────────────────────────────────────────────────────────
  const PortSignal(
    'خرائط',
    r'google\.maps|GoogleMap|leaflet|mapbox|MapView',
    '✖️ لا قدرة بالقالب — سجّلها بـTEMPLATE_FEEDBACK إن كانت عامّة',
  ),
  const PortSignal(
    'دفع',
    r'\b[Ss]tripe\b|paypal|InAppPurchase|in_app_purchase|StoreKit',
    '✖️ لا قدرة بالقالب',
  ),
];

/// أسماءُ ملفات الاعتماديات والإعداد — تُقرأ مع الكود، فاسمُ حزمةٍ وحده يكفي.
const portManifestNames = {
  'package.json',
  'pubspec.yaml',
  'build.gradle',
  'build.gradle.kts',
  'Podfile',
  'AndroidManifest.xml',
  'Info.plist',
  'colors.xml',
  'strings.xml',
};

/// امتداداتُ ما تُطابَق عليه الإشارات وحده — الأنماط لا تُحسب «ملفات كود».
const portStyleExtensions = ['.scss', '.css', '.less'];

/// الإشارات التي ظهرت بـ[sources] (مسارٌ ⇐ نصّ)، مع ملفاتها مرتّبة.
List<(PortSignal, List<String>)> scanPortSignals(Map<String, String> sources) {
  final found = <(PortSignal, List<String>)>[];
  for (final signal in portSignals) {
    final re = RegExp(signal.pattern);
    final hits = [
      for (final e in sources.entries)
        if (re.hasMatch(e.value)) e.key,
    ]..sort();
    if (hits.isNotEmpty) found.add((signal, hits));
  }
  return found;
}
