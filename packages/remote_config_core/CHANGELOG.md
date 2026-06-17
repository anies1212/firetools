# Changelog

## 0.1.0

- Initial release.
- Fetches Remote Config templates via the Admin REST API.
- Authenticates with Application Default Credentials, falling back to a
  service-account JSON key.
- Maps `valueType` (STRING / BOOLEAN / NUMBER / JSON) to Dart types.
- Infers JSON schemas from default values.
