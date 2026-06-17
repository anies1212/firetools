import 'package:remote_config_core/remote_config_core.dart';
import 'package:test/test.dart';

RemoteConfigParameter param(
  ParameterValueType type, {
  String? value,
}) =>
    RemoteConfigParameter(
      key: 'k',
      valueType: type,
      defaultValueString: value,
    );

void main() {
  group('TypeMapper.numberDartType', () {
    test('narrows integral defaults to int', () {
      expect(TypeMapper.numberDartType('3'), 'int');
      expect(TypeMapper.numberDartType('3.0'), 'int');
    });

    test('keeps fractional defaults as double', () {
      expect(TypeMapper.numberDartType('3.5'), 'double');
    });

    test('falls back to num when missing or unparseable', () {
      expect(TypeMapper.numberDartType(null), 'num');
      expect(TypeMapper.numberDartType(''), 'num');
      expect(TypeMapper.numberDartType('abc'), 'num');
    });
  });

  group('TypeMapper.scalarDartType', () {
    test('maps each value type', () {
      expect(TypeMapper.scalarDartType(param(ParameterValueType.string)),
          'String');
      expect(
          TypeMapper.scalarDartType(param(ParameterValueType.boolean)), 'bool');
      expect(
          TypeMapper.scalarDartType(
              param(ParameterValueType.number, value: '4')),
          'int');
      expect(
          TypeMapper.scalarDartType(
              param(ParameterValueType.number, value: '4.5')),
          'double');
    });
  });

  group('TypeMapper.accessorMethod', () {
    test('selects the SDK getter per type', () {
      expect(TypeMapper.accessorMethod(param(ParameterValueType.string)),
          'getString');
      expect(TypeMapper.accessorMethod(param(ParameterValueType.boolean)),
          'getBool');
      expect(
          TypeMapper.accessorMethod(
              param(ParameterValueType.number, value: '4')),
          'getInt');
      expect(
          TypeMapper.accessorMethod(
              param(ParameterValueType.number, value: '4.5')),
          'getDouble');
      expect(TypeMapper.accessorMethod(param(ParameterValueType.json)),
          'getString');
    });
  });

  group('TypeMapper.defaultLiteral', () {
    test('emits bool literal', () {
      expect(
          TypeMapper.defaultLiteral(
              param(ParameterValueType.boolean, value: 'true')),
          'true');
      expect(
          TypeMapper.defaultLiteral(
              param(ParameterValueType.boolean, value: 'FALSE')),
          'false');
    });

    test('emits number literal', () {
      expect(
          TypeMapper.defaultLiteral(
              param(ParameterValueType.number, value: '42')),
          '42');
    });

    test('quotes and escapes string/json literals', () {
      expect(
          TypeMapper.defaultLiteral(
              param(ParameterValueType.string, value: "it's")),
          r"'it\'s'");
      expect(
          TypeMapper.defaultLiteral(
              param(ParameterValueType.json, value: '{"a":1}')),
          "'{\"a\":1}'");
    });
  });
}
