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
import 'package:app_template/ui/widgets/audio/audio_player_tile.dart';
import 'package:app_template/ui/widgets/audio/voice_note_recorder.dart';
import 'package:app_template/ui/widgets/media/captured_photo.dart';

/// kit_audio as the app sees it — through the contracts, present or absent.
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
          body: Center(child: SizedBox(width: 360, child: child)),
        ),
      ),
    ),
  );

  testWidgets('without the kit both widgets draw nothing', (tester) async {
    await tester.pumpWidget(
      host(
        Column(
          children: [
            VoiceNoteRecorder(onRecorded: (_) {}),
            const AudioPlayerTile(source: '/tmp/a.m4a'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(IconButton), findsNothing);
    expect(find.text('Record a voice note'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with the kit the recorder offers to record', (tester) async {
    getIt.registerSingleton<AudioRecorder>(FakeAudioRecorder());
    await tester.pumpWidget(host(VoiceNoteRecorder(onRecorded: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text('Record a voice note'), findsOneWidget);
  });

  group('player', () {
    late FakeAudioPlayback player;
    setUp(() {
      player = FakeAudioPlayback();
      getIt.registerFactory<AudioPlayback>(() => player);
    });

    testWidgets('opens its source and shows the length', (tester) async {
      await tester.pumpWidget(host(const AudioPlayerTile(source: '/n.m4a')));
      await tester.pumpAndSettle();
      expect(player.opened, '/n.m4a');
      expect(find.text('00:00 / 00:30'), findsOneWidget);
    });

    testWidgets('play and pause follow the player', (tester) async {
      await tester.pumpWidget(host(const AudioPlayerTile(source: '/n.m4a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();
      expect(player.playing, isTrue);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();
      expect(player.playing, isFalse);
    });

    testWidgets('a finished note shows its full length', (tester) async {
      await tester.pumpWidget(host(const AudioPlayerTile(source: '/n.m4a')));
      await tester.pumpAndSettle();
      player.emit(
        const PlaybackState(
          position: Duration(seconds: 29),
          duration: Duration(seconds: 30),
          playing: false,
          completed: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('00:30 / 00:30'), findsOneWidget);
    });

    testWidgets('an unstated length shows the position alone', (tester) async {
      // A fresh recording's header may not state its length: the player is
      // usable, the bar waits, and no "/ 00:00" pretends the note is empty.
      player.length = Duration.zero;
      await tester.pumpWidget(host(const AudioPlayerTile(source: '/n.m4a')));
      await tester.pumpAndSettle();
      player.emit(
        const PlaybackState(position: Duration(seconds: 4), playing: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('00:04'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
      expect(find.text("This audio file can't be played"), findsNothing);
    });

    testWidgets('a file that cannot play says so', (tester) async {
      player.length = null;
      await tester.pumpWidget(host(const AudioPlayerTile(source: '/bad')));
      await tester.pumpAndSettle();
      expect(find.text("This audio file can't be played"), findsOneWidget);
    });

    testWidgets('leaving the tree releases the player', (tester) async {
      await tester.pumpWidget(host(const AudioPlayerTile(source: '/n.m4a')));
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(const SizedBox()));
      await tester.pumpAndSettle();
      expect(player.disposed, isTrue);
    });
  });

  test('an attachment is audio by its type, then by its name', () {
    expect(const CapturedPhoto(mimeType: Recording.mimeType).isAudio, isTrue);
    expect(const CapturedPhoto(label: 'note.M4A').isAudio, isTrue);
    expect(const CapturedPhoto(remotePath: r'storage\a\b.mp3').isAudio, isTrue);
    expect(
      const CapturedPhoto(label: 'note.m4a', mimeType: 'image/png').isAudio,
      isFalse,
      reason: 'the content type outranks the name',
    );
    expect(const CapturedPhoto(label: 'photo.jpg').isAudio, isFalse);
  });
}
