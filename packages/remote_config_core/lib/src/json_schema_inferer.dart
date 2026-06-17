import 'package:recase/recase.dart';

/// An inferred Dart type for a JSON value.
sealed class InferredType {
  /// The Dart type expression (e.g. `String`, `List<Foo>`, `Foo`).
  String get dartType;
}

/// A scalar Dart type (`String`, `int`, `double`, `bool`, `dynamic`).
class ScalarType implements InferredType {
  @override
  final String dartType;
  const ScalarType(this.dartType);
}

/// A `List<element>` type.
class ListType implements InferredType {
  final InferredType element;
  const ListType(this.element);
  @override
  String get dartType => 'List<${element.dartType}>';
}

/// An object type that maps to a generated class.
class ObjectType implements InferredType {
  final String className;
  final List<InferredField> fields;
  const ObjectType(this.className, this.fields);
  @override
  String get dartType => className;
}

/// One field of an inferred object type.
class InferredField {
  /// Dart field name (camelCase).
  final String name;

  /// Original JSON key.
  final String jsonKey;

  final InferredType type;

  /// Whether the value was null / could not be determined.
  final bool nullable;

  const InferredField({
    required this.name,
    required this.jsonKey,
    required this.type,
    this.nullable = false,
  });
}

/// The result of inferring a model from a JSON default value.
class InferenceResult {
  /// The root inferred type (an [ObjectType] when the JSON is an object).
  final InferredType root;

  /// All object types discovered, in declaration order (root first).
  final List<ObjectType> objects;

  /// Human-readable warnings about ambiguous inference (e.g. null values,
  /// empty arrays) the caller should surface.
  final List<String> warnings;

  const InferenceResult({
    required this.root,
    required this.objects,
    required this.warnings,
  });

  /// Whether the root is an object that warrants generating model classes.
  bool get hasModel => root is ObjectType;
}

/// Infers a Dart model shape from a decoded JSON default value.
///
/// Inference is best-effort and driven by the example default value, so
/// ambiguities (null fields, empty arrays, mixed-type arrays) are recorded as
/// [InferenceResult.warnings] rather than silently dropped.
class JsonSchemaInferer {
  final List<ObjectType> _objects = [];
  final List<String> _warnings = [];

  /// Infers a model for [decoded] using [baseClassName] (PascalCase) as the
  /// root class name.
  static InferenceResult infer(Object? decoded, String baseClassName) {
    final inferer = JsonSchemaInferer._();
    final root = inferer._inferValue(decoded, baseClassName, baseClassName);
    return InferenceResult(
      root: root,
      objects: List.unmodifiable(inferer._objects),
      warnings: List.unmodifiable(inferer._warnings),
    );
  }

  JsonSchemaInferer._();

  InferredType _inferValue(Object? value, String pathName, String className) {
    return switch (value) {
      null => _dynamicFor(pathName),
      bool() => const ScalarType('bool'),
      int() => const ScalarType('int'),
      double() => const ScalarType('double'),
      String() => const ScalarType('String'),
      List() => _inferList(value, pathName, className),
      Map() => _inferObject(value.cast<String, dynamic>(), className),
      _ => _dynamicFor(pathName),
    };
  }

  InferredType _dynamicFor(String pathName) {
    _warnings.add(
        "Could not infer a type for '$pathName' (null/unknown); using dynamic.");
    return const ScalarType('dynamic');
  }

  InferredType _inferList(
      List<dynamic> list, String pathName, String className) {
    if (list.isEmpty) {
      _warnings
          .add("Empty array at '$pathName'; element type defaults to dynamic.");
      return const ListType(ScalarType('dynamic'));
    }
    final elementClass = '${className}Item';
    final element = _inferValue(list.first, '$pathName[]', elementClass);
    return ListType(element);
  }

  ObjectType _inferObject(Map<String, dynamic> map, String className) {
    final fields = <InferredField>[];
    map.forEach((key, value) {
      final fieldName = ReCase(key).camelCase;
      final nestedClass = '$className${ReCase(key).pascalCase}';
      final type = _inferValue(value, '$className.$key', nestedClass);
      fields.add(InferredField(
        name: fieldName,
        jsonKey: key,
        type: type,
        nullable: value == null,
      ));
    });
    final object = ObjectType(className, fields);
    _objects.add(object);
    return object;
  }
}
