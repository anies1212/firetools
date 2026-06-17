# Changelog

## 0.1.0

- Initial release.
- Generates `enum RemoteConfigKey`, type-safe `RemoteConfigValues` accessors,
  and a `remoteConfigDefaults` map from a Firebase Remote Config template.
- Infers Freezed models for JSON parameters (`json_models: true`).
- Optionally generates Riverpod providers (`generate_providers: true`).
- Incremental generation with SHA-256 template/parameter caching.
- `firefreeze.yaml` configuration with `include` / `exclude` filtering and
  `fetch` modes (`always` / `if_no_cache` / `never`).
