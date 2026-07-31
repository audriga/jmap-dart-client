// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sieve_script.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SieveScript _$SieveScriptFromJson(Map<String, dynamic> json) => SieveScript(
      id: _$JsonConverterFromJson<String, Id>(
          json['id'], const IdConverter().fromJson),
      name: json['name'] as String?,
      blobId: json['blobId'] as String?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$SieveScriptToJson(SieveScript instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'id',
      _$JsonConverterToJson<String, Id>(
          instance.id, const IdConverter().toJson));
  writeNotNull('name', instance.name);
  writeNotNull('blobId', instance.blobId);
  writeNotNull('isActive', instance.isActive);
  return val;
}

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
