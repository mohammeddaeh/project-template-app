import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kit_contracts/kit_contracts.dart';
import 'package:kit_contracts/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/core/platform/permissions/app_permission.dart';
import 'package:app_template/core/platform/permissions/app_permission_status.dart';
import 'package:app_template/core/platform/permissions/permissions_service.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/scan/device_scan.dart';

/// kit_scan as the app sees it — through the contracts, present or absent.
void main() {
  final getIt = GetIt.instance;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  tearDown(getIt.reset);

  /// A button that runs [action] — the calls need a live context.
  Widget host(Future<void> Function(BuildContext) action) => EasyLocalization(
    supportedLocales: const [Locale('en')],
    fallbackLocale: const Locale('en'),
    path: 'assets/translations',
    assetLoader: const CodegenLoader(),
    child: Builder(
      builder: (context) => MaterialApp(
        theme: AppThemeData.light(const Locale('en'), AppFonts.available.first),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => action(context),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
  );

  test('without the kit nothing offers to scan', () {
    expect(DeviceScan.canScanCodes, isFalse);
    expect(DeviceScan.canScanDocuments, isFalse);
    expect(DeviceScan.canReadText, isFalse);
  });

  testWidgets('a code closes the sheet and releases the camera', (
    tester,
  ) async {
    final scanner = FakeCodeScanner();
    getIt
      ..registerSingleton<CodeScanner>(scanner)
      ..registerSingleton<PermissionsService>(_GrantAll());
    ScannedCode? result;

    await tester.pumpWidget(
      host((context) async => result = await DeviceScan.code(context)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fake-camera')), findsOneWidget);

    scanner.session!.read('https://example.com/x');
    await tester.pumpAndSettle();
    expect(result?.value, 'https://example.com/x');
    expect(find.byKey(const Key('fake-camera')), findsNothing);
    expect(scanner.session!.disposed, isTrue);
  });

  testWidgets('the torch follows its button', (tester) async {
    final scanner = FakeCodeScanner();
    getIt
      ..registerSingleton<CodeScanner>(scanner)
      ..registerSingleton<PermissionsService>(_GrantAll());
    await tester.pumpWidget(host(DeviceScan.code));
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.flashlight_on));
    await tester.pumpAndSettle();
    expect(scanner.session!.torch, isTrue);
    expect(find.byIcon(Icons.flashlight_off_outlined), findsOneWidget);
  });

  testWidgets('scanned pages come back in order', (tester) async {
    final scanner = FakeDocumentScanner(
      result: const DocumentScanned(['/p1.jpg', '/p2.jpg']),
    );
    getIt.registerSingleton<DocumentScanner>(scanner);
    List<String>? pages;
    await tester.pumpWidget(
      host((c) async => pages = await DeviceScan.document(c, maxPages: 2)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(pages, ['/p1.jpg', '/p2.jpg']);
    expect(scanner.askedFor, 2);
  });

  testWidgets('backing out of the scanner is no pages and no message', (
    tester,
  ) async {
    getIt.registerSingleton<DocumentScanner>(FakeDocumentScanner());
    List<String>? pages = const ['untouched'];
    await tester.pumpWidget(
      host((c) async => pages = await DeviceScan.document(c)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(pages, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('printed text is read from the image given', (tester) async {
    final recognizer = FakeTextRecognizer(text: 'SN 4471-AB');
    getIt.registerSingleton<TextRecognizer>(recognizer);
    String? text;
    await tester.pumpWidget(
      host((c) async => text = await DeviceScan.text(c, '/p1.jpg')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(text, 'SN 4471-AB');
    expect(recognizer.readFrom, '/p1.jpg');
  });
}

class _GrantAll implements PermissionsService {
  @override
  Future<Map<AppPermission, AppPermissionStatus>> requestMany(
    List<AppPermission> permissions,
  ) async => {for (final p in permissions) p: AppPermissionStatus.granted};

  @override
  Future<AppPermissionStatus> check(AppPermission p) async =>
      AppPermissionStatus.granted;

  @override
  Future<AppPermissionStatus> request(AppPermission p) async =>
      AppPermissionStatus.granted;

  @override
  Future<void> openSettings() async {}
}
