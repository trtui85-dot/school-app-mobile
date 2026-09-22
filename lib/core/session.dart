import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

const List<String> allPermissions = [
  'overview',
  'sections',
  'requests',
  'students',
  'absences',
  'payments',
  'messages',
  'complaints',
  'ads',
  'settings',
  'users',
];

const Map<String, String> permissionLabels = {
  'overview': 'الرئيسية والإحصائيات',
  'sections': 'الأقسام',
  'requests': 'طلبات التسجيل',
  'students': 'التلاميذ',
  'absences': 'الغياب',
  'payments': 'الدفعات',
  'messages': 'الرسائل',
  'complaints': 'الشكاوى',
  'ads': 'المساحة الإعلانية',
  'settings': 'الإعدادات',
  'users': 'إدارة المستخدمين',
};

bool hasPermission(List<String>? perms, String key) =>
    perms == null || perms.isEmpty || perms.contains(key);

class AppUser {
  final int id;
  final String name;
  final String role; // agent | admin
  final String? phone;
  final List<String> permissions;

  AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.phone,
    this.permissions = const [],
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '').toString(),
        role: (j['role'] ?? 'agent').toString(),
        phone: j['phone']?.toString(),
        permissions: (j['permissions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'phone': phone,
        'permissions': permissions,
      };
}

class SessionManager extends ChangeNotifier {
  AppUser? user;
  bool loading = true;

  SessionManager() {
    _restore();
  }

  Future<void> _restore() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('sess_token');
    final userJson = sp.getString('sess_user');
    if (token != null) {
      ApiClient.instance.setToken(token);
      if (userJson != null) {
        try {
          user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        } catch (_) {}
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _persist(String? token, AppUser? u) async {
    final sp = await SharedPreferences.getInstance();
    if (token != null) {
      await sp.setString('sess_token', token);
    } else {
      await sp.remove('sess_token');
    }
    if (u != null) {
      await sp.setString('sess_user', jsonEncode(u.toJson()));
    } else {
      await sp.remove('sess_user');
    }
  }

  Future<AppUser> login(String identifier, String password) async {
    final res = await ApiClient.instance
        .post('/api/auth/login', body: {'phone': identifier, 'password': password});
    final token = res['token']?.toString();
    final u = AppUser.fromJson(Map<String, dynamic>.from(res['user'] as Map));
    ApiClient.instance.setToken(token);
    user = u;
    await _persist(token, u);
    notifyListeners();
    return u;
  }

  Future<AppUser> signup(String fullName, String phone, String password) async {
    final res = await ApiClient.instance.post('/api/auth/signup',
        body: {'fullName': fullName, 'phone': phone, 'password': password});
    final token = res['token']?.toString();
    final u = AppUser.fromJson(Map<String, dynamic>.from(res['user'] as Map));
    ApiClient.instance.setToken(token);
    user = u;
    await _persist(token, u);
    notifyListeners();
    return u;
  }

  Future<void> logout() async {
    try {
      await ApiClient.instance.post('/api/auth/logout');
    } catch (_) {}
    ApiClient.instance.setToken(null);
    user = null;
    await _persist(null, null);
    notifyListeners();
  }
}
