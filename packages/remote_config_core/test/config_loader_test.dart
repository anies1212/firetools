import 'package:remote_config_core/remote_config_core.dart';
import 'package:test/test.dart';

void main() {
  group('BaseConfigLoader.resolveValue', () {
    test(r'resolves ${VAR} with dart-define > env priority', () {
      final loader = BaseConfigLoader(
        dartDefines: {'TOKEN': 'from-define'},
        envVars: {'TOKEN': 'from-env'},
      );
      expect(loader.resolveValue(r'${TOKEN}'), 'from-define');
    });

    test(r'resolves $env{VAR} only from environment', () {
      final loader = BaseConfigLoader(
        dartDefines: {'X': 'define'},
        envVars: {'X': 'env'},
      );
      expect(loader.resolveValue(r'$env{X}'), 'env');
    });

    test('returns null for empty resolution', () {
      final loader = BaseConfigLoader(envVars: {});
      expect(loader.resolveValue(r'${MISSING}'), isNull);
    });

    test('passes through literals', () {
      final loader = BaseConfigLoader(envVars: {});
      expect(loader.resolveValue('my-project'), 'my-project');
    });
  });

  group('BaseConfigLoader.parseFetchMode', () {
    test('parses each mode', () {
      final loader = BaseConfigLoader(envVars: {});
      expect(loader.parseFetchMode('always'), FetchMode.always);
      expect(loader.parseFetchMode('if_no_cache'), FetchMode.ifNoCache);
      expect(loader.parseFetchMode('never'), FetchMode.never);
      expect(loader.parseFetchMode('garbage'), FetchMode.always);
    });
  });
}
