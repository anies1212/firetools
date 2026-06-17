import 'package:firefreeze/firefreeze.dart';
import 'package:remote_config_core/remote_config_core.dart';
import 'package:test/test.dart';

RemoteConfigTemplate template() => const RemoteConfigTemplate(parameters: [
      RemoteConfigParameter(
        key: 'feature_x_enabled',
        valueType: ParameterValueType.boolean,
        defaultValueString: 'true',
      ),
      RemoteConfigParameter(
        key: 'theme_config',
        valueType: ParameterValueType.json,
        defaultValueString: '{"primary":"#000"}',
      ),
      RemoteConfigParameter(
        key: 'legacy',
        valueType: ParameterValueType.string,
        defaultValueString: 'x',
      ),
    ]);

void main() {
  const generator = FirefreezeGenerator();

  test('generates keys, values, models and barrel by default', () {
    // Act
    final result = generator.generate(template(), const FirefreezeConfig());

    // Assert
    expect(result.files.keys, contains('remote_config_keys.dart'));
    expect(result.files.keys, contains('remote_config_values.dart'));
    expect(result.files.keys, contains('models/theme_config.firefreeze.dart'));
    expect(result.files.keys, contains('remote_config.dart'));
    expect(result.files.keys, isNot(contains('remote_config_providers.dart')));

    final barrel = result.files['remote_config.dart']!;
    expect(barrel, contains("export 'remote_config_keys.dart';"));
    expect(barrel, contains("export 'models/theme_config.firefreeze.dart';"));
  });

  test('generates providers when enabled', () {
    final result = generator.generate(
      template(),
      const FirefreezeConfig(generateProviders: true),
    );
    expect(result.files.keys, contains('remote_config_providers.dart'));
  });

  test('respects exclude filter', () {
    final result = generator.generate(
      template(),
      const FirefreezeConfig(exclude: ['legacy']),
    );
    final keys = result.files['remote_config_keys.dart']!;
    expect(keys, isNot(contains("legacy('legacy')")));
  });

  test('falls back to Map and warns when json_models disabled', () {
    final result = generator.generate(
      template(),
      const FirefreezeConfig(jsonModels: false),
    );
    expect(result.files.keys,
        isNot(contains('models/theme_config.firefreeze.dart')));
    expect(result.files['remote_config_values.dart'],
        contains('Map<String, dynamic> get themeConfig =>'));
  });

  test('warns on invalid json default', () {
    final result = generator.generate(
      const RemoteConfigTemplate(parameters: [
        RemoteConfigParameter(
          key: 'broken',
          valueType: ParameterValueType.json,
          defaultValueString: 'not json',
        ),
      ]),
      const FirefreezeConfig(),
    );
    expect(result.warnings, isNotEmpty);
    expect(result.files['remote_config_values.dart'],
        contains('Map<String, dynamic> get broken =>'));
  });
}
