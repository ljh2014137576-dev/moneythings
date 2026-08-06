/// 本地预算预警系统通知（Android 13+ 需运行时授权）
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../widgets/amount_text.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (kIsWeb) return;
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
      id: 1001,
      title: '本月预算已超支',
      body: '已超出 ${AmountText.format(overCents)}，注意控制',
      notificationDetails: const NotificationDetails(android: details),
    );
  }
}
