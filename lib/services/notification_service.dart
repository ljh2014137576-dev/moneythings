/// 本地通知服务：预算超支提醒 + 每日记账提醒
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../widgets/amount_text.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  static const _budgetId = 1001;
  static const _reminderId = 2001;

  Future<void> init() async {
    if (kIsWeb) return;
    tzdata.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // 时区获取失败时使用默认（UTC），提醒时间可能不精确
    }
    const settings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: settings),
    );
    _inited = true;
  }

  /// Android 13+ 运行时请求通知权限
  Future<void> requestPermission() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// 发送「本月预算超支」通知
  Future<void> notifyBudgetOverrun(int overCents) async {
    if (kIsWeb || !_inited) return;
    const details = AndroidNotificationDetails(
      'budget',
      '预算预警',
      channelDescription: '每月预算超支时提醒',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      id: _budgetId,
      title: '本月预算已超支',
      body: '已超出 ${AmountText.format(overCents)}，注意控制',
      notificationDetails: const NotificationDetails(android: details),
    );
  }

  /// 调度每日记账提醒（固定 20:00，非精确模式无需额外权限）
  Future<void> scheduleDailyReminder() async {
    if (kIsWeb || !_inited) return;
    const details = AndroidNotificationDetails(
      'reminder',
      '记账提醒',
      channelDescription: '每天提醒记一笔',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, 20, 0);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: _reminderId,
      title: '今天记一笔了吗？',
      body: '花 10 秒记录今天的收支吧',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(android: details),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// 取消每日记账提醒
  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    await _plugin.cancel(id: _reminderId);
  }
}

