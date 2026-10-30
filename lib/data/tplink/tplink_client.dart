import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'cgi_protocol.dart';

class RouterException implements Exception {
  const RouterException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RouterAuthException extends RouterException {
  const RouterAuthException([
    super.message =
        'The router rejected the username or password. After 10 failed '
        'attempts it locks for 2 hours.',
  ]);
}

class RouterUnreachableException extends RouterException {
  const RouterUnreachableException([
    super.message =
        'Could not reach the router. Check that this phone is on the same '
        'Wi-Fi network and the admin address is correct.',
  ]);
}

class CgiException extends RouterException {
  CgiException(this.code, [String request = ''])
    : super(
        request.isEmpty
            ? 'The router rejected the request (error $code).'
            : 'The router rejected the request (error $code: $request).',
      );

  final int code;
}

class RouterProtocolException extends RouterException {
  const RouterProtocolException(super.message);
}

/// Minimal, serialised HTTP client for the router's local admin API.
///
/// The TL-WR840N v6 authenticates with a cookie containing
/// `Authorization: Basic base64(user:password)`. The password only ever lives
/// in memory here and is never logged.
class TplinkClient {
  TplinkClient({
    required this.host,
    required String username,
    required String password,
    Dio? dio,
  }) : _token = base64Encode(utf8.encode('$username:$password')),
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 4),
               sendTimeout: const Duration(seconds: 4),
               receiveTimeout: const Duration(seconds: 8),
               responseType: ResponseType.plain,
               validateStatus: (status) => status != null,
               followRedirects: true,
             ),
           );

  final String host;
  final String _token;
  final Dio _dio;

  Future<void> _queue = Future<void>.value();

  Future<CgiResponse> execute(CgiRequest request) {
    if (request.isEmpty) {
      return Future.error(
        const RouterProtocolException('Empty router request.'),
      );
    }

    final completer = Completer<CgiResponse>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await _send(request));
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<CgiResponse> _send(CgiRequest request) async {
    final uri = Uri.parse('http://$host/cgi?${request.query}');

    final Response<String> response;
    try {
      response = await _dio.postUri<String>(
        uri,
        data: request.body,
        options: Options(
          contentType: 'text/plain',
          headers: {
            'Accept': '*/*',
            'Origin': 'http://$host',
            'Cookie': 'Authorization=Basic $_token',
            'Authorization': 'Basic $_token',
            'Referer': 'http://$host/',
          },
        ),
      );
    } on DioException catch (_) {
      throw const RouterUnreachableException();
    }

    final status = response.statusCode ?? 0;
    if (status == 401 || status == 403) {
      throw const RouterAuthException();
    }
    if (status < 200 || status >= 300) {
      throw RouterUnreachableException(
        'The router answered with HTTP $status.',
      );
    }

    final body = response.data ?? '';
    final lower = body.trimLeft().toLowerCase();
    if (lower.startsWith('<!doctype') || lower.startsWith('<html')) {
      throw const RouterAuthException();
    }

    final parsed = CgiResponse.parse(body);
    if (parsed.errorCode != 0) {
      throw CgiException(parsed.errorCode, request.summary);
    }
    return parsed;
  }

  void dispose() {
    _dio.close(force: true);
  }
}
