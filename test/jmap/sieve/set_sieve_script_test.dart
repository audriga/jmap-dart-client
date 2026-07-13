import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:jmap_dart_client/http/http_client.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/patch_object.dart';
import 'package:jmap_dart_client/jmap/core/request/request_invocation.dart';
import 'package:jmap_dart_client/jmap/sieve/sieve_script.dart';
import 'package:jmap_dart_client/util/session_util.dart';
import 'package:jmap_dart_client/util/sieve_util.dart';

void main() {
  //create unique script names
  String unique(String name) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return "$ts-$name";
  }

  group('IETF SieveScript - Live API Tests', () {
    late HttpClient httpClient;
    late AccountId accountId;

    String? createdId;

    setUp(() async {
      final client = await createLiveClientFromFile(
        credentialsPath: 'test/jmap/credentials/auth_ietf.json',
      );
      httpClient = client.httpClient;
      accountId = client.accountId;
    });

    test('Simple Blob/upload + SieveScript/set', () async {
      const script = 'require ["fileinto"];\nkeep;\n';

      createdId = await SieveUtil.createSieveScript(
        client: httpClient,
        accountId: accountId,
        name: unique('simple-script'),
        content: script,
      );

      expect(createdId, isNotNull);
      expect(createdId!.isNotEmpty, true);
    });

    test('SieveScript/set : rename script', () async {
      const script = 'require ["fileinto"];\nkeep;\n';

      createdId = await SieveUtil.createSieveScript(
        client: httpClient,
        accountId: accountId,
        name: unique('update_test'),
        content: script,
      );

      expect(createdId, isNotNull);

      final newName = unique('updated_name');
      final updateResp = await SieveUtil.updateSieveScript(
        client: httpClient,
        accountId: accountId,
        id: Id(createdId!),
        patch: PatchObject({'name': newName}),
      );

      expect(updateResp, isNotNull);

      final updated = await SieveUtil.getSieveScriptById(
        client: httpClient,
        accountId: accountId,
        id: createdId!,
      );

      expect(updated, isNotNull);
      expect(updated!.name, newName);
    });

    tearDown(() async {
      if (createdId == null) return;

      await SieveUtil.deleteSieveScript(
        client: httpClient,
        accountId: accountId,
        id: createdId!,
      );

      createdId = null;
    });
  });

  group('SieveScript/set - mocked tests', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late HttpClient httpClient;

    const apiBase = 'https://mocked.test/jmap';
    final accountId = AccountId(Id('accSieve'));

    setUp(() {
      dio = Dio(BaseOptions(method: 'POST', baseUrl: apiBase));
      dioAdapter = DioAdapter(dio: dio);
      httpClient = HttpClient(dio);
    });

    test('SieveScript/set : create, update, destroy', () async {
      dioAdapter.onPost(
        '',
        (server) => server.reply(200, {
          "sessionState": "s2",
          "methodResponses": [
            [
              "SieveScript/set",
              {
                "accountId": "accSieve",
                "oldState": "st-old",
                "newState": "st-new",
                "created": {
                  "sNew": {"id": "sNew", "blobId": "bNew"}
                },
                "updated": {
                  "s1": null
                },
                "destroyed": ["s2"]
              },
              "c0"
            ]
          ]
        }),
        data: {
          "methodCalls": [
            [
              "SieveScript/set",
              {
                "accountId": "accSieve",
                "create": {
                  "sNew": {"name": "newscript", "blobId": "bNew"}
                },
                "update": {
                  "s1": {"name": "renamed-script"}
                },
                "destroy": ["s2"]
              },
              "c0"
            ]
          ],
          "using": ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:sieve"]
        },
      );

      final resp = await SieveUtil.setSieveScripts(
        client: httpClient,
        accountId: accountId,
        create: {
          Id('sNew'): SieveScript(name: 'newscript', blobId: 'bNew'),
        },
        update: {
          Id('s1'): PatchObject({'name': 'renamed-script'})
        },
        destroy: {Id('s2')},
        methodCallId: MethodCallId('c0'),
      );

      expect(resp.accountId.id.value, 'accSieve');
      expect(resp.created?[Id('sNew')]?.id?.value, 'sNew');
      expect(resp.destroyed!.first.value, 's2');
    });

    test('SieveScript/set : activate', () async {
      dioAdapter.onPost(
        '',
        (server) => server.reply(200, {
          "sessionState": "s3",
          "methodResponses": [
            [
              "SieveScript/set",
              {
                "accountId": "accSieve",
                "oldState": "st-old",
                "newState": "st-new"
              },
              "c0"
            ]
          ]
        }),
        data: {
          "methodCalls": [
            [
              "SieveScript/set",
              {
                "accountId": "accSieve",
                "onSuccessActivateScript": "s1"
              },
              "c0"
            ]
          ],
          "using": ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:sieve"]
        },
      );

      final resp = await SieveUtil.activateSieveScript(
        client: httpClient,
        accountId: accountId,
        id: 's1',
        methodCallId: MethodCallId('c0'),
      );

      expect(resp.accountId.id.value, 'accSieve');
    });

    test('SieveScript/set : deactivate', () async {
      dioAdapter.onPost(
        '',
        (server) => server.reply(200, {
          "sessionState": "s4",
          "methodResponses": [
            [
              "SieveScript/set",
              {
                "accountId": "accSieve",
                "oldState": "st-old",
                "newState": "st-new"
              },
              "c0"
            ]
          ]
        }),
        data: {
          "methodCalls": [
            [
              "SieveScript/set",
              {
                "accountId": "accSieve",
                "onSuccessDeactivateScript": true
              },
              "c0"
            ]
          ],
          "using": ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:sieve"]
        },
      );

      final resp = await SieveUtil.deactivateActiveSieveScript(
        client: httpClient,
        accountId: accountId,
        methodCallId: MethodCallId('c0'),
      );

      expect(resp.accountId.id.value, 'accSieve');
    });
  });
}
