// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: public_member_api_docs, sort_constructors_first, lines_longer_than_80_chars, directives_ordering, invalid_annotation_target

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'firebase_remote_config_provider.dart';
import 'remote_config_values.dart';
import 'models/theme_config.firefreeze.dart';

part 'remote_config_providers.g.dart';

/// Type-safe Remote Config accessor provider.
@riverpod
RemoteConfigValues remoteConfigValues(Ref ref) =>
    RemoteConfigValues(ref.watch(firebaseRemoteConfigProvider));

/// Whether feature X is enabled
@riverpod
bool featureXEnabled(Ref ref) =>
    ref.watch(remoteConfigValuesProvider).featureXEnabled;

/// Maximum number of API call retries
@riverpod
int maxRetryCount(Ref ref) =>
    ref.watch(remoteConfigValuesProvider).maxRetryCount;

/// Discount ratio applied at checkout
@riverpod
double discountRatio(Ref ref) =>
    ref.watch(remoteConfigValuesProvider).discountRatio;

/// Welcome message shown on the home screen
@riverpod
String welcomeMessage(Ref ref) =>
    ref.watch(remoteConfigValuesProvider).welcomeMessage;

/// Theme configuration
@riverpod
ThemeConfig themeConfig(Ref ref) =>
    ref.watch(remoteConfigValuesProvider).themeConfig;
