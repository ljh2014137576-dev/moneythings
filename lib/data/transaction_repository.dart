/// 本地持久化：SharedPreferences 存 JSON
library;

import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';
import '../models/account.dart';
import '../models/book.dart';

class TransactionRepository {
  static const String _kTxKey = 'transactions_v1';
  static const String _kBudgetKey = 'monthly_budget_cents';
  static const String _kSeededKey = 'seeded_v1';
  static const String _kCustomKey = 'custom_categories_v1';
  static const String _kAccountsKey = 'accounts_v1';
  static const String _kOnboardedKey = 'onboarded_v1';
  static const String _kBooksKey = 'books_v1';
  static const String _kCurrentBookKey = 'current_book_v1';
  static const String _kBookBudgetsKey = 'book_budgets_v1';
  static const String _kBudgetNotifyKey = 'budget_notify_v1';
  static const String _kDailyReminderKey = 'daily_reminder_v1';
  static const String _kLastAccountKey = 'last_account_v1';
  static const String _kRecentSearchesKey = 'recent_searches_v1';

  Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTxKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<Transaction> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kTxKey,
      jsonEncode(items.map((t) => t.toJson()).toList()),
    );
  }

  Future<int> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kBudgetKey) ?? 0;
  }

  Future<Map<String, int>> loadBookBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBookBudgetsKey);
    final map = <String, int>{};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in decoded.entries) {
          map[e.key] = (e.value as num).toInt();
        }
      } catch (_) {}
    }
    // 兼容旧版单一预算（归入默认账本）
    final legacy = prefs.getInt(_kBudgetKey);
    if (legacy != null && legacy > 0 && !map.containsKey(kDefaultBook.id)) {
      map[kDefaultBook.id] = legacy;
    }
    return map;
  }

  Future<void> saveBookBudgets(Map<String, int> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kBookBudgetsKey,
      jsonEncode(budgets),
    );
  }

  Future<bool> loadBudgetNotify() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBudgetNotifyKey) ?? true;
  }

  Future<void> saveBudgetNotify(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBudgetNotifyKey, value);
  }

  Future<bool> loadDailyReminder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDailyReminderKey) ?? false;
  }

  Future<void> saveDailyReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDailyReminderKey, value);
  }

  Future<String> loadLastAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastAccountKey) ?? 'alipay';
  }

  Future<void> saveLastAccountId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastAccountKey, id);
  }

  Future<void> saveBudget(int cents) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBudgetKey, cents);
  }

 
  Future<List<TxCategory>> loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCustomKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          if (e is Map<String, dynamic>) TxCategory.fromJson(e),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomCategories(List<TxCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCustomKey,
      jsonEncode([for (final c in categories) c.toJson()]),
    );
  }
 
  Future<List<Account>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAccountsKey);
    if (raw == null || raw.isEmpty) {
      return [for (final a in kDefaultAccounts) a];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final loaded = [
        for (final e in list)
          if (e is Map<String, dynamic>) Account.fromJson(e),
      ];
      if (loaded.isEmpty) return [for (final a in kDefaultAccounts) a];
      return loaded;
    } catch (_) {
      return [for (final a in kDefaultAccounts) a];
    }
  }

  Future<void> saveAccounts(List<Account> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kAccountsKey,
      jsonEncode([for (final a in accounts) a.toJson()]),
    );
  }
 
  Future<bool> loadOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardedKey) ?? false;
  }

  Future<void> saveOnboarded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardedKey, value);
  }
 
  Future<List<Book>> loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBooksKey);
    if (raw == null || raw.isEmpty) return [kDefaultBook];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final books = [
        for (final e in list)
          if (e is Map<String, dynamic>) Book.fromJson(e),
      ];
      if (books.isEmpty || !books.any((b) => b.id == kDefaultBook.id)) {
        return [kDefaultBook, ...books];
      }
      return books;
    } catch (_) {
      return [kDefaultBook];
    }
  }

  Future<void> saveBooks(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kBooksKey,
      jsonEncode([for (final b in books) b.toJson()]),
    );
  }

  Future<String> loadCurrentBookId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrentBookKey) ?? kDefaultBook.id;
  }

  Future<void> saveCurrentBookId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentBookKey, id);
  }
  /// 首次启动写入示例数据，让首页 / 统计立即可体验
  Future<void> seedIfFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSeededKey) ?? false) return;
    final existing = await loadTransactions();
    if (existing.isNotEmpty) {
      await prefs.setBool(_kSeededKey, true);
      return;
    }
    final seeded = _buildSampleData();
    await saveTransactions(seeded);
    await prefs.setBool(_kSeededKey, true);
  }

  Future<void> clearAll() async {
    await saveTransactions(const []);
  }

  /// 公开的示例数据生成入口
  Future<List<Transaction>> buildSampleData() async => _buildSampleData();

  /// 生成最近两个自然月的真实感示例流水
  static List<Transaction> _buildSampleData() {
    final now = DateTime.now();
    final rnd = Random(42);
    final items = <Transaction>[];

    // 加权支出分类：餐饮最多
    const expensePool = [
      ('food', 28),
      ('transport', 16),
      ('shopping', 20),
      ('home', 6),
      ('fun', 10),
      ('medical', 3),
      ('comm', 8),
      ('edu', 4),
      ('social', 5),
    ];
    int totalWeight = 0;
    for (final e in expensePool) {
      totalWeight += e.$2;
    }

    int pickExpense() {
      int r = rnd.nextInt(totalWeight);
      for (int i = 0; i < expensePool.length; i++) {
        r -= expensePool[i].$2;
        if (r < 0) return i;
      }
      return 0;
    }

    int amountFor(String cat) {
      switch (cat) {
        case 'food':
          return rnd.nextInt(46) + 12;
        case 'transport':
          return rnd.nextInt(18) + 2;
        case 'shopping':
          return rnd.nextInt(40) + 20;
        case 'home':
          return 200 + rnd.nextInt(60) * 10;
        case 'fun':
          return 30 + rnd.nextInt(16) * 10;
        case 'medical':
          return 60 + rnd.nextInt(20) * 10;
        case 'comm':
          return 30 + rnd.nextInt(10) * 10;
        case 'edu':
          return 60 + rnd.nextInt(30) * 10;
        default:
          return 50 + rnd.nextInt(20) * 10;
      }
    }

    for (int back = 1; back >= 0; back--) {
      final month = DateTime(now.year, now.month - back);
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      final lastDay = back == 0 ? now.day : daysInMonth;

      for (int day = 1; day <= lastDay; day++) {
        final count = rnd.nextInt(3) + 1; // 每天 1~3 笔
        for (int i = 0; i < count; i++) {
          final idx = pickExpense();
          final cat = expensePool[idx].$1;
          final amount = amountFor(cat) * 100;
          final hour = 7 + rnd.nextInt(15);
          final minute = rnd.nextInt(60);
          items.add(Transaction(
            id: 'seed-${month.year}-${month.month}-$day-$i',
            type: TxType.expense,
            amount: amount,
            categoryId: cat,
            accountId: ['alipay', 'wechat', 'card'][rnd.nextInt(3)],
            date: DateTime(month.year, month.month, day, hour, minute),
            note: i == 0 && rnd.nextBool() ? _noteFor(cat) : '',
          ));
        }
      }

      // 工资与理财收入
      for (final payDay in [5, 10, 15, 20, 25]) {
        if (payDay <= lastDay) {
          items.add(Transaction(
            id: 'seed-inc-${month.year}-${month.month}-$payDay',
            type: TxType.income,
            amount: payDay == 10 ? 1280000 : (12000 + rnd.nextInt(5) * 500) * 100,
            categoryId: payDay == 10 ? 'salary' : 'invest',
            accountId: 'card',
            date: DateTime(month.year, month.month, payDay, 9, 0),
            note: payDay == 10 ? '工资' : '理财收益',
          ));
        }
      }
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  static String _noteFor(String cat) {
    const notes = {
      'food': ['午饭', '晚饭', '咖啡', '外卖', '早餐'],
      'transport': ['地铁', '公交', '打车'],
      'shopping': ['日用品', '超市', '网购'],
      'fun': ['电影', '游戏', 'KTV'],
      'comm': ['话费', '流量包'],
    };
    final list = notes[cat] ?? const ['日常开销'];
    return list[Random(cat.hashCode).nextInt(list.length)];
  }

  Future<List<String>> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kRecentSearchesKey) ?? [];
  }

  Future<void> saveRecentSearches(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kRecentSearchesKey, items);
  }
}


