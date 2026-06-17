import 'package:recase/recase.dart';
import 'package:remote_config_core/remote_config_core.dart';

import 'generator_header.dart';

/// Generates a Freezed model source file for a single JSON-typed parameter,
/// based on a [InferenceResult] inferred from its default value.
class JsonModelGenerator {
  const JsonModelGenerator();

  /// The generated file name for a parameter key (e.g. `theme_config` →
  /// `theme_config.firefreeze.dart`).
  String fileName(String paramKey) =>
      '${ReCase(paramKey).snakeCase}.firefreeze.dart';

  /// The root model class name for a parameter key.
  String className(String paramKey) => ReCase(paramKey).pascalCase;

  /// Generates the Freezed source. Emits one `@freezed` class per inferred
  /// object type (root first, then nested classes).
  String generate(String paramKey, InferenceResult inference) {
    final fileBase = ReCase(paramKey).snakeCase;
    final buffer = StringBuffer()
      ..writeln(generatedHeader)
      ..writeln("import 'package:freezed_annotation/freezed_annotation.dart';")
      ..writeln()
      ..writeln("part '$fileBase.firefreeze.freezed.dart';")
      ..writeln("part '$fileBase.firefreeze.g.dart';")
      ..writeln();

    for (final object in inference.objects) {
      _writeClass(buffer, object);
      buffer.writeln();
    }

    return buffer.toString();
  }

  void _writeClass(StringBuffer buffer, ObjectType object) {
    final name = object.className;
    buffer
      ..writeln('@freezed')
      ..writeln('abstract class $name with _\$$name {')
      ..writeln('  const factory $name({');

    for (final field in object.fields) {
      buffer.writeln('    ${_field(field)}');
    }

    buffer
      ..writeln('  }) = _$name;')
      ..writeln()
      ..writeln('  factory $name.fromJson(Map<String, dynamic> json) =>')
      ..writeln('      _\$${name}FromJson(json);')
      ..writeln('}');
  }

  String _field(InferredField field) {
    final type = field.type.dartType;
    final nullable = field.nullable;
    final annotation = field.name != field.jsonKey
        ? "@JsonKey(name: '${field.jsonKey}') "
        : '';

    if (nullable) {
      // `dynamic` is already nullable; `dynamic?` is not valid Dart.
      final suffix = type == 'dynamic' ? '' : '?';
      return '$annotation$type$suffix ${field.name},';
    }
    return '${annotation}required $type ${field.name},';
  }
}
