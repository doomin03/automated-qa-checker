import 'package:api_client_dart/health_client.dart';

class ServerRepository {
  HealthClient? _client;
  Future<String> connect(String origin) async {
    _client?.close();
    final client = HealthClient(origin);
    _client = client;
    final response = await client.getHealth(client: 'app');
    return '${response.service} · ${response.status.value} · ${response.client?.value} · API ${response.apiVersion}';
  }

  void dispose() {
    _client?.close();
  }
}
