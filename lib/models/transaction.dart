/// 交易领域模型与预设分类
library;

import 'package:flutter/material.dart';

import 'category_icons.dart';

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
    this.isCustom = false,
    this.iconKey,
  });

  final String id;
  final String name;
  final IconData icon;

  /// 是否属于支出分类
  final bool isExpense;

  /// 是否用户自定义
  final bool isCustom;

  /// 自定义图标 key（见 category_icons.dart）
  final String? iconKey;

  static TxCategory expense(String id, String name, IconData icon) =>
      TxCategory(id: id, name: name, icon: icon, isExpense: true);
  static TxCategory income(String id, String name, IconData icon) =>
      TxCategory(id: id, name: name, icon: icon, isExpense: false);

  /// 自定义分类
  static TxCategory custom({
    required String id,
    required String name,
    required String iconKey,
    required bool isExpense,
  }) =>
      TxCategory(
        id: id,
        name: name,
        icon: categoryIconByKey(iconKey),
        isExpense: isExpense,
        isCustom: true,
        iconKey: iconKey,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'isExpense': isExpense,
      };

  factory TxCategory.fromJson(Map<String, dynamic> json) => TxCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: categoryIconByKey((json['iconKey'] as String?) ?? 'more'),
        isExpense: json['isExpense'] as bool? ?? true,
        isCustom: true,
        iconKey: json['iconKey'] as String? ?? 'more',
      );
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

/// 分类注册表：预设 + 自定义
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

  /// 用户自定义分类（由 AppState 在加载后注入）
  static List<TxCategory> _custom = const [];

  static List<TxCategory> get custom => List.unmodifiable(_custom);

  static void setCustom(List<TxCategory> categories) {
    _custom = List.unmodifiable(categories);
  }

  /// 某类型的全部分类（预设 + 自定义）
  static List<TxCategory> of(TxType type) {
    final presets = type == TxType.expense ? expense : income;
    return [
      ...presets,
      ..._custom.where((c) =>
          c.isExpense == (type == TxType.expense)),
    ];
  }

  /// 按 id 查找分类（预设 + 自定义）；找不到回退到「其他」
  static TxCategory byId(String id) {
    for (final c in _custom) {
      if (c.id == id) return c;
    }
    for (final c in [...expense, ...income]) {
      if (c.id == id) return c;
    }
    return id.startsWith('other_i') ? income.last : expense.last;
  }
}
