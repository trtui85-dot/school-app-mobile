import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiClient {
  static const String baseUrl = 'https://iqra-modern.vercel.app';

  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 40),
    sendTimeout: const Duration(seconds: 40),
    headers: {'Accept': 'application/json'},
    // Never throw on non-2xx; we map errors ourselves.
    validateStatus: (s) => s != null && s < 600,
  ));

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Options _options({bool json = true}) => Options(
        contentType: json ? Headers.jsonContentType : null,
        headers: _token != null ? {'Cookie': 'sess=$_token'} : null,
      );

  Options get imageOptions => Options(
        responseType: ResponseType.bytes,
        headers: _token != null ? {'Cookie': 'sess=$_token'} : null,
      );

  Map<String, String> get authHeaders =>
      _token != null ? {'Cookie': 'sess=$_token'} : {};

  dynamic _decode(Response res) {
    final data = res.data;
    if (data is Map) return data;
    if (data is String && data.isNotEmpty) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  Never _throw(Response res) {
    final status = res.statusCode ?? 0;
    final data = _decode(res);
    String message;
    if (status == 502 || status == 504) {
      message = 'الخادم غير متاح مؤقتًا، أعد المحاولة';
    } else if (data is Map && data['message'] != null) {
      message = data['message'].toString();
    } else if (status == 401) {
      message = 'غير مصرح لك';
    } else {
      message = 'حدث خطأ (HTTP $status)';
    }
    throw ApiException(message, status);
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    try {
      final res = await _dio.request(
        path,
        queryParameters: query,
        data: body == null ? null : jsonEncode(body),
        options: _options().copyWith(method: method),
      );
      final status = res.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final data = _decode(res);
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        return {'data': data};
      }
      _throw(res);
    } on DioException catch (e) {
      throw ApiException(_dioMessage(e));
    }
  }

  String _dioMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'خطأ في الاتصال';
    }
    return 'خطأ في الاتصال';
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      request('GET', path, query: query);
  Future<Map<String, dynamic>> post(String path,
          {Object? body, Map<String, dynamic>? query}) =>
      request('POST', path, body: body, query: query);
  Future<Map<String, dynamic>> put(String path,
          {Object? body, Map<String, dynamic>? query}) =>
      request('PUT', path, body: body, query: query);
  Future<Map<String, dynamic>> patch(String path,
          {Object? body, Map<String, dynamic>? query}) =>
      request('PATCH', path, body: body, query: query);
  Future<Map<String, dynamic>> delete(String path,
          {Object? body, Map<String, dynamic>? query}) =>
      request('DELETE', path, body: body, query: query);

  Future<Uint8List?> fetchBytes(String path) async {
    try {
      final res = await _dio.get<List<int>>(path, options: imageOptions);
      if (res.statusCode == 200 && res.data != null) {
        return Uint8List.fromList(res.data!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
