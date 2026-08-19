import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps `lib/modules/sync/` **deletable in one operation**.
///
/// ## Why this is a test and not a note in a README
///
/// The supported way out of the sync module is to derive from the template and
/// delete the folder — and the module is planned to roughly double in size when
/// attachments land (P4.5 in `lib/modules/sync/PLAN.md`). A convention like
/// "only import it through the ports" holds for exactly as long as everyone
/// remembers it; the first forgotten import turns a six-step removal into a
/// hunt through the whole tree, and nobody notices until the day someone tries.
///
/// So the ports are enforced rather than requested. If this test fails, the
/// answer is almost never "add another port" — it is that something reached
/// into the module from a place that should not know it exists.
///
/// The mirror rule lives in `SETUP.md` → "Removing this module".
void main() {
  /// The only files allowed to name the module.
  ///
  /// - the feature flag that switches it on
  /// - the one bootstrap line that starts it
  /// - the presentation layer, which cannot live inside the module because it
  ///   depends on Flutter and the module is deliberately Flutter-free
  /// - the module itself, and its own tests
  const allowedPrefixes = <String>[
    'lib/modules/sync/',
    'lib/presentation/shared/sync/',
    'lib/modules/modules_bootstrap.dart',
    'lib/core/platform/features/app_features.dart',
    'test/sync/',
  ];

  /// The fourth shape of port: a feature that opts into sync.
  ///
  /// A contract, an executor and a decorator **have** to name the module — that
  /// is what opting in is. What matters for deletability is not that they avoid
  /// the import but that they are all in one predictable place, so removing the
  /// module stays a glob rather than a search:
  ///
  ///     rm -rf lib/modules/sync lib/presentation/shared/sync lib/**/data/sync
  ///
  /// Hence the rule this pattern enforces: **feature sync adapters live in
  /// `<feature>/data/sync/` and nowhere else.** A contract dropped into
  /// `data/repositories/` beside the ordinary one would work perfectly and
  /// would be found, months later, by whoever deleted the module and then spent
  /// an afternoon on the compile errors.
  final featureSyncAdapter = RegExp(r'^lib/Features/[^/]+/data/sync/');

  /// Generated files are rewritten from annotations, so a reference inside one
  /// is a symptom of a source file elsewhere — and that source file is what
  /// this test should be pointing at.
  bool isGenerated(String path) =>
      path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart') ||
      path.endsWith('.config.dart');

  /// Matches an `import`/`export` directive whose URI names the module.
  ///
  /// A plain substring search over the file was the first attempt, and its very
  /// first run flagged `business_failure_message_key_test.dart` — for a **code
  /// comment** that mentions `modules/sync/` while explaining why a conflict is
  /// not a business failure. A guard that fails on prose is a guard people
  /// learn to switch off, and the ban is on depending on the module, not on
  /// naming it.
  final syncImport = RegExp(
    r'''^\s*(?:import|export)\s+['"][^'"]*modules/sync/[^'"]*['"]''',
    multiLine: true,
  );

  test('nothing outside the three ports imports the sync module', () {
    final offenders = <String>[];

    for (final dir in ['lib', 'test']) {
      final root = Directory(dir);
      if (!root.existsSync()) continue;

      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final path = entity.path.replaceAll(r'\', '/');
        if (isGenerated(path)) continue;
        if (allowedPrefixes.any(path.startsWith)) continue;
        if (featureSyncAdapter.hasMatch(path)) continue;

        if (syncImport.hasMatch(entity.readAsStringSync())) {
          offenders.add(path);
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These files reach into lib/modules/sync/ from outside its ports, so '
          'deleting the module would no longer be a folder removal:\n'
          '  ${offenders.join('\n  ')}\n\n'
          'The fix is almost never a fourth port. Either the dependency belongs '
          'in presentation/shared/sync/, or it should go through a contract in '
          'core/foundation/contracts/ that the module implements — the way '
          'UnsyncedWorkProbe does.',
    );
  });

  test('a feature sync adapter outside data/sync/ is caught', () {
    // Guards the guard: the pattern above must be tight enough to reject the
    // placement it exists to prevent, or it is a hole shaped like a rule.
    expect(
      featureSyncAdapter.hasMatch('lib/Features/notes/data/sync/x.dart'),
      isTrue,
    );
    expect(
      featureSyncAdapter.hasMatch('lib/Features/notes/data/repositories/x.dart'),
      isFalse,
    );
    expect(featureSyncAdapter.hasMatch('lib/core/sync/x.dart'), isFalse);
  });

  /// The module's entire public surface — the one file the outside may name.
  const publicApi = 'modules/sync/sync_plugin.dart';

  /// Same shape as [syncImport], but it **captures** the URI, so the suffix can
  /// be judged rather than merely detected.
  final syncImportUri = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]*modules/sync/[^'"]*)['"]''',
    multiLine: true,
  );

  /// Files that may name an internal path, and why.
  ///
  /// - the module itself, whose files import each other by definition
  /// - the module's own tests, which exist to exercise `SyncContractValidator`,
  ///   `SyncLock` and the rest; routing them through the public surface would
  ///   only prove that the surface compiles
  bool mayReachInside(String path) =>
      path.startsWith('lib/modules/sync/') || path.startsWith('test/sync/');

  test('consumers reach the sync module only through sync_plugin.dart', () {
    // A deep import compiles, passes `dart analyze`, and reads exactly like a
    // legitimate one. Nothing distinguishes it until the day an internal file is
    // renamed and a consumer breaks — and for a module planned to roughly
    // double in size (P4.5 / P3.5 in `PLAN.md`), that day is coming.
    //
    // This is the second half of the deletion contract. The first test keeps the
    // *set of files* that may know the module small; this one keeps the *set of
    // symbols* they may know small, so the module stays free to move its own
    // internals without a migration.
    final offenders = <String>[];

    for (final dir in ['lib', 'test']) {
      final root = Directory(dir);
      if (!root.existsSync()) continue;

      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final path = entity.path.replaceAll(r'\', '/');
        // Generated files are rewritten from annotations — `injection.config.dart`
        // names every registered type's own file and cannot be routed through a
        // barrel. The source of a bad import there is the annotation, and that
        // source file is what the first test already covers.
        if (isGenerated(path)) continue;
        if (mayReachInside(path)) continue;

        for (final match in syncImportUri.allMatches(
          entity.readAsStringSync(),
        )) {
          final uri = match.group(1)!;
          if (uri.endsWith(publicApi)) continue;
          offenders.add('$path\n      → $uri');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These imports reach past the sync module\'s public surface:\n'
          '  ${offenders.join('\n  ')}\n\n'
          'Import package:app_template/modules/sync/sync_plugin.dart instead. '
          'If the symbol is not exported there, that is the question to answer '
          'first: either it belongs on the public surface — add one `export … '
          'show` line — or the consumer is reaching for an internal and wants a '
          'different seam.',
    );
  });

  test('the public-surface matcher judges the suffix, not the substring', () {
    // Guards the guard: a matcher that accepted anything containing the barrel's
    // name, or that missed a relative import, would be a hole shaped like a rule.
    String? uriOf(String line) =>
        syncImportUri.firstMatch(line)?.group(1);

    expect(
      uriOf("import 'package:app_template/modules/sync/sync_plugin.dart';"),
      endsWith(publicApi),
    );
    expect(uriOf("import '../../../modules/sync/sync_plugin.dart';"), endsWith(publicApi));
    expect(
      uriOf("import 'package:app_template/modules/sync/engine/sync_engine.dart';"),
      isNot(endsWith(publicApi)),
    );
    expect(
      uriOf("import 'package:app_template/modules/sync/domain/sync_status.dart';"),
      isNot(endsWith(publicApi)),
    );
    // An export is a dependency too, and re-exporting an internal would hand it
    // to everyone downstream while this file's own import looked clean.
    expect(
      uriOf("export 'package:app_template/modules/sync/data/sync_database.dart';"),
      isNot(endsWith(publicApi)),
    );
  });

  test('no sync path reaches the public Downloads folder', () {
    // `FileService.saveToDownloads` is the one call in this codebase that
    // writes outside private app storage, and it is legitimate — data-transfer
    // exports are files the user asked to keep.
    //
    // Collected data is not. A photograph taken as evidence must not land in
    // the user's Downloads folder, visible to every app and surviving this
    // app's uninstall. The call is one line away from any attachment path, so
    // the distance is enforced rather than trusted.
    final offenders = <String>[];

    for (final dir in ['lib/modules/sync', 'lib/Features']) {
      final root = Directory(dir);
      if (!root.existsSync()) continue;

      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path.replaceAll(r'\', '/');
        if (isGenerated(path)) continue;

        // Comments are stripped: these files explain *why* they avoid the call,
        // and a guard that fires on its own rationale is one people disable.
        final code = entity
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');

        if (code.contains('saveToDownloads') ||
            code.contains('getDownloadsDirectory')) {
          offenders.add(path);
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These files can write collected data into the public Downloads '
          'folder:\n  ${offenders.join('\n  ')}\n\n'
          'Attachments belong in AttachmentFileStore, which only ever uses '
          'getApplicationDocumentsDirectory().',
    );
  });

  test('the ports themselves still exist — the contract is not vacuous', () {
    // A passing test proves nothing if the module was renamed and the paths
    // silently stopped matching anything.
    expect(Directory('lib/modules/sync').existsSync(), isTrue);
    // The public surface itself: if this file were renamed away, every consumer
    // import above would be judged against a suffix nothing can match, and the
    // boundary test would pass by describing a rule about nothing.
    expect(File('lib/modules/sync/sync_plugin.dart').existsSync(), isTrue);
    expect(File('lib/modules/modules_bootstrap.dart').existsSync(), isTrue);
    expect(
      File('lib/core/platform/features/app_features.dart').existsSync(),
      isTrue,
    );
  });
}
