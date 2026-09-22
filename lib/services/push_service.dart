import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/api_client.dart';

const _fcmChannel = AndroidNotificationChannel(
  'general',
  'إشعارات المدرسة',
  description: 'إشعارات الرسوم والغياب والرسائل',
  importance: Importance.high,
);

final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await _ensureLocalNotificationsInit();
  await _showLocal(message);
}

Future<void> _ensureLocalNotificationsInit() async {
  await _flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_fcmChannel);
  await _flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
}

Future<void> _showLocal(RemoteMessage message) async {
  final title = message.notification?.title ?? message.data['title'];
  final body = message.notification?.body ?? message.data['body'];
  if (title == null && body == null) return;
  await _flutterLocalNotificationsPlugin.show(
    id: message.messageId.hashCode,
    title: title ?? 'مدارس اقرأ الحديثة',
    body: body ?? '',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'general',
        'إشعارات المدرسة',
        channelDescription: 'إشعارات الرسوم والغياب والرسائل',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}

class PushService {
  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Appelé une seule fois au démarrage (avant runApp) :
  /// affiche la demande d'autorisation et active l'affichage des notifications.
  static Future<void> configure() async {
    if (kIsWeb) return;
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    // Android 13+/iOS : boîte de dialogue d'autorisation au premier lancement.
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_showLocal);
  }

  /// Enregistre le token de cet appareil auprès du serveur après la connexion.
  /// role: 'agent' ou 'admin'.
  static Future<void> bind({required String role}) async {
    if (kIsWeb) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _registerToken(token, role);
      _messaging.onTokenRefresh.listen((t) => _registerToken(t, role));
    } catch (_) {
      // no-op: push reste optionnel
    }
  }

  static Future<void> _registerToken(String token, String role) async {
    try {
      final path = role == 'admin'
          ? '/api/admin/push/mobile'
          : '/api/me/push/mobile';
      await ApiClient.instance.post(path, body: {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
    } on ApiException {
      // تُنظَّف التوكنات القديمة من السيرفر عند أول تسجيل لاحق
    }
  }

  /// Supprime le token enregistré de cet appareil (à la déconnexion).
  static Future<void> unbind({required String role}) async {
    if (kIsWeb) return;
    try {
      final path = role == 'admin'
          ? '/api/admin/push/mobile'
          : '/api/me/push/mobile';
      await ApiClient.instance.delete(path,
          body: {'token': (await _messaging.getToken()) ?? ''});
    } catch (_) {
      // no-op
    }
  }
}