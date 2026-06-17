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
/// Authentication is dual-mode (see [authClient]):
/// - a service-account key file when [serviceAccountPath] is provided, else
/// - Application Default Credentials (ADC).
class TemplateFetcher {
  /// OAuth scope required to read the Remote Config template.
  static const scope = 'https://www.googleapis.com/auth/firebase.remoteconfig';

  final String projectId;
  final String? serviceAccountPath;

  /// Injectable client factory for testing. When null, real auth clients are
  /// created from a service account or ADC.
  final Future<http.Client> Function()? clientFactory;

  const TemplateFetcher({
    required this.projectId,
    this.serviceAccountPath,
    this.clientFactory,
  });

  Uri get _endpoint => Uri.parse(
        'https://firebaseremoteconfig.googleapis.com/v1/projects/$projectId/remoteConfig',
      );

  /// Creates an authenticated HTTP client (service account → ADC fallback).
  Future<http.Client> authClient() async {
    if (clientFactory != null) return clientFactory!();

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
