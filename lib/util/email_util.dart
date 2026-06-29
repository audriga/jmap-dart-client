import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:jmap_dart_client/http/http_client.dart';
import 'package:jmap_dart_client/jmap/mail/email/import/import_email_method.dart';
import 'package:jmap_dart_client/jmap/mail/email/import/import_email_response.dart';
import 'package:jmap_dart_client/util/blob_util.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/patch_object.dart';
import 'package:jmap_dart_client/jmap/core/request/request_invocation.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/jmap/core/unsigned_int.dart';
import 'package:jmap_dart_client/jmap/jmap_request.dart';
import 'package:jmap_dart_client/jmap/mail/email/changes/changes_email_method.dart';
import 'package:jmap_dart_client/jmap/mail/email/changes/changes_email_response.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_filter_condition.dart';
import 'package:jmap_dart_client/jmap/mail/email/get/get_email_method.dart';
import 'package:jmap_dart_client/jmap/mail/email/get/get_email_response.dart';
import 'package:jmap_dart_client/jmap/mail/email/query/query_email_method.dart';
import 'package:jmap_dart_client/jmap/mail/email/query/query_email_response.dart';
import 'package:jmap_dart_client/jmap/mail/email/set/set_email_method.dart';
import 'package:jmap_dart_client/jmap/mail/email/set/set_email_response.dart';
import 'package:jmap_dart_client/jmap/mail/email/submission/email_submission.dart';
import 'package:jmap_dart_client/jmap/mail/email/submission/email_submission_id.dart';
import 'package:jmap_dart_client/jmap/mail/email/submission/set/set_email_submission_method.dart';
import 'package:jmap_dart_client/jmap/mail/email/submission/set/set_email_submission_response.dart';
import 'package:jmap_dart_client/util/file_node_util.dart';

/// Utility class for creating, updating, deleting, and fetching emails.
class EmailUtil {
  EmailUtil._();

  /// Fetches emails, optionally filtered to specific ids.
  static Future<GetEmailResponse> getEmails({
    required HttpClient client,
    required AccountId accountId,
    Set<Id>? ids,
    MethodCallId? methodCallId,
  }) async {
    final method = GetEmailMethod(accountId);
    if (ids != null) method.ids = ids;

    return _executeGet(client: client, method: method, methodCallId: methodCallId);
  }

  /// Fetches a single email by id. Returns null if not found.
  static Future<Email?> getEmailById({
    required HttpClient client,
    required AccountId accountId,
    required String id,
  }) async {
    final resp = await getEmails(
      client: client,
      accountId: accountId,
      ids: {Id(id)},
    );
    return resp.list.isEmpty ? null : resp.list.first;
  }

  /// Sends create, update, or destroy email operations.
  static Future<SetEmailResponse> setEmails({
    required HttpClient client,
    required AccountId accountId,
    Map<Id, Email>? create,
    Map<Id, PatchObject>? update,
    Set<Id>? destroy,
    MethodCallId? methodCallId,
  }) async {
    final method = SetEmailMethod(accountId);

    if (create != null && create.isNotEmpty) method.addCreates(create);
    if (update != null && update.isNotEmpty) method.addUpdates(update);
    if (destroy != null && destroy.isNotEmpty) method.addDestroy(destroy);

    return _executeSet(client: client, method: method, methodCallId: methodCallId);
  }

  /// Creates a new email on the server.
  static Future<SetEmailResponse> createEmail({
    required HttpClient client,
    required AccountId accountId,
    required Email email,
  }) async {
    final cid = Id('email-${DateTime.now().millisecondsSinceEpoch % 1000000}');
    final method = SetEmailMethod(accountId)..addCreate(cid, email);
    return _executeSet(client: client, method: method);
  }

  /// Updates an existing email.
  static Future<SetEmailResponse> updateEmail({
    required HttpClient client,
    required AccountId accountId,
    required Id id,
    required PatchObject patch,
  }) async {
    final method = SetEmailMethod(accountId)..addUpdates({id: patch});
    return _executeSet(client: client, method: method);
  }

  /// Deletes an email by id.
  static Future<SetEmailResponse> deleteEmail({
    required HttpClient client,
    required AccountId accountId,
    required Id id,
  }) async {
    final method = SetEmailMethod(accountId)..addDestroy({id});
    return _executeSet(client: client, method: method);
  }

  /// Fetches all email ids via paged Email/query requests.
  static Future<List<Id>> getAllEmailIds({
    required HttpClient client,
    required AccountId accountId,
    EmailFilterCondition? filter,
    int batchSize = 50,
  }) async {
    final allIds = <Id>[];
    var position = 0;

    while (true) {
      final method = QueryEmailMethod(accountId)
        ..position = position
        ..limit = UnsignedInt(batchSize);
      if (filter != null) method.filter = filter;

      final builder = JmapRequestBuilder(client, ProcessingInvocation());
      final inv = builder.invocation(method);
      final resp = await (builder..usings(method.requiredCapabilities)).build().execute();
      final parsed = resp.parse<QueryEmailResponse>(inv.methodCallId, QueryEmailResponse.deserialize);
      if (parsed == null) throw Exception('QueryEmailResponse parse failure');

      allIds.addAll(parsed.ids);

      if (parsed.ids.length < batchSize) break;
      position += batchSize;
    }

    return allIds;
  }

  /// Fetches all emails by first collecting all ids via getAllEmailIds, then fetching the actual email objects in batches.
  static Future<List<Email>> getAllEmails({
    required HttpClient client,
    required AccountId accountId,
    EmailFilterCondition? filter,
    int batchSize = 50,
  }) async {
    final ids = await getAllEmailIds(
      client: client,
      accountId: accountId,
      filter: filter,
      batchSize: batchSize,
    );

    final allEmails = <Email>[];

    for (var i = 0; i < ids.length; i += batchSize) {
      final batch = ids.skip(i).take(batchSize).toSet();
      final resp = await getEmails(client: client, accountId: accountId, ids: batch);
      allEmails.addAll(resp.list);
    }

    return allEmails;
  }

  /// Queries email ids matching the given filter.
  static Future<QueryEmailResponse> queryEmails({
    required HttpClient client,
    required AccountId accountId,
    EmailFilterCondition? filter,
    UnsignedInt? limit,
    int? position,
    bool? collapseThreads,
    MethodCallId? methodCallId,
  }) async {
    final method = QueryEmailMethod(accountId);
    if (filter != null) method.filter = filter;
    if (limit != null) method.limit = limit;
    if (position != null) method.position = position;
    if (collapseThreads != null) method.addCollapseThreads(collapseThreads);

    final builder = JmapRequestBuilder(client, ProcessingInvocation());
    final inv = builder.invocation(method, methodCallId: methodCallId);

    final resp = await (builder..usings(method.requiredCapabilities)).build().execute();
    final parsed = resp.parse<QueryEmailResponse>(
      inv.methodCallId,
      QueryEmailResponse.deserialize,
    );

    if (parsed == null) throw Exception('QueryEmailResponse parse failure');
    return parsed;
  }

  /// Sends a changes request for emails since [sinceState].
  static Future<ChangesEmailResponse> changesEmails({
    required HttpClient client,
    required AccountId accountId,
    required State sinceState,
    UnsignedInt? maxChanges,
    MethodCallId? methodCallId,
  }) async {
    final method = ChangesEmailMethod(accountId, sinceState, maxChanges: maxChanges);

    final builder = JmapRequestBuilder(client, ProcessingInvocation());
    final inv = builder.invocation(method, methodCallId: methodCallId);

    final resp = await (builder..usings(method.requiredCapabilities)).build().execute();
    final parsed = resp.parse<ChangesEmailResponse>(
      inv.methodCallId,
      ChangesEmailResponse.deserialize,
    );

    if (parsed == null) throw Exception('ChangesEmailResponse parse failure');
    return parsed;
  }

  /// Submits an email for delivery via EmailSubmission/set.
  static Future<SetEmailSubmissionResponse> sendEmail({
    required HttpClient client,
    required AccountId accountId,
    required EmailSubmission submission,
    Map<EmailSubmissionId, PatchObject>? onSuccessUpdateEmail,
    MethodCallId? methodCallId,
  }) async {
    final cid = Id('sub-${DateTime.now().millisecondsSinceEpoch % 1000000}');
    final method = SetEmailSubmissionMethod(accountId)
      ..addCreate(cid, submission);

    if (onSuccessUpdateEmail != null) {
      method.addOnSuccessUpdateEmail(onSuccessUpdateEmail);
    }

    final builder = JmapRequestBuilder(client, ProcessingInvocation());
    final inv = builder.invocation(method, methodCallId: methodCallId);

    final resp = await (builder..usings(method.requiredCapabilities)).build().execute();
    final parsed = resp.parse<SetEmailSubmissionResponse>(
      inv.methodCallId,
      SetEmailSubmissionResponse.deserialize,
    );

    if (parsed == null) throw Exception('SetEmailSubmissionResponse parse failure');
    return parsed;
  }

  /// Downloads the raw MIME content of an email as bytes.
  ///
  /// Fetches the email to get its blobId, then downloads the blob via HTTP.
  static Future<Uint8List> downloadEmailMime({
    required HttpClient client,
    required AccountId accountId,
    required String emailId,
    required Dio dio,
    required String downloadUrlTemplate,
    required String authorization,
  }) async {
    final email = await getEmailById(
      client: client,
      accountId: accountId,
      id: emailId,
    );

    if (email == null) throw Exception('Email not found: $emailId');

    final blobId = email.blobId?.value;
    if (blobId == null) throw Exception('Email $emailId has no blobId');

    return FileNodeUtil.downloadBlobRaw(
      dio: dio,
      downloadUrlTemplate: downloadUrlTemplate,
      accountId: accountId.id.value,
      blobId: blobId,
      name: 'message.eml',
      authorization: authorization,
    );
  }

  /// Uploads raw MIME bytes as a blob then imports it as an email via Email/import.
  ///
  /// Returns the id of the newly created email, or throws on failure.
  static Future<String> importEmailMime({
    required HttpClient client,
    required AccountId accountId,
    required Uint8List mimeBytes,
    required String mailboxId,
    Map<String, bool>? keywords,
  }) async {
    final blob = await BlobUtil.uploadBlobFromBytes(
      client: client,
      accountId: accountId,
      content: mimeBytes,
    );

    if (blob?.blobId == null) throw Exception('Blob upload failed');

    final cid = Id('import-${DateTime.now().millisecondsSinceEpoch % 1000000}');
    final method = ImportEmailMethod(accountId, {
      cid: EmailImportObject(
        blobId: blob!.blobId!,
        mailboxIds: {mailboxId: true},
        keywords: keywords,
      ),
    });

    final builder = JmapRequestBuilder(client, ProcessingInvocation());
    final inv = builder.invocation(method);
    final resp = await (builder..usings(method.requiredCapabilities)).build().execute();

    final parsed = resp.parse<ImportEmailResponse>(
      inv.methodCallId,
      ImportEmailResponse.deserialize,
    );

    if (parsed == null) throw Exception('ImportEmailResponse parse failure');

    final notCreated = parsed.notCreated;
    if (notCreated != null && notCreated.isNotEmpty) {
      final err = notCreated.values.first;
      throw Exception('Email/import notCreated: ${err.type.value} - ${err.description}');
    }

    final id = parsed.created?[cid]?.id?.id.value;
    if (id == null) throw Exception('Email/import: no id in created response');
    return id;
  }

  /// Internal helper for GetEmail calls.
  static Future<GetEmailResponse> _executeGet({
    required HttpClient client,
    required GetEmailMethod method,
    MethodCallId? methodCallId,
  }) async {
    final builder = JmapRequestBuilder(client, ProcessingInvocation());
    final inv = builder.invocation(method, methodCallId: methodCallId);

    final resp = await (builder..usings(method.requiredCapabilities)).build().execute();
    final parsed = resp.parse<GetEmailResponse>(
      inv.methodCallId,
      GetEmailResponse.deserialize,
    );

    if (parsed == null) throw Exception('GetEmailResponse parse failure');
    return parsed;
  }

  /// Executes a SetEmailMethod request and returns its response.
  static Future<SetEmailResponse> _executeSet({
    required HttpClient client,
    required SetEmailMethod method,
    MethodCallId? methodCallId,
  }) async {
    final builder = JmapRequestBuilder(client, ProcessingInvocation());
    final inv = builder.invocation(method, methodCallId: methodCallId);

    final resp = await (builder..usings(method.requiredCapabilities)).build().execute();
    final parsed = resp.parse<SetEmailResponse>(
      inv.methodCallId,
      SetEmailResponse.deserialize,
    );

    if (parsed == null) throw Exception('SetEmailResponse parse failure');
    return parsed;
  }
}
