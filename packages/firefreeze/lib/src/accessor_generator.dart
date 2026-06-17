import 'package:recase/recase.dart';
import 'package:remote_config_core/remote_config_core.dart';

import 'generator_header.dart';

/// Generates the type-safe key enum and the `RemoteConfigValues` accessor.
class AccessorGenerator {
  const AccessorGenerator();

  /// Generates `remote_config_keys.dart`: an enum of all parameter keys.
  String generateKeys(List<RemoteConfigParameter> params) {
    final buffer = StringBuffer()
      ..writeln(generatedHeader)
      ..writeln('/// Type-safe Remote Config parameter keys.')
      ..writeln('enum RemoteConfigKey {');

    for (var i = 0; i < params.length; i++) {
      final param = params[i];
      final name = _safeName(ReCase(param.key).camelCase);
      final terminator = i == params.length - 1 ? ';' : ',';
      buffer.writeln("  $name('${param.key}')$terminator");
    }

    buffer
      ..writeln()
      ..writeln('  const RemoteConfigKey(this.key);')
      ..writeln()
      ..writeln('  /// The raw Remote Config parameter key.')
      ..writeln('  final String key;')
      ..writeln('}');
    return buffer.toString();
  }

  /// Generates `remote_config_values.dart`: the typed accessor wrapping
  /// `FirebaseRemoteConfig`, optionally followed by the defaults map.
  ///
  /// [jsonModelClasses] maps a JSON parameter key to its generated model class
  /// name; keys absent from the map fall back to `Map<String, dynamic>`.
  String generateValues({
    required List<RemoteConfigParameter> params,
    required String remoteConfigImport,
    required Map<String, String> jsonModelClasses,
    required Map<String, String> modelImports,
    String? defaultsBlock,
  }) {
    final usesJson = params.any((p) => p.valueType == ParameterValueType.json);
    final buffer = StringBuffer()..writeln(generatedHeader);

    if (usesJson) buffer.writeln("import 'dart:convert';");
    buffer.writeln("import '$remoteConfigImport';");
    final imports = modelImports.values.toSet().toList()..sort();
    for (final import in imports) {
      buffer.writeln("import '$import';");
    }
    buffer
      ..writeln()
      ..writeln('/// Type-safe accessors over [FirebaseRemoteConfig].')
      ..writeln('class RemoteConfigValues {')
      ..writeln('  const RemoteConfigValues(this._rc);')
      ..writeln()
      ..writeln('  final FirebaseRemoteConfig _rc;');

    for (final param in params) {
      buffer
        ..writeln()
        ..write(_accessor(param, jsonModelClasses));
    }

    buffer.writeln('}');

    if (defaultsBlock != null) {
      buffer
        ..writeln()
        ..writeln(defaultsBlock);
    }

    return buffer.toString();
  }

  String _accessor(
    RemoteConfigParameter param,
    Map<String, String> jsonModelClasses,
  ) {
    final buffer = StringBuffer();
    if (param.description != null && param.description!.isNotEmpty) {
      buffer.writeln('  /// ${param.description}');
    }

    final body = switch (param.valueType) {
      ParameterValueType.json => _jsonAccessor(param, jsonModelClasses),
      _ => _scalarAccessor(param),
    };
    buffer.writeln('  $body');
    return buffer.toString();
  }

  String _scalarAccessor(RemoteConfigParameter param) {
    final name = _safeName(ReCase(param.key).camelCase);
    final type = TypeMapper.scalarDartType(param);
    final method = TypeMapper.accessorMethod(param);
    return "$type get $name => _rc.$method('${param.key}');";
  }

  String _jsonAccessor(
    RemoteConfigParameter param,
    Map<String, String> jsonModelClasses,
  ) {
    final name = _safeName(ReCase(param.key).camelCase);
    final className = jsonModelClasses[param.key];
    final decode = "jsonDecode(_rc.getString('${param.key}'))";
    if (className != null) {
      return '$className get $name => '
          '$className.fromJson($decode as Map<String, dynamic>);';
    }
    return 'Map<String, dynamic> get $name => '
        '$decode as Map<String, dynamic>;';
  }

  static const _reserved = {
    'is',
    'in',
    'if',
    'for',
    'do',
    'new',
    'this',
    'null',
    'true',
    'false',
    'class',
    'enum',
    'void',
    'final',
    'const',
    'return',
    'switch',
    'default',
  };

  String _safeName(String name) {
    if (name.isEmpty) return 'value';
    var result = name;
    if (RegExp(r'^[0-9]').hasMatch(result)) result = 'v$result';
    if (_reserved.contains(result)) result = '$result\$';
    return result;
  }
}
