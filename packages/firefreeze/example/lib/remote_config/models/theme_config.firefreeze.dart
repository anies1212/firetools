// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: public_member_api_docs, sort_constructors_first, lines_longer_than_80_chars, directives_ordering, invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme_config.firefreeze.freezed.dart';
part 'theme_config.firefreeze.g.dart';

@freezed
abstract class ThemeConfigPalette with _$ThemeConfigPalette {
  const factory ThemeConfigPalette({
    required String accent,
  }) = _ThemeConfigPalette;

  factory ThemeConfigPalette.fromJson(Map<String, dynamic> json) =>
      _$ThemeConfigPaletteFromJson(json);
}

@freezed
abstract class ThemeConfig with _$ThemeConfig {
  const factory ThemeConfig({
    @JsonKey(name: 'primary_color') required String primaryColor,
    @JsonKey(name: 'dark_mode') required bool darkMode,
    @JsonKey(name: 'corner_radius') required int cornerRadius,
    required ThemeConfigPalette palette,
  }) = _ThemeConfig;

  factory ThemeConfig.fromJson(Map<String, dynamic> json) =>
      _$ThemeConfigFromJson(json);
}
