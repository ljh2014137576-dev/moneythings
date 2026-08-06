/// 全局应用状态（ChangeNotifier + Provider）
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/book.dart';
import '../models/transaction.dart';
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

  Future<void> load() async {
    await _repository.seedIfFirstLaunch();
    _transactions = await _repository.loadTransactions();
    _bookBudgets = await _repository.loadBookBudgets();
    _customCategories = await _repository.loadCustomCategories();
    _accounts = await _repository.loadAccounts();
    _books = await _repository.loadBooks();
    _currentBookId = await _repository.loadCurrentBookId();
    _lastAccountId = await _repository.loadLastAccountId();
    _dailyReminder = await _repository.loadDailyReminder();
    _budgetNotify = await _repository.loadBudgetNotify();
    _onboarded = await _repository.loadOnboarded();
    if (!_books.any((b) => b.id == _currentBookId)) {
      _currentBookId = kDefaultBook.id;
    }
    TxCategories.setCustom(_customCategories);
    _loaded = true;
    notifyListeners();
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

  Future<void> deleteTransaction(String id) async {
    _transactions = [
      for (final t in _transactions)
        if (t.id != id) t,
    ];
    await _persist();
    notifyListeners();
  }

  Future<void> setBudget(int cents) async {
    _bookBudgets = {..._bookBudgets, _currentBookId: cents};
    await _repository.saveBookBudgets(_bookBudgets);
    notifyListeners();
  }

 
 



  String get lastAccountId => _lastAccountId;
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
      TxCategories.setCustom(_customCategories);
      await _persist();
      await _repository.saveAccounts(_accounts);
      await _repository.saveCustomCategories(_customCategories);
      await _repository.saveBooks(_books);
      await _repository.saveCurrentBookId(_currentBookId);
      await _repository.saveBookBudgets(_bookBudgets);
      await _repository.saveBudgetNotify(_budgetNotify);
      await _repository.saveDailyReminder(_dailyReminder);
      notifyListeners();
      return null;
    } catch (_) {
      return '备份文件解析失败，请检查内容是否完整';
    }
  }
Future<CsvImportResult> importCsv(String csv) async {
    final result = CsvImporter.parseCsv(csv, existing: _transactions);
    if (result.transactions.isNotEmpty) {
    final imported = [
      for (final t in result.transactions)
        t.copyWith(bookId: _currentBookId),
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
      if (t.type == TxType.expense) {
        exp += t.amount;
      } else {
        inc += t.amount;
      }
    }
    return MonthSummary(expense: exp, income: inc);
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
  /// 账户当前余额 = 初始余额 + 收支合计
  int balanceOf(Account account) {
    int sum = account.initialBalance;
    for (final t in _bookTx) {
      if (t.accountId == account.id) {
        sum += t.type == TxType.income ? t.amount : -t.amount;
      }
    }
    return sum;
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

  Future<void> setCurrentBook(String id) async {
    if (!_books.any((b) => b.id == id)) return;
    _currentBookId = id;
    await _repository.saveCurrentBookId(id);
    notifyListeners();
  }

  Future<void> addBook(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final book = Book(
      id: 'b_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed,
    );
    _books = [..._books, book];
    await _repository.saveBooks(_books);
    notifyListeners();
  }

  Future<void> renameBook(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || id == kDefaultBook.id) return;
    _books = [
      for (final b in _books) b.id == id ? b.copyWith(name: trimmed) : b,
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
        if (t.type == TxType.expense) {
          exp += t.amount;
        } else {
          inc += t.amount;
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



