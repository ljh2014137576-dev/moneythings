/// CSV 导出：纯函数，便于单元测试
library;

import '../models/account.dart';
import '../models/transaction.dart';
import '../models/recurring_rule.dart';

class CsvExporter {
  CsvExporter._();

  /// 生成 CSV 文本（UTF-8 BOM，Excel 可直接打开中文）
  static String exportCsv(
    List<Transaction> transactions, {
    Map<String, String>? bookNames,
    List<String> metaLines = const [],
  }) {
    final buf = StringBuffer('﻿');
    for (final m in metaLines) {
      buf.writeln('# $m');
    }
    buf.writeln('日期,类型,分类,金额(元),账户,账本,备注,转入账户');
    for (final t in transactions) {
      final d = t.date;
      final date =
          '${d.year}-${_p2(d.month)}-${_p2(d.day)} ${_p2(d.hour)}:${_p2(d.minute)}';
      final type = switch (t.type) {
        TxType.expense => '支出',
        TxType.income => '收入',
        TxType.transfer => '转账',
      };
      final category = t.type == TxType.transfer
          ? '转账'
          : TxCategories.byId(t.categoryId).name;
      final amount = (t.amount / 100).toStringAsFixed(2);
      final account = accountById(t.accountId).name;
      final book = bookNames?[t.bookId] ?? t.bookId;
      final toAccount = t.transferToAccountId == null
          ? ''
          : accountById(t.transferToAccountId!).name;
      buf.writeln(
          '$date,$type,$category,$amount,$account,${_escape(book)},'
          '${_escape(t.note)},${_escape(toAccount)}');
    }
    return buf.toString();
  }

  /// 周期规则清单 CSV（Excel 可直接打开）
  static String exportRecurringCsv(List<RecurringRule> rules) {
    final buf = StringBuffer('\\uFEFF');
    buf.writeln('频率,类型,金额(元),分类,账户,下次日期,备注,转入账户');
    for (final r in rules) {
      final category = TxCategories.byId(r.categoryId).name;
      final account = accountById(r.accountId).name;
      final toAccount = r.transferToAccountId == null
          ? ''
          : accountById(r.transferToAccountId!).name;
      final d = r.nextDate;
      final next =
          '${d.year}-${_p2(d.month)}-${_p2(d.day)}';
      final amount = (r.amount / 100).toStringAsFixed(2);
      buf.writeln('${r.frequency.label},${r.type.label},$amount,'
          '${_escape(category)},${_escape(account)},$next,'
          '${_escape(r.note)},${_escape(toAccount)}');
    }
    return buf.toString();
  }

  static String _p2(int v) => v.toString().padLeft(2, '0');

  static String _escape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
