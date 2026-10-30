// lib/services/notification_service.dart

import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static NotificationService get instance => _instance;
  static final NotificationService _instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> notifyTerritoryStolen({
    required String attackerName,
    required String territoryArea,
  }) async {
    await init();
    await _plugin.show(
      1,
      '⚔️ Seu território foi roubado!',
      '$attackerName tomou sua área de $territoryArea. Vá recuperar!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'attacks',
          'Ataques',
          channelDescription: 'Notificações de territórios roubados',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFF5722),
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> scheduleStreakReminder() async {
    await init();
    await _plugin.cancel(2);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      19,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      2,
      '🔥 Não perca seu streak!',
      'Corra hoje para manter sua sequência de dias!',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'streak',
          'Streak Diário',
          channelDescription: 'Lembretes de sequência diária',
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelStreakReminder() => _plugin.cancel(2);
  Future<void> cancelAll() => _plugin.cancelAll();
}
