import 'dart:developer';

import 'package:dio/dio.dart';

import '../constants/constants.dart';
import '../utils/session_guard.dart';

/// One shared Dio for the app.
///
/// Why not `Dio()` per call: a bare Dio has no connectTimeout, so when the
/// server drops a TCP connect (admin.paani76.com does this intermittently)
/// the request hangs until the OS gives up and Dio then reports the
/// misleading "took longer than 0:00:00.000000". A new Dio per call also
/// means a new TLS handshake per request; a shared one reuses keep-alive
/// connections, so there are far fewer connects to drop in the first place.
class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      // Endpoints routinely take ~4s; leave generous headroom.
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 30),
    ),
  )..interceptors.addAll([_RetryInterceptor(), _SessionInterceptor()]);
}

/// Watches for a rejected token (HTTP 401) on any request made while a user
/// is signed in. The login request is skipped, so a wrong password is not
/// treated as an expired session.
class _SessionInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isLogin = err.requestOptions.path.contains('login_admin.php');
    final isSignedIn = Constants.token.isNotEmpty;

    final status = err.response?.statusCode;
    final isRejected = status == 401 || status == 403;

    if (isRejected && isSignedIn && !isLogin) {
      SessionGuard.handleExpired();
    }

    handler.next(err);
  }
}

/// Retries GET requests (safe to repeat) that failed before getting any
/// response from the server: connect timeouts and dropped connections.
class _RetryInterceptor extends Interceptor {
  static const _maxRetries = 2;
  static const _retryKey = '_retryCount';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_retryKey] as int?) ?? 0;

    final retryable =
        options.method.toUpperCase() == 'GET' &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.connectionError);

    if (!retryable || attempt >= _maxRetries) {
      return handler.next(err);
    }

    options.extra[_retryKey] = attempt + 1;
    log('Retrying ${options.path} (${attempt + 1}/$_maxRetries): ${err.type}');
    await Future.delayed(Duration(milliseconds: 800 * (attempt + 1)));

    try {
      final response = await ApiClient.dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
