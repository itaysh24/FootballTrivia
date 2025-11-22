import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 4000);
  print('✅ Dart MCP server running at http://localhost:4000');

  await for (HttpRequest request in server) {
    if (request.uri.path == '/listOfferings') {
      // Respond to MCP "ListOfferings"
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'offerings': ['completions', 'tools']
        }));
    } else {
      request.response
        ..statusCode = 404
        ..write('Not found');
    }
    await request.response.close();
  }
}
