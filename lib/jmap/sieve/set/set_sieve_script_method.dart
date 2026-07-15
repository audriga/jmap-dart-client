import 'package:jmap_dart_client/http/converter/account_id_converter.dart';
import 'package:jmap_dart_client/http/converter/set/set_method_properties_converter.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/method/request/set_method.dart';
import 'package:jmap_dart_client/jmap/core/request/request_invocation.dart';
import 'package:jmap_dart_client/jmap/sieve/sieve_script.dart';

class SetSieveScriptMethod extends SetMethod<SieveScript> {
  SetSieveScriptMethod(AccountId accountId) : super(accountId);

  /// Turns on the script with this id after the call succeeds. Use
  /// '#creationId' to activate a script created in the same call.
  String? onSuccessActivateScript;

  /// Turns off whichever script is currently active, once the call succeeds.
  bool? onSuccessDeactivateScript;

  // Cyrus has a typo: it checks 'onSuccessDeactivatescript' (lowercase s) and
  // rejects the RFC key above. This field is used as a fallback for Cyrus.
  bool? onSuccessDeactivatescript;

  @override
  MethodName get methodName => MethodName('SieveScript/set');

  @override
  Set<CapabilityIdentifier> get requiredCapabilities =>
      {CapabilityIdentifier.jmapCore, CapabilityIdentifier.jmapSieve};

  @override
  Map<String, dynamic> toJson() {
    final val = <String, dynamic>{
      'accountId': const AccountIdConverter().toJson(accountId),
    };

    void writeNotNull(String key, dynamic value) {
      if (value != null) val[key] = value;
    }

    writeNotNull('ifInState', ifInState?.value);

    writeNotNull('create', create?.map((id, script) {
      return MapEntry(id.value, script.toJson());
    }));

    writeNotNull('update', update?.map((id, patch) {
      return SetMethodPropertiesConverter()
          .fromMapIdToJson(id, patch.toJson());
    }));

    writeNotNull(
      'destroy',
      destroy?.map((id) => id.value).toList(),
    );

    writeNotNull('onSuccessActivateScript', onSuccessActivateScript);
    writeNotNull('onSuccessDeactivateScript', onSuccessDeactivateScript);
    writeNotNull('onSuccessDeactivatescript', onSuccessDeactivatescript);

    return val;
  }

  @override
  List<Object?> get props => [
        accountId,
        ifInState,
        create,
        update,
        destroy,
        onSuccessActivateScript,
        onSuccessDeactivateScript,
        onSuccessDeactivatescript,
      ];
}
