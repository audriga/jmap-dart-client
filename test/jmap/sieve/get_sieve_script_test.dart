import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:jmap_dart_client/http/http_client.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/request/request_invocation.dart';
import 'package:jmap_dart_client/util/session_util.dart';
import 'package:jmap_dart_client/util/sieve_util.dart';

void main() {
  group('Stalwart SieveScript - Live Test', () {
    test('SieveScript/get', () async {
      final client =
          await createLiveClientFromFile(credentialsPath: 'test/jmap/credentials/auth_ietf.json');

      final httpClient = client.httpClient;
      final accountId = client.accountId;

      final resp = await SieveUtil.getSieveScripts(
        client: httpClient,
        accountId: accountId,
      );

      expect(resp.accountId.id.value, equals(accountId.id.value));
      expect(resp.state.value, isNotEmpty);
      expect(resp.list, isNotNull);
    });

    test('SieveScript/get by id returns null when not found', () async {
      final client = await createLiveClientFromFile(
        credentialsPath: 'test/jmap/credentials/auth_ietf.json',
      );

      final httpClient = client.httpClient;
      final accountId = client.accountId;

      final fetched = await SieveUtil.getSieveScriptById(
        client: httpClient,
        accountId: accountId,
        id: 'does-not-exist',
      );

      expect(fetched, isNull);
    });
  });

  group('SieveScript/get - mocked tests', () {
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

    test('SieveScript/get : returns list', () async {
      dioAdapter.onPost(
        '',
        (server) => server.reply(200, {
          "sessionState": "s1",
          "methodResponses": [
            [
              "SieveScript/get",
              {
                "accountId": "accSieve",
                "state": "st-1",
                "list": [
                  {"id": "s1", "name": "vacation", "blobId": "b1", "isActive": true},
                  {"id": "s2", "name": "spam-filter", "blobId": "b2", "isActive": false}
                ],
                "notFound": []
              },
              "c0"
            ]
          ]
        }),
        data: {
          "methodCalls": [
            [
              "SieveScript/get",
              {"accountId": "accSieve"},
              "c0"
            ]
          ],
          "using": ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:sieve"]
        },
      );

      final resp = await SieveUtil.getSieveScripts(
        client: httpClient,
        accountId: accountId,
        methodCallId: MethodCallId('c0'),
      );

      expect(resp.accountId.id.value, 'accSieve');
      expect(resp.list.length, 2);

      expect(resp.list[0].id!.value, 's1');
      expect(resp.list[0].name, 'vacation');
      expect(resp.list[0].isActive, true);

      expect(resp.list[1].id!.value, 's2');
      expect(resp.list[1].name, 'spam-filter');
      expect(resp.list[1].isActive, false);
    });

    test('SieveScript/get : returns a single script by id', () async {
      dioAdapter.onPost(
        '',
        (server) => server.reply(200, {
          "sessionState": "s1",
          "methodResponses": [
            [
              "SieveScript/get",
              {
                "accountId": "accSieve",
                "state": "st-1",
                "list": [
                  {"id": "s123", "name": "single", "blobId": "b987", "isActive": false}
                ],
                "notFound": []
              },
              "c0"
            ]
          ]
        }),
        data: {
          "methodCalls": [
            [
              "SieveScript/get",
              {
                "accountId": "accSieve",
                "ids": ["s123"]
              },
              "c0"
            ]
          ],
          "using": ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:sieve"]
        },
      );

      final script = await SieveUtil.getSieveScriptById(
        client: httpClient,
        accountId: accountId,
        id: 's123',
      );

      expect(script, isNotNull);
      expect(script!.id!.value, 's123');
      expect(script.name, 'single');
      expect(script.blobId, 'b987');
      expect(script.isActive, false);
    });
  });
}
