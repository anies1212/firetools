# firefreeze example

A sample `firefreeze.yaml` together with the code generated from it.

This example uses `fetch: never` plus a pre-seeded
`.dart_tool/firefreeze/template_cache.json` (5 parameters: BOOLEAN / NUMBER(int) /
NUMBER(double) / STRING / JSON), so it runs offline without Firebase
authentication.

```bash
dart run firefreeze
```

See the generated output under [`lib/remote_config/`](lib/remote_config/):

- `remote_config_keys.dart` — `enum RemoteConfigKey`
- `remote_config_values.dart` — type-safe accessors + `remoteConfigDefaults`
- `remote_config_providers.dart` — Riverpod providers
- `models/theme_config.firefreeze.dart` — Freezed model inferred from a JSON
  parameter (the nested object `palette` is also generated as
  `ThemeConfigPalette`)

In a real project, add `freezed` / `riverpod_generator` to your
`dev_dependencies` and run
`dart run build_runner build --delete-conflicting-outputs` to produce the
`*.freezed.dart` / `*.g.dart` files.
