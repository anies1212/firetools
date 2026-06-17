import 'dart:io';

import 'package:firefreeze/firefreeze.dart';
import 'package:remote_config_core/remote_config_core.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigLoader.loadConfig', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('firefreeze_cfg_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    Future<FirefreezeConfig?> load(String yaml) async {
      final file = File('${tempDir.path}/firefreeze.yaml');
      await file.writeAsString(yaml);
      return ConfigLoader(envVars: const {}).loadConfig(file.path);
    }

    test('returns null when file is missing', () async {
      final config =
          await ConfigLoader().loadConfig('${tempDir.path}/nope.yaml');
      expect(config, isNull);
    });

    test('parses fields with defaults', () async {
      final config = await load('''
project_id: my-project
output: lib/rc
fetch: if_no_cache
generate_providers: true
json_models: false
exclude:
  - legacy
''');
      expect(config!.projectId, 'my-project');
      expect(config.output, 'lib/rc');
      expect(config.fetch, FetchMode.ifNoCache);
      expect(config.generateProviders, isTrue);
      expect(config.jsonModels, isFalse);
      expect(config.generateDefaults, isTrue); // default true
      expect(config.exclude, ['legacy']);
    });

    test('resolves project_id from environment', () async {
      final file = File('${tempDir.path}/firefreeze.yaml');
      await file.writeAsString(r'project_id: ${FIREBASE_PROJECT_ID}');
      final config = await ConfigLoader(
        envVars: const {'FIREBASE_PROJECT_ID': 'resolved-id'},
      ).loadConfig(file.path);
      expect(config!.projectId, 'resolved-id');
    });

    test('validates required project_id', () {
      const config = FirefreezeConfig();
      expect(config.isValid, isFalse);
      expect(config.validate(), isNotEmpty);
    });

    test('flags include/exclude conflict', () {
      const config = FirefreezeConfig(
        projectId: 'p',
        include: ['a'],
        exclude: ['b'],
      );
      expect(config.validate(), isNotEmpty);
    });

    test('shouldInclude honors include then exclude', () {
      const withInclude = FirefreezeConfig(projectId: 'p', include: ['a']);
      expect(withInclude.shouldInclude('a'), isTrue);
      expect(withInclude.shouldInclude('b'), isFalse);

      const withExclude = FirefreezeConfig(projectId: 'p', exclude: ['a']);
      expect(withExclude.shouldInclude('a'), isFalse);
      expect(withExclude.shouldInclude('b'), isTrue);
    });
  });
}
