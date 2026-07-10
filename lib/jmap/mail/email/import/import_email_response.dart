import 'package:jmap_dart_client/http/converter/account_id_converter.dart';
import 'package:jmap_dart_client/http/converter/id_converter.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/error/set_error.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/method/method_response.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';

class ImportEmailResponse extends ResponseRequiringAccountId {
  final Map<Id, Email>? created;
  final Map<Id, SetError>? notCreated;

  ImportEmailResponse(
    AccountId accountId, {
    this.created,
    this.notCreated,
  }) : super(accountId);

  @override
  List<Object?> get props => [accountId, created, notCreated];

  static ImportEmailResponse deserialize(Map<String, dynamic> json) {
    return ImportEmailResponse(
      const AccountIdConverter().fromJson(json['accountId'] as String),
      created: (json['created'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          const IdConverter().fromJson(key),
          Email.fromJson(value as Map<String, dynamic>),
        ),
      ),
      notCreated: (json['notCreated'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          const IdConverter().fromJson(key),
          SetError.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}
