#!/usr/bin/env dart

import 'dart:io';

import 'package:firefreeze/src/config_loader.dart';
import 'package:firefreeze/src/firefreeze_generator.dart';
import 'package:firefreeze/src/template_cache.dart';
import 'package:path/path.dart' as p;
import 'package:remote_config_core/remote_config_core.dart';

/// CLI for generating type-safe Remote Config code.
///
/// Usage:
///   dart run firefreeze
///   dart run firefreeze --force
Future<void> main(List<String> args) async {
  final force = args.contains('--force') || args.contains('-f');

  print('🔄 firefreeze: Syncing Remote Config template...');

  final config = await ConfigLoader().loadConfig();
  if (config == null) {
    stderr.writeln('❌ Error: firefreeze.yaml not found.');
    exit(1);
  }

  if (!config.isValid && config.fetch != FetchMode.never) {
    stderr.writeln('❌ Error: Configuration incomplete:');
    for (final issue in config.validate()) {
      stderr.writeln('   - $issue');
    }
    exit(1);
  }

  final cache = TemplateCache();
  if (force) await cache.clear();

  final template = await _resolveTemplate(config, cache);
  if (template == null) exit(1);

  final params =
      template.parameters.where((p) => config.shouldInclude(p.key)).toList();
  final diff = await cache.computeDiff(params);
  if (!diff.hasChanges && !force) {
    print('✅ Template unchanged. Generated code is up to date.');
    exit(0);
  }

  print('📊 ${params.length} parameter(s); ${diff.changed.length} changed, '
      '${diff.removedKeys.length} removed.');

  final result = const FirefreezeGenerator().generate(template, config);

  final outputDir = Directory(config.output);
  if (!await outputDir.exists()) await outputDir.create(recursive: true);

  for (final entry in result.files.entries) {
    final filePath = p.join(config.output, entry.key);
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(entry.value);
    print('✨ Generated: $filePath');
  }

  await cache.saveHashes(params);
  await cache.saveTemplate(template);

  if (result.warnings.isNotEmpty) {
    print('\n⚠️  ${result.warnings.length} warning(s):');
    for (final warning in result.warnings) {
      print('   - $warning');
    }
  }

  print('\n🎉 Done! Generated ${result.files.length} file(s).');
  if (config.jsonModels || config.generateProviders) {
    print(
        '📝 Now run: dart run build_runner build --delete-conflicting-outputs');
  }
}

/// Resolves the template per fetch mode, with cache fallback on fetch failure.
Future<RemoteConfigTemplate?> _resolveTemplate(
  FirefreezeConfig config,
  TemplateCache cache,
) async {
  Future<RemoteConfigTemplate?> fromCache(String reason) async {
    final cached = await cache.loadTemplate();
    if (cached == null) {
      stderr.writeln('❌ Error: $reason and no cached template is available.');
      return null;
    }
    print('📦 Using cached template ($reason).');
    return cached;
  }

  if (config.fetch == FetchMode.never) {
    return fromCache('fetch: never');
  }

  if (config.fetch == FetchMode.ifNoCache) {
    final cached = await cache.loadTemplate();
    if (cached != null) {
      print('📦 Using cached template (fetch: if_no_cache).');
      return cached;
    }
  }

  final fetcher = TemplateFetcher(
    projectId: config.projectId!,
    serviceAccountPath: config.serviceAccount,
  );
  try {
    print('🌐 Fetching template for project ${config.projectId}...');
    return await fetcher.fetch();
  } on TemplateFetchException catch (e) {
    stderr.writeln('⚠️  Fetch failed: ${e.message}');
    return fromCache('fetch failed');
  }
}
