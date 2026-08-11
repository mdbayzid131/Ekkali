import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/config/constants/storage_constants.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/storege_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/utils/logger.dart';

/// ===================== API CLIENT =====================
/// Centralized HTTP client built on Dio with:
/// - Automatic token injection via interceptors (supports temporaryToken)
/// - Token refresh on 401 with retry
/// - Structured request/response logging
/// - Multipart upload support with progress
/// - Single-presentation error routing

class ApiClient extends GetxService {
  static late Dio _dio;
  static final String _bearerToken = '';
  static Future<bool>? _refreshFuture;

  static const String _fallbackMessage =
      'Something went wrong, please try again';
  static const int _timeoutSeconds = 30;

  /// Expose static temporaryToken for specialized authentication override (e.g. Socket/Auth Service)
  static String? temporaryToken;

  /// Expose dio only for edge-case direct usage (avoid if possible).
  Dio get dio => _dio;

  // ─────────────────────────── LIFECYCLE ───────────────────────────

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: _timeoutSeconds),
        receiveTimeout: const Duration(seconds: _timeoutSeconds),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(_buildInterceptor());
  }

  // ──────────────────────── INTERCEPTOR ────────────────────────

  InterceptorsWrapper _buildInterceptor() {
    return InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    String? tokenToUse;

    if (temporaryToken != null && temporaryToken!.isNotEmpty) {
      tokenToUse = temporaryToken;
    } else {
      tokenToUse = await StorageService.getString(StorageConstants.bearerToken);
    }

    if (tokenToUse != null &&
        tokenToUse.isNotEmpty &&
        !options.path.contains(ApiConstants.refreshToken)) {
      options.headers['Authorization'] = 'Bearer $tokenToUse';
    }

    AppLogger.request(options);
    return handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.response(response);
    return handler.next(response);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
    // 1️⃣ Connection Error → pass connection error down to response builder
    final isConnectionError =
        e.type == DioExceptionType.connectionError ||
        (e.type == DioExceptionType.unknown && e.error is SocketException) ||
        e.message?.contains('SocketException') == true ||
        e.error?.toString().contains('SocketException') == true;

    if (isConnectionError) {
      return handler.next(e);
    }

    // 2️⃣ Token expired → refresh & retry
    if (e.response?.statusCode == 401 &&
        !e.requestOptions.path.contains(ApiConstants.refreshToken) &&
        !e.requestOptions.path.contains(ApiConstants.resetPassword) &&
        !e.requestOptions.path.contains(ApiConstants.login) &&
        !e.requestOptions.path.contains(ApiConstants.signup) &&
        !e.requestOptions.path.contains(ApiConstants.verifyEmail)) {
      final refreshToken = await StorageService.getString(
        StorageConstants.refreshToken,
      );
      if (refreshToken.isEmpty) {
        _forceLogout();
        return handler.next(e);
      }

      final refreshed = await _refreshToken();

      if (refreshed) {
        final retryResponse = await _retryRequest(e.requestOptions);
        return handler.resolve(retryResponse);
      } else {
        _forceLogout();
        return handler.next(e);
      }
    }

    AppLogger.error(e);
    return handler.next(e);
  }

  // ──────────────────────── HTTP METHODS ────────────────────────

  /// GET request
  Future<Response> getData(
    String uri, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    Map<String, dynamic>? extraHeaders,
  }) async {
    try {
      return await _dio.get(
        uri,
        queryParameters: query,
        cancelToken: cancelToken,
        options: extraHeaders != null ? Options(headers: extraHeaders) : null,
      );
    } on DioException catch (e) {
      return _buildErrorResponse(e);
    }
  }

  /// POST request
  Future<Response> postData(
    String uri,
    dynamic body, {
    CancelToken? cancelToken,
    Map<String, dynamic>? extraHeaders,
    String? resetToken,
  }) async {
    try {
      Options? options;
      if (resetToken != null) {
        options = Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': resetToken,
          },
        );
      } else if (extraHeaders != null) {
        options = Options(headers: extraHeaders);
      }

      return await _dio.post(
        uri,
        data: body,
        cancelToken: cancelToken,
        options: options,
      );
    } on DioException catch (e) {
      return _buildErrorResponse(e);
    }
  }

  /// PUT request
  Future<Response> putData(
    String uri,
    dynamic body, {
    CancelToken? cancelToken,
    Map<String, dynamic>? extraHeaders,
  }) async {
    try {
      return await _dio.put(
        uri,
        data: body,
        cancelToken: cancelToken,
        options: extraHeaders != null ? Options(headers: extraHeaders) : null,
      );
    } on DioException catch (e) {
      return _buildErrorResponse(e);
    }
  }

  /// PATCH request
  Future<Response> patchData(
    String uri,
    dynamic body, {
    CancelToken? cancelToken,
    Map<String, dynamic>? extraHeaders,
  }) async {
    try {
      return await _dio.patch(
        uri,
        data: body,
        cancelToken: cancelToken,
        options: extraHeaders != null ? Options(headers: extraHeaders) : null,
      );
    } on DioException catch (e) {
      return _buildErrorResponse(e);
    }
  }

  /// DELETE request
  Future<Response> deleteData(
    String uri, {
    dynamic body,
    CancelToken? cancelToken,
    Map<String, dynamic>? extraHeaders,
  }) async {
    try {
      return await _dio.delete(
        uri,
        data: body,
        cancelToken: cancelToken,
        options: extraHeaders != null ? Options(headers: extraHeaders) : null,
      );
    } on DioException catch (e) {
      return _buildErrorResponse(e);
    }
  }

  /// Multipart POST with progress tracking
  Future<Response> postMultipartData(
    String uri,
    Map<String, dynamic> body, {
    required List<MultipartBody> multipartBody,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = await _buildFormData(body, multipartBody);
      return await _dio.post(
        uri,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      return _buildErrorResponse(e);
    }
  }

  /// Multipart PATCH with progress tracking
  Future<Response> patchMultipartData(
    String uri,
    Map<String, dynamic> body, {
    required List<MultipartBody> multipartBody,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = await _buildFormData(body, multipartBody);
      return await _dio.patch(
        uri,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      return _buildErrorResponse(e);
    }
  }

  /// Multipart PUT with progress tracking
  Future<Response> putMultipartData(
    String uri,
    Map<String, dynamic> body, {
    required List<MultipartBody> multipartBody,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = await _buildFormData(body, multipartBody);
      return await _dio.put(
        uri,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      return _buildErrorResponse(e);
    }
  }

  /// File download with progress tracking
  Future<Response> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      return _buildErrorResponse(e);
    }
  }

  // ──────────────────── PRIVATE HELPERS ────────────────────

  /// Build FormData from body map and multipart files
  Future<FormData> _buildFormData(
    Map<String, dynamic> body,
    List<MultipartBody> multipartBody,
  ) async {
    final formData = FormData.fromMap(body);
    for (final part in multipartBody) {
      formData.files.add(
        MapEntry(part.key, await MultipartFile.fromFile(part.file.path)),
      );
    }
    return formData;
  }

  /// Create a fallback Response from a DioException
  Response _buildErrorResponse(DioException e) {
    final String message;
    final isConnectionError =
        e.type == DioExceptionType.connectionError ||
        (e.type == DioExceptionType.unknown && e.error is SocketException) ||
        e.message?.contains('SocketException') == true ||
        e.error?.toString().contains('SocketException') == true;

    if (isConnectionError) {
      message =
          'Unable to connect to server. Please check your internet connection.';
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          message = 'Connection timed out';
          break;
        case DioExceptionType.receiveTimeout:
          message = 'Server took too long to respond';
          break;
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 413) {
            message = 'Your uploaded file is too large!';
          } else {
            final data = e.response?.data;
            if (data is Map && data['message'] != null) {
              message = data['message'].toString();
            } else {
              message =
                  'Bad response: ${e.response?.statusMessage ?? 'Unknown'}';
            }
          }
          break;
        case DioExceptionType.cancel:
          message = 'Request cancelled';
          break;
        default:
          message = _fallbackMessage;
      }
    }

    return Response(
      requestOptions: e.requestOptions,
      statusCode: e.response?.statusCode ?? 0,
      statusMessage: message,
      data: e.response?.data,
    );
  }

  /// Refresh the access token using stored refresh token with strict locking
  Future<bool> _refreshToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    final completer = Completer<bool>();
    _refreshFuture = completer.future;

    try {
      final refreshTokenValue = await StorageService.getString(
        StorageConstants.refreshToken,
      );
      if (refreshTokenValue.isEmpty) {
        completer.complete(false);
        return false;
      }

      // Separate clean Dio instance to completely bypass our main client's interceptor chain
      final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final response = await refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshTokenValue},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authData = response.data['data'] ?? response.data;
        final newAccessToken = authData['accessToken'] ?? authData['token'];
        final newRefreshToken = authData['refreshToken'];

        if (newAccessToken != null) {
          await StorageService.setString(
            StorageConstants.bearerToken,
            newAccessToken,
          );
        }
        if (newRefreshToken != null) {
          await StorageService.setString(
            StorageConstants.refreshToken,
            newRefreshToken,
          );
        }
        completer.complete(true);
        return true;
      }
    } catch (e) {
      Helpers.debug('Error refreshing token: $e');
    } finally {
      _refreshFuture = null; // Always unlock after completion/error
    }

    completer.complete(false);
    return false;
  }

  /// Retry the original failed request with new token
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final newToken = await StorageService.getString(
      StorageConstants.bearerToken,
    );
    requestOptions.headers['Authorization'] = 'Bearer $newToken';

    return await _dio.fetch(requestOptions);
  }

  /// Force logout when refresh fails
  void _forceLogout() {
    // Disabled auto-logout in static UI testing mode
    Helpers.debug('401 Unauthorized / Token expired');
  }
}

/// ===================== MULTIPART BODY =====================
/// Wraps a file with its form-data key for multipart uploads.
class MultipartBody {
  final String key;
  final File file;

  const MultipartBody(this.key, this.file);
}
