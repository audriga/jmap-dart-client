import 'package:jmap_dart_client/http/converter/account_id_converter.dart';
import 'package:jmap_dart_client/http/converter/id_converter.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/method/method.dart';
import 'package:jmap_dart_client/jmap/core/request/request_invocation.dart';

class EmailImportObject {
  final String blobId;
  final Map<String, bool> mailboxIds;
  final Map<String, bool>? keywords;

  EmailImportObject({
    required this.blobId,
    required this.mailboxIds,
    this.keywords,
  });

  Map<String, dynamic> toJson() {
    final val = <String, dynamic>{
      'blobId': blobId,
      'mailboxIds': mailboxIds,
    };
    if (keywords != null) val['keywords'] = keywords;
    return val;
  }
}

class ImportEmailMethod extends MethodRequiringAccountId {
  final Map<Id, EmailImportObject> emails;

  ImportEmailMethod(AccountId accountId, this.emails) : super(accountId);

  @override
  MethodName get methodName => MethodName('Email/import');

  @override
  Set<CapabilityIdentifier> get requiredCapabilities => {
        CapabilityIdentifier.jmapMail,
        CapabilityIdentifier.jmapCore,
      };

  @override
  Map<String, dynamic> toJson() {
    return {
      'accountId': const AccountIdConverter().toJson(accountId),
      'emails': emails.map(
        (id, obj) => MapEntry(const IdConverter().toJson(id), obj.toJson()),
      ),
    };
  }

  @override
  List<Object?> get props => [accountId, emails];
}
