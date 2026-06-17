import 'package:remote_config_core/remote_config_core.dart';
import 'package:test/test.dart';

void main() {
  group('ParameterValueType.parse', () {
    test('parses known Admin API names', () {
      expect(ParameterValueType.parse('STRING'), ParameterValueType.string);
      expect(ParameterValueType.parse('BOOLEAN'), ParameterValueType.boolean);
      expect(ParameterValueType.parse('NUMBER'), ParameterValueType.number);
      expect(ParameterValueType.parse('JSON'), ParameterValueType.json);
    });

    test('falls back to unknown for unrecognized values', () {
      expect(ParameterValueType.parse(null), ParameterValueType.unknown);
      expect(ParameterValueType.parse('FOO'), ParameterValueType.unknown);
    });
  });

  group('RemoteConfigTemplate.fromAdminResponse', () {
    test('parses top-level parameters and sorts by key', () {
      // Arrange
      final body = {
        'parameters': {
          'max_retry': {
            'defaultValue': {'value': '3'},
            'valueType': 'NUMBER',
            'description': 'retries',
          },
          'feature_x': {
            'defaultValue': {'value': 'true'},
            'valueType': 'BOOLEAN',
          },
        },
      };

      // Act
      final template = RemoteConfigTemplate.fromAdminResponse(body);

      // Assert
      expect(template.parameters.map((p) => p.key), ['feature_x', 'max_retry']);
      final retry = template.parameters.last;
      expect(retry.valueType, ParameterValueType.number);
      expect(retry.defaultValueString, '3');
      expect(retry.description, 'retries');
    });

    test('flattens parameters inside parameter groups', () {
      // Arrange
      final body = {
        'parameters': {
          'top': {
            'defaultValue': {'value': 'a'},
            'valueType': 'STRING',
          },
        },
        'parameterGroups': {
          'onboarding': {
            'parameters': {
              'grouped': {
                'defaultValue': {'value': 'b'},
                'valueType': 'STRING',
              },
            },
          },
        },
      };

      // Act
      final template = RemoteConfigTemplate.fromAdminResponse(body);

      // Assert
      expect(template.parameters.map((p) => p.key), ['grouped', 'top']);
    });

    test('marks in-app defaults and excludes them from concrete defaults', () {
      // Arrange
      final body = {
        'parameters': {
          'in_app': {
            'defaultValue': {'useInAppDefault': true},
            'valueType': 'STRING',
          },
        },
      };

      // Act
      final param =
          RemoteConfigTemplate.fromAdminResponse(body).parameters.single;

      // Assert
      expect(param.useInAppDefault, isTrue);
      expect(param.defaultValueString, isNull);
      expect(param.hasConcreteDefault, isFalse);
    });

    test('round-trips through json', () {
      final body = {
        'parameters': {
          'k': {
            'defaultValue': {'value': '1'},
            'valueType': 'NUMBER',
          },
        },
      };
      final template = RemoteConfigTemplate.fromAdminResponse(body);
      final restored = RemoteConfigTemplate.fromJson(template.toJson());
      expect(restored.parameters.single.key, 'k');
      expect(restored.parameters.single.valueType, ParameterValueType.number);
    });
  });
}
