# Changelog

## 0.2.0

- Add `TemplateFetcher.accessToken` to authenticate with a pre-minted OAuth
  access token (Bearer), in addition to service-account keys and ADC. This
  enables CI flows that issue tokens out-of-band — notably Workload Identity
  Federation, which `googleapis_auth` cannot consume via ADC.

## 0.1.0

- Initial release.
- Fetches Remote Config templates via the Admin REST API.
- Authenticates with Application Default Credentials, falling back to a
  service-account JSON key.
- Maps `valueType` (STRING / BOOLEAN / NUMBER / JSON) to Dart types.
- Infers JSON schemas from default values.
