/// 账户模型
library;

import 'package:flutter/material.dart';

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.icon,
    this.initialBalance = 0,
  });

  final String id;
  final String name;
  final IconData icon;
  final int initialBalance;

  Account copyWith({int? initialBalance}) => Account(
        id: id,
        name: name,
        icon: icon,
        initialBalance: initialBalance ?? this.initialBalance,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon.codePoint,
        'initialBalance': initialBalance,
      };

  /// 按 id 还原账户（图标来自预设，避免运行时构造 IconData）
  factory Account.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final balance = (json['initialBalance'] as num?)?.toInt() ?? 0;
    for (final a in kDefaultAccounts) {
      if (a.id == id) return a.copyWith(initialBalance: balance);
    }
    return Account(
      id: id,
      name: (json['name'] as String?) ?? '账户',
      icon: Icons.account_balance_wallet_outlined,
      initialBalance: balance,
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
  for (final a in kDefaultAccounts) {
    if (a.id == id) return a;
  }
  return kDefaultAccounts.first;
}
