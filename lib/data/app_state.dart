/// 全局应用状态（ChangeNotifier + Provider）
library;

import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import 'transaction_repository.dart';

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
  int _monthlyBudget = 0;
  List<TxCategory> _customCategories = [];
  bool _loaded = false;

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  int get monthlyBudget => _monthlyBudget;
  bool get loaded => _loaded;

  Future<void> load() async {
    await _repository.seedIfFirstLaunch();
    _transactions = await _repository.loadTransactions();
    _monthlyBudget = await _repository.loadBudget();
    _customCategories = await _repository.loadCustomCategories();
    TxCategories.setCustom(_customCategories);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() => _repository.saveTransactions(_transactions);

  Future<void> addTransaction(Transaction tx) async {
    _transactions = [..._transactions, tx]
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
    _monthlyBudget = cents;
    await _repository.saveBudget(cents);
    notifyListeners();
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

  /// 某月（年份+月份）的流水
  List<Transaction> ofMonth(DateTime month) {
    final y = month.year, m = month.month;
    return _transactions
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
  /// 账户当前余额 = 初始余额 + 收支合计
  int balanceOf(Account account) {
    int sum = account.initialBalance;
    for (final t in _transactions) {
      if (t.accountId == account.id) {
        sum += t.type == TxType.income ? t.amount : -t.amount;
      }
    }
    return sum;
  }

  int get totalAssets {
    int sum = 0;
    for (final a in kDefaultAccounts) {
      sum += balanceOf(a);
    }
    return sum;
  }

  /// 当月已支出（用于预算进度）
  int get currentMonthExpense {
    final now = DateTime.now();
    return summaryOf(DateTime(now.year, now.month)).expense;
  }
}



