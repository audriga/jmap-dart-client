import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:jmap_dart_client/http/http_client.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/util/sieve_util.dart';

// Note: SieveScript/changes is part of the JMAP Sieve specification, but we
// are not aware of a working server implementation of it yet (Stalwart
// v1.0.0 returns an `unknownMethod` error for SieveScript/changes), so there
// is no live test here for it.
void main() {
  group('SieveScript/changes - mocked tests', () {
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

    test('SieveScript/changes : returns changes since a state', () async {
      dioAdapter.onPost(
        '',
        (server) => server.reply(200, {
          "sessionState": "s1",
          "methodResponses": [
            [
              "SieveScript/changes",
              {
                "accountId": "accSieve",
                "oldState": "st-0",
                "newState": "st-1",
                "hasMoreChanges": false,
                "created": ["s1"],
                "updated": [],
                "destroyed": []
              },
              "c0"
            ]
          ]
        }),
        data: {
          "methodCalls": [
            [
              "SieveScript/changes",
              {"accountId": "accSieve", "sinceState": "st-0"},
              "c0"
            ]
          ],
          "using": ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:sieve"]
        },
      );

      final resp = await SieveUtil.changesSieveScripts(
        client: httpClient,
        accountId: accountId,
        sinceState: State('st-0'),
      );

      expect(resp.accountId.id.value, 'accSieve');
      expect(resp.oldState.value, 'st-0');
      expect(resp.newState.value, 'st-1');
      expect(resp.hasMoreChanges, false);
      expect(resp.created.map((id) => id.value), contains('s1'));
    });
  });
}
