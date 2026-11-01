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
import 'package:app_template/core/platform/permissions/kit_readiness.dart';
import 'package:app_template/core/platform/permissions/permissions_service.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/inputs/custom_text_field.dart';
import 'package:app_template/ui/widgets/voice/speak_button.dart';

/// kit_voice as the app sees it: through the contracts, with the kit present
/// or absent — never through a platform package.
void main() {
  final getIt = GetIt.instance;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  tearDown(getIt.reset);

  Widget host(Widget child) => EasyLocalization(
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
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );

  group('without the kit', () {
    testWidgets('a dictation field has no microphone', (tester) async {
      await tester.pumpWidget(
        host(
          CustomTextField(controller: TextEditingController(), dictation: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.mic_none_rounded), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a speak button draws nothing', (tester) async {
      await tester.pumpWidget(host(const SpeakButton(text: 'Hello')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.volume_up_outlined), findsNothing);
    });
  });

  group('dictation', () {
    testWidgets('joins what was heard to what the field held', (tester) async {
      final input = FakeSpeechInput(
        script: const [
          SpeechHeard('wor', isFinal: false),
          SpeechHeard('world', isFinal: true),
        ],
      );
      getIt
        ..registerSingleton<SpeechInput>(input)
        ..registerSingleton<PermissionsService>(_Permissions());
      final controller = TextEditingController(text: 'Hello ');
      String? reported;

      await tester.pumpWidget(
        host(
          CustomTextField(
            controller: controller,
            dictation: true,
            onChanged: (String v) => reported = v,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();

      expect(controller.text, 'Hello world');
      expect(reported, 'Hello world');
      expect(input.lastLanguage, 'en', reason: "in the app's language");
      expect(
        find.byIcon(Icons.mic_none_rounded),
        findsOneWidget,
        reason: 'idle again once listening ends',
      );
    });

    testWidgets('a password field never dictates', (tester) async {
      getIt.registerSingleton<SpeechInput>(FakeSpeechInput());
      await tester.pumpWidget(
        host(
          CustomTextField(
            controller: TextEditingController(),
            isFieldObscure: true,
            dictation: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.mic_none_rounded), findsNothing);
    });
  });

  testWidgets('reading aloud is stopped by a second tap', (tester) async {
    final output = FakeSpeechOutput(holdUntilFinished: true);
    getIt.registerSingleton<SpeechOutput>(output);

    await tester.pumpWidget(
      host(const SpeakButton(text: 'Hello', languageCode: 'en')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.volume_up_outlined));
    await tester.pumpAndSettle();
    expect(output.spoken, ['Hello']);
    expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.stop_circle_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
  });

  group('ensureKitReady', () {
    const needs = KitNeedsPermission([
      KitPermission.microphone,
      KitPermission.speechRecognition,
    ]);

    test(
      'asks for every missing permission at once, then checks again',
      () async {
        final permissions = _Permissions();
        var granted = false;
        final readiness = await ensureKitReady(
          () async => granted ? const KitReady() : needs,
          permissions..onRequest = () => granted = true,
        );
        expect(readiness, KitReadiness.ready);
        expect(permissions.asked, [
          AppPermission.microphone,
          AppPermission.speechRecognition,
        ]);
      },
    );

    test('a permanent refusal points to the settings', () async {
      final readiness = await ensureKitReady(
        () async => needs,
        _Permissions(AppPermissionStatus.permanentlyDenied),
      );
      expect(readiness, KitReadiness.blocked);
    });

    test('a refusal this time is only denied', () async {
      final readiness = await ensureKitReady(
        () async => needs,
        _Permissions(AppPermissionStatus.denied),
      );
      expect(readiness, KitReadiness.denied);
    });

    test('an unsupported device asks for nothing', () async {
      final permissions = _Permissions();
      final readiness = await ensureKitReady(
        () async => const KitUnsupported(),
        permissions,
      );
      expect(readiness, KitReadiness.unsupported);
      expect(permissions.asked, isEmpty);
    });
  });
}

class _Permissions implements PermissionsService {
  _Permissions([this.answer = AppPermissionStatus.granted]);

  final AppPermissionStatus answer;
  final asked = <AppPermission>[];
  void Function()? onRequest;

  @override
  Future<Map<AppPermission, AppPermissionStatus>> requestMany(
    List<AppPermission> permissions,
  ) async {
    asked.addAll(permissions);
    onRequest?.call();
    return {for (final p in permissions) p: answer};
  }

  @override
  Future<AppPermissionStatus> check(AppPermission permission) async => answer;

  @override
  Future<AppPermissionStatus> request(AppPermission permission) async => answer;

  @override
  Future<void> openSettings() async {}
}
