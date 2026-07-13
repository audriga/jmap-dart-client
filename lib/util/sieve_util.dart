import 'package:jmap_dart_client/http/http_client.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/patch_object.dart';
import 'package:jmap_dart_client/jmap/core/request/request_invocation.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/jmap/core/unsigned_int.dart';
import 'package:jmap_dart_client/jmap/jmap_request.dart';
import 'package:jmap_dart_client/jmap/sieve/changes/changes_sieve_script_method.dart';
import 'package:jmap_dart_client/jmap/sieve/changes/changes_sieve_script_response.dart';
import 'package:jmap_dart_client/jmap/sieve/get/get_sieve_script_method.dart';
import 'package:jmap_dart_client/jmap/sieve/get/get_sieve_script_response.dart';
import 'package:jmap_dart_client/jmap/sieve/set/set_sieve_script_method.dart';
import 'package:jmap_dart_client/jmap/sieve/set/set_sieve_script_response.dart';
import 'package:jmap_dart_client/jmap/sieve/sieve_script.dart';
import 'blob_util.dart';

/// Utility class for creating, updating, deleting, and fetching Sieve scripts.
///
/// A Sieve script's content is stored as a Blob, referenced by SieveScript's
/// blobId, so uploading a script reuses the same Blob/upload path as FileNode.
class SieveUtil {
  SieveUtil._();

  /// Fetches SieveScript items, optionally filtered to specific ids.
  static Future<GetSieveScriptResponse> getSieveScripts({
    required HttpClient client,
    required AccountId accountId,
    Set<Id>? ids,
    MethodCallId? methodCallId,
  }) async {
    final method = GetSieveScriptMethod(accountId);
    if (ids != null) method.ids = ids;

    return _executeGet(client: client, method: method, methodCallId: methodCallId);
  }

  /// Fetches a single SieveScript by id. Returns null if not found.
  static Future<SieveScript?> getSieveScriptById({
    required HttpClient client,
    required AccountId accountId,
    required String id,
  }) async {
    final resp = await getSieveScripts(
      client: client,
      accountId: accountId,
      ids: {Id(id)},
    );
    return resp.list.isEmpty ? null : resp.list.first;
  }

  /// Sends create, update, or destroy SieveScript operations.
  static Future<SetSieveScriptResponse> setSieveScripts({
    required HttpClient client,
    required AccountId accountId,
    Map<Id, SieveScript>? create,
    Map<Id, PatchObject>? update,
    Set<Id>? destroy,
    MethodCallId? methodCallId,
  }) async {
    final method = SetSieveScriptMethod(accountId);

    if (create != null && create.isNotEmpty) method.addCreates(create);
    if (update != null && update.isNotEmpty) method.addUpdates(update);
    if (destroy != null && destroy.isNotEmpty) method.addDestroy(destroy);

    return _executeSet(client: client, method: method, methodCallId: methodCallId);
  }

  /// Uploads Sieve script source as a Blob, then creates a SieveScript
  /// referencing that blob.
  static Future<String?> createSieveScript({
    required HttpClient client,
    required AccountId accountId,
    required String name,
    required String content,
  }) async {
    final blob = await BlobUtil.uploadBlobFromText(
      client: client,
      accountId: accountId,
      content: content,
    );

    if (blob?.blobId == null) throw Exception('Blob upload failed');

    final cid = Id('sieve-${DateTime.now().millisecondsSinceEpoch % 1000000}');
    final method = SetSieveScriptMethod(accountId)
      ..addCreate(cid, SieveScript(name: name, blobId: blob!.blobId!));

    final resp = await _executeSet(client: client, method: method);
    return resp.created?[cid]?.id?.value;
  }

  /// Updates a SieveScript using a patch object (e.g. rename).
  ///
  /// Note: `isActive` is server-set and cannot be changed this way; use
  /// [activateSieveScript] or [deactivateActiveSieveScript] instead.
  static Future<SetSieveScriptResponse> updateSieveScript({
    required HttpClient client,
    required AccountId accountId,
    required Id id,
    required PatchObject patch,
  }) {
    return setSieveScripts(
      client: client,
      accountId: accountId,
      update: {id: patch},
    );
  }

  /// Turns on the given SieveScript, replacing whichever script was
  /// previously active (a server can only have one active script at a time).
  static Future<SetSieveScriptResponse> activateSieveScript({
    required HttpClient client,
    required AccountId accountId,
    required String id,
    MethodCallId? methodCallId,
  }) {
    final method = SetSieveScriptMethod(accountId)
      ..onSuccessActivateScript = id;
    return _executeSet(client: client, method: method, methodCallId: methodCallId);
  }

  /// Turns off whichever SieveScript is currently active, if any.
  static Future<SetSieveScriptResponse> deactivateActiveSieveScript({
    required HttpClient client,
    required AccountId accountId,
    MethodCallId? methodCallId,
  }) {
    final method = SetSieveScriptMethod(accountId)
      ..onSuccessDeactivateScript = true;
    return _executeSet(client: client, method: method, methodCallId: methodCallId);
  }

  /// Deletes a SieveScript by id.
  static Future<SetSieveScriptResponse> deleteSieveScript({
    required HttpClient client,
    required AccountId accountId,
    required String id,
  }) {
    return setSieveScripts(
      client: client,
      accountId: accountId,
      destroy: {Id(id)},
    );
  }

  /// Fetches changes to SieveScript objects since a given state.
  ///
  /// Note: this is part of the JMAP Sieve specification, but not all
  /// servers implement it yet (e.g. Stalwart v1.0.0 returns an
  /// `unknownMethod` error for SieveScript/changes).
  static Future<ChangesSieveScriptResponse> changesSieveScripts({
    required HttpClient client,
    required AccountId accountId,
    required State sinceState,
    UnsignedInt? maxChanges,
    MethodCallId? methodCallId,
  }) async {
    final method =
        ChangesSieveScriptMethod(accountId, sinceState, maxChanges: maxChanges);
    final builder = JmapRequestBuilder(client, ProcessingInvocation());
    final inv = builder.invocation(method, methodCallId: methodCallId);
    final resp =
        await (builder..usings(method.requiredCapabilities)).build().execute();
    final parsed = resp.parse<ChangesSieveScriptResponse>(
      inv.methodCallId,
      ChangesSieveScriptResponse.deserialize,
    );
    if (parsed == null) throw Exception('ChangesSieveScriptResponse parse failure');
    return parsed;
  }

  /// Executes SieveScript/get.
  static Future<GetSieveScriptResponse> _executeGet({
    required HttpClient client,
    required GetSieveScriptMethod method,
    MethodCallId? methodCallId,
  }) async {
    final builder = JmapRequestBuilder(client, ProcessingInvocation());
    final inv = builder.invocation(method, methodCallId: methodCallId);
    final resp =
        await (builder..usings(method.requiredCapabilities)).build().execute();

    final parsed = resp.parse<GetSieveScriptResponse>(
      inv.methodCallId,
      GetSieveScriptResponse.deserialize,
    );
    if (parsed == null) throw Exception('GetSieveScriptResponse parse failure');
    return parsed;
  }

  /// Executes SieveScript/set.
  static Future<SetSieveScriptResponse> _executeSet({
    required HttpClient client,
    required SetSieveScriptMethod method,
    MethodCallId? methodCallId,
  }) async {
    final builder = JmapRequestBuilder(client, ProcessingInvocation());
    final inv = builder.invocation(method, methodCallId: methodCallId);
    final resp =
        await (builder..usings(method.requiredCapabilities)).build().execute();

    final parsed = resp.parse<SetSieveScriptResponse>(
      inv.methodCallId,
      SetSieveScriptResponse.deserialize,
    );
    if (parsed == null) throw Exception('SetSieveScriptResponse parse failure');
    return parsed;
  }
}
