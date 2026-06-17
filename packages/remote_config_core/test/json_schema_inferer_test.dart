import 'dart:convert';

import 'package:remote_config_core/remote_config_core.dart';
import 'package:test/test.dart';

void main() {
  group('JsonSchemaInferer', () {
    test('infers scalar fields with camelCase names', () {
      // Arrange
      final decoded = jsonDecode('{"primary_color":"#000","retries":3,'
          '"ratio":1.5,"enabled":true}');

      // Act
      final result = JsonSchemaInferer.infer(decoded, 'ThemeConfig');

      // Assert
      expect(result.hasModel, isTrue);
      final root = result.root as ObjectType;
      expect(root.className, 'ThemeConfig');
      final byName = {for (final f in root.fields) f.name: f};
      expect(byName['primaryColor']!.type.dartType, 'String');
      expect(byName['primaryColor']!.jsonKey, 'primary_color');
      expect(byName['retries']!.type.dartType, 'int');
      expect(byName['ratio']!.type.dartType, 'double');
      expect(byName['enabled']!.type.dartType, 'bool');
    });

    test('infers nested objects as separate classes', () {
      final decoded = jsonDecode('{"colors":{"bg":"#fff"}}');

      final result = JsonSchemaInferer.infer(decoded, 'ThemeConfig');

      expect(result.objects.map((o) => o.className),
          containsAll(['ThemeConfig', 'ThemeConfigColors']));
      final root = result.root as ObjectType;
      expect(root.fields.single.type.dartType, 'ThemeConfigColors');
    });

    test('infers list element types', () {
      final decoded = jsonDecode('{"tags":["a","b"]}');

      final result = JsonSchemaInferer.infer(decoded, 'Cfg');

      final root = result.root as ObjectType;
      expect(root.fields.single.type, isA<ListType>());
      expect(root.fields.single.type.dartType, 'List<String>');
    });

    test('warns on empty arrays and uses dynamic element', () {
      final decoded = jsonDecode('{"items":[]}');

      final result = JsonSchemaInferer.infer(decoded, 'Cfg');

      expect(result.root, isA<ObjectType>());
      expect((result.root as ObjectType).fields.single.type.dartType,
          'List<dynamic>');
      expect(result.warnings, isNotEmpty);
    });

    test('warns on null fields and uses dynamic', () {
      final decoded = jsonDecode('{"maybe":null}');

      final result = JsonSchemaInferer.infer(decoded, 'Cfg');

      final field = (result.root as ObjectType).fields.single;
      expect(field.type.dartType, 'dynamic');
      expect(field.nullable, isTrue);
      expect(result.warnings, isNotEmpty);
    });
  });
}
