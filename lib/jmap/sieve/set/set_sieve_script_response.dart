import 'package:jmap_dart_client/http/converter/account_id_converter.dart';
import 'package:jmap_dart_client/http/converter/id_converter.dart';
import 'package:jmap_dart_client/http/converter/state_nullable_converter.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/error/set_error.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/method/response/set_response.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/jmap/sieve/sieve_script.dart';

class SetSieveScriptResponse extends SetResponse<SieveScript> {
  SetSieveScriptResponse(
    AccountId accountId, {
    State? newState,
    State? oldState,
    Map<Id, SieveScript>? created,
    Map<Id, SieveScript?>? updated,
    Set<Id>? destroyed,
    Map<Id, SetError>? notCreated,
    Map<Id, SetError>? notUpdated,
    Map<Id, SetError>? notDestroyed,
  }) : super(
          accountId,
          newState: newState,
          oldState: oldState,
          created: created,
          updated: updated,
          destroyed: destroyed,
          notCreated: notCreated,
          notUpdated: notUpdated,
          notDestroyed: notDestroyed,
        );

  static SetSieveScriptResponse deserialize(Map<String, dynamic> json) {
    const idConverter = IdConverter();

    SieveScript? parseScript(dynamic data) =>
        data is Map<String, dynamic> ? SieveScript.fromJson(data) : null;

    Map<Id, SieveScript>? mapScripts(Map<String, dynamic>? source) {
      if (source == null) return null;

      final result = <Id, SieveScript>{};
      for (final entry in source.entries) {
        final script = parseScript(entry.value);
        if (script != null) {
          result[idConverter.fromJson(entry.key)] = script;
        }
      }
      return result.isNotEmpty ? result : null;
    }

    return SetSieveScriptResponse(
      const AccountIdConverter().fromJson(json['accountId'] as String),

      newState:
          const StateNullableConverter().fromJson(json['newState'] as String?),

      oldState:
          const StateNullableConverter().fromJson(json['oldState'] as String?),

      created: mapScripts(json['created'] as Map<String, dynamic>?),
      updated: mapScripts(json['updated'] as Map<String, dynamic>?),

      destroyed: (json['destroyed'] as List<dynamic>?)
          ?.map((id) => const IdConverter().fromJson(id))
          .toSet(),

      notCreated: (json['notCreated'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          idConverter.fromJson(key),
          SetError.fromJson(value),
        ),
      ),

      notUpdated: (json['notUpdated'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          idConverter.fromJson(key),
          SetError.fromJson(value),
        ),
      ),

      notDestroyed: (json['notDestroyed'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          idConverter.fromJson(key),
          SetError.fromJson(value),
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [
        oldState,
        newState,
        created,
        updated,
        destroyed,
        notCreated,
        notUpdated,
        notDestroyed,
      ];
}
