import 'dart:convert';

import 'package:firefreeze/firefreeze.dart';
import 'package:remote_config_core/remote_config_core.dart';
import 'package:test/test.dart';

void main() {
  const gen = JsonModelGenerator();

  test('generates a Freezed class from an inferred object', () {
    // Arrange
    final decoded = jsonDecode('{"primary_color":"#000","retries":3}');
    final inference = JsonSchemaInferer.infer(decoded, 'ThemeConfig');

    // Act
    final result = gen.generate('theme_config', inference);

    // Assert
    expect(result, contains('// GENERATED CODE - DO NOT MODIFY BY HAND'));
    expect(result, contains("part 'theme_config.firefreeze.freezed.dart';"));
    expect(result, contains("part 'theme_config.firefreeze.g.dart';"));
    expect(
        result, contains('abstract class ThemeConfig with _\$ThemeConfig {'));
    expect(
        result,
        contains(
            "@JsonKey(name: 'primary_color') required String primaryColor,"));
    expect(result, contains('required int retries,'));
    expect(result,
        contains('factory ThemeConfig.fromJson(Map<String, dynamic> json)'));
  });

  test('emits nested classes for nested objects', () {
    final decoded = jsonDecode('{"colors":{"bg":"#fff"}}');
    final inference = JsonSchemaInferer.infer(decoded, 'ThemeConfig');

    final result = gen.generate('theme_config', inference);

    expect(result, contains('abstract class ThemeConfig with'));
    expect(result, contains('abstract class ThemeConfigColors with'));
    expect(result, contains('required ThemeConfigColors colors,'));
  });

  test('makes null fields nullable', () {
    final decoded = jsonDecode('{"maybe":null}');
    final inference = JsonSchemaInferer.infer(decoded, 'Cfg');

    final result = gen.generate('cfg', inference);

    expect(result, contains('dynamic maybe,'));
    expect(result, isNot(contains('required dynamic maybe')));
  });
}
