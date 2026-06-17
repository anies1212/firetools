// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: public_member_api_docs, sort_constructors_first, lines_longer_than_80_chars, directives_ordering, invalid_annotation_target

import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'models/theme_config.firefreeze.dart';

/// Type-safe accessors over [FirebaseRemoteConfig].
class RemoteConfigValues {
  const RemoteConfigValues(this._rc);

  final FirebaseRemoteConfig _rc;

  /// Whether feature X is enabled
  bool get featureXEnabled => _rc.getBool('feature_x_enabled');

  /// Maximum number of API call retries
  int get maxRetryCount => _rc.getInt('max_retry_count');

  /// Discount ratio applied at checkout
  double get discountRatio => _rc.getDouble('discount_ratio');

  /// Welcome message shown on the home screen
  String get welcomeMessage => _rc.getString('welcome_message');

  /// Theme configuration
  ThemeConfig get themeConfig => ThemeConfig.fromJson(
      jsonDecode(_rc.getString('theme_config')) as Map<String, dynamic>);
}

/// Default values mirrored from the Remote Config template.
///
/// Pass to `FirebaseRemoteConfig.setDefaults` so the app has sensible
/// values before the first fetch.
const remoteConfigDefaults = <String, dynamic>{
  'feature_x_enabled': true,
  'max_retry_count': 3,
  'discount_ratio': 0.15,
  'welcome_message': 'Welcome',
  'theme_config':
      '{"primary_color":"#000000","dark_mode":false,"corner_radius":8,"palette":{"accent":"#FF8800"}}',
};
