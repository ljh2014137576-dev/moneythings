/// 交易领域模型与预设分类
library;

import 'package:flutter/material.dart';

/// 收支类型
enum TxType {
  expense('支出'),
  income('收入');

  const TxType(this.label);
  final String label;

  static TxType fromName(String? name) =>
      name == 'income' ? TxType.income : TxType.expense;
}

/// 分类
class TxCategory {
  const TxCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.isExpense,
  });

  final String id;
  final String name;
  final IconData icon;
  final bool isExpense;

  static TxCategory expense(String id, String name, IconData icon) =>
      TxCategory(id: id, name: name, icon: icon, isExpense: true);
  static TxCategory income(String id, String name, IconData icon) =>
      TxCategory(id: id, name: name, icon: icon, isExpense: false);
}

/// 单笔账目；金额以「分」为单位存储（int，避免浮点误差）
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.date,
    this.note = '',
  });

  final String id;
  final TxType type;
  final int amount;
  final String categoryId;
  final String accountId;
  final String note;
  final DateTime date;

  Transaction copyWith({
    TxType? type,
    int? amount,
    String? categoryId,
    String? accountId,
    String? note,
    DateTime? date,
  }) {
    return Transaction(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'categoryId': categoryId,
        'accountId': accountId,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        type: TxType.fromName(json['type'] as String?),
        amount: (json['amount'] as num).toInt(),
        categoryId: json['categoryId'] as String,
        accountId: json['accountId'] as String,
        note: (json['note'] as String?) ?? '',
        date: DateTime.parse(json['date'] as String),
      );
}

/// 预设分类（黑白线性图标，不用彩虹分类色）
class TxCategories {
  TxCategories._();

  static final List<TxCategory> expense = [
    TxCategory.expense('food', '餐饮', Icons.restaurant_outlined),
    TxCategory.expense('transport', '交通', Icons.directions_bus_outlined),
    TxCategory.expense('shopping', '购物', Icons.shopping_bag_outlined),
    TxCategory.expense('home', '居住', Icons.home_outlined),
    TxCategory.expense('fun', '娱乐', Icons.movie_outlined),
    TxCategory.expense('medical', '医疗', Icons.medical_services_outlined),
    TxCategory.expense('comm', '通讯', Icons.smartphone_outlined),
    TxCategory.expense('edu', '教育', Icons.school_outlined),
    TxCategory.expense('social', '人情', Icons.volunteer_activism_outlined),
    TxCategory.expense('other_e', '其他', Icons.more_horiz_outlined),
  ];

  static final List<TxCategory> income = [
    TxCategory.income('salary', '工资', Icons.payments_outlined),
    TxCategory.income('bonus', '奖金', Icons.emoji_events_outlined),
    TxCategory.income('invest', '理财', Icons.savings_outlined),
    TxCategory.income('parttime', '兼职', Icons.work_outline),
    TxCategory.income('redpacket', '红包', Icons.card_giftcard_outlined),
    TxCategory.income('other_i', '其他', Icons.more_horiz_outlined),
  ];

  static List<TxCategory> of(TxType type) =>
      type == TxType.expense ? expense : income;

  /// 按 id 查找分类；找不到时回退到「其他」
  static TxCategory byId(String id) {
    for (final c in [...expense, ...income]) {
      if (c.id == id) return c;
    }
    return id.startsWith('other_i') ? income.last : expense.last;
  }
}

