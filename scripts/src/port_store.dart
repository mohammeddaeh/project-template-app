/// هويّةُ التطبيق القديم بالمتجر — **ما يجب أن يبقى كما هو ليصل التحديث**.
///
/// المتجر يعرف التطبيق بثلاثة: معرّف الحزمة، ومفتاح التوقيع، ورقم البناء. معرّفٌ
/// آخر = تطبيقٌ جديد بجانب القديم، لا تحديثٌ له. ومفتاحٌ آخر = أندرويد يرفض
/// التثبيت فوقه. ورقمُ بناءٍ أصغر = `INSTALL_FAILED_VERSION_DOWNGRADE`. وكلُّها لا
/// تظهر إلا يوم الرفع.
///
/// يُقرأ ما يُقرأ من الملفات، **ولا يُقرأ محتوى مفتاحٍ أبداً** — مسارُه وحده.
library;

class StoreIdentityItem {
  const StoreIdentityItem(this.label, this.value, this.source);

  final String label;
  final String value;
  final String source;
}

final _rules = <(String, RegExp, bool Function(String path))>[
  (
    'Android applicationId',
    RegExp(r'''applicationId\s*=?\s*["']([\w.]+)["']'''),
    (p) => p.endsWith('build.gradle') || p.endsWith('build.gradle.kts'),
  ),
  (
    'Android versionCode',
    RegExp(r'versionCode\s*=?\s*(\d+)'),
    (p) => p.endsWith('build.gradle') || p.endsWith('build.gradle.kts'),
  ),
  (
    'Android versionName',
    RegExp(r'''versionName\s*=?\s*["']([^"']+)["']'''),
    (p) => p.endsWith('build.gradle') || p.endsWith('build.gradle.kts'),
  ),
  (
    'Android signingConfigs',
    RegExp(r'signingConfigs\s*\{[\s\S]*?(storeFile[^\n]*)'),
    (p) => p.endsWith('build.gradle') || p.endsWith('build.gradle.kts'),
  ),
  (
    'iOS bundle id',
    RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*"?([\w.\-]+)"?;'),
    (p) => p.endsWith('project.pbxproj'),
  ),
  (
    'iOS version',
    RegExp(r'MARKETING_VERSION\s*=\s*([\w.]+);'),
    (p) => p.endsWith('project.pbxproj'),
  ),
  (
    'iOS build',
    RegExp(r'CURRENT_PROJECT_VERSION\s*=\s*([\w.]+);'),
    (p) => p.endsWith('project.pbxproj'),
  ),
  (
    'Capacitor appId',
    RegExp(r'''appId["']?\s*:\s*["']([\w.]+)["']'''),
    (p) => p.contains('capacitor.config.'),
  ),
  (
    'Flutter version',
    RegExp(r'^version:\s*(\S+)', multiLine: true),
    (p) => p.endsWith('pubspec.yaml'),
  ),
];

/// ما ظهر — قيمةٌ لكل مصدر، بلا تكرار.
List<StoreIdentityItem> readStoreIdentity(
  Map<String, String> sources,
  Iterable<String> allPaths,
) {
  final found = <StoreIdentityItem>[];
  final seen = <String>{};
  for (final (label, re, applies) in _rules) {
    for (final e in sources.entries) {
      if (!applies(e.key)) continue;
      for (final m in re.allMatches(e.value)) {
        final value = m[1]!.trim();
        if (seen.add('$label|$value')) {
          found.add(StoreIdentityItem(label, value, e.key));
        }
      }
    }
  }
  // مفاتيحُ التوقيع: المسار وحده — محتواها سرّ، ولا يُقرأ.
  for (final path in allPaths) {
    if (RegExp(r'\.(jks|keystore|p12)$').hasMatch(path) ||
        path.endsWith('key.properties')) {
      found.add(StoreIdentityItem('signing key file', path, path));
    }
  }
  return found;
}
