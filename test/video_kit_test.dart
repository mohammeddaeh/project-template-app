import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kit_contracts/kit_contracts.dart';
import 'package:kit_contracts/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/media/captured_photo.dart';
import 'package:app_template/ui/widgets/video/app_video_player.dart';

/// kit_video as the app sees it — through the contract, present or absent.
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
        home: Scaffold(
          body: Center(child: SizedBox(width: 320, child: child)),
        ),
      ),
    ),
  );

  testWidgets('without the kit the player draws nothing', (tester) async {
    await tester.pumpWidget(host(const AppVideoPlayer(source: '/v.mp4')));
    await tester.pumpAndSettle();
    expect(find.byType(AspectRatio), findsNothing);
  });

  group('with the kit', () {
    late FakeVideoPlayback player;
    setUp(() {
      player = FakeVideoPlayback();
      getIt.registerFactory<VideoPlayback>(() => player);
    });

    testWidgets('shows the picture at its own shape with its length', (
      tester,
    ) async {
      player.info = const VideoInfo(
        aspectRatio: 4 / 3,
        duration: Duration(seconds: 12),
      );
      await tester.pumpWidget(host(const AppVideoPlayer(source: '/v.mp4')));
      await tester.pumpAndSettle();
      expect(player.opened, '/v.mp4');
      expect(find.byKey(const Key('fake-video')), findsOneWidget);
      final box = tester.getSize(find.byType(AspectRatio));
      expect(box.width / box.height, closeTo(4 / 3, 0.01));
      expect(find.text('00:00 / 00:12'), findsOneWidget);
    });

    testWidgets('a tap on the picture plays it', (tester) async {
      await tester.pumpWidget(host(const AppVideoPlayer(source: '/v.mp4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fake-video')));
      await tester.pumpAndSettle();
      expect(player.playing, isTrue);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('a video that cannot play says so, with no bar', (
      tester,
    ) async {
      player.info = null;
      await tester.pumpWidget(host(const AppVideoPlayer(source: '/bad')));
      await tester.pumpAndSettle();
      expect(find.text("This video can't be played"), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('leaving the tree releases the player', (tester) async {
      await tester.pumpWidget(host(const AppVideoPlayer(source: '/v.mp4')));
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(const SizedBox()));
      await tester.pumpAndSettle();
      expect(player.disposed, isTrue);
    });
  });

  test('an attachment is video by its type, then by its name', () {
    expect(const CapturedPhoto(mimeType: 'video/mp4').isVideo, isTrue);
    expect(const CapturedPhoto(label: 'clip.MOV').isVideo, isTrue);
    expect(
      const CapturedPhoto(label: 'clip.mp4', mimeType: 'audio/mp4').isVideo,
      isFalse,
      reason: 'the content type outranks the name',
    );
    expect(const CapturedPhoto(label: 'note.m4a').isVideo, isFalse);
  });
}
