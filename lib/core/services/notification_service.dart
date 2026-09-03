import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/firebase_providers.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    messaging: ref.watch(firebaseMessagingProvider),
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

class NotificationService {
  NotificationService({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _messaging = messaging,
        _firestore = firestore,
        _auth = auth;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _inAppNotificationsSub;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications and messages.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    showBadge: true,
  );

  /// Initializes local notifications, notification channel, FCM handlers, and sound.
  Future<void> initialize() async {
    try {
      // 1. Initialize Flutter Local Notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // 2. Create the Android notification channel with sound & vibration
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
        await androidPlugin.requestNotificationsPermission();
      }

      // 3. Request FCM permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted notification permissions');
        await updateFcmToken();
      }

      // 4. Foreground notification presentation options for iOS
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Listen to token refreshes
      _messaging.onTokenRefresh.listen((token) async {
        await _saveTokenToFirestore(token);
      });

      // 6. Foreground FCM message listener -> Show local notification with sound!
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground message: ${message.notification?.title}');
        _showLocalNotification(
          title: message.notification?.title ?? 'رسالة جديدة',
          body: message.notification?.body ?? '',
          payload: message.data.toString(),
        );
      });

      // 7. Listen to auth state changes to update token and listen to in-app notifications
      _auth.authStateChanges().listen((user) {
        if (user != null) {
          updateFcmToken();
          _startListeningToInAppNotifications(user.uid);
        } else {
          _inAppNotificationsSub?.cancel();
        }
      });

      if (_auth.currentUser != null) {
        _startListeningToInAppNotifications(_auth.currentUser!.uid);
      }
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  /// Listens to new in-app notifications in Firestore and triggers sound + local popup
  void _startListeningToInAppNotifications(String uid) {
    _inAppNotificationsSub?.cancel();
    final sessionStartTime = DateTime.now().subtract(const Duration(seconds: 10));

    _inAppNotificationsSub = _firestore
        .collection('imams')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final rawTs = data['timestamp'];
          DateTime? timestamp;
          if (rawTs is Timestamp) {
            timestamp = rawTs.toDate();
          }

          // If timestamp is null (local pending write) or after session start time
          if (timestamp == null || timestamp.isAfter(sessionStartTime)) {
            final title = data['title']?.toString() ?? 'تنبيه جديد';
            final body = data['body']?.toString() ?? '';

            // Trigger sound and heads-up local notification
            _showLocalNotification(
              title: title,
              body: body,
              payload: data['groupId']?.toString() ?? data['postId']?.toString(),
            );
          }
        }
      }
    });
  }

  /// Displays a local heads-up notification with sound and vibration
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();

      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription:
            'This channel is used for important notifications and messages.',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        fullScreenIntent: false,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Fetches and saves the current FCM token for the signed-in user/imam.
  Future<void> updateFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final uid = user.uid;
      // Save token in imams collection
      await _firestore.collection('imams').doc(uid).set({
        'fcmToken': token,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also save in users collection
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  /// Sends an in-app notification document to an imam's inbox.
  Future<void> sendInAppNotification({
    required String targetImamId,
    required String title,
    required String body,
    required String type,
    String? groupId,
    String? postId,
    String? questionId,
  }) async {
    if (targetImamId.isEmpty) return;

    try {
      await _firestore
          .collection('imams')
          .doc(targetImamId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
        if (groupId != null) 'groupId': groupId,
        if (postId != null) 'postId': postId,
        if (questionId != null) 'questionId': questionId,
        'read': false,
      });
    } catch (e) {
      debugPrint('Error sending in-app notification: $e');
    }
  }
}
