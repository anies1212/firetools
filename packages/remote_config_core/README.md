# remote_config_core

[![pub package](https://img.shields.io/pub/v/remote_config_core.svg)](https://pub.dev/packages/remote_config_core)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Shared internals for [firetools](https://github.com/anies1212/firetools).

This package fetches Firebase Remote Config templates from the Admin REST API,
handles authentication, maps `valueType` to Dart types, and infers JSON schemas
from default values. It is consumed by the
[`firefreeze`](https://pub.dev/packages/firefreeze) generator.

> **Note:** This is an internal building block. Most users want `firefreeze`,
> not this package directly.

## What it provides

- `TemplateFetcher` — fetches a Remote Config template via the Admin REST API,
  authenticating with Application Default Credentials or a service-account key.
- `RemoteConfigTemplate` / `RemoteConfigParameter` — parsed template models.
- `TypeMapper` — maps `STRING` / `BOOLEAN` / `NUMBER` / `JSON` to Dart types.
- `JsonSchemaInferer` — infers a structured schema from a JSON default value.
- `BaseConfigLoader` — environment-variable resolution (`${VAR}`, `$env{}`,
  `$define{}`, `$dotenv{}`) and `FetchMode` parsing.

## License

MIT — see [LICENSE](LICENSE).
