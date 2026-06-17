import 'dart:io';

import 'package:firefreeze/firefreeze.dart';
import 'package:remote_config_core/remote_config_core.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateCache', () {
    late Directory tempDir;
    late TemplateCache cache;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('firefreeze_cache_');
      cache = TemplateCache(cacheDir: tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    const a = RemoteConfigParameter(
      key: 'a',
      valueType: ParameterValueType.string,
      defaultValueString: '1',
    );
    const aChanged = RemoteConfigParameter(
      key: 'a',
      valueType: ParameterValueType.string,
      defaultValueString: '2',
    );
    const b = RemoteConfigParameter(
      key: 'b',
      valueType: ParameterValueType.boolean,
      defaultValueString: 'true',
    );

    test('reports all params as changed on first run', () async {
      final diff = await cache.computeDiff([a, b]);
      expect(diff.changed.length, 2);
      expect(diff.removedKeys, isEmpty);
      expect(diff.hasChanges, isTrue);
    });

    test('reports no changes after saving hashes', () async {
      await cache.saveHashes([a, b]);
      final diff = await cache.computeDiff([a, b]);
      expect(diff.hasChanges, isFalse);
    });

    test('detects changed and removed params', () async {
      await cache.saveHashes([a, b]);
      final diff = await cache.computeDiff([aChanged]);
      expect(diff.changed.single.key, 'a');
      expect(diff.removedKeys, contains('b'));
    });

    test('round-trips the cached template', () async {
      const template = RemoteConfigTemplate(parameters: [a, b]);
      await cache.saveTemplate(template);
      final loaded = await cache.loadTemplate();
      expect(loaded!.parameters.map((p) => p.key), ['a', 'b']);
    });
  });
}
