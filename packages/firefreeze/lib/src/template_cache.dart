import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:remote_config_core/remote_config_core.dart';

/// The result of comparing a fetched template against the cache.
class TemplateDiff {
  final List<RemoteConfigParameter> changed;
  final List<String> removedKeys;

  const TemplateDiff({required this.changed, required this.removedKeys});

  bool get hasChanges => changed.isNotEmpty || removedKeys.isNotEmpty;
}

/// Hash-based cache for Remote Config templates, mirroring the supatools
/// `SchemaCache` convention. Stores per-parameter SHA256 hashes for diffing
/// and the full template for offline regeneration.
class TemplateCache {
  final String cacheDir;

  TemplateCache({this.cacheDir = '.dart_tool/firefreeze'});

  File get _hashesFile => File(p.join(cacheDir, 'param_hashes.json'));
  File get _templateFile => File(p.join(cacheDir, 'template_cache.json'));

  String _hash(RemoteConfigParameter param) {
    final payload = '${param.key}|${param.valueType.apiName}|'
        '${param.defaultValueString}|${param.useInAppDefault}';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  Future<Map<String, String>> _loadHashes() async {
    if (!await _hashesFile.exists()) return {};
    final json = jsonDecode(await _hashesFile.readAsString());
    return (json as Map).map((k, v) => MapEntry(k as String, v as String));
  }

  /// Computes which parameters are new/changed and which were removed.
  Future<TemplateDiff> computeDiff(List<RemoteConfigParameter> params) async {
    final cached = await _loadHashes();
    final changed = <RemoteConfigParameter>[];
    for (final param in params) {
      if (cached[param.key] != _hash(param)) changed.add(param);
    }
    final currentKeys = params.map((p) => p.key).toSet();
    final removed = cached.keys.where((k) => !currentKeys.contains(k)).toList();
    return TemplateDiff(changed: changed, removedKeys: removed);
  }

  /// Persists parameter hashes for the full current parameter set.
  Future<void> saveHashes(List<RemoteConfigParameter> params) async {
    await _ensureDir();
    final map = {for (final param in params) param.key: _hash(param)};
    await _hashesFile
        .writeAsString(const JsonEncoder.withIndent('  ').convert(map));
  }

  Future<void> saveTemplate(RemoteConfigTemplate template) async {
    await _ensureDir();
    await _templateFile.writeAsString(jsonEncode(template.toJson()));
  }

  /// Loads the cached template, or null when none exists.
  Future<RemoteConfigTemplate?> loadTemplate() async {
    if (!await _templateFile.exists()) return null;
    final json = jsonDecode(await _templateFile.readAsString());
    return RemoteConfigTemplate.fromJson(json as Map<String, dynamic>);
  }

  Future<void> clear() async {
    if (await _hashesFile.exists()) await _hashesFile.delete();
  }

  Future<void> _ensureDir() async {
    final dir = Directory(cacheDir);
    if (!await dir.exists()) await dir.create(recursive: true);
  }
}
