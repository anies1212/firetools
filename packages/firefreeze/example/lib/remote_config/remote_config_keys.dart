// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: public_member_api_docs, sort_constructors_first, lines_longer_than_80_chars, directives_ordering, invalid_annotation_target

/// Type-safe Remote Config parameter keys.
enum RemoteConfigKey {
  featureXEnabled('feature_x_enabled'),
  maxRetryCount('max_retry_count'),
  discountRatio('discount_ratio'),
  welcomeMessage('welcome_message'),
  themeConfig('theme_config');

  const RemoteConfigKey(this.key);

  /// The raw Remote Config parameter key.
  final String key;
}
