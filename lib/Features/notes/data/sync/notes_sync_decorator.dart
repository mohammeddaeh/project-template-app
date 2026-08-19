import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import 'package:app_template/Features/notes/data/sync/notes_feature_contract.dart';
import 'package:app_template/Features/notes/data/sync/sync_aware_notes_repository.dart';
import 'package:app_template/Features/notes/domain/repositories/notes_repository.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';

/// Swaps the bound [NotesRepository] for the offline-aware one, once, at
/// startup — and **only if the sync engine actually started.**
///
/// ## Why a decorator instead of just registering the sync-aware repository
///
/// Because the feature must work identically with the module switched off. If
/// `SyncAwareNotesRepository` were the registered binding, every build would
/// carry a queue, a local store and a sqflite dependency — including the
/// projects that deleted the module. The decorator runs from
/// `SyncSDK.initialize`, which returns early when `AppFeatures.offlineSync` is
/// false, so an online-only app never constructs any of it.
///
/// ## It wraps what is already bound rather than naming a concrete class
///
/// `getIt<NotesRepository>()` is resolved **before** the unregister, so the
/// inner instance is whatever the graph had — the plain implementation today,
/// or something another decorator installed before this one. Reaching for
/// `NotesRepositoryImpl` by name would quietly discard that, and the discarded
/// layer is invisible: everything compiles and one behaviour is simply gone.
@LazySingleton(as: SyncRepositoryDecorator)
class NotesSyncRepositoryDecorator implements SyncRepositoryDecorator {
  const NotesSyncRepositoryDecorator();

  @override
  Future<void> decorate(GetIt getIt) async {
    final inner = getIt<NotesRepository>();
    await getIt.unregister<NotesRepository>();

    getIt.registerLazySingleton<NotesRepository>(
      () => SyncAwareNotesRepository(
        inner,
        getIt<SyncEntityStore>(),
        getIt<SyncWriteGateway>(),
        getIt<Uuid>(),
        const NotesFeatureContract(),
      ),
    );

    LogService.debug(
      'NotesRepository is now offline-aware.',
      tag: 'SYNC-NOTES',
    );
  }
}
