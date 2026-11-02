import 'package:flutter_test/flutter_test.dart';

import '../scripts/src/port_store.dart';

/// The store knows an app by its package id, its signing key and its build
/// number. Get one wrong and the port ships as a second app, or refuses to
/// install over the first — and nothing says so until the upload.
void main() {
  Map<String, String> found(
    Map<String, String> sources, [
    List<String>? paths,
  ]) => {
    for (final i in readStoreIdentity(sources, paths ?? sources.keys))
      i.label: i.value,
  };

  test('Groovy and Kotlin Gradle both give up the id and the build number', () {
    expect(
      found({
        'android/app/build.gradle': '''
          defaultConfig {
            applicationId "org.example.oldapp"
            versionCode 42
            versionName "3.1.0"
          }
          signingConfigs {
            release { storeFile file(MYAPP_STORE_FILE) }
          }''',
      }),
      {
        'Android applicationId': 'org.example.oldapp',
        'Android versionCode': '42',
        'Android versionName': '3.1.0',
        'Android signingConfigs': 'storeFile file(MYAPP_STORE_FILE) }',
      },
    );
    expect(
      found({
        'android/app/build.gradle.kts':
            'applicationId = "org.example.oldapp"\nversionCode = 7',
      }),
      {
        'Android applicationId': 'org.example.oldapp',
        'Android versionCode': '7',
      },
    );
  });

  test('iOS and Capacitor ids', () {
    expect(
      found({
        'ios/App/App.xcodeproj/project.pbxproj':
            'PRODUCT_BUNDLE_IDENTIFIER = org.example.oldapp;\n'
            'MARKETING_VERSION = 3.1;\nCURRENT_PROJECT_VERSION = 42;',
        'capacitor.config.json': '{ "appId": "org.example.oldapp" }',
      }),
      {
        'iOS bundle id': 'org.example.oldapp',
        'iOS version': '3.1',
        'iOS build': '42',
        'Capacitor appId': 'org.example.oldapp',
      },
    );
  });

  test('a signing key is listed by path, never read', () {
    final items = readStoreIdentity(const {}, [
      'android/app/release.jks',
      'android/key.properties',
      'src/app.ts',
    ]);
    expect(items.map((i) => i.value), [
      'android/app/release.jks',
      'android/key.properties',
    ]);
  });
}
