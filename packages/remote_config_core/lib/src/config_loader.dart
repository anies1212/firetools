import 'dart:io';
import 'package:yaml/yaml.dart';

/// Fetch mode for Remote Config template retrieval.
enum FetchMode {
  /// Always fetch from the Admin API (default).
  always,

  /// Only fetch if no cache exists.
  ifNoCache,

  /// Never fetch, always use cache (offline mode).
  never,
}

/// Base configuration loader with environment-variable resolution.
///
/// Ported from the supatools convention so firefreeze configs can reference
/// secrets via `${VAR}`, `$env{VAR}`, `$define{VAR}` and `$dotenv{VAR}`.
class BaseConfigLoader {
  final Map<String, String> _dartDefines;
  final Map<String, String> _envVars;
  Map<String, String>? _dotEnvVars;

  BaseConfigLoader({
    Map<String, String>? dartDefines,
    Map<String, String>? envVars,
  })  : _dartDefines = dartDefines ?? const {},
        _envVars = envVars ?? Platform.environment;

  /// Loads variables from a `.env` file (if present).
  Future<void> loadDotEnv([String path = '.env']) async {
    final file = File(path);
    if (!await file.exists()) {
      _dotEnvVars = {};
      return;
    }

    final vars = <String, String>{};
    for (final line in await file.readAsLines()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final eqIndex = trimmed.indexOf('=');
      if (eqIndex == -1) continue;

      final key = trimmed.substring(0, eqIndex).trim();
      final rawValue = trimmed.substring(eqIndex + 1).trim();
      vars[key] = _unquote(rawValue);
    }

    _dotEnvVars = vars;
  }

  String _unquote(String value) {
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  /// Resolves a value that may contain variable references.
  ///
  /// Supports:
  /// - `${VAR}` - auto-resolve (dart-define > .env > environment)
  /// - `$env{VAR}` - explicit environment variable
  /// - `$define{VAR}` - dart-define variable
  /// - `$dotenv{VAR}` - explicit .env variable
  String? resolveValue(String? value) {
    if (value == null) return null;

    var result = value.replaceAllMapped(
      RegExp(r'\$\{(\w+)\}'),
      (m) => getValue(m.group(1)!) ?? '',
    );
    result = result.replaceAllMapped(
      RegExp(r'\$env\{(\w+)\}'),
      (m) => _envVars[m.group(1)!] ?? '',
    );
    result = result.replaceAllMapped(
      RegExp(r'\$define\{(\w+)\}'),
      (m) => _dartDefines[m.group(1)!] ?? '',
    );
    result = result.replaceAllMapped(
      RegExp(r'\$dotenv\{(\w+)\}'),
      (m) => _dotEnvVars?[m.group(1)!] ?? '',
    );

    return result.isEmpty ? null : result;
  }

  /// Gets a value with priority: dart-define > .env > environment.
  String? getValue(String name) {
    if (_dartDefines.containsKey(name)) return _dartDefines[name];
    if (_dotEnvVars?.containsKey(name) == true) return _dotEnvVars![name];
    if (_envVars.containsKey(name)) return _envVars[name];
    return null;
  }

  /// Parses a YAML list to a string list.
  List<String>? parseStringList(dynamic value) {
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  /// Parses a fetch mode from its yaml string.
  FetchMode parseFetchMode(String? value) => switch (value?.toLowerCase()) {
        'always' => FetchMode.always,
        'if_no_cache' || 'ifnocache' => FetchMode.ifNoCache,
        'never' => FetchMode.never,
        _ => FetchMode.always,
      };
}

/// Exception thrown when configuration is invalid.
class ConfigException implements Exception {
  final String message;
  final String? field;
  final String? hint;

  const ConfigException(this.message, {this.field, this.hint});

  @override
  String toString() {
    final buffer = StringBuffer('ConfigException: $message');
    if (field != null) buffer.write(' (field: $field)');
    if (hint != null) buffer.write('\nHint: $hint');
    return buffer.toString();
  }
}
