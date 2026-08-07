/// 全局应用状态（ChangeNotifier + Provider）
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/book.dart';
import '../models/transaction.dart';
import '../models/recurring_rule.dart';
import 'transaction_repository.dart';
import '../services/csv_importer.dart';

/// 某自然月的收支统计
class MonthSummary {
  MonthSummary({required this.expense, required this.income});
  final int expense;
  final int income;
  int get balance => income - expense;
}

class AppState extends ChangeNotifier {
  AppState({TransactionRepository? repository})
      : _repository = repository ?? TransactionRepository();

  final TransactionRepository _repository;

  List<Transaction> _transactions = [];
  List<RecurringRule> _rules = [];
  Map<String, int> _bookBudgets = {};
  List<TxCategory> _customCategories = [];
  List<Account> _accounts = kDefaultAccounts;
  List<Book> _books = [kDefaultBook];
  String _currentBookId = kDefaultBook.id;
  bool _budgetNotify = true;
  bool _dailyReminder = false;
  String _lastAccountId = 'alipay';
  bool _onboarded = false;
  bool _loaded = false;

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  /// 当前账本的流水
  List<Transaction> get _bookTx => [
    for (final t in _transactions)
      if (t.bookId == _currentBookId) t,
  ];

  List<Book> get books => List.unmodifiable(_books);

  Book get currentBook {
    for (final b in _books) {
      if (b.id == _currentBookId) return b;
    }

    return kDefaultBook;
  }

  /// 当前账本的流水（用于导出）
  List<Transaction> get currentBookTransactions => _bookTx;
  int get monthlyBudget => _bookBudgets[_currentBookId] ?? 0;
  bool get loaded => _loaded;

  String get currentBookId => _currentBookId;

  /// 当前账本的周期规则
  List<RecurringRule> get recurringRules =>
      List.unmodifiable(_rules.where((r) => r.bookId == _currentBookId));

  /// 全部账本的周期规则数
  int get recurringRuleCount => _rules.length;

  Future<void> load() async {
    await _repository.seedIfFirstLaunch();
    _transactions = await _repository.loadTransactions();
    _bookBudgets = await _repository.loadBookBudgets();
    _customCategories = await _repository.loadCustomCategories();
    _accounts = await _repository.loadAccounts();
    _syncAccounts();
    _books = await _repository.loadBooks();
    _currentBookId = await _repository.loadCurrentBookId();
    _lastAccountId = await _repository.loadLastAccountId();
    _recentSearches = await _repository.loadRecentSearches();
    _dailyReminder = await _repository.loadDailyReminder();
    _budgetNotify = await _repository.loadBudgetNotify();
    _onboarded = await _repository.loadOnboarded();
    _rules = await _repository.loadRecurringRules();
    if (!_books.any((b) => b.id == _currentBookId)) {
      _currentBookId = kDefaultBook.id;
    }
    TxCategories.setCustom(_customCategories);
    _loaded = true;
    notifyListeners();
    await generateDueRecurring();
  }

  Future<void> _persist() => _repository.saveTransactions(_transactions);

  Future<void> addTransaction(Transaction tx) async {
    if (tx.accountId.isNotEmpty) {
      _lastAccountId = tx.accountId;
      await _repository.saveLastAccountId(tx.accountId);
    }
    _transactions = [..._transactions, tx.copyWith(bookId: _currentBookId)]
      ..sort((a, b) => b.date.compareTo(a.date));
    await _persist();
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction tx) async {
    _transactions = [
      for (final t in _transactions) t.id == tx.id ? tx : t,
    ]..sort((a, b) => b.date.compareTo(a.date));
    await _persist();
    notifyListeners();
  }

  /// 复制流水到指定账本（新 id，保留日期/分类/账户/备注）
  Future<bool> copyTransactionToBook(
      String txId, String bookId) async {
    final tx = _transactions.where((t) => t.id == txId).firstOrNull;
    if (tx == null) return false;
    final copy = tx.copyWith(
      id: 'cp_${DateTime.now().microsecondsSinceEpoch}',
      bookId: bookId,
    );
    _transactions = [..._transactions, copy]
      ..sort((a, b) => b.date.compareTo(a.date));
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> deleteTransaction(String id) async {
    _transactions = [
      for (final t in _transactions)
        if (t.id != id) t,
    ];
    await _persist();
    notifyListeners();
  }

  /// 批量更新指定流水（改分类/账户；未提供的字段保持不变）
  Future<void> bulkUpdateTransactions(
    List<String> ids, {
    String? categoryId,
    String? accountId,
  }) async {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    _transactions = [
      for (final t in _transactions)
        idSet.contains(t.id)
            ? t.copyWith(
                categoryId: categoryId ?? t.categoryId,
                accountId: accountId ?? t.accountId,
              )
            : t,
    ];
    await _persist();
    notifyListeners();
  }

  /// 生成到期周期流水：对每个启用规则，把 nextDate <= 今天的每次发生生成流水并推进 nextDate
  Future<int> generateDueRecurring() async {
    if (!_loaded) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int generated = 0;
    final rules = [..._rules];
    var changed = false;
    for (int i = 0; i < rules.length; i++) {
      final r = rules[i];
      if (!r.active || r.bookId != _currentBookId) continue;
      var next = r.nextDate;
      int guard = 0;
      while (!next.isAfter(today) && guard < 400) {
        _transactions = [
          ..._transactions,
          Transaction(
            id: 'rc_${DateTime.now().microsecondsSinceEpoch}_$generated',
            type: r.type,
            amount: r.amount,
            categoryId: r.categoryId,
            accountId: r.accountId,
            transferToAccountId: r.transferToAccountId,
            note: r.note,
            date: next,
            bookId: r.bookId,
          ),
        ];
        next = RecurringRule.nextAfter(next, r.frequency);
        generated++;
        guard++;
      }
      if (guard > 0) {
        rules[i] = r.copyWith(nextDate: next);
        changed = true;
      }
    }
    if (changed) {
      _rules = rules;
      await _repository.saveRecurringRules(_rules);
    }
    if (generated > 0) {
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      await _persist();
      notifyListeners();
    }
    return generated;
  }

  /// 跳过下次：nextDate 推进一期且不生成流水
  Future<void> skipNextOccurrence(String ruleId) async {
    final idx = _rules.indexWhere((r) => r.id == ruleId);
    if (idx < 0) return;
    final r = _rules[idx];
    if (!r.active || r.bookId != _currentBookId) return;
    _rules = [
      for (final x in _rules)
        x.id == ruleId
            ? x.copyWith(
                nextDate:
                    RecurringRule.nextAfter(x.nextDate, x.frequency))
            : x,
    ];
    await _repository.saveRecurringRules(_rules);
    notifyListeners();
  }

  /// 立即生成本次周期流水：未来规则按今天生成并推进 nextDate；过期规则走正常补生成
  Future<void> generateRecurringNow(String ruleId) async {
    final idx = _rules.indexWhere((r) => r.id == ruleId);
    if (idx < 0) return;
    final r = _rules[idx];
    if (!r.active || r.bookId != _currentBookId) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!r.nextDate.isAfter(today)) {
      await generateDueRecurring();
      return;
    }
    _transactions = [
      ..._transactions,
      Transaction(
        id: 'rc_${DateTime.now().microsecondsSinceEpoch}_now',
        type: r.type,
        amount: r.amount,
        categoryId: r.categoryId,
        accountId: r.accountId,
        transferToAccountId: r.transferToAccountId,
        note: r.note,
        date: today,
        bookId: r.bookId,
      ),
    ]
      ..sort((a, b) => b.date.compareTo(a.date));
    _rules = [
      for (final x in _rules)
        x.id == ruleId
            ? x.copyWith(
                nextDate: RecurringRule.nextAfter(today, x.frequency))
            : x,
    ];
    await _persist();
    await _repository.saveRecurringRules(_rules);
    notifyListeners();
  }

  Future<void> addRecurringRule(RecurringRule rule) async {
    _rules = [..._rules, rule];
    await _repository.saveRecurringRules(_rules);
    notifyListeners();
  }

  Future<void> updateRecurringRule(RecurringRule rule) async {
    _rules = [
      for (final r in _rules) r.id == rule.id ? rule : r,
    ];
    await _repository.saveRecurringRules(_rules);
    notifyListeners();
  }

  Future<void> deleteRecurringRule(String id) async {
    _rules = [for (final r in _rules) if (r.id != id) r];
    await _repository.saveRecurringRules(_rules);
    notifyListeners();
  }

  /// 导入周期规则 CSV（按 频率+金额+备注 去重），返回新增数量
  Future<int> importRecurringCsv(String csv) async {
    final rules = CsvImporter.parseRecurringCsv(csv);
    if (rules.isEmpty) return 0;
    final existing = {
      for (final r in _rules)
        '${r.frequency.name}|${r.amount}|${r.note.trim()}',
    };
    var added = 0;
    for (final r in rules) {
      final fp = '${r.frequency.name}|${r.amount}|${r.note.trim()}';
      if (existing.contains(fp)) continue;
      _rules = [..._rules, r.copyWith(bookId: _currentBookId)];
      existing.add(fp);
      added++;
    }
    if (added > 0) {
      await _repository.saveRecurringRules(_rules);
      notifyListeners();
    }
    return added;
  }

  Future<void> setBudget(int cents) async {
    _bookBudgets = {..._bookBudgets, _currentBookId: cents};
    await _repository.saveBookBudgets(_bookBudgets);
    notifyListeners();
  }

 
 



  String get lastAccountId => _lastAccountId;

  List<String> _recentSearches = [];

  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  /// 记录最近搜索词（去重置顶，最多 5 条）
  Future<void> recordSearch(String q) async {
    final t = q.trim();
    if (t.isEmpty) return;
    _recentSearches = [
      t,
      ..._recentSearches.where((e) => e != t),
    ].take(5).toList();
    await _repository.saveRecentSearches(_recentSearches);
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    _recentSearches = [];
    await _repository.saveRecentSearches([]);
    notifyListeners();
  }
  bool get dailyReminder => _dailyReminder;

  Future<void> setDailyReminder(bool value) async {
    _dailyReminder = value;
    await _repository.saveDailyReminder(value);
    notifyListeners();
  }

  bool get budgetNotify => _budgetNotify;

  Future<void> setBudgetNotify(bool value) async {
    _budgetNotify = value;
    await _repository.saveBudgetNotify(value);
    notifyListeners();
  }

  bool get onboarded => _onboarded;

  Future<void> completeOnboarding() async {
    _onboarded = true;
    await _repository.saveOnboarded(true);
  }
  List<TxCategory> get customCategories => List.unmodifiable(_customCategories);

  Future<void> addCustomCategory({
    required String name,
    required String iconKey,
    required bool isExpense,
  }) async {
    final cat = TxCategory.custom(
      id: 'c_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      iconKey: iconKey,
      isExpense: isExpense,
    );
    _customCategories = [..._customCategories, cat];
    await _syncCustom();
  }

  Future<void> removeCustomCategory(String id) async {
    _customCategories = [
      for (final c in _customCategories)
        if (c.id != id) c,
    ];
    await _syncCustom();
  }

 
  Future<void> updateCustomCategory(TxCategory cat) async {
    _customCategories = [
      for (final c in _customCategories)
        if (c.id == cat.id) cat else c,
    ];
    await _syncCustom();
  }
  Future<void> _syncCustom() async {
    TxCategories.setCustom(_customCategories);
    await _repository.saveCustomCategories(_customCategories);
    notifyListeners();
  }
  Future<void> clearAll() async {
    _transactions = [];
    _rules = [];
    await _repository.clearAll();
    notifyListeners();
  }

  /// 载入示例数据（覆盖当前流水）
  Future<void> loadSampleData() async {
    _transactions = await _repository.buildSampleData();
    await _persist();
    notifyListeners();
  }

 
  /// 导入 CSV，返回解析结果（已合并去重）
  

  /// 导出全量数据为 JSON（备份）
  String exportJson() => jsonEncode({
        'version': 1,
        'transactions': [for (final t in _transactions) t.toJson()],
        'accounts': [for (final a in _accounts) a.toJson()],
        'customCategories': [for (final c in _customCategories) c.toJson()],
        'books': [for (final b in _books) b.toJson()],
        'currentBookId': _currentBookId,
        'bookBudgets': _bookBudgets,
        'budgetNotify': _budgetNotify,
        'dailyReminder': _dailyReminder,
        'recurringRules': [for (final r in _rules) r.toJson()],
      });

  /// 从 JSON 备份恢复；成功返回 null，失败返回错误信息
  Future<String?> importJson(String raw) async {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['version'] != 1) return '备份文件版本不受支持';
      _transactions = [
        for (final e in (map['transactions'] as List<dynamic>? ?? []))
          Transaction.fromJson(e as Map<String, dynamic>),
      ];
      _accounts = [
        for (final e in (map['accounts'] as List<dynamic>? ?? []))
          Account.fromJson(e as Map<String, dynamic>),
      ];
      if (_accounts.isEmpty) _accounts = kDefaultAccounts;
      _customCategories = [
        for (final e in (map['customCategories'] as List<dynamic>? ?? []))
          TxCategory.fromJson(e as Map<String, dynamic>),
      ];
      _books = [
        for (final e in (map['books'] as List<dynamic>? ?? []))
          Book.fromJson(e as Map<String, dynamic>),
      ];
      if (_books.isEmpty || !_books.any((b) => b.id == kDefaultBook.id)) {
        _books = [kDefaultBook, ..._books];
      }
      _currentBookId = (map['currentBookId'] as String?) ?? kDefaultBook.id;
      _bookBudgets = Map<String, int>.from(
          (map['bookBudgets'] as Map<dynamic, dynamic>?) ?? {});
      _budgetNotify = (map['budgetNotify'] as bool?) ?? true;
      _dailyReminder = (map['dailyReminder'] as bool?) ?? false;
      _rules = [
        for (final e in (map['recurringRules'] as List<dynamic>? ?? []))
          RecurringRule.fromJson(e as Map<String, dynamic>),
      ];
      TxCategories.setCustom(_customCategories);
      await _persist();
      await _repository.saveAccounts(_accounts);
      await _repository.saveCustomCategories(_customCategories);
      await _repository.saveBooks(_books);
      await _repository.saveCurrentBookId(_currentBookId);
      await _repository.saveBookBudgets(_bookBudgets);
      await _repository.saveBudgetNotify(_budgetNotify);
      await _repository.saveDailyReminder(_dailyReminder);
      await _repository.saveRecurringRules(_rules);
      notifyListeners();
      return null;
    } catch (_) {
      return '备份文件解析失败，请检查内容是否完整';
    }
  }
  Future<CsvImportResult> importCsv(String csv) async {
    final result = CsvImporter.parseCsv(csv, existing: _transactions);
    if (result.transactions.isNotEmpty) {
      // 为未知账户自动创建自定义账户并映射
      final nameToId = <String, String>{};
      for (final name in result.unknownAccountNames.values.toSet()) {
        final existingId = accountIdByName(name);
        if (existingId != null) {
          nameToId[name] = existingId;
        } else {
          final account = Account.custom(
            id: 'a_${DateTime.now().microsecondsSinceEpoch}_${nameToId.length}',
            name: name,
            iconKey: 'card_gift',
          );
          _accounts = [..._accounts, account];
          nameToId[name] = account.id;
        }
      }
      if (nameToId.isNotEmpty) {
        _syncAccounts();
        await _repository.saveAccounts(_accounts);
      }
      final imported = [
        for (final t in result.transactions)
          t.copyWith(
            bookId: _currentBookId,
            accountId: nameToId[result.unknownAccountNames[t.accountId]] ??
                t.accountId,
            transferToAccountId: t.transferToAccountId != null
                ? nameToId[result.unknownAccountNames[t.transferToAccountId!]] ??
                    t.transferToAccountId
                : null,
          ),
      ];
      _transactions = [..._transactions, ...imported]
          ..sort((a, b) => b.date.compareTo(a.date));
      await _persist();
      notifyListeners();
    }
    return result;
  }
  /// 某月（年份+月份）的流水
  List<Transaction> ofMonth(DateTime month) {
    final y = month.year, m = month.month;
    return _bookTx
        .where((t) => t.date.year == y && t.date.month == m)
        .toList();
  }

  MonthSummary summaryOf(DateTime month) {
    int exp = 0, inc = 0;
    for (final t in ofMonth(month)) {
      switch (t.type) {
        case TxType.expense:
          exp += t.amount;
        case TxType.income:
          inc += t.amount;
        case TxType.transfer:
          break;
      }
    }
    return MonthSummary(expense: exp, income: inc);
  }

  /// 某年汇总：总支出/总收入/结余/日均支出/笔数/支出最多分类
  ({int expense, int income, int dailyExpense,
      int count, String topCategoryName}) yearSummary(
      int year) {
    int exp = 0, inc = 0, count = 0;
    final catMap = <String, int>{};
    for (final t in _bookTx) {
      if (t.date.year != year) continue;
      if (t.type == TxType.expense) {
        exp += t.amount;
        catMap[t.categoryId] = (catMap[t.categoryId] ?? 0) + t.amount;
      } else if (t.type == TxType.income) {
        inc += t.amount;
      }
      count++;
    }
    String topName = '';
    int topAmount = 0;
    catMap.forEach((k, v) {
      if (v > topAmount) {
        topAmount = v;
        topName = TxCategories.byId(k).name;
      }
    });
    final days = DateTime(year, 12, 31)
        .difference(DateTime(year, 1, 1))
        .inDays +
        1;
    final daily = count == 0 ? 0 : exp ~/ days;
    return (
      expense: exp,
      income: inc,
      dailyExpense: daily,
      count: count,
      topCategoryName: topName,
    );
  }

  /// 与上月支出差额（正数=支出增加）
  int expenseDeltaOf(DateTime month) {
    final cur = summaryOf(month).expense;
    final prev = summaryOf(DateTime(month.year, month.month - 1)).expense;
    return cur - prev;
  }

  /// 某月每日支出序列（1..daysInMonth）
  List<int> dailyExpenseSeries(DateTime month) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final list = List<int>.filled(days, 0);
    for (final t in ofMonth(month)) {
      if (t.type == TxType.expense) {
        list[t.date.day - 1] += t.amount;
      }

    }
    return list;
  }

  /// 某月每日收入序列（1..daysInMonth）
  List<int> dailyIncomeSeries(DateTime month) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final list = List<int>.filled(days, 0);
    for (final t in ofMonth(month)) {
      if (t.type == TxType.income) {
        list[t.date.day - 1] += t.amount;
      }
    }
    return list;
  }

  /// 某月按周聚合的支出（第 1 周 ~ 第 N 周）
  List<({String label, int amount})> weeklyExpenseSeries(DateTime month) {
    final daily = dailyExpenseSeries(month);
    final weekCount = (daily.length + 6) ~/ 7;
    final weeks = List<int>.filled(weekCount, 0);
    for (int day = 0; day < daily.length; day++) {
      weeks[day ~/ 7] += daily[day];
    }
    return [
      for (int i = 0; i < weeks.length; i++)
        (label: '第${i + 1}周', amount: weeks[i]),
    ];
  }

  /// 某月分类支出排行（降序）
  List<({TxCategory category, int amount})> categoryExpenseRanking(DateTime month) {
    final map = <String, int>{};
    for (final t in ofMonth(month)) {
      if (t.type == TxType.expense) {
        map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
      }
    }
    final ranked = map.entries.map((e) {
      return (category: TxCategories.byId(e.key), amount: e.value);
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return ranked;
  }

 
  /// 某月分类收入排行（降序）
  List<({TxCategory category, int amount})> categoryIncomeRanking(DateTime month) {
    final map = <String, int>{};
    for (final t in ofMonth(month)) {
      if (t.type == TxType.income) {
        map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
      }

    }
    final ranked = map.entries.map((e) {
      return (category: TxCategories.byId(e.key), amount: e.value);
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return ranked;
  }

  /// 最近使用过的分类 id（按时间倒序，去重）
  List<String> recentCategoryIds(TxType type, {int limit = 4}) {
    final seen = <String>[];
    final sorted = [..._bookTx]..sort((a, b) => b.date.compareTo(a.date));
    for (final t in sorted) {
      if (t.type == type && !seen.contains(t.categoryId)) {
        seen.add(t.categoryId);
        if (seen.length >= limit) break;
      }

    }
    return seen;
  }

  /// 当前账本按类型最近一笔（用于「复制上一条」）
  Transaction? lastTransactionOf(TxType type) {
    final sorted = [..._bookTx]..sort((a, b) => b.date.compareTo(a.date));
    for (final t in sorted) {
      if (t.type == type) return t;
    }
    return null;
  }
 
  /// 以某月为终点，往前 count 个月的月度结余序列（时间升序）
  List<({DateTime month, int balance})> recentBalanceSeries(
    DateTime endMonth,

    int count,
  ) {
    final out = <({DateTime month, int balance})>[];
    for (int i = count - 1; i >= 0; i--) {
      final m = DateTime(endMonth.year, endMonth.month - i);
      final s = summaryOf(m);
      out.add((month: m, balance: s.balance));
    }
    return out;
  }

  /// 指定年逐月支出，与上一年对比（1..12 月）
  List<({int month, int thisYear, int lastYear})> yearComparison(
    int year,
  ) {
    final out = <({int month, int thisYear, int lastYear})>[];
    for (int m = 1; m <= 12; m++) {
      final cur = summaryOf(DateTime(year, m)).expense;
      final prev = summaryOf(DateTime(year - 1, m)).expense;
      out.add((month: m, thisYear: cur, lastYear: prev));
    }
    return out;
  }

  /// 生成某月记账小结文本（可复制分享）
  String monthSummaryText(DateTime month) {
    final s = summaryOf(month);
    final txs = ofMonth(month);
    final ranking = categoryExpenseRanking(month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final daily = txs.isEmpty ? 0 : s.expense ~/ days;
    final top = ranking.isNotEmpty ? ranking.first : null;
    String fmt(int cents) => (cents / 100).toStringAsFixed(2);
    final buf = StringBuffer();
    buf.writeln('${month.year}年${month.month}月 记账小结');
    buf.writeln('收入：${fmt(s.income)}');
    buf.writeln('支出：${fmt(s.expense)}');
    buf.writeln('结余：${fmt(s.balance)}');
    buf.writeln('笔数：${txs.length} 笔');
    buf.writeln('日均支出：${fmt(daily)}');
    if (top != null) {
      buf.writeln('支出最多：${top.category.name} ${fmt(top.amount)}');
    }
    return buf.toString();
  }

  /// 生成本周记账小结文本（可复制分享）
  String weekSummaryText() {
    final s = weekSummary ?? MonthSummary(expense: 0, income: 0);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));
    int count = 0;
    for (final t in _bookTx) {
      if (!t.date.isBefore(monday)) count++;
    }
    String fmt(int cents) => (cents / 100).toStringAsFixed(2);
    final buf = StringBuffer();
    buf.writeln(
        '本周记账小结（${monday.month}月${monday.day}日 - ${today.month}月${today.day}日）');
    buf.writeln('收入：${fmt(s.income)}');
    buf.writeln('支出：${fmt(s.expense)}');
    buf.writeln('结余：${fmt(s.balance)}');
    buf.writeln('笔数：$count 笔');
    return buf.toString();
  }
  /// 账户当前余额 = 初始余额 + 收支合计
  int balanceOf(Account account) {
    int sum = account.initialBalance;
    for (final t in _bookTx) {
      if (t.type == TxType.transfer) {
        if (t.accountId == account.id) sum -= t.amount;
        if (t.transferToAccountId == account.id) sum += t.amount;
      } else if (t.accountId == account.id) {
        sum += t.type == TxType.income ? t.amount : -t.amount;
      }
    }
    return sum;
  }

  /// 某账户某月的支出/收入/笔数（仅当前账本）
  ({int expense, int income, int count}) monthlySummaryOfAccount(
      String accountId, DateTime month) {
    int exp = 0, inc = 0, count = 0;
    for (final t in _bookTx) {
      if (t.accountId != accountId ||
          t.date.year != month.year ||
          t.date.month != month.month) {
        continue;
      }
      if (t.type == TxType.expense) {
        exp += t.amount;
        count++;
      } else if (t.type == TxType.income) {
        inc += t.amount;
        count++;
      }
    }
    return (expense: exp, income: inc, count: count);
  }

  /// 某账户某月转出/转入统计（仅当前账本）
  ({int outAmount, int outCount, int inAmount, int inCount})
      monthlyTransferSummaryOfAccount(String accountId, DateTime month) {
    int outA = 0, outC = 0, inA = 0, inC = 0;
    for (final t in _bookTx) {
      if (t.type != TxType.transfer ||
          t.date.year != month.year ||
          t.date.month != month.month) {
        continue;
      }
      if (t.accountId == accountId) {
        outA += t.amount;
        outC++;
      }
      if (t.transferToAccountId == accountId) {
        inA += t.amount;
        inC++;
      }
    }
    return (
      outAmount: outA,
      outCount: outC,
      inAmount: inA,
      inCount: inC,
    );
  }

  int get totalAssets {
    int sum = 0;
    for (final a in _accounts) {
      sum += balanceOf(a);
    }
    return sum;
  }

 
  List<Account> get accounts => List.unmodifiable(_accounts);

  /// 设置账户初始余额（分）
  Future<void> setAccountInitialBalance(String id, int cents) async {
    _accounts = [
      for (final a in _accounts)
        if (a.id == id) a.copyWith(initialBalance: cents) else a,
    ];
    await _repository.saveAccounts(_accounts);
    notifyListeners();
  }

  void _syncAccounts() {
    Account.setCustom(
      [for (final a in _accounts) if (a.isCustom) a],
    );
  }

  Future<void> addAccount({
    required String name,
    required String iconKey,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final account = Account.custom(
      id: 'a_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed,
      iconKey: iconKey,
    );
    _accounts = [..._accounts, account];
    _syncAccounts();
    await _repository.saveAccounts(_accounts);
    notifyListeners();
  }

  Future<void> renameAccount(
    String id, String name, {
    String? iconKey,
  }) async {
    _accounts = [
      for (final a in _accounts)
        if (a.id == id)
            a.copyWith(name: name.trim(), iconKey: iconKey) else a,
    ];
    _syncAccounts();
    await _repository.saveAccounts(_accounts);
    notifyListeners();
  }

  /// 删除账户（仅自定义；有流水的账户禁止删除）
  Future<bool> removeAccount(String id) async {
    final hasTx = _transactions.any((t) => t.accountId == id);
    if (hasTx) return false;
    _accounts = [
      for (final a in _accounts)
        if (a.id != id) a,
    ];
    _syncAccounts();
    await _repository.saveAccounts(_accounts);
    notifyListeners();
    return true;
  }

  Future<void> setCurrentBook(String id) async {
    if (!_books.any((b) => b.id == id)) return;
    _currentBookId = id;
    await _repository.saveCurrentBookId(id);
    notifyListeners();
    await generateDueRecurring();
  }

  Future<void> addBook(String name, {String iconKey = 'menu_book'}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final book = Book(
      id: 'b_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed,
      iconKey: iconKey,
    );
    _books = [..._books, book];
    await _repository.saveBooks(_books);
    notifyListeners();
  }

  Future<void> renameBook(String id, String name,
      {String? iconKey}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || id == kDefaultBook.id) return;
    _books = [
      for (final b in _books)
        b.id == id ? b.copyWith(name: trimmed, iconKey: iconKey) : b,
    ];
    await _repository.saveBooks(_books);
    notifyListeners();
  }

  /// 删除账本：其流水并入默认账本；若删除的是当前账本则切回默认
  Future<void> removeBook(String id) async {
    if (id == kDefaultBook.id) return;
    _books = [for (final b in _books) if (b.id != id) b];
    _transactions = [
      for (final t in _transactions)
        t.bookId == id ? t.copyWith(bookId: kDefaultBook.id) : t,
    ];
    if (_currentBookId == id) _currentBookId = kDefaultBook.id;
    await _repository.saveBooks(_books);
    _bookBudgets = {..._bookBudgets}..remove(id);
    await _repository.saveBookBudgets(_bookBudgets);
    await _repository.saveCurrentBookId(_currentBookId);
    await _persist();
    notifyListeners();
  }
  /// 当月已支出（用于预算进度）
  int get currentMonthExpense {
    final now = DateTime.now();
    return summaryOf(DateTime(now.year, now.month)).expense;
  }

  /// 本周（周一起）收支概览
  MonthSummary? get weekSummary {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));
    int exp = 0, inc = 0;
    for (final t in _bookTx) {
      if (!t.date.isBefore(monday)) {
        switch (t.type) {
          case TxType.expense:
            exp += t.amount;
          case TxType.income:
            inc += t.amount;
          case TxType.transfer:
            break;
        }
      }
    }
    return MonthSummary(expense: exp, income: inc);
  }

  /// 本月预算剩余（分，不小于 0）
  int get budgetRemaining {
    final r = monthlyBudget - currentMonthExpense;
    return r < 0 ? 0 : r;
  }

  /// 本月剩余天数（含今天）
  int get budgetDaysLeft {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month + 1, 0).day;
    return last - now.day + 1;
  }

  /// 剩余日均可用（分）
  int get budgetDailyRemaining =>
      budgetDaysLeft == 0 ? 0 : budgetRemaining ~/ budgetDaysLeft;
}



