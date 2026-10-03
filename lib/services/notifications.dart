import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../clock.dart';

/// Şipşak bildirimleri. Sunucu olmadan, telefonun kendisi önümüzdeki
/// 7 günün Şipşak anlarını, oylama ve sonuç saatlerini kurar.
class Notifs {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const AndroidNotificationDetails _android = AndroidNotificationDetails(
    'sipsak_an',
    'Şipşak',
    channelDescription: 'Günün Şipşak anı, oylama ve sonuçlar',
    importance: Importance.max,
    priority: Priority.high,
    color: Color(0xFFFFD23F),
  );

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
    } catch (_) {}
    for (final icon in ['ic_stat_sipsak', '@mipmap/ic_launcher']) {
      try {
        await _plugin.initialize(InitializationSettings(android: AndroidInitializationSettings(icon)));
        _ready = true;
        return;
      } catch (_) {
        // bir sonraki simgeyi dene
      }
    }
  }

  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> showTest() async {
    if (!_ready) return;
    final s = DaySchedule.today();
    try {
      await _plugin.show(
        999,
        'ŞİPŞAK! Bir saatin var',
        'Bugünün teması: ${s.theme}',
        const NotificationDetails(android: _android),
      );
    } catch (_) {}
  }

  /// Önümüzdeki 7 günün bildirimlerini yeniden kurar.
  static Future<void> scheduleWeek() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final ist = tz.getLocation('Europe/Istanbul');
      final now = tz.TZDateTime.now(ist);
      final todayTr = trNow();
      for (var i = 0; i < 7; i++) {
        final s = DaySchedule.forDay(todayTr.add(Duration(days: i)));
        tz.TZDateTime at(DateTime t) => tz.TZDateTime(ist, t.year, t.month, t.day, t.hour, t.minute);
        final items = <List<Object>>[
          [at(s.moment), 'ŞİPŞAK! Bir saatin var', 'Bugünün teması: ${s.theme}'],
          [at(s.votingStart), 'Oylama başladı', 'Grubunun karelerine bak, günün karesini seç.'],
          [at(s.resultsAt), 'Günün Karesi belli oldu', 'Bakalım bugün kim kazandı?'],
        ];
        for (var k = 0; k < items.length; k++) {
          final when = items[k][0] as tz.TZDateTime;
          if (!when.isAfter(now)) continue;
          await _plugin.zonedSchedule(
            i * 10 + k,
            items[k][1] as String,
            items[k][2] as String,
            when,
            const NotificationDetails(android: _android),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (e) {
      debugPrint('Bildirimler kurulamadı: $e');
    }
  }
}
