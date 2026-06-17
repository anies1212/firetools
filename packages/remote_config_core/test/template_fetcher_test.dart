import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:remote_config_core/remote_config_core.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateFetcher.fetch', () {
    test('parses a successful Admin API response', () async {
      // Arrange
      final body = jsonEncode({
        'parameters': {
          'feature_x': {
            'defaultValue': {'value': 'true'},
            'valueType': 'BOOLEAN',
          },
        },
      });
      final fetcher = TemplateFetcher(
        projectId: 'demo',
        clientFactory: () async => MockClient((req) async {
          expect(req.url.toString(), contains('projects/demo/remoteConfig'));
          return http.Response(body, 200);
        }),
      );

      // Act
      final template = await fetcher.fetch();

      // Assert
      expect(template.parameters.single.key, 'feature_x');
      expect(template.parameters.single.valueType, ParameterValueType.boolean);
    });

    test('attaches the access token as a Bearer credential', () async {
      // Arrange
      final captured = <String>[];
      final fetcher = TemplateFetcher(
        projectId: 'demo',
        accessToken: 'test-token',
        clientFactory: () async => MockClient((req) async {
          captured.add(req.headers['Authorization'] ?? '');
          return http.Response(jsonEncode({'parameters': {}}), 200);
        }),
      );

      // Act
      await fetcher.fetch();

      // Assert
      expect(captured.single, 'Bearer test-token');
    });

    test('throws with body on non-200 responses', () async {
      final fetcher = TemplateFetcher(
        projectId: 'demo',
        clientFactory: () async =>
            MockClient((req) async => http.Response('nope', 403)),
      );

      expect(
        fetcher.fetch,
        throwsA(isA<TemplateFetchException>()),
      );
    });
  });
}
