import 'package:jmap_dart_client/http/converter/account_id_converter.dart';
import 'package:jmap_dart_client/http/converter/id_converter.dart';
import 'package:jmap_dart_client/http/converter/state_converter.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/method/response/get_response.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:json_annotation/json_annotation.dart';
import '../sieve_script.dart';

part 'get_sieve_script_response.g.dart';

@StateConverter()
@AccountIdConverter()
@IdConverter()
@JsonSerializable()
class GetSieveScriptResponse extends GetResponse<SieveScript> {

  GetSieveScriptResponse(
    AccountId accountId,
    State? state,
    List<SieveScript>? list,
    List<Id>? notFound,
  ) : super(
          accountId,
          state ?? State(''),
          list ?? const <SieveScript>[],
          notFound,
        );

  factory GetSieveScriptResponse.fromJson(Map<String, dynamic> json) {
    final raw = _$GetSieveScriptResponseFromJson(json);
    return GetSieveScriptResponse(
      raw.accountId,
      raw.state,
      raw.list,
      raw.notFound,
    );
  }

  static GetSieveScriptResponse deserialize(Map<String, dynamic> json) =>
      GetSieveScriptResponse.fromJson(json);

  Map<String, dynamic> toJson() => _$GetSieveScriptResponseToJson(this);

  @override
  List<Object?> get props => [accountId, state, list, notFound];
}
