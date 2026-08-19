import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:app_template/Features/notes/data/models/note_model.dart';
import 'package:app_template/Features/notes/domain/entities/note.dart';
import 'package:app_template/Features/notes/domain/repositories/notes_repository.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';

/// What the sync module needs to know about a note — **the whole of it.**
///
/// This is the first contract implemented in this repository. Before it, the
/// module shipped `SyncFeatureContract<TEntity>` with three abstract members
/// (`toJson` / `fromJson` / `localIdOf`) and **no implementation and no
/// caller**: a typed seam that cost every future feature three methods and
/// bought nothing, because the engine passed `dataJson` around as raw text.
///
/// ## Registration: `as: SyncFeatureContractBase` is the part that matters
///
/// `GetIt` keys its registry by the **literal** type — `getAll<T>()` is a map
/// lookup on `T` and nothing else (`get_it_impl.dart` → `typeRegistrations[T]`).
/// So a plain `@LazySingleton()` here registers this class under
/// `NotesFeatureContract`, and `getAll<SyncFeatureContractBase>()` — which is
/// how `SyncContractValidator` and `SyncEngine` find every contract — returns
/// an empty list.
///
/// That is not a theoretical hazard. It shipped: `validatePreInitialization()`
/// answered `false`, `SyncSDK.initialize` returned early with "no
/// SyncFeatureContractBase is registered", and **flipping
/// `AppFeatures.offlineSync` to `true` left the app running fully online** —
/// no throw, no failing test, `dart analyze` clean. A flag that silently does
/// nothing is worse than one that fails, because nothing sends anyone looking.
///
/// ## And `@Named` had to go, for a second reason in the same chain
///
/// `getAll<T>()` does return named registrations — but every caller reaches it
/// through the same guard:
///
/// ```dart
/// if (!di.isRegistered<SyncFeatureContractBase>()) return const [];
/// ```
///
/// and `isRegistered<T>()` **without an instanceName** looks only at the
/// *unnamed* list (`getRegistration(null)` → `registrations.firstOrNull`). A
/// name-only registration is invisible to it, so the guard short-circuits and
/// the `getAll` behind it never runs. Fixing the type alone left the module
/// exactly as dead as before — the test in
/// `test/sync/feature_contract_registration_test.dart` is what caught that.
///
/// So the registration is unnamed, matching the three sibling adapters in this
/// folder (`SyncExecutor`, `SyncPullExecutor`, `SyncRepositoryDecorator`),
/// which have always bound this way. The label bought nothing: nothing ever
/// read the instance name.
///
/// ## Conflict strategy
///
/// [SyncConflictStrategy.serverWins] — the default, and right for a note whose
/// only editor is its owner: a conflict here means the same account edited from
/// two devices, and the later screen is the one the user is looking at.
///
/// A form filled in the field would want field-level merge instead; a record an
/// administrator can delete under you wants `manual`. The choice is per entity
/// precisely because it is not a technical one.
@LazySingleton(as: SyncFeatureContractBase)
class NotesFeatureContract extends SyncFeatureContract<Note> {
  const NotesFeatureContract();

  @override
  String get entityName => 'notes';

  @override
  Type get repositoryContractType => NotesRepository;

  @override
  Object resolveRepository(GetIt di) => di<NotesRepository>();

  @override
  Map<String, dynamic> toJson(Note entity) =>
      NoteModel.fromEntity(entity).toJson();

  @override
  Note fromJson(Map<String, dynamic> json) => NoteModel.fromJson(json).toEntity();

  @override
  String localIdOf(Note entity) => entity.id;

  /// Rejects a payload that could never succeed, **before it is stored**.
  ///
  /// A queued job outlives the app that created it: it is replayed hours later,
  /// possibly after an update, against a server that will answer 422. Catching
  /// the shape here turns "a write that silently dead-letters tomorrow" into a
  /// failure at the moment the user pressed save, while they can still fix it.
  ///
  /// Deliberately shallow — it checks that the fields the server requires are
  /// *present*, not that their contents are valid. Restating the server's
  /// validation rules here would be a second copy of them, and the two copies
  /// drift the first time one side changes.
  @override
  bool isValidQueuePayload(Map<String, dynamic> payload) {
    final id = payload['id'];
    if (id is! String || id.isEmpty) return false;
    // A delete carries no title; a create and an update both do.
    if (payload['is_deleted'] == true) return true;
    final title = payload['title'];
    return title is String && title.trim().isNotEmpty;
  }
}
