import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mailbox_rights.g.dart';

@JsonSerializable()
class MailboxRights with EquatableMixin {
  final bool mayReadItems;
  final bool mayAddItems;
  final bool mayRemoveItems;
  final bool maySetSeen;
  final bool maySetKeywords;
  final bool mayCreateChild;
  final bool mayRename;
  final bool mayDelete;
  final bool maySubmit;

  // Stalwart-specific extension right, not part of the base JMAP Mail spec.
  // Only meaningful on shareWith entries, not on myRights.
  @JsonKey(includeIfNull: false)
  final bool? mayShare;

  MailboxRights(
      this.mayReadItems,
      this.mayAddItems,
      this.mayRemoveItems,
      this.maySetSeen,
      this.maySetKeywords,
      this.mayCreateChild,
      this.mayRename,
      this.mayDelete,
      this.maySubmit,
      {this.mayShare});

  factory MailboxRights.fromJson(Map<String, dynamic> json) {
    return _$MailboxRightsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MailboxRightsToJson(this);

  @override
  List<Object?> get props => [mayReadItems, mayAddItems, mayRemoveItems, maySetSeen,
    maySetKeywords, mayCreateChild, mayRename, mayDelete, maySubmit, mayShare];
}
