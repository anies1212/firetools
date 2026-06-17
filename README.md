# firetools

A Dart monorepo that generates code from Firebase Remote Config. It applies the
same idea as [supatools](https://github.com/anies1212/supatools) (the Supabase
edition) to Remote Config.

The Remote Config Admin REST API returns an explicit `valueType`
(`STRING` / `BOOLEAN` / `NUMBER` / `JSON`) for every parameter, so firetools can
**read the declared type instead of guessing it** and generate type-safe
accessors, default values, and Riverpod providers. The goal is to eliminate
stringly-typed access such as `getBool('feature_x')`.

## Packages

| Package | Role |
|---------|------|
| [remote_config_core](packages/remote_config_core) | Template fetching, authentication, type mapping, and JSON schema inference (shared internals) |
| [firefreeze](packages/firefreeze) | Generator for type-safe accessors / defaults / Riverpod providers / Freezed models (CLI: `firefreeze`) |

## Quick start

```bash
# 1. Create a firefreeze.yaml (at minimum, project_id).
# 2. Authenticate (either option):
gcloud auth application-default login          # ADC (recommended)
# or set service_account: <key path> in firefreeze.yaml

# 3. Generate.
dart run firefreeze

# 4. Generate Freezed / Riverpod parts (when using JSON models or providers).
dart run build_runner build --delete-conflicting-outputs
```

### firefreeze.yaml

```yaml
project_id: ${FIREBASE_PROJECT_ID}        # required (env vars are resolved)
# service_account: $dotenv{GOOGLE_APPLICATION_CREDENTIALS}  # optional; falls back to ADC
output: lib/remote_config                 # output directory
fetch: always                             # always | if_no_cache | never
generate_defaults: true                   # generate remoteConfigDefaults
json_models: true                         # generate Freezed models for JSON (false -> Map)
generate_providers: false                 # also generate the Riverpod variant
client_provider_import: firebase_remote_config_provider.dart
include: []                               # key allowlist (mutually exclusive with exclude)
exclude: []
generate_barrel: true
```

## Generated output

```
lib/remote_config/
├── remote_config.dart                # barrel
├── remote_config_keys.dart           # enum RemoteConfigKey
├── remote_config_values.dart         # type-safe accessors + remoteConfigDefaults
├── remote_config_providers.dart      # Riverpod (only when generate_providers: true)
└── models/
    └── <param>.firefreeze.dart       # Freezed model for a JSON parameter
```

The non-Riverpod variant (`RemoteConfigValues`) is the baseline; when
`generate_providers: true`, Riverpod providers are generated in addition. See
[packages/firefreeze/example](packages/firefreeze/example) for real output.

## Development

```bash
dart pub get                  # resolve the workspace from the repo root
cd packages/<pkg> && dart test
dart analyze
dart format .
```

If you prefer melos: `dart pub global activate melos && melos bootstrap`.

## A note on authentication

- Never commit keys to the repository. Prefer ADC, and when you do use a
  service-account key, resolve its path via `$dotenv{}` / `$env{}`.
- No tokens or keys are left in generated output or caches (only template
  content is cached).

## Limitations

- JSON type inference depends on the default value. If the default is not
  representative or is empty, the inferred type may drift, so a warning is
  emitted at generation time. Use `json_models: false` to fall back to
  `Map<String, dynamic>`.
- Conditional values are resolved at runtime by the SDK, so generation uses only
  the key, valueType, and default.

## License

MIT
