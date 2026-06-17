# firetools

[![firefreeze](https://img.shields.io/pub/v/firefreeze?label=firefreeze)](https://pub.dev/packages/firefreeze)
[![remote_config_core](https://img.shields.io/pub/v/remote_config_core?label=remote_config_core)](https://pub.dev/packages/remote_config_core)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

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

## GitHub Action

This repo doubles as a **composite action** (`anies1212/firetools`, defined in
[`action.yml`](action.yml)). It runs firefreeze in CI to regenerate type-safe
Remote Config code, then reports the diff. A typical setup triggers it with
`workflow_dispatch`, surfaces the diff in the job summary, and uses the
`changed` output to open a pull request — see the
[full example workflow](examples/workflows/generate-remote-config.yml).

### What the action does

1. Sets up the Dart SDK (skippable when Dart/Flutter is already installed).
2. Authenticates to Google Cloud and mints an OAuth access token (scope
   `firebase.remoteconfig`).
3. Activates `firefreeze` from pub.dev and regenerates code from your
   `firefreeze.yaml`.
4. Optionally runs `build_runner` for Freezed/Riverpod parts.
5. Detects working-tree changes (including newly generated, untracked files),
   writes the diff to the job summary, and sets the `changed` output.

### Usage

```yaml
permissions:
  contents: read
  id-token: write # for Workload Identity Federation
steps:
  - uses: actions/checkout@v6
  - id: firefreeze
    uses: anies1212/firetools@v0.2.1
    with:
      working-directory: .
      config: firefreeze.yaml
      version: ^0.2.0
      # Auth — pick one:
      workload-identity-provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      service-account: ${{ vars.GCP_SERVICE_ACCOUNT }}
      # credentials-json: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
  - if: steps.firefreeze.outputs.changed == 'true'
    run: echo "Remote Config code changed"
```

### Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `working-directory` | `.` | Directory that contains `firefreeze.yaml` (and the project). |
| `config` | `firefreeze.yaml` | Path to `firefreeze.yaml`, relative to `working-directory`. |
| `version` | `''` (latest) | firefreeze version to activate from pub.dev. |
| `force` | `false` | Pass `--force` to regenerate even when the template is unchanged. |
| `run-build-runner` | `false` | Run `build_runner build` after generation (for Freezed/Riverpod parts). Requires deps already resolved. |
| `setup-dart` | `true` | Install the Dart SDK. Set `false` if Dart/Flutter is already set up. |
| `dart-sdk` | `stable` | Dart SDK version/channel used when `setup-dart` is true. |
| `access-token` | `''` | Pre-minted OAuth access token used directly as a Bearer credential. When set, the Google Cloud auth step is skipped. |
| `workload-identity-provider` | `''` | Full identifier of the Workload Identity Provider for keyless auth. |
| `service-account` | `''` | Service-account email to impersonate with WIF. Required when `workload-identity-provider` is set. |
| `credentials-json` | `''` | Service-account key JSON (alternative to WIF). Pass via a secret. |

### Outputs

| Output | Description |
|--------|-------------|
| `changed` | `true` when generation produced changes in the working tree. Use it to gate a commit/PR step. |

### Authentication

Auth resolves in priority order: `access-token` → Google Cloud auth
(`workload-identity-provider` **or** `credentials-json`) → ambient ADC. The
action mints an OAuth access token (scope `firebase.remoteconfig`) and passes it
to firefreeze via `FIREFREEZE_ACCESS_TOKEN`, so Workload Identity Federation
works even though `googleapis_auth` cannot consume WIF via ADC directly. When
using WIF, the job must request `id-token: write` permission.

### Committing the diff

The action itself only generates code and reports `changed` — it does not
commit. The [example workflow](examples/workflows/generate-remote-config.yml)
pairs it with `peter-evans/create-pull-request` to commit the diff to a branch
(chosen at dispatch time via a `branch` input) and open a pull request, which
needs `contents: write` and `pull-requests: write`.

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
