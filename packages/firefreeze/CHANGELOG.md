# Changelog

## 0.2.1

- Format generated Dart with `dart_style` so the output passes
  `dart format --set-exit-if-changed` in consumer projects (no more long lines
  in `remote_config_values.dart`). Falls back to unformatted output with a
  warning if a file cannot be parsed.

## 0.2.0

- Support authenticating with a pre-minted OAuth access token, via the
  `access_token` config field or the `FIREFREEZE_ACCESS_TOKEN` environment
  variable. Takes precedence over `service_account` and ADC, and unblocks
  Workload Identity Federation in CI (see the bundled GitHub Action).

## 0.1.0

- Initial release.
- Generates `enum RemoteConfigKey`, type-safe `RemoteConfigValues` accessors,
  and a `remoteConfigDefaults` map from a Firebase Remote Config template.
- Infers Freezed models for JSON parameters (`json_models: true`).
- Optionally generates Riverpod providers (`generate_providers: true`).
- Incremental generation with SHA-256 template/parameter caching.
- `firefreeze.yaml` configuration with `include` / `exclude` filtering and
  `fetch` modes (`always` / `if_no_cache` / `never`).
