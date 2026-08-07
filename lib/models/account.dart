/// 账户模型
library;

import 'package:flutter/material.dart';

import 'category_icons.dart';

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.icon,
    this.initialBalance = 0,
    this.isCustom = false,
    this.iconKey,
  });

  final String id;
  final String name;
  final IconData icon;
  final int initialBalance;

  /// 是否自定义账户
  final bool isCustom;

  /// 自定义图标 key（见 category_icons.dart）
  final String? iconKey;

  /// 自定义账户
  static Account custom({
    required String id,
    required String name,
    required String iconKey,
    int initialBalance = 0,
  }) =>
      Account(
        id: id,
        name: name,
        icon: categoryIconByKey(iconKey),
        initialBalance: initialBalance,
        isCustom: true,
        iconKey: iconKey,
      );

  /// 用户自定义账户注册表（由 AppState 加载后注入）
  static List<Account> _custom = const [];

  static void setCustom(List<Account> accounts) {
    _custom = List.unmodifiable(accounts);
  }

  static List<Account> get customAccounts => List.unmodifiable(_custom);

  Account copyWith({
    int? initialBalance,
    String? name,
    String? iconKey,
  }) =>
      Account(
        id: id,
        name: name ?? this.name,
        icon: iconKey != null
            ? categoryIconByKey(iconKey)
            : icon,
        initialBalance: initialBalance ?? this.initialBalance,
        isCustom: isCustom,
        iconKey: iconKey ?? this.iconKey,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon.codePoint,
        'initialBalance': initialBalance,
        'isCustom': isCustom,
        'iconKey': iconKey,
      };

  /// 按 id 还原账户（图标来自预设，避免运行时构造 IconData）
  factory Account.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final balance = (json['initialBalance'] as num?)?.toInt() ?? 0;
    for (final a in kDefaultAccounts) {
      if (a.id == id) return a.copyWith(initialBalance: balance);
    }
    final isCustom = json['isCustom'] as bool? ?? true;
    final iconKey = json['iconKey'] as String?;
    return Account(
      id: id,
      name: (json['name'] as String?) ?? '账户',
      icon: iconKey != null
          ? categoryIconByKey(iconKey)
          : Icons.account_balance_wallet_outlined,
      initialBalance: balance,
      isCustom: isCustom,
      iconKey: iconKey,
    );
  }
}

/// 默认账户
const List<Account> kDefaultAccounts = [
  Account(
      id: 'cash',
      name: '现金',
      icon: Icons.payments_outlined,
      initialBalance: 0),
  Account(
      id: 'card',
      name: '银行卡',
      icon: Icons.credit_card_outlined,
      initialBalance: 0),
  Account(
      id: 'alipay',
      name: '支付宝',
      icon: Icons.account_balance_wallet_outlined,
      initialBalance: 0),
  Account(
      id: 'wechat',
      name: '微信',
      icon: Icons.chat_bubble_outline_outlined,
      initialBalance: 0),
];

Account accountById(String id) {
  for (final a in Account.customAccounts) {
    if (a.id == id) return a;
  }
  for (final a in kDefaultAccounts) {
    if (a.id == id) return a;
  }
  return kDefaultAccounts.first;
}

/// 按名称查找账户 id（预设 + 自定义）；找不到返回 null
String? accountIdByName(String name) {
  for (final a in Account.customAccounts) {
    if (a.name == name) return a.id;
  }
  for (final a in kDefaultAccounts) {
    if (a.name == name) return a.id;
  }
  return null;
}
