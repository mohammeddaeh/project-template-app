import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/Features/auth/login/data/models/login_model.dart';
import 'package:app_template/Features/auth/me/data/models/current_user_model.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/Features/auth/shared/models/auth_user_model.dart';
import 'package:app_template/Features/notes/data/models/note_model.dart';
import 'package:app_template/modules/access_control/data/models/access_control_models.dart';
import 'package:app_template/modules/access_control/domain/role.dart';
import 'package:app_template/modules/data_transfer/data/models/import_report_model.dart';
import 'package:app_template/modules/data_transfer/domain/import_report.dart';
import 'package:app_template/modules/data_transfer/data/models/transfer_resource_model.dart';
import 'package:app_template/modules/data_transfer/domain/transfer_resource.dart';
import 'package:app_template/modules/multi_device/data/models/device_session_model.dart';

/// **The check that would have caught the defect this file exists because of.**
///
/// On 2026-08-11 an audit found the client reading `data.user` from
/// `POST /account/login` against a server that has always sent `data.account`,
/// and reading `data.user` from `GET /account/me` against a server that puts
/// the account at the root of `data`. Sign-in therefore failed on every
/// attempt — with a `200 OK` in the server log, a real session row in the
/// database, and a generic "something went wrong" on the screen.
///
/// Nothing in either repository could see it:
///
/// - `dart analyze` passes — a missing key is `null`, and `null` is a
///   perfectly good `dynamic`.
/// - `tsc --noEmit` passes — the server has no idea a client exists.
/// - Both CI pipelines were green.
/// - `HandleBodyResponse` catches every exception and maps it to a `Failure`,
///   so even the throw was swallowed into a message with no stack in it.
///
/// The only place the two halves can be compared is a test that parses a
/// document written to the server's shape with the client's own parser.
///
/// ## Keeping the fixtures honest
///
/// Every file under `test/fixtures/wire/` names the backend symbol it mirrors.
/// `backend_template/src/features/**/__tests__/wire-contract.test.ts` asserts
/// the same key sets from the server side, so a rename that passes there and
/// fails here (or the reverse) is a real disagreement, not a stale fixture.
///
/// **When a payload changes, edit the fixture first.** A green suite against a
/// fixture nobody updated is exactly the reassurance that let the original
/// defect ship.
Map<String, dynamic> _fixture(String name) => jsonDecode(
      File('test/fixtures/wire/$name.json').readAsStringSync(),
    ) as Map<String, dynamic>;

void main() {
  group('POST /api/v1/account/login → data', () {
    // Mirrors `loginResponseSchema` in
    // backend_template/src/features/account/dtos/account.dto.ts
    late final Map<String, dynamic> json = _fixture('login_data');

    test('the account arrives under `account`, never `user`', () {
      expect(json.containsKey('account'), isTrue);
      expect(
        json.containsKey('user'),
        isFalse,
        reason: 'If the server ever renames this key, change LoginModel with it '
            '— do not relax this assertion.',
      );

      final model = LoginModel.fromJson(json);
      expect(model.account.id, 42);
      expect(model.account.email, 'person@example.com');
    });

    test('token and session_id both survive the round trip', () {
      final entity = LoginModel.fromJson(json).toEntity();
      expect(entity.token, isNotEmpty);
      // `session_id` was parsed and discarded before this test existed.
      expect(entity.sessionId, 108);
    });

    test('a pending_verification account maps to the state that routes to the '
        'code screen', () {
      final entity = LoginModel.fromJson(json).toEntity();
      expect(entity.user.status, AuthUserStatus.pendingVerification);
      expect(entity.user.emailVerified, isFalse);
    });
  });

  group('GET /api/v1/account/me → data', () {
    // Mirrors `WireAccount`/`toWireAccount` in the same file.
    late final Map<String, dynamic> json = _fixture('account');

    test('the account is the root of `data` — there is no wrapper key', () {
      expect(json.containsKey('user'), isFalse);
      expect(json.containsKey('account'), isFalse);

      final user = currentUserFromJson(json);
      expect(user.id, 42);
      expect(user.email, 'person@example.com');
      expect(user.fullName, 'Sara Haddad');
      expect(user.status, AuthUserStatus.active);
      expect(user.emailVerified, isTrue);
      expect(user.emailVerifiedAt, isNotNull);
      expect(user.createdAt.year, 2026);
    });

    test('AuthUserModel consumes every key the server sends, and expects no '
        'others', () {
      // The exhaustive half of the contract. `AuthUser` used to declare eight
      // fields — first_name, last_name, phone, image, address, is_admin,
      // mfa_enabled, rejection_reason — that no response has ever carried, so
      // every one of them read as empty on every account forever.
      expect(
        json.keys.toSet(),
        {
          'id',
          'email',
          'full_name',
          'email_verified',
          'email_verified_at',
          'status',
          'created_at',
        },
        reason: 'Adding a field means adding the column server-side first. '
            'See the class doc on AuthUser.',
      );
    });

    test('round-trips through the local cache without losing a field', () {
      // `CurrentUserRepository` persists via toJson and restores via fromJson.
      // A field serialized but not parsed (or the reverse) silently empties
      // itself on the next app launch and nowhere else.
      final user = currentUserFromJson(json);
      final restored =
          AuthUserModel.fromJson(AuthUserModel.fromEntity(user).toJson())
              .toEntity();
      expect(restored, user);
    });
  });

  group('POST /api/v1/auth/verify-email → data', () {
    test('carries exactly the three fields core/auth owns', () {
      expect(
        _fixture('verify_email_data').keys.toSet(),
        {'status', 'email_verified', 'email_verified_at'},
      );
    });
  });

  group('GET /api/v1/auth/sessions → data[]', () {
    // Mirrors `WireSession`/`toWireSession` in
    // backend_template/src/features/auth/dtos/auth.dto.ts
    test('every field is read', () {
      final json = _fixture('session');
      expect(
        json.keys.toSet(),
        {
          'id',
          'device_info',
          'provider',
          'created_at',
          'last_active_at',
          'expires_at',
          'is_current',
        },
      );

      final session = DeviceSessionModel.fromJson(json).toDomain();
      expect(session.id, 108);
      expect(session.isCurrent, isTrue);
      expect(session.deviceInfo, contains('android'));
      // DateTime(2000) is the model's "unparseable" sentinel — seeing it here
      // would mean a format the client cannot read, not a stale session.
      expect(session.lastActiveAt.year, 2026);
    });
  });

  group('POST /api/v1/auth/refresh → data', () {
    test('carries the rotated token the gateway stores', () {
      final json = _fixture('refresh_data');
      expect(json.keys.toSet(), {'token', 'rotated', 'expires_at'});
      // TokenRefreshGatewayImpl reads exactly these two.
      expect(json['token'], isA<String>());
      expect(json['rotated'], isA<bool>());
    });
  });

  group('GET /api/v1/notes → data (paginated)', () {
    test('the page envelope is items/page/limit/total/total_pages', () {
      // The pagination shape existed on both sides for months with no endpoint
      // using it — so it had never once been parsed from a real response.
      final json = jsonDecode(
        File('test/fixtures/wire/notes_page.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      expect(
        json.keys.toSet(),
        {'items', 'page', 'limit', 'total', 'total_pages'},
      );

      final items = (json['items'] as List<dynamic>)
          .map((e) => NoteModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
      expect(items, hasLength(2));
      expect(items.first.title, isNotEmpty);
    });

    test('a note carries every field the server sends', () {
      final json = jsonDecode(
        File('test/fixtures/wire/note.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(
        json.keys.toSet(),
        {'id', 'title', 'body', 'created_at', 'updated_at', 'version', 'is_deleted'},
      );
    });

    test('the id is a uuid string, not a number', () {
      // It was a server-assigned `int` until the sync contract landed. Parsing
      // it as one now yields `null`, which `NoteModel.fromJson` would turn into
      // `''` — every row sharing one empty id, so a list dedupes down to a
      // single item and every edit targets whichever row was parsed last.
      final note = NoteModel.fromJson(_fixture('note'));
      expect(note.id, isA<String>());
      expect(note.id, isNotEmpty);
      expect(int.tryParse(note.id), isNull);
    });

    test('version and is_deleted survive the round trip to the entity', () {
      // `version` is what makes an offline edit conditional; `is_deleted` is
      // what makes a delete travel. Dropping either in the model is invisible
      // — the list still renders — and both failures only appear later as
      // overwritten edits and notes that come back from the dead.
      final page = jsonDecode(
        File('test/fixtures/wire/notes_page.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final second = NoteModel.fromJson(
        (page['items'] as List<dynamic>)[1] as Map<String, dynamic>,
      ).toEntity();

      expect(second.version, 3);
      expect(second.isDeleted, isFalse);
    });

    test('a response predating the sync contract still parses', () {
      // Defaults matching the server's, so a deployed older backend degrades to
      // "unconditional writes" rather than to a blank list.
      final legacy = NoteModel.fromJson({
        'id': '3f2a7c14-9b1e-4d5a-8c60-2e1f4a6b8d09',
        'title': 'Buy olive oil',
        'body': null,
        'created_at': '2026-08-11T10:00:00.000Z',
        'updated_at': '2026-08-11T10:00:00.000Z',
      });
      expect(legacy.version, 1);
      expect(legacy.isDeleted, isFalse);
    });
  });

  group('GET /api/v1/data-transfer/resources → data', () {
    // Mirrors `WireTransferResource` in
    // backend_template/src/core/data-transfer/descriptor.ts, whose own key set
    // is asserted by
    // backend_template/src/core/data-transfer/__tests__/wire-contract.test.ts.
    //
    // **This descriptor is the only thing the import/export screens are built
    // from.** A renamed key does not break a parser here — it silently produces
    // an empty column list, a resource that "does not support import", or a
    // format list with nothing in it. Every one of those looks like a working
    // screen with nothing to do on it.
    late final Map<String, dynamic> json = _fixture('transfer_resources');

    test('a resource carries exactly the eight documented keys', () {
      final resource = (json['resources'] as List<dynamic>).first
          as Map<String, dynamic>;
      expect(resource.keys.toSet(), {
        'name',
        'label',
        'export_formats',
        'import_formats',
        'max_export_rows',
        'supports_import',
        'columns',
        // Added after the export screen was found shipping a hardcoded `?q=`
        // box: the first application that named its filter `search` got a
        // control that sent an ignored parameter and filtered nothing.
        'filters',
      });
    });

    test('filters are declared by the server, not guessed by the client', () {
      final resource = TransferResourceModel.fromJson(
        (json['resources'] as List<dynamic>).first as Map<String, dynamic>,
      );
      expect(resource.filters, hasLength(1));
      expect(resource.filters.single.key, 'q');
      expect(resource.filters.single.type, TransferFilterType.text);
      expect(resource.filters.single.label(isArabic: true), 'بحث بالعنوان');
      expect(resource.filters.single.placeholder(isArabic: false),
          'Part of the title');
    });

    test('a filter type this build cannot draw is dropped, not guessed', () {
      // A `select` rendered as a free-text box would invite the user to type a
      // value the server rejects — worse than the filter being absent until
      // the app is updated.
      final resource = TransferResourceModel.fromJson({
        'name': 'x',
        'label': {'ar': 'س', 'en': 'X'},
        'columns': [
          {'key': 'k', 'label': {'ar': 'ك', 'en': 'K'}, 'type': 'string'},
        ],
        'filters': [
          {'key': 'a', 'label': {'ar': 'أ', 'en': 'A'}, 'type': 'text'},
          {'key': 'b', 'label': {'ar': 'ب', 'en': 'B'}, 'type': 'radar'},
        ],
      });
      expect(resource.filters.map((f) => f.key), ['a']);
    });

    test('hint and example are separate — a meaning and a value', () {
      // They were one field, and the import screen showed a sample value where
      // an explanation belonged.
      final resource = TransferResourceModel.fromJson(
        (json['resources'] as List<dynamic>).first as Map<String, dynamic>,
      );
      final title = resource.columns.firstWhere((c) => c.key == 'title');

      expect(title.example, 'Weekly summary');
      expect(title.hint(isArabic: true), 'إلزامي · حتى ٢٠٠ حرف');
      expect(title.hint(isArabic: false), 'Required · up to 200 characters');
    });

    test('system columns are separable, so the screen can explain itself', () {
      // A user looking at a seven-column export and a three-field import needs
      // to be told the other four are ours.
      final resource = TransferResourceModel.fromJson(
        (json['resources'] as List<dynamic>).first as Map<String, dynamic>,
      );
      expect(resource.importableColumns.map((c) => c.key), ['title', 'body']);
      expect(resource.systemColumns.map((c) => c.key),
          ['id', 'created_at', 'updated_at']);
    });

    test('the parser reads every field, not just the ones a screen shows', () {
      final resource = TransferResourceModel.fromJson(
        (json['resources'] as List<dynamic>).first as Map<String, dynamic>,
      );

      expect(resource.name, 'notes');
      expect(resource.labelAr, 'الملاحظات');
      expect(resource.labelEn, 'Notes');
      expect(resource.maxExportRows, 50000);
      expect(resource.supportsImport, isTrue);
      expect(resource.exportFormats, [TransferFormat.csv, TransferFormat.xlsx]);
      expect(resource.columns, hasLength(5));
    });

    test('importable and exportable columns are told apart', () {
      // The asymmetry the whole export→edit→import round trip depends on:
      // `id` and `created_at` are ours, exportable, and never importable.
      final resource = TransferResourceModel.fromJson(
        (json['resources'] as List<dynamic>).first as Map<String, dynamic>,
      );
      expect(
        resource.importableColumns.map((c) => c.key),
        ['title', 'body'],
      );
      expect(resource.columns.firstWhere((c) => c.key == 'title').required,
          isTrue);
    });

    test('an unknown column type degrades instead of throwing', () {
      // A server that adds a type after this build shipped must not take the
      // whole screen down over one column.
      final resource = TransferResourceModel.fromJson({
        'name': 'x',
        'label': {'ar': 'س', 'en': 'X'},
        'columns': [
          {'key': 'k', 'label': {'ar': 'ك', 'en': 'K'}, 'type': 'geography'},
        ],
      });
      expect(resource.columns.single.type, TransferColumnType.unknown);
    });
  });

  group('POST /api/v1/data-transfer/{resource}/import → data', () {
    late final Map<String, dynamic> report = _fixture('import_report');
    late final Map<String, dynamic> result = _fixture('import_result');

    test('the validate report carries exactly nine keys', () {
      expect(report.keys.toSet(), {
        'token',
        'expires_in',
        'total_rows',
        'valid_rows',
        'errors',
        'truncated_errors',
        // The grid's inputs. Without `columns` + `rows` the client can only
        // print line numbers, which is the difference between a correction the
        // user makes in place and a chore they postpone.
        'columns',
        'rows',
        'truncated_rows',
      });
    });

    test('every row comes back, valid and invalid alike', () {
      // The grid paints the bad ones red — it cannot do that with only the
      // good ones, and a grid missing exactly the rows that need fixing would
      // be worse than no grid.
      final parsed = ImportReportModel.fromJson(report);
      expect(parsed.rows, hasLength(parsed.totalRows));
      expect(parsed.columns, ['title', 'body']);
      expect(parsed.hasGrid, isTrue);
    });

    test('cells arrive as text, whatever their JSON type', () {
      // A cell the server sends as a JSON number would blow up a
      // Map<String,String> cast far from here. The grid's contract is "every
      // cell is text the user can edit", enforced at the boundary.
      final parsed = ImportReportModel.fromJson({
        ...report,
        'rows': [
          {'title': 42, 'body': null},
        ],
      });
      expect(parsed.rows.single, {'title': '42', 'body': ''});
    });

    test('severity separates "must fix" from "will be skipped"', () {
      final parsed = ImportReportModel.fromJson({
        ...report,
        'errors': [
          {
            'row': 1,
            'column': 'title',
            'code': 'duplicate_in_database',
            'message': 'Already exists',
            'severity': 'warning',
          },
        ],
      });
      expect(parsed.errors.single.severity, ImportSeverity.warning);
      // Absent severity must not silently become a warning — an unknown value
      // has to fail safe as an error the user is told to fix.
      final legacy = ImportReportModel.fromJson({
        ...report,
        'errors': [
          {'row': 1, 'column': 'title', 'code': 'required', 'message': 'x'},
        ],
      });
      expect(legacy.errors.single.severity, ImportSeverity.error);
    });

    test('a duplicate names the row it collides with', () {
      final parsed = ImportReportModel.fromJson(report);
      final duplicate = parsed.errors.firstWhere(
        (e) => e.code == ImportErrorCodes.duplicateInFile,
      );
      expect(duplicate.duplicateOfRow, 1);
      expect(duplicate.row, 3);
    });

    test('errorsByCell indexes by the (row, column) intersection', () {
      // What the grid looks up per cell. Keyed by the empty string for a
      // whole-row rule, so it can be shown on the row header without competing
      // with any one cell.
      final byCell = ImportReportModel.fromJson(report).errorsByCell;
      expect(byCell[2]!['title']!.code, 'required');
      expect(byCell[3]!['title']!.code, ImportErrorCodes.duplicateInFile);
      expect(byCell[4]!['']!.message, 'Nothing to update');
    });

    test('a file past the preview cap sends no rows and says so', () {
      final parsed = ImportReportModel.fromJson({
        ...report,
        'rows': <dynamic>[],
        'truncated_rows': true,
      });
      // The client then shows the error list alone. A grid silently missing
      // rows would have the user editing a file they cannot fully see.
      expect(parsed.hasGrid, isFalse);
    });

    test('the commit report carries exactly four counts', () {
      expect(result.keys.toSet(), {
        'inserted',
        'updated',
        'skipped',
        'failed',
      });
    });

    test('a row error keeps `column: null` rather than dropping the key', () {
      final parsed = ImportReportModel.fromJson(report);
      expect(parsed.errors, hasLength(3));
      expect(parsed.errors.first.column, 'title');
      // A whole-row rule (a zod object-level refine) has no column. The client
      // renders "whole row" for it, which it cannot do if the key vanishes.
      expect(parsed.errors.last.column, isNull);
      expect(parsed.errors.last.value, isNull);
    });

    test('the row number is 1-based over DATA rows, not file lines', () {
      // The server counts the first row under the header as 1; Excel's gutter
      // counts the header as line 1. Off by one here sends every user to the
      // wrong line, and nothing fails loudly.
      final parsed = ImportReportModel.fromJson(report);
      expect(parsed.errors.first.row, 2);
      expect(parsed.errors.first.spreadsheetLine, 3);
    });

    test('a null token means "nothing to confirm", not "field missing"', () {
      final parsed = ImportReportModel.fromJson({
        ...report,
        'token': null,
        'valid_rows': 0,
      });
      expect(parsed.token, isNull);
      // The confirm button hangs off this. Defaulting a missing token to `''`
      // would put an enabled button on a screen with nothing to import, and
      // the commit would report `inserted: 0` as success.
      expect(parsed.canCommit, isFalse);
    });

    test('a full report is committable', () {
      final parsed = ImportReportModel.fromJson(report);
      expect(parsed.canCommit, isTrue);
      // One clean row out of four — the other three carry the three errors.
      expect(parsed.validRows, 1);
      expect(parsed.invalidRows, 3);
    });

    test('commit counts survive the round trip', () {
      final parsed = ImportReportModel.resultFromJson(result);
      expect(parsed.inserted, 400);
      expect(parsed.updated, 87);
      expect(parsed.skipped, 13);
      expect(parsed.failed, 0);
      expect(parsed.written, 487);
    });
  });

  group('GET /api/v1/authz/me → data', () {
    // Mirrors `myAbilitiesResponseSchema` in
    // backend_template/src/core/authz/dtos/authz.dto.ts
    late final Map<String, dynamic> json = _fixture('authz_me');

    test('the permission set arrives under `permissions`', () {
      // **The key this whole file exists to protect.** A rename here parses to
      // an empty set, and an empty ability set is indistinguishable — in the
      // app and in the code — from an account genuinely allowed nothing. That
      // is the exact shape of the defect that got the previous permissions
      // implementation deleted on 2026-08-11: a gate that is always shut reads
      // like a gate that works.
      expect(json.containsKey('permissions'), isTrue);
      expect(abilitySetFromJson(json).permissions, {
        'notes.create',
        'notes.update',
        'notes.view',
      });
    });

    test('`enabled: false` opens every gate rather than closing them', () {
      // A client hiding buttons against a server that refuses nothing shows an
      // app with no controls and no explanation. Mid-rollout is exactly when
      // that would happen.
      final open = abilitySetFromJson({...json, 'enabled': false});
      expect(open.can('anything.at_all'), isTrue);
      expect(abilitySetFromJson(json).can('anything.at_all'), isFalse);
    });

    test('an absent `enabled` is read as enforced, not as open', () {
      final absent = Map<String, dynamic>.from(json)..remove('enabled');
      expect(abilitySetFromJson(absent).enforced, isTrue);
    });

    test('`declared_keys` is absent on an ordinary response', () {
      // Requested only by debug builds. Its absence must not be read as "no
      // key is known", or every gate would report a typo.
      expect(abilitySetFromJson(json).declaredKeys, isNull);
      expect(abilitySetFromJson(json).isKnown('anything.at_all'), isTrue);
    });
  });

  group('GET /api/v1/authz/catalog → data', () {
    // Mirrors `buildCatalog` in backend_template/src/core/authz/catalog.ts
    late final Map<String, dynamic> json = _fixture('authz_catalog');
    late final catalog = catalogFromJson(json);

    test('groups arrive under `groups`, keyed by `resource`', () {
      expect(catalog.groups.map((g) => g.resource), ['audit_log', 'notes']);
    });

    test('a permission carries key, action, label, implies and synthetic', () {
      final notes = catalog.groups.firstWhere((g) => g.resource == 'notes');
      final update = notes.permissions.firstWhere((p) => p.key == 'notes.update');
      expect(update.action, 'update');
      expect(update.label.resolve('ar'), 'تعديل');
      expect(update.label.resolve('en'), 'Edit');
      // Shown under the tick, so the consequence is visible before saving.
      expect(update.implies, ['notes.view']);
      expect(update.synthetic, isFalse);
    });

    test('an inferred label is flagged, in both languages identically', () {
      final audit = catalog.groups.firstWhere((g) => g.resource == 'audit_log');
      expect(audit.labelInferred, isTrue);
      // Same string in `ar` and `en` on purpose — an obviously-untranslated
      // label prompts someone to fix it; a machine-made Arabic one does not.
      expect(audit.label.resolve('ar'), audit.label.resolve('en'));
    });

    test('the synthetic `manage` entry is last and marked', () {
      final notes = catalog.groups.firstWhere((g) => g.resource == 'notes');
      final manage = notes.permissions.last;
      expect(manage.key, 'notes.manage');
      expect(manage.synthetic, isTrue);
      expect(manage.implies, hasLength(4));
    });
  });

  group('GET /api/v1/authz/users/{id}/access → data', () {
    // Mirrors `userAccessResponseSchema` in
    // backend_template/src/core/authz/dtos/authz.dto.ts
    late final Map<String, dynamic> json = _fixture('authz_user_access');
    late final access = userAccessFromJson(json);

    test('a role keeps its stored grants and names the stale ones', () {
      final role = access.roles.single;
      // Not filtered out: hiding a stale grant would show a role different
      // from the one in the database.
      expect(role.permissions, ['notes.update', 'deleted_feature.update']);
      expect(role.stalePermissions, ['deleted_feature.update']);
      expect(role.hasStaleGrants, isTrue);
    });

    test('overrides carry the tri-state as allow/deny plus absence', () {
      expect(access.effectFor('notes.delete'), OverrideEffect.deny);
      expect(access.effectFor('notes.create'), OverrideEffect.allow);
      // "Inherit" is the absence of a row, not a value — see role.dart.
      expect(access.effectFor('notes.update'), isNull);
    });

    test('an unknown effect is dropped rather than guessed at', () {
      final withUnknown = {
        ...json,
        'overrides': [
          {'key': 'notes.view', 'effect': 'maybe', 'note': null},
        ],
      };
      // Reading an unfamiliar effect as `allow` would silently grant.
      expect(userAccessFromJson(withUnknown).overrides, isEmpty);
    });

    test('the resolved set arrives under `effective_permissions`', () {
      // The outcome, next to the inputs. `notes.delete` is granted by the role
      // and removed by the deny — which is only visible here.
      expect(access.effectivePermissions, {
        'notes.create',
        'notes.update',
        'notes.view',
      });
    });
  });
}
