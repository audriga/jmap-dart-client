import 'package:json_annotation/json_annotation.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox_rights.dart';

class MailboxRightsMapConverter
    implements JsonConverter<Map<String, MailboxRights>?, Map<String, dynamic>?> {
  const MailboxRightsMapConverter();

  @override
  Map<String, MailboxRights>? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return json.map(
      (key, value) =>
          MapEntry(key, MailboxRights.fromJson(value as Map<String, dynamic>)),
    );
  }

  @override
  Map<String, dynamic>? toJson(Map<String, MailboxRights>? object) {
    if (object == null) return null;
    return object.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
  }
}
