import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

/// Thrown when the Remote Config template cannot be fetched.
class TemplateFetchException implements Exception {
  final String message;
  const TemplateFetchException(this.message);
  @override
  String toString() => 'TemplateFetchException: $message';
}

/// Fetches a Remote Config template via the Admin REST API.
///
/// Authentication is resolved in priority order (see [authClient]):
/// 1. a pre-minted OAuth access token when [accessToken] is provided
///    (e.g. issued by `google-github-actions/auth` in CI, which works with
///    both Workload Identity Federation and service-account keys), else
/// 2. a service-account key file when [serviceAccountPath] is provided, else
/// 3. Application Default Credentials (ADC).
class TemplateFetcher {
  /// OAuth scope required to read the Remote Config template.
  static const scope = 'https://www.googleapis.com/auth/firebase.remoteconfig';

  final String projectId;
  final String? serviceAccountPath;

  /// A pre-minted OAuth 2.0 access token used directly as a Bearer credential.
  ///
  /// Takes precedence over [serviceAccountPath] and ADC. This is the path used
  /// in CI when a token is issued out-of-band (notably for Workload Identity
  /// Federation, which `googleapis_auth` cannot consume via ADC).
  final String? accessToken;

  /// Injectable client factory for testing. When null, real auth clients are
  /// created from an access token, a service account, or ADC.
  final Future<http.Client> Function()? clientFactory;

  const TemplateFetcher({
    required this.projectId,
    this.serviceAccountPath,
    this.accessToken,
    this.clientFactory,
  });

  Uri get _endpoint => Uri.parse(
        'https://firebaseremoteconfig.googleapis.com/v1/projects/$projectId/remoteConfig',
      );

  /// Creates an authenticated HTTP client
  /// (access token → service account → ADC).
  Future<http.Client> authClient() async {
    final token = accessToken;
    final hasToken = token != null && token.isNotEmpty;

    if (clientFactory != null) {
      final base = await clientFactory!();
      return hasToken ? _BearerClient(base, token) : base;
    }

    if (hasToken) {
      return _BearerClient(http.Client(), token);
    }

    final path = serviceAccountPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (!await file.exists()) {
        throw TemplateFetchException('Service account file not found: $path');
      }
      final json = jsonDecode(await file.readAsString());
      final credentials = ServiceAccountCredentials.fromJson(json);
      return clientViaServiceAccount(credentials, const [scope]);
    }

    try {
      return await clientViaApplicationDefaultCredentials(
          scopes: const [scope]);
    } catch (e) {
      throw TemplateFetchException(
        'Failed to obtain Application Default Credentials. Run '
        '`gcloud auth application-default login` or set `service_account` '
        'in firefreeze.yaml. Cause: $e',
      );
    }
  }

  /// Fetches and parses the Remote Config template.
  Future<RemoteConfigTemplate> fetch() async {
    final client = await authClient();
    try {
      final response = await client.get(
        _endpoint,
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw TemplateFetchException(
          'Admin API returned ${response.statusCode}: ${response.body}',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return RemoteConfigTemplate.fromAdminResponse(body);
    } finally {
      client.close();
    }
  }
}

/// An HTTP client that attaches a static Bearer token to every request.
class _BearerClient extends http.BaseClient {
  _BearerClient(this._inner, this._token);

  final http.Client _inner;
  final String _token;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
