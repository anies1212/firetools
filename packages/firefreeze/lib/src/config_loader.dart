import 'dart:io';

import 'package:remote_config_core/remote_config_core.dart';
import 'package:yaml/yaml.dart';

/// Resolved firefreeze configuration (from `firefreeze.yaml`).
class FirefreezeConfig {
  /// Firebase project id (required).
  final String? projectId;

  /// Path to a service-account JSON key. When null, ADC is used.
  final String? serviceAccount;

  /// Output directory for generated files.
  final String output;

  final FetchMode fetch;

  /// Whether to emit the `remoteConfigDefaults` map.
  final bool generateDefaults;

  /// Whether to generate Freezed models for JSON parameters (else `Map`).
  final bool jsonModels;

  /// Whether to generate Riverpod providers.
  final bool generateProviders;

  /// Import path for the user-provided `firebaseRemoteConfigProvider`.
  final String clientProviderImport;

  /// Import path for the `firebase_remote_config` package.
  final String remoteConfigImport;

  final List<String>? include;
  final List<String>? exclude;

  /// Whether to emit a `remote_config.dart` barrel file.
  final bool generateBarrel;

  const FirefreezeConfig({
    this.projectId,
    this.serviceAccount,
    this.output = 'lib/remote_config',
    this.fetch = FetchMode.always,
    this.generateDefaults = true,
    this.jsonModels = true,
    this.generateProviders = false,
    this.clientProviderImport = 'firebase_remote_config_provider.dart',
    this.remoteConfigImport =
        'package:firebase_remote_config/firebase_remote_config.dart',
    this.include,
    this.exclude,
    this.generateBarrel = true,
  });

  bool get isValid => projectId != null && projectId!.isNotEmpty;

  /// Validates the configuration and returns a list of issues.
  List<String> validate() {
    final issues = <String>[];
    if (projectId == null || projectId!.isEmpty) {
      issues.add('project_id is not configured. Set it in firefreeze.yaml '
          'or via ${r'${FIREBASE_PROJECT_ID}'}.');
    }
    if (include != null &&
        exclude != null &&
        include!.isNotEmpty &&
        exclude!.isNotEmpty) {
      issues.add('Both include and exclude are specified. Use only one.');
    }
    return issues;
  }

  /// Whether a parameter key should be included in generation.
  bool shouldInclude(String key) {
    if (include != null && include!.isNotEmpty) return include!.contains(key);
    if (exclude != null && exclude!.isNotEmpty) return !exclude!.contains(key);
    return true;
  }
}

/// Loads and resolves `firefreeze.yaml`.
class ConfigLoader extends BaseConfigLoader {
  ConfigLoader({super.dartDefines, super.envVars});

  /// Loads config from [path] (default `firefreeze.yaml`). Returns null when
  /// the file does not exist.
  Future<FirefreezeConfig?> loadConfig(
      [String path = 'firefreeze.yaml']) async {
    final file = File(path);
    if (!await file.exists()) return null;

    await loadDotEnv();

    final yaml = loadYaml(await file.readAsString()) as YamlMap?;
    if (yaml == null) return const FirefreezeConfig();

    return FirefreezeConfig(
      projectId: resolveValue(yaml['project_id']?.toString()),
      serviceAccount: resolveValue(yaml['service_account']?.toString()),
      output: yaml['output']?.toString() ?? 'lib/remote_config',
      fetch: parseFetchMode(yaml['fetch']?.toString()),
      generateDefaults: yaml['generate_defaults'] != false,
      jsonModels: yaml['json_models'] != false,
      generateProviders: yaml['generate_providers'] == true,
      clientProviderImport: yaml['client_provider_import']?.toString() ??
          'firebase_remote_config_provider.dart',
      remoteConfigImport: yaml['remote_config_import']?.toString() ??
          'package:firebase_remote_config/firebase_remote_config.dart',
      include: parseStringList(yaml['include']),
      exclude: parseStringList(yaml['exclude']),
      generateBarrel: yaml['generate_barrel'] != false,
    );
  }
}
