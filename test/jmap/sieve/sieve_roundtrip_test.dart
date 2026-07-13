import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/http/http_client.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/patch_object.dart';
import 'package:jmap_dart_client/util/blob_util.dart';
import 'package:jmap_dart_client/util/session_util.dart';
import 'package:jmap_dart_client/util/sieve_util.dart';

void main() {
  group('IETF SieveScript - Live Round-Trip Tests', () {
    late HttpClient httpClient;
    late AccountId accountId;

    String? createdSieveScriptId;

    setUp(() async {
      final client = await createLiveClientFromFile(
        credentialsPath: 'test/jmap/credentials/auth_ietf.json',
      );
      httpClient = client.httpClient;
      accountId = client.accountId;
    });

    test(
        'roundtrip: upload blob -> create sieve script -> get sieve script -> get blob -> destroy',
        () async {
      const script = 'require ["fileinto"];\n'
          'if header :contains "subject" "roundtrip test" {\n'
          '  fileinto "Junk Mail";\n'
          '}\n';

      final blob = await BlobUtil.uploadBlobFromText(
        client: httpClient,
        accountId: accountId,
        content: script,
      );

      expect(blob, isNotNull);
      expect(blob!.blobId, isNotEmpty);

      final scriptName = 'roundtrip_${DateTime.now().millisecondsSinceEpoch}';

      createdSieveScriptId = await SieveUtil.createSieveScript(
        client: httpClient,
        accountId: accountId,
        name: scriptName,
        content: script,
      );

      expect(createdSieveScriptId, isNotNull);
      expect(createdSieveScriptId!.isNotEmpty, true);

      final fetched = await SieveUtil.getSieveScriptById(
        client: httpClient,
        accountId: accountId,
        id: createdSieveScriptId!,
      );

      expect(fetched, isNotNull);
      expect(fetched!.name, scriptName);
      expect(fetched.blobId, isNotNull);
      expect(fetched.isActive, false);

      final blobData = await BlobUtil.getBlob(
        client: httpClient,
        accountId: accountId,
        blobId: fetched.blobId!,
      );

      expect(blobData, script);

      await SieveUtil.deleteSieveScript(
        client: httpClient,
        accountId: accountId,
        id: createdSieveScriptId!,
      );

      final afterDelete = await SieveUtil.getSieveScriptById(
        client: httpClient,
        accountId: accountId,
        id: createdSieveScriptId!,
      );

      expect(afterDelete, isNull);

      createdSieveScriptId = null;
    });

    test('rename a sieve script via patch', () async {
      const script = 'require ["fileinto"];\nkeep;\n';

      createdSieveScriptId = await SieveUtil.createSieveScript(
        client: httpClient,
        accountId: accountId,
        name: 'rename_before_${DateTime.now().millisecondsSinceEpoch}',
        content: script,
      );

      expect(createdSieveScriptId, isNotNull);

      final newName = 'rename_after_${DateTime.now().millisecondsSinceEpoch}';

      final updateResp = await SieveUtil.updateSieveScript(
        client: httpClient,
        accountId: accountId,
        id: Id(createdSieveScriptId!),
        patch: PatchObject({'name': newName}),
      );

      expect(updateResp.notUpdated, isNull);

      final fetched = await SieveUtil.getSieveScriptById(
        client: httpClient,
        accountId: accountId,
        id: createdSieveScriptId!,
      );

      expect(fetched!.name, newName);
    });

    test('activate then deactivate a sieve script', () async {
      const script = 'require ["fileinto"];\nkeep;\n';

      createdSieveScriptId = await SieveUtil.createSieveScript(
        client: httpClient,
        accountId: accountId,
        name: 'activate_test_${DateTime.now().millisecondsSinceEpoch}',
        content: script,
      );

      expect(createdSieveScriptId, isNotNull);

      final beforeActivate = await SieveUtil.getSieveScriptById(
        client: httpClient,
        accountId: accountId,
        id: createdSieveScriptId!,
      );
      expect(beforeActivate!.isActive, false);

      await SieveUtil.activateSieveScript(
        client: httpClient,
        accountId: accountId,
        id: createdSieveScriptId!,
      );

      final afterActivate = await SieveUtil.getSieveScriptById(
        client: httpClient,
        accountId: accountId,
        id: createdSieveScriptId!,
      );
      expect(afterActivate!.isActive, true);

      await SieveUtil.deactivateActiveSieveScript(
        client: httpClient,
        accountId: accountId,
      );

      final afterDeactivate = await SieveUtil.getSieveScriptById(
        client: httpClient,
        accountId: accountId,
        id: createdSieveScriptId!,
      );
      expect(afterDeactivate!.isActive, false);
    });

    tearDown(() async {
      if (createdSieveScriptId == null) return;

      await SieveUtil.deleteSieveScript(
        client: httpClient,
        accountId: accountId,
        id: createdSieveScriptId!,
      );

      createdSieveScriptId = null;
    });
  });
}
