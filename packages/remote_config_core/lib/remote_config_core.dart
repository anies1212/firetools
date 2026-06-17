/// Internal package for Firebase Remote Config template fetching,
/// authentication, type mapping and JSON schema inference.
///
/// Used by `firefreeze`. Not intended for direct use.
library;

export 'src/config_loader.dart';
export 'src/json_schema_inferer.dart';
export 'src/models.dart';
export 'src/template_fetcher.dart';
export 'src/type_mapper.dart';
