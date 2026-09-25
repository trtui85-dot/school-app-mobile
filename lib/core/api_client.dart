import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiClient {
  static const String baseUrl = 'https://iqra-modern.vercel.app';
  static const String _cachePrefix = 'api_get_v1:';
  static const Duration cacheTtl = Duration(seconds: 20);

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

  SharedPreferences? _sp;
  final Map<String, Uint8List> _bytesCache = {};
  static const int _bytesCacheLimit = 80;

  Future<SharedPreferences> _prefs() async => _sp ??= await SharedPreferences.getInstance();

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

  String _cacheKey(String path, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return _cachePrefix + path;
    final parts = query.keys.toList()..sort();
    final q = parts.map((k) => '$k=${query[k]}').join('&');
    return '$_cachePrefix$path?$q';
  }

  Future<Map<String, dynamic>?> _readCache(String key) async {
    try {
      final sp = await _prefs();
      final raw = sp.getString(key);
      if (raw == null) return null;
      final m = jsonDecode(raw);
      if (m is Map && m['at'] is int && m['d'] is Map) {
        final age = DateTime.now().millisecondsSinceEpoch - (m['at'] as int);
        if (age > cacheTtl.inMilliseconds) return null;
        return Map<String, dynamic>.from(m['d'] as Map);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _readStale(String key) async {
    try {
      final sp = await _prefs();
      final raw = sp.getString(key);
      if (raw == null) return null;
      final m = jsonDecode(raw);
      if (m is Map && m['d'] is Map) {
        return Map<String, dynamic>.from(m['d'] as Map);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _writeCache(String key, Map<String, dynamic> data) async {
    try {
      final sp = await _prefs();
      await sp.setString(
          key, jsonEncode({'at': DateTime.now().millisecondsSinceEpoch, 'd': data}));
    } catch (_) {}
  }

  Future<void> invalidateCache() async {
    try {
      final sp = await _prefs();
      final rem = sp.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
      for (final k in rem) {
        await sp.remove(k);
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool useCache = true,
  }) async {
    final m = method.toUpperCase();
    final isGet = m == 'GET';
    final key = isGet ? _cacheKey(path, query) : '';
    Map<String, dynamic>? cached;
    if (isGet && useCache) {
      cached = await _readCache(key);
      if (cached != null) return cached;
    }
    try {
      final res = await _dio.request(
        path,
        queryParameters: query,
        data: body == null ? null : jsonEncode(body),
        options: _options().copyWith(method: m),
      );
      final status = res.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final data = _decode(res);
        Map<String, dynamic> map;
        if (data is Map<String, dynamic>) {
          map = data;
        } else if (data is Map) {
          map = Map<String, dynamic>.from(data);
        } else {
          map = {'data': data};
        }
        if (isGet && useCache) await _writeCache(key, map);
        if (!isGet) unawaited(invalidateCache());
        return map;
      }
      _throw(res);
    } on DioException catch (e) {
      if (isGet && useCache) {
        final stale = cached ?? await _readStale(key);
        if (stale != null) return stale;
      }
      throw ApiException(_dioMessage(e));
    }
  }

  String _dioMessage(DioException e) => 'خطأ في الاتصال';

  Future<Map<String, dynamic>> get(String path,
          {Map<String, dynamic>? query, bool useCache = true}) =>
      request('GET', path, query: query, useCache: useCache);
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
    final hit = _bytesCache[path];
    if (hit != null) return hit;
    try {
      final res = await _dio.get<List<int>>(path, options: imageOptions);
      if (res.statusCode == 200 && res.data != null) {
        final bytes = Uint8List.fromList(res.data!);
        if (_bytesCache.length >= _bytesCacheLimit) _bytesCache.remove(_bytesCache.keys.first);
        _bytesCache[path] = bytes;
        return bytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
