import 'package:firefreeze/firefreeze.dart';
import 'package:remote_config_core/remote_config_core.dart';
import 'package:test/test.dart';

void main() {
  const gen = AccessorGenerator();

  final params = [
    const RemoteConfigParameter(
      key: 'feature_x_enabled',
      valueType: ParameterValueType.boolean,
      defaultValueString: 'true',
      description: 'Whether feature X is enabled',
    ),
    const RemoteConfigParameter(
      key: 'max_retry_count',
      valueType: ParameterValueType.number,
      defaultValueString: '3',
    ),
    const RemoteConfigParameter(
      key: 'ratio',
      valueType: ParameterValueType.number,
      defaultValueString: '1.5',
    ),
    const RemoteConfigParameter(
      key: 'welcome_text',
      valueType: ParameterValueType.string,
      defaultValueString: 'hi',
    ),
  ];

  group('generateKeys', () {
    test('emits an enum entry per parameter', () {
      final result = gen.generateKeys(params);
      expect(result, contains('enum RemoteConfigKey {'));
      expect(result, contains("featureXEnabled('feature_x_enabled'),"));
      expect(result, contains("welcomeText('welcome_text');"));
      expect(result, contains('final String key;'));
    });
  });

  group('generateValues', () {
    test('emits typed getters with correct SDK accessors', () {
      final result = gen.generateValues(
        params: params,
        remoteConfigImport: 'package:firebase_remote_config/x.dart',
        jsonModelClasses: const {},
        modelImports: const {},
      );
      expect(
          result,
          contains(
              "bool get featureXEnabled => _rc.getBool('feature_x_enabled');"));
      expect(result,
          contains("int get maxRetryCount => _rc.getInt('max_retry_count');"));
      expect(result, contains("double get ratio => _rc.getDouble('ratio');"));
      expect(result,
          contains("String get welcomeText => _rc.getString('welcome_text');"));
      expect(result, contains('/// Whether feature X is enabled'));
    });

    test('uses model accessor for JSON params with models', () {
      final jsonParam = const RemoteConfigParameter(
        key: 'theme_config',
        valueType: ParameterValueType.json,
        defaultValueString: '{}',
      );
      final result = gen.generateValues(
        params: [jsonParam],
        remoteConfigImport: 'package:firebase_remote_config/x.dart',
        jsonModelClasses: const {'theme_config': 'ThemeConfig'},
        modelImports: const {
          'theme_config': 'models/theme_config.firefreeze.dart'
        },
      );
      expect(result, contains("import 'dart:convert';"));
      expect(result, contains("import 'models/theme_config.firefreeze.dart';"));
      expect(
          result,
          contains('ThemeConfig get themeConfig => '
              "ThemeConfig.fromJson(jsonDecode(_rc.getString('theme_config')) "
              'as Map<String, dynamic>);'));
    });

    test('falls back to Map for JSON params without models', () {
      final jsonParam = const RemoteConfigParameter(
        key: 'blob',
        valueType: ParameterValueType.json,
        defaultValueString: '{}',
      );
      final result = gen.generateValues(
        params: [jsonParam],
        remoteConfigImport: 'package:firebase_remote_config/x.dart',
        jsonModelClasses: const {},
        modelImports: const {},
      );
      expect(result, contains('Map<String, dynamic> get blob =>'));
    });

    test('appends defaults block when provided', () {
      const defaults = DefaultsGenerator();
      final result = gen.generateValues(
        params: params,
        remoteConfigImport: 'package:firebase_remote_config/x.dart',
        jsonModelClasses: const {},
        modelImports: const {},
        defaultsBlock: defaults.mapBlock(params),
      );
      expect(
          result, contains('const remoteConfigDefaults = <String, dynamic>{'));
      expect(result, contains("'feature_x_enabled': true,"));
      expect(result, contains("'max_retry_count': 3,"));
    });
  });
}
