# firefreeze

Generate type-safe Dart code from a Firebase Remote Config template.

`firefreeze` reads the explicit `valueType` (`STRING` / `BOOLEAN` / `NUMBER` /
`JSON`) that the Remote Config Admin API returns for every parameter, so it
generates **type-safe accessors, default values, Riverpod providers, and Freezed
models** without guessing types. The goal is to eliminate stringly-typed access
such as `getBool('feature_x')`.

It fetches the template **directly from the Admin REST API** (no manual
`firebase remoteconfig:get` step), and infers Freezed models from JSON
parameters.

## Install

```yaml
dev_dependencies:
  firefreeze: ^0.1.0
```

## Usage

1. Create a `firefreeze.yaml` (at minimum, `project_id`).
2. Authenticate with Application Default Credentials
   (`gcloud auth application-default login`) or set a `service_account` key path
   in the config.
3. Generate:

```bash
dart run firefreeze
# then, when using JSON models or providers:
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

See [example/](example) for real output that runs offline.

## License

MIT — see [LICENSE](LICENSE). Part of the
[firetools](https://github.com/anies1212/firetools) monorepo.
