import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/Features/auth/login/data/models/login_model.dart';
import 'package:app_template/Features/auth/me/data/models/current_user_model.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/Features/auth/shared/models/auth_user_model.dart';
import 'package:app_template/Features/notes/data/models/note_model.dart';
import 'package:app_template/modules/data_transfer/data/models/import_report_model.dart';
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
        {'id', 'title', 'body', 'created_at', 'updated_at'},
      );
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

    test('a resource carries exactly the seven documented keys', () {
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
      });
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

    test('the validate report carries exactly six keys', () {
      expect(report.keys.toSet(), {
        'token',
        'expires_in',
        'total_rows',
        'valid_rows',
        'errors',
        'truncated_errors',
      });
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
      expect(parsed.errors, hasLength(2));
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
      expect(parsed.validRows, 2);
      expect(parsed.invalidRows, 1);
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
}
