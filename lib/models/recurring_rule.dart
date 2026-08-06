/// 周期记账规则模型
library;

import 'transaction.dart';

/// 重复频率
enum RecurFrequency {
  none('不重复'),
  weekly('每周'),
  monthly('每月'),
  yearly('每年');

  const RecurFrequency(this.label);
  final String label;

  static RecurFrequency fromName(String? name) => switch (name) {
        'weekly' => RecurFrequency.weekly,
        'monthly' => RecurFrequency.monthly,
        'yearly' => RecurFrequency.yearly,
        _ => RecurFrequency.none,
      };
}

/// 周期规则：按频率自动生成流水
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.date,
    required this.nextDate,
    required this.frequency,
    this.transferToAccountId,
    this.note = '',
    this.bookId = 'default',
    this.active = true,
  });

  final String id;
  final TxType type;
  final int amount;
  final String categoryId;
  final String accountId;

  /// 转账目标账户（仅 type == transfer 时有值）
  final String? transferToAccountId;
  final String note;

  /// 首次发生日期（锚点）
  final DateTime date;

  /// 下次应生成的日期
  final DateTime nextDate;
  final RecurFrequency frequency;
  final String bookId;
  final bool active;

  /// 计算下次日期（月末自动钳制：1 月 31 日 + 1 月 → 2 月最后一天）
  static DateTime nextAfter(DateTime d, RecurFrequency f) {
    switch (f) {
      case RecurFrequency.weekly:
        return d.add(const Duration(days: 7));
      case RecurFrequency.monthly:
        // 用目标月的天数钳制：1 月 31 日 + 1 月 → 2 月最后一天
        final last = DateTime(d.year, d.month + 2, 0).day;
        final day = d.day <= last ? d.day : last;
        return DateTime(d.year, d.month + 1, day, d.hour, d.minute);
      case RecurFrequency.yearly:
        final last = DateTime(d.year + 1, d.month + 1, 0).day;
        final day = d.day <= last ? d.day : last;
        return DateTime(d.year + 1, d.month, day, d.hour, d.minute);
      case RecurFrequency.none:
        return d;
    }
  }

  RecurringRule copyWith({
    int? amount,
    String? categoryId,
    String? accountId,
    String? note,
    DateTime? nextDate,
    RecurFrequency? frequency,
    bool? active,
  }) {
    return RecurringRule(
      id: id,
      type: type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      transferToAccountId: transferToAccountId,
      note: note ?? this.note,
      date: date,
      nextDate: nextDate ?? this.nextDate,
      frequency: frequency ?? this.frequency,
      bookId: bookId,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'categoryId': categoryId,
        'accountId': accountId,
        'transferToAccountId': transferToAccountId,
        'note': note,
        'date': date.toIso8601String(),
        'nextDate': nextDate.toIso8601String(),
        'frequency': frequency.name,
        'bookId': bookId,
        'active': active,
      };

  factory RecurringRule.fromJson(Map<String, dynamic> json) => RecurringRule(
        id: json['id'] as String,
        type: TxType.fromName(json['type'] as String?),
        amount: (json['amount'] as num).toInt(),
        categoryId: json['categoryId'] as String,
        accountId: json['accountId'] as String,
        transferToAccountId: json['transferToAccountId'] as String?,
        note: (json['note'] as String?) ?? '',
        date: DateTime.parse(json['date'] as String),
        nextDate: DateTime.parse(json['nextDate'] as String),
        frequency: RecurFrequency.fromName(json['frequency'] as String?),
        bookId: (json['bookId'] as String?) ?? 'default',
        active: json['active'] as bool? ?? true,
      );
}