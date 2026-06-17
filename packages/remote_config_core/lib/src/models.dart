/// The value type declared for a Remote Config parameter.
///
/// Mirrors the `valueType` field returned by the Remote Config Admin REST API.
enum ParameterValueType {
  string,
  boolean,
  number,
  json,
  unknown;

  /// Parses the Admin API string (e.g. `STRING`, `BOOLEAN`, `NUMBER`, `JSON`).
  static ParameterValueType parse(String? value) =>
      switch (value?.toUpperCase()) {
        'STRING' => ParameterValueType.string,
        'BOOLEAN' => ParameterValueType.boolean,
        'NUMBER' => ParameterValueType.number,
        'JSON' => ParameterValueType.json,
        _ => ParameterValueType.unknown,
      };

  String get apiName => switch (this) {
        ParameterValueType.string => 'STRING',
        ParameterValueType.boolean => 'BOOLEAN',
        ParameterValueType.number => 'NUMBER',
        ParameterValueType.json => 'JSON',
        ParameterValueType.unknown => 'UNKNOWN',
      };
}

/// A single Remote Config parameter as declared in the template.
class RemoteConfigParameter {
  /// The parameter key (e.g. `feature_x_enabled`).
  final String key;

  /// The declared value type.
  final ParameterValueType valueType;

  /// The concrete default value as a string, or null when the parameter
  /// uses an in-app default (`useInAppDefault: true`) or has no default.
  final String? defaultValueString;

  /// Whether the default is the in-app default (no concrete server value).
  final bool useInAppDefault;

  /// Optional human-readable description from the console.
  final String? description;

  const RemoteConfigParameter({
    required this.key,
    required this.valueType,
    this.defaultValueString,
    this.useInAppDefault = false,
    this.description,
  });

  /// Whether this parameter contributes a concrete value to the defaults map.
  bool get hasConcreteDefault => !useInAppDefault && defaultValueString != null;

  Map<String, dynamic> toJson() => {
        'key': key,
        'valueType': valueType.apiName,
        'defaultValueString': defaultValueString,
        'useInAppDefault': useInAppDefault,
        'description': description,
      };

  factory RemoteConfigParameter.fromJson(Map<String, dynamic> json) =>
      RemoteConfigParameter(
        key: json['key'] as String,
        valueType: ParameterValueType.parse(json['valueType'] as String?),
        defaultValueString: json['defaultValueString'] as String?,
        useInAppDefault: json['useInAppDefault'] as bool? ?? false,
        description: json['description'] as String?,
      );

  @override
  String toString() => 'RemoteConfigParameter($key: ${valueType.apiName}, '
      'default: $defaultValueString, useInAppDefault: $useInAppDefault)';
}

/// A parsed Remote Config template: the flat list of all parameters,
/// including those nested inside parameter groups.
class RemoteConfigTemplate {
  final List<RemoteConfigParameter> parameters;

  const RemoteConfigTemplate({required this.parameters});

  /// Parses an Admin API `remoteConfig` response body.
  ///
  /// Flattens top-level `parameters` and every `parameterGroups[].parameters`
  /// into a single list, since group membership does not affect how a
  /// parameter is addressed by key at runtime.
  factory RemoteConfigTemplate.fromAdminResponse(Map<String, dynamic> body) {
    final result = <RemoteConfigParameter>[];

    void addAll(Map<String, dynamic>? params) {
      if (params == null) return;
      params.forEach((key, value) {
        result.add(_parseParameter(key, value as Map<String, dynamic>));
      });
    }

    addAll(body['parameters'] as Map<String, dynamic>?);

    final groups = body['parameterGroups'] as Map<String, dynamic>?;
    groups?.forEach((_, group) {
      final groupMap = group as Map<String, dynamic>;
      addAll(groupMap['parameters'] as Map<String, dynamic>?);
    });

    result.sort((a, b) => a.key.compareTo(b.key));
    return RemoteConfigTemplate(parameters: result);
  }

  static RemoteConfigParameter _parseParameter(
    String key,
    Map<String, dynamic> param,
  ) {
    final defaultValue = param['defaultValue'] as Map<String, dynamic>?;
    final useInAppDefault = defaultValue?['useInAppDefault'] == true;
    final value = defaultValue?['value'] as String?;

    return RemoteConfigParameter(
      key: key,
      valueType: ParameterValueType.parse(param['valueType'] as String?),
      defaultValueString: useInAppDefault ? null : value,
      useInAppDefault: useInAppDefault,
      description: param['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'parameters': parameters.map((p) => p.toJson()).toList(),
      };

  factory RemoteConfigTemplate.fromJson(Map<String, dynamic> json) =>
      RemoteConfigTemplate(
        parameters: (json['parameters'] as List)
            .map((e) =>
                RemoteConfigParameter.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
