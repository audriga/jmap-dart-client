import 'package:equatable/equatable.dart';
import 'package:jmap_dart_client/http/converter/id_converter.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sieve_script.g.dart';

@JsonSerializable()
class SieveScript with EquatableMixin {
  @IdConverter()
  @JsonKey(includeIfNull: false)
  final Id? id;

  @JsonKey(includeIfNull: false)
  final String? name;

  @JsonKey(includeIfNull: false)
  final String? blobId;

  /// Whether the server currently runs this script against incoming mail
  @JsonKey(includeIfNull: false)
  final bool? isActive;

  SieveScript({
    this.id,
    this.name,
    this.blobId,
    this.isActive,
  });

  factory SieveScript.fromJson(Map<String, dynamic> json) =>
      _$SieveScriptFromJson(json);

  Map<String, dynamic> toJson() => _$SieveScriptToJson(this);

  @override
  List<Object?> get props => [id, name, blobId, isActive];
}
