/// CSV 导入解析：与 CsvExporter 格式对应
library;

import '../models/account.dart';
import '../models/transaction.dart';

class CsvImportResult {
  const CsvImportResult({
    required this.transactions,
    required this.skipped,
    required this.errors,
  });

  final List<Transaction> transactions;

  /// 因重复/非法而跳过的行数
  final int skipped;
  final List<String> errors;
}

class CsvImporter {
  CsvImporter._();

  static CsvImportResult parseCsv(
    String content, {
    List<Transaction> existing = const [],
  }) {
    final lines = content
        .replaceFirst('\uFEFF', '')
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty && !l.trim().startsWith('#'))
        .toList();

    if (lines.isEmpty) {
      return const CsvImportResult(
          transactions: [], skipped: 0, errors: ['文件为空']);
    }

    // 首行可能是表头：包含「日期/类型」则跳过
    final rows = <List<String>>[];
    final first = _parseRow(lines.first);
    final hasHeader =
        first.any((c) => c.contains('日期')) || first.any((c) => c.contains('类型'));
    for (int i = hasHeader ? 1 : 0; i < lines.length; i++) {
      rows.add(_parseRow(lines[i]));
    }

    final seen = <String>{
      for (final t in existing) _fingerprint(t),
    };
    final out = <Transaction>[];
    final errors = <String>[];
    int skipped = 0;

    for (int i = 0; i < rows.length; i++) {
      final cols = rows[i];
      if (cols.length < 4) {
        errors.add('第 ${i + 1} 行字段不足');
        skipped++;
        continue;
      }
      try {
        final date = _parseDate(cols[0].trim());
        final type = cols[1].trim() == '收入'
            ? TxType.income
            : (cols[1].trim() == '支出' ? TxType.expense : null);
        if (type == null) {
          errors.add('第 ${i + 1} 行类型无效');
          skipped++;
          continue;
        }
        final categoryName = cols[2].trim();
        final amountYuan = double.tryParse(cols[3].trim());
        if (amountYuan == null || amountYuan < 0) {
          errors.add('第 ${i + 1} 行金额无效');
          skipped++;
          continue;
        }
        final accountName = cols.length > 4 ? cols[4].trim() : '';
        final note = cols.length > 5 ? cols[5].trim() : '';

        final tx = Transaction(
          id: 'imp_${DateTime.now().microsecondsSinceEpoch}_$i',
          type: type,
          amount: (amountYuan * 100).round(),
          categoryId: _categoryIdByName(categoryName, type),
          accountId: _accountIdByName(accountName),
          note: note,
          date: date,
        );
        final fp = _fingerprint(tx);
        if (seen.contains(fp)) {
          skipped++;
          continue;
        }
        seen.add(fp);
        out.add(tx);
      } catch (_) {
        errors.add('第 ${i + 1} 行解析失败');
        skipped++;
      }
    }

    return CsvImportResult(transactions: out, skipped: skipped, errors: errors);
  }

  /// 简易 CSV 行解析（支持引号包裹的逗号/引号）
  static List<String> _parseRow(String line) {
    final out = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buf.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buf.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',') {
          out.add(buf.toString());
          buf.clear();
        } else {
          buf.write(ch);
        }
      }
    }
    out.add(buf.toString());
    return out;
  }

  static DateTime _parseDate(String s) {
    final clean = s.trim();
    DateTime? d = DateTime.tryParse(clean);
    if (d == null) {
      // 支持 yyyy-MM-dd HH:mm
      final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:\s+(\d{1,2}):(\d{1,2}))?$')
          .firstMatch(clean);
      if (m != null) {
        d = DateTime(
          int.parse(m.group(1)!),
          int.parse(m.group(2)!),
          int.parse(m.group(3)!),
          m.group(4) != null ? int.parse(m.group(4)!) : 12,
          m.group(5) != null ? int.parse(m.group(5)!) : 0,
        );
      }
    }
    if (d == null) throw const FormatException('bad date');
    return d;
  }

  static String _categoryIdByName(String name, TxType type) {
    if (name.isEmpty) return type == TxType.expense ? 'other_e' : 'other_i';
    for (final c in TxCategories.of(type)) {
      if (c.name == name) return c.id;
    }
    return type == TxType.expense ? 'other_e' : 'other_i';
  }

  static String _accountIdByName(String name) {
    for (final a in kDefaultAccounts) {
      if (a.name == name) return a.id;
    }
    return kDefaultAccounts.first.id;
  }

  static String _fingerprint(Transaction t) {
    final d = t.date;
    final day = '${d.year}-${d.month}-${d.day}';
    return '$day|${t.type.name}|${t.categoryId}|${t.amount}|${t.note.trim()}';
  }
}
