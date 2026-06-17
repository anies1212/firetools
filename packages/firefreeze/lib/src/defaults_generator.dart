import 'package:remote_config_core/remote_config_core.dart';

/// Generates the `remoteConfigDefaults` map block used with
/// `FirebaseRemoteConfig.setDefaults`.
class DefaultsGenerator {
  const DefaultsGenerator();

  /// Returns the `const remoteConfigDefaults = {...};` block.
  ///
  /// Only parameters with a concrete server default are included; in-app
  /// defaults are intentionally omitted (the app supplies those).
  String mapBlock(List<RemoteConfigParameter> params) {
    final concrete = params.where((p) => p.hasConcreteDefault).toList();
    final buffer = StringBuffer()
      ..writeln('/// Default values mirrored from the Remote Config template.')
      ..writeln('///')
      ..writeln('/// Pass to `FirebaseRemoteConfig.setDefaults` so the app has '
          'sensible')
      ..writeln('/// values before the first fetch.')
      ..writeln('const remoteConfigDefaults = <String, dynamic>{');

    for (final param in concrete) {
      buffer.writeln("  '${param.key}': ${TypeMapper.defaultLiteral(param)},");
    }

    buffer.writeln('};');
    return buffer.toString();
  }
}
