import 'models.dart';

/// Maps Remote Config [ParameterValueType]s to Dart types and the
/// corresponding `FirebaseRemoteConfig` accessor method.
class TypeMapper {
  const TypeMapper._();

  /// Returns the Dart type for a NUMBER parameter, narrowing to `int` when the
  /// default value has no fractional component and `double` otherwise.
  ///
  /// Falls back to `num` when the default is absent or unparseable.
  static String numberDartType(String? defaultValue) {
    if (defaultValue == null || defaultValue.isEmpty) return 'num';
    final parsed = num.tryParse(defaultValue.trim());
    if (parsed == null) return 'num';
    return parsed is int || parsed == parsed.roundToDouble() ? 'int' : 'double';
  }

  /// The `FirebaseRemoteConfig` getter for a parameter (e.g. `getBool`).
  ///
  /// For JSON parameters the SDK has no typed getter; callers read
  /// `getString` and decode it themselves, so this returns `getString`.
  static String accessorMethod(RemoteConfigParameter param) =>
      switch (param.valueType) {
        ParameterValueType.string => 'getString',
        ParameterValueType.boolean => 'getBool',
        ParameterValueType.number =>
          numberDartType(param.defaultValueString) == 'double'
              ? 'getDouble'
              : 'getInt',
        ParameterValueType.json => 'getString',
        ParameterValueType.unknown => 'getString',
      };

  /// The scalar Dart type for non-JSON parameters. JSON types are resolved by
  /// the JSON schema inferer instead, so this returns `String` for JSON.
  static String scalarDartType(RemoteConfigParameter param) =>
      switch (param.valueType) {
        ParameterValueType.string => 'String',
        ParameterValueType.boolean => 'bool',
        ParameterValueType.number => numberDartType(param.defaultValueString),
        ParameterValueType.json => 'String',
        ParameterValueType.unknown => 'String',
      };

  /// Parses a default value string into the Dart literal used in the
  /// generated `remoteConfigDefaults` map.
  ///
  /// JSON values are kept as raw strings (the SDK's `setDefaults` expects the
  /// JSON-encoded string for JSON parameters).
  static String defaultLiteral(RemoteConfigParameter param) {
    final raw = param.defaultValueString ?? '';
    return switch (param.valueType) {
      ParameterValueType.boolean =>
        raw.toLowerCase() == 'true' ? 'true' : 'false',
      ParameterValueType.number =>
        num.tryParse(raw.trim())?.toString() ?? "'${_escape(raw)}'",
      _ => "'${_escape(raw)}'",
    };
  }

  static String _escape(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\n');
}
