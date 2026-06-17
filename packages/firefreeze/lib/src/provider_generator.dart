import 'package:recase/recase.dart';
import 'package:remote_config_core/remote_config_core.dart';

import 'generator_header.dart';

/// Generates Riverpod providers exposing [RemoteConfigValues] and each
/// individual parameter.
///
/// Expects the consuming project to provide a `firebaseRemoteConfigProvider`
/// (imported via [clientProviderImport]) that yields a `FirebaseRemoteConfig`.
class ProviderGenerator {
  const ProviderGenerator();

  String generate({
    required List<RemoteConfigParameter> params,
    required String clientProviderImport,
    required Map<String, String> jsonModelClasses,
    required Map<String, String> modelImports,
    String valuesImport = 'remote_config_values.dart',
  }) {
    final buffer = StringBuffer()
      ..writeln(generatedHeader)
      ..writeln(
          "import 'package:riverpod_annotation/riverpod_annotation.dart';")
      ..writeln("import '$clientProviderImport';")
      ..writeln("import '$valuesImport';");
    final imports = modelImports.values.toSet().toList()..sort();
    for (final import in imports) {
      buffer.writeln("import '$import';");
    }
    buffer
      ..writeln()
      ..writeln("part 'remote_config_providers.g.dart';")
      ..writeln()
      ..writeln('/// Type-safe Remote Config accessor provider.')
      ..writeln('@riverpod')
      ..writeln('RemoteConfigValues remoteConfigValues(Ref ref) =>')
      ..writeln(
          '    RemoteConfigValues(ref.watch(firebaseRemoteConfigProvider));');

    for (final param in params) {
      buffer
        ..writeln()
        ..write(_provider(param, jsonModelClasses));
    }

    return buffer.toString();
  }

  String _provider(
    RemoteConfigParameter param,
    Map<String, String> jsonModelClasses,
  ) {
    final name = _safeName(ReCase(param.key).camelCase);
    final type = switch (param.valueType) {
      ParameterValueType.json =>
        jsonModelClasses[param.key] ?? 'Map<String, dynamic>',
      _ => TypeMapper.scalarDartType(param),
    };
    final buffer = StringBuffer();
    if (param.description != null && param.description!.isNotEmpty) {
      buffer.writeln('/// ${param.description}');
    }
    buffer
      ..writeln('@riverpod')
      ..writeln('$type $name(Ref ref) =>')
      ..writeln('    ref.watch(remoteConfigValuesProvider).$name;');
    return buffer.toString();
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
