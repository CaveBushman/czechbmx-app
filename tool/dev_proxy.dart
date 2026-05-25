import 'dart:io';

const _targetScheme = 'https';
const _targetHost = 'czechbmx.cz';
const _defaultPort = 8080;

Future<void> main(List<String> args) async {
  final port =
      args.isNotEmpty ? int.tryParse(args.first) ?? _defaultPort : _defaultPort;
  final client = HttpClient();
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);

  stdout.writeln('Czech BMX dev proxy listening on http://localhost:$port');
  stdout.writeln('Forwarding requests to $_targetScheme://$_targetHost');

  await for (final request in server) {
    await _handleRequest(request, client);
  }
}

Future<void> _handleRequest(HttpRequest request, HttpClient client) async {
  _setCorsHeaders(request.response);

  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  try {
    final targetUri = request.requestedUri.replace(
      scheme: _targetScheme,
      host: _targetHost,
      port: 443,
    );
    final proxyRequest = await client.openUrl(request.method, targetUri);

    request.headers.forEach((name, values) {
      if (_isHopByHopHeader(name)) return;
      for (final value in values) {
        proxyRequest.headers.add(name, value);
      }
    });

    proxyRequest.headers.host = _targetHost;
    await proxyRequest.addStream(request);
    final proxyResponse = await proxyRequest.close();
    request.response.statusCode = proxyResponse.statusCode;

    proxyResponse.headers.forEach((name, values) {
      if (_isHopByHopHeader(name) || name.toLowerCase() == 'content-encoding') {
        return;
      }
      for (final value in values) {
        request.response.headers.add(name, value);
      }
    });
    _setCorsHeaders(request.response);

    await proxyResponse.pipe(request.response);
  } catch (error) {
    request.response.statusCode = HttpStatus.badGateway;
    request.response.headers.contentType = ContentType.json;
    request.response.write('{"detail":"Dev proxy failed: $error"}');
    await request.response.close();
  }
}

void _setCorsHeaders(HttpResponse response) {
  response.headers
    ..set(HttpHeaders.accessControlAllowOriginHeader, '*')
    ..set(
      HttpHeaders.accessControlAllowMethodsHeader,
      'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    )
    ..set(
      HttpHeaders.accessControlAllowHeadersHeader,
      'Origin, Content-Type, Accept, Authorization',
    );
}

bool _isHopByHopHeader(String name) {
  return switch (name.toLowerCase()) {
    'connection' ||
    'keep-alive' ||
    'proxy-authenticate' ||
    'proxy-authorization' ||
    'te' ||
    'trailer' ||
    'transfer-encoding' ||
    'upgrade' =>
      true,
    _ => false,
  };
}
