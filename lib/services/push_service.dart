import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service de notifications push (FCM via la Supabase Edge Function "push").
///
/// - Enregistre le token FCM de l'appareil dans la table Supabase
///   `push_subscriptions` (au démarrage, au login, au refresh du token).
/// - Affiche les notifications quand l'app est au premier plan.
/// - Conserve le message tapé (lastOpenedMessage) pour la navigation.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  static const String _channelId = 'family_blog_notifications';
  static const String _androidIcon = '@mipmap/launcher_icon';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _initialized = false;
  StreamSubscription<AuthStateChangeEvent>? _authSub;

  /// Dernière notification tapée (app ouverte ou réouverte depuis le centre).
  RemoteMessage? lastOpenedMessage;

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (_isSupported && !_initialized) {
      _initialized = true;
      try {
        await _initLocalNotifications();
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        await _registerToken(await FirebaseMessaging.instance.getToken());

        FirebaseMessaging.instance.onTokenRefresh.listen(
          (token) => _registerToken(token),
        );
        FirebaseMessaging.onMessage.listen(_showForeground);
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          lastOpenedMessage = message;
        });

        // Si l'utilisateur se connecte alors que l'app est déjà ouverte,
        // on enregistre le token au nom du nouveau user.
        _authSub = _supabase.auth.onAuthStateChange.listen((event) async {
          if (event is AuthSignedInEvent) {
            await _registerToken(await FirebaseMessaging.instance.getToken());
          }
        });
      } catch (e) {
        debugPrint('Push init error: $e');
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    await _local.initialize(
      initializationSettings: const InitializationSettings(
        android: AndroidInitializationSettings(_androidIcon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        _channelId,
        'Family Blog',
        description: 'Notifications du blog familial',
        importance: Importance.high,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _registerToken(String? token) async {
    if (token == null) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('push_subscriptions').upsert(
            {
              'user_id': user.id,
              'fcm_token': token,
              'platform': defaultTargetPlatform == TargetPlatform.iOS
                  ? 'ios'
                  : 'android',
            },
            onConflict: 'user_id,fcm_token',
          );
    } catch (e) {
      debugPrint('Push token registration error: $e');
    }
  }

  /// Supprime les tokens de l'appareil (à appeler à la déconnexion).
  Future<void> unsubscribe() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase
          .from('push_subscriptions')
          .delete()
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('Push unsubscribe error: $e');
    }
  }

  /// App affichée au premier plan : on montre la notification soi-même
  /// (le SDK FCM ne l'affiche pas en foreground).
  Future<void> _showForeground(RemoteMessage message) async {
    try {
      await _local.show(
        DateTime.now().microsecondsSinceEpoch,
        message.notification?.title ?? 'Family Blog',
        message.notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Family Blog',
            channelDescription: 'Notifications du blog familial',
            icon: _androidIcon,
          ),
          iOS: const DarwinNotificationDetails(presentBadge: true),
        ),
      );
    } catch (e) {
      debugPrint('Local notification error: $e');
    }
  }
}
