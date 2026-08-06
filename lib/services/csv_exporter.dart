/// CSV 导出：纯函数，便于单元测试
library;

import '../models/account.dart';
import '../models/transaction.dart';

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
    buf.writeln('日期,类型,分类,金额(元),账户,账本,备注');
    for (final t in transactions) {
      final d = t.date;
      final date =
          '${d.year}-${_p2(d.month)}-${_p2(d.day)} ${_p2(d.hour)}:${_p2(d.minute)}';
      final type = t.type == TxType.expense ? '支出' : '收入';
      final category = TxCategories.byId(t.categoryId).name;
      final amount = (t.amount / 100).toStringAsFixed(2);
      final account = accountById(t.accountId).name;
      final book = bookNames?[t.bookId] ?? t.bookId;
      buf.writeln(
          '$date,$type,$category,$amount,$account,${_escape(book)},${_escape(t.note)}');
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
