// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'changes_sieve_script_method.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangesSieveScriptMethod _$ChangesSieveScriptMethodFromJson(
        Map<String, dynamic> json) =>
    ChangesSieveScriptMethod(
      const AccountIdConverter().fromJson(json['accountId'] as String),
      const StateConverter().fromJson(json['sinceState'] as String),
      maxChanges: const UnsignedIntNullableConverter()
          .fromJson(json['maxChanges'] as int?),
    );

Map<String, dynamic> _$ChangesSieveScriptMethodToJson(
    ChangesSieveScriptMethod instance) {
  final val = <String, dynamic>{
    'accountId': const AccountIdConverter().toJson(instance.accountId),
    'sinceState': const StateConverter().toJson(instance.sinceState),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('maxChanges',
      const UnsignedIntNullableConverter().toJson(instance.maxChanges));
  return val;
}
