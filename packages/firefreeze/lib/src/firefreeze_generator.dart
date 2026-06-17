import 'dart:convert';

import 'package:dart_style/dart_style.dart';
import 'package:remote_config_core/remote_config_core.dart';

import 'accessor_generator.dart';
import 'config_loader.dart';
import 'defaults_generator.dart';
import 'generator_header.dart';
import 'json_model_generator.dart';
import 'provider_generator.dart';

/// Output of a generation pass: relative file paths (under the configured
/// output dir) mapped to their content, plus any inference warnings.
class GenerationResult {
  final Map<String, String> files;
  final List<String> warnings;

  const GenerationResult({required this.files, required this.warnings});
}

/// Ties the individual generators together into a single set of output files.
class FirefreezeGenerator {
  final AccessorGenerator _accessor;
  final DefaultsGenerator _defaults;
  final JsonModelGenerator _jsonModel;
  final ProviderGenerator _provider;

  const FirefreezeGenerator({
    AccessorGenerator accessor = const AccessorGenerator(),
    DefaultsGenerator defaults = const DefaultsGenerator(),
    JsonModelGenerator jsonModel = const JsonModelGenerator(),
    ProviderGenerator provider = const ProviderGenerator(),
  })  : _accessor = accessor,
        _defaults = defaults,
        _jsonModel = jsonModel,
        _provider = provider;

  GenerationResult generate(
    RemoteConfigTemplate template,
    FirefreezeConfig config,
  ) {
    final params =
        template.parameters.where((p) => config.shouldInclude(p.key)).toList();

    final files = <String, String>{};
    final warnings = <String>[];

    // JSON models: infer each JSON parameter's shape from its default value.
    final jsonModelClasses = <String, String>{};
    final modelImports = <String, String>{};

    if (config.jsonModels) {
      for (final param in params) {
        if (param.valueType != ParameterValueType.json) continue;
        final raw = param.defaultValueString;
        if (raw == null || raw.trim().isEmpty) {
          warnings.add("JSON parameter '${param.key}' has no default value; "
              'falling back to Map<String, dynamic>.');
          continue;
        }
        Object? decoded;
        try {
          decoded = jsonDecode(raw);
        } catch (_) {
          warnings.add("JSON parameter '${param.key}' default is not valid "
              'JSON; falling back to Map<String, dynamic>.');
          continue;
        }
        final className = _jsonModel.className(param.key);
        final inference = JsonSchemaInferer.infer(decoded, className);
        warnings.addAll(inference.warnings.map((w) => '[${param.key}] $w'));
        if (!inference.hasModel) {
          warnings.add("JSON parameter '${param.key}' is not an object; "
              'falling back to Map<String, dynamic>.');
          continue;
        }
        final fileName = _jsonModel.fileName(param.key);
        files['models/$fileName'] = _jsonModel.generate(param.key, inference);
        jsonModelClasses[param.key] = className;
        modelImports[param.key] = 'models/$fileName';
      }
    }

    // Keys enum.
    files['remote_config_keys.dart'] = _accessor.generateKeys(params);

    // Values accessor (+ defaults map).
    final defaultsBlock =
        config.generateDefaults ? _defaults.mapBlock(params) : null;
    files['remote_config_values.dart'] = _accessor.generateValues(
      params: params,
      remoteConfigImport: config.remoteConfigImport,
      jsonModelClasses: jsonModelClasses,
      modelImports: modelImports,
      defaultsBlock: defaultsBlock,
    );

    // Riverpod providers.
    if (config.generateProviders) {
      files['remote_config_providers.dart'] = _provider.generate(
        params: params,
        clientProviderImport: config.clientProviderImport,
        jsonModelClasses: jsonModelClasses,
        modelImports: modelImports,
      );
    }

    // Barrel.
    if (config.generateBarrel) {
      files['remote_config.dart'] = _barrel(files.keys, config);
    }

    // Format Dart output so it passes `dart format --set-exit-if-changed`
    // in consumer projects. Falls back to the unformatted source if the
    // content cannot be parsed (should not happen for generated code).
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    final formatted = files.map((path, content) {
      if (!path.endsWith('.dart')) return MapEntry(path, content);
      try {
        return MapEntry(path, formatter.format(content));
      } catch (_) {
        warnings.add('Could not format generated file: $path');
        return MapEntry(path, content);
      }
    });

    return GenerationResult(files: formatted, warnings: warnings);
  }

  String _barrel(Iterable<String> paths, FirefreezeConfig config) {
    final exports = paths.where((p) => p != 'remote_config.dart').toList()
      ..sort();
    final buffer = StringBuffer()..writeln(generatedHeader);
    for (final path in exports) {
      buffer.writeln("export '$path';");
    }
    return buffer.toString();
  }
}
