import 'package:firefreeze/firefreeze.dart';
import 'package:remote_config_core/remote_config_core.dart';
import 'package:test/test.dart';

void main() {
  const gen = ProviderGenerator();

  final params = [
    const RemoteConfigParameter(
      key: 'feature_x_enabled',
      valueType: ParameterValueType.boolean,
      defaultValueString: 'true',
    ),
    const RemoteConfigParameter(
      key: 'theme_config',
      valueType: ParameterValueType.json,
      defaultValueString: '{}',
    ),
  ];

  test('generates the values provider and per-key providers', () {
    final result = gen.generate(
      params: params,
      clientProviderImport: 'firebase_remote_config_provider.dart',
      jsonModelClasses: const {'theme_config': 'ThemeConfig'},
      modelImports: const {
        'theme_config': 'models/theme_config.firefreeze.dart'
      },
    );

    expect(
        result,
        contains(
            "import 'package:riverpod_annotation/riverpod_annotation.dart';"));
    expect(result, contains("import 'firebase_remote_config_provider.dart';"));
    expect(result, contains("part 'remote_config_providers.g.dart';"));
    expect(
        result,
        contains('RemoteConfigValues remoteConfigValues(Ref ref) =>\n'
            '    RemoteConfigValues(ref.watch(firebaseRemoteConfigProvider));'));
    expect(result, contains('bool featureXEnabled(Ref ref) =>'));
    expect(result, contains('ThemeConfig themeConfig(Ref ref) =>'));
    expect(
        result, contains('ref.watch(remoteConfigValuesProvider).themeConfig;'));
  });
}
