import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneythings_goal/data/app_state.dart';
import 'package:moneythings_goal/data/transaction_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:moneythings_goal/main.dart';
import 'package:moneythings_goal/pages/add_transaction_page.dart';
import 'package:moneythings_goal/pages/home_page.dart';
import 'package:moneythings_goal/pages/ledger_page.dart';
import 'package:moneythings_goal/pages/profile_page.dart';
import 'package:moneythings_goal/pages/stats_page.dart';
import 'package:moneythings_goal/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:moneythings_goal/models/account.dart';
import 'package:moneythings_goal/models/recurring_rule.dart';
import 'package:moneythings_goal/models/transaction.dart';
import 'package:moneythings_goal/services/csv_exporter.dart';
import 'package:moneythings_goal/services/csv_importer.dart';
import 'package:moneythings_goal/widgets/amount_text.dart';
import 'package:moneythings_goal/widgets/transaction_tile.dart';
import 'package:moneythings_goal/widgets/paper_group.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AmountText 分转元格式化', () {
    expect(AmountText.format(123456), '¥1,234.56');
    expect(AmountText.format(0), '¥0.00');
    expect(AmountText.format(500), '¥5.00');
    expect(AmountText.format(5), '¥0.05');
  });

  test('分类回退到「其他」', () {
    expect(TxCategories.byId('food').name, '餐饮');
    expect(TxCategories.byId('unknown').name, '其他');
    expect(TxCategories.of(TxType.expense).length, 10);
    expect(TxCategories.of(TxType.income).length, 6);
  });

  group('AppState', () {
    test('新增 / 修改 / 删除流水', () async {
      SharedPreferences.setMockInitialValues({'onboarded_v1': true});
      final state = AppState();
      await state.load();
      await state.clearAll(); // 示例数据只用于演示，测试从空开始

      final tx = Transaction(
        id: 't1',
        type: TxType.expense,
        amount: 2500,
        categoryId: 'food',
        accountId: 'alipay',
        date: DateTime(2026, 8, 6),
      );
      await state.addTransaction(tx);
      expect(state.transactions.length, 1);
      expect(state.summaryOf(DateTime(2026, 8)).expense, 2500);

      await state.updateTransaction(tx.copyWith(amount: 3000));
      expect(state.summaryOf(DateTime(2026, 8)).expense, 3000);

      await state.deleteTransaction('t1');
      expect(state.transactions, isEmpty);
    });

    test('首次启动自动载入示例数据', () async {
      SharedPreferences.setMockInitialValues({'onboarded_v1': true});
      final state = AppState();
      await state.load();
      expect(state.transactions.length, greaterThan(20));
      expect(state.dailyExpenseSeries(DateTime(2026, 8)).length, 31);
    });

    test('预算设置与读取', () async {
      SharedPreferences.setMockInitialValues({'onboarded_v1': true});
      final state = AppState();
      await state.load();
      await state.setBudget(300000);
      expect(state.monthlyBudget, 300000);
    });

    test('expenseDeltaOf 计算与上月差额', () async {
      SharedPreferences.setMockInitialValues({'onboarded_v1': true});
      final state = AppState();
      await state.load();
      await state.clearAll();
      await state.addTransaction(Transaction(
        id: 'x',
        type: TxType.expense,
        amount: 1000,
        categoryId: 'food',
        accountId: 'alipay',
        date: DateTime(2026, 8, 1),
      ));
      await state.addTransaction(Transaction(
        id: 'y',
        type: TxType.expense,
        amount: 3000,
        categoryId: 'food',
        accountId: 'alipay',
        date: DateTime(2026, 7, 15),
      ));
      expect(state.expenseDeltaOf(DateTime(2026, 8)), -2000);
      expect(state.expenseDeltaOf(DateTime(2026, 7)), 3000);
    });
  });

  test('CsvExporter 生成 CSV（含账本列与转义）', () {
    final txs = [
      Transaction(
        id: 'a',
        type: TxType.expense,
        amount: 123456,
        categoryId: 'food',
        accountId: 'alipay',
        date: DateTime(2026, 8, 6, 12, 30),
        note: '午饭,咖啡',
      ),
      Transaction(
        id: 'b',
        type: TxType.income,
        amount: 500,
        categoryId: 'salary',
        accountId: 'card',
        date: DateTime(2026, 8, 10, 9, 0),
        bookId: 'b_work',
      ),
    ];
    final csv = CsvExporter.exportCsv(
      txs,
      bookNames: {'b_work': '工作'},
    );
    expect(csv, startsWith('\uFEFF'));
    expect(csv, contains('日期,类型,分类,金额(元),账户,账本,备注'));
    expect(csv, contains('2026-08-06 12:30,支出,餐饮,1234.56,支付宝,default,"午饭,咖啡"'));
    expect(csv, contains('2026-08-10 09:00,收入,工资,5.00,银行卡,工作,'));
  });

  testWidgets('记一笔 -> 明细 -> 编辑 -> 删除 全流程', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '42');
    await tester.tap(find.text('餐饮'));
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    // 等待「已保存」SnackBar 消失，避免遮挡后续点击
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('¥42.00'), findsWidgets);

    await tester.tap(find.text('明细').first);
    await tester.pumpAndSettle();
    expect(find.text('¥42.00'), findsWidgets);
    // 清除残留 SnackBar，避免遮挡行点击
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
        .clearSnackBars();
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TransactionTile).first);
    await tester.pumpAndSettle();
    expect(find.text('编辑账目'), findsOneWidget);

    await tester.tap(find.byTooltip('删除账目'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(find.text('¥42.00'), findsNothing);
  });

  testWidgets('预算超额时保存弹出确认，可取消', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.setBudget(10000); // ¥100
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '200');
    await tester.tap(find.text('餐饮'));
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('超出本月预算'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(state.transactions, isEmpty);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续保存'));
    await tester.pumpAndSettle();
    expect(state.transactions.length, 1);
  });

  testWidgets('我的页包含导出入口', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('导出数据 (CSV)'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('导出数据 (CSV)'), findsOneWidget);
  });

  testWidgets('应用启动并渲染首页概览', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('记账本'), findsOneWidget);
    expect(find.text('本月支出'), findsOneWidget);
    expect(find.text('记一笔'), findsWidgets);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('明细'), findsOneWidget);
    expect(find.text('统计'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
 
  test('自定义分类：注册表与持久化', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addCustomCategory(name: '宠物', iconKey: 'pets', isExpense: true);
    expect(TxCategories.of(TxType.expense).any((c) => c.name == '宠物'), isTrue);
    expect(TxCategories.byId(state.customCategories.first.id).name, '宠物');

    // 重新加载后仍保留
    final state2 = AppState();
    await state2.load();
    expect(state2.customCategories.any((c) => c.name == '宠物'), isTrue);

    await state2.removeCustomCategory(state2.customCategories.first.id);
    expect(TxCategories.of(TxType.expense).any((c) => c.name == '宠物'), isFalse);
  });

  testWidgets('我的页新增自定义分类并出现在记一笔', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('分类管理'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '宠物');
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();

    // 回首页进入记一笔，分类网格应包含「宠物」
    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    expect(find.text('宠物'), findsWidgets);
  });
 
  test('CsvImporter 解析/错误行', () {
    const csv = '\uFEFF日期,类型,分类,金额(元),账户,备注\n'
        '2026-08-06 12:30,支出,餐饮,42.50,支付宝,午饭\n'
        '2026-08-05,收入,工资,5000,银行卡,工资\n'
        'bad line\n';
    final r = CsvImporter.parseCsv(csv);
    expect(r.transactions.length, 2);
    expect(r.errors.length, 1);
    expect(r.transactions[0].amount, 4250);
    expect(r.transactions[0].categoryId, 'food');
    expect(r.transactions[1].type, TxType.income);
    expect(r.transactions[1].categoryId, 'salary');
  });

  test('importCsv 合并去重', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    const csv = '日期,类型,分类,金额(元),账户,备注\n'
        '2026-08-06,支出,餐饮,42.00,支付宝,午饭\n'
        '2026-08-06,支出,餐饮,42.00,支付宝,午饭\n';
    final r = await state.importCsv(csv);
    expect(r.transactions.length, 1);
    expect(r.skipped, 1);
    expect(state.transactions.length, 1);
  });

  testWidgets('明细搜索按备注过滤', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'a',
      type: TxType.expense,
      amount: 1600,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 5),
      note: '咖啡',
    ));
    await state.addTransaction(Transaction(
      id: 'b',
      type: TxType.expense,
      amount: 500,
      categoryId: 'transport',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 6),
      note: '地铁',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '咖啡');
    await tester.pumpAndSettle();
    expect(find.textContaining('咖啡 · 支付宝'), findsOneWidget);
    expect(find.textContaining('地铁'), findsNothing);

    // 清除搜索后恢复
    await tester.tap(find.byTooltip('清除搜索'));
    await tester.pumpAndSettle();
    expect(find.textContaining('地铁 · 支付宝'), findsOneWidget);
  });

  testWidgets('月份快速跳转', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('2026年8月'));
    await tester.pumpAndSettle();
    expect(find.textContaining('年'), findsWidgets);

    await tester.tap(find.text('7月'));
    await tester.pumpAndSettle();
    expect(find.text('2026年7月'), findsOneWidget);
  });
 
  testWidgets('导入 CSV 对话框可取消并导入', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('导入数据 (CSV)'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(Scrollable).last,
      const Offset(0, -160),
    );
    await tester.pumpAndSettle();

    // 打开 -> 取消（不应崩溃）
    await tester.tap(find.text('导入数据 (CSV)'));
    await tester.pumpAndSettle();
    expect(find.text('导入 CSV'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // 重新打开 -> 粘贴 -> 导入
    await tester.tap(find.text('导入数据 (CSV)'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      '日期,类型,分类,金额(元),账户,备注\n2026-08-07,支出,餐饮,35.50,支付宝,导入测试',
    );
    await tester.tap(find.text('导入').last);
    await tester.pumpAndSettle();
    // 预览确认
    await tester.tap(find.text('追加导入').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('导入 1 笔'), findsOneWidget);
    expect(state.transactions.any((t) => t.note == '导入测试'), isTrue);
  });
 
  testWidgets('首次启动显示引导，开始使用后进入首页', (tester) async {
    SharedPreferences.setMockInitialValues({}); // 未完成引导
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('记录每一笔'), findsOneWidget);
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('统计一目了然'), findsOneWidget);
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始使用'));
    await tester.pumpAndSettle();
    expect(find.text('记账本'), findsOneWidget);
  });
 
  test('账户初始余额设置与持久化', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.setAccountInitialBalance('cash', 100000);
    expect(state.accounts.firstWhere((a) => a.id == 'cash').initialBalance,
        100000);
    expect(state.totalAssets, 100000);

    final state2 = AppState();
    await state2.load();
    expect(state2.accounts.firstWhere((a) => a.id == 'cash').initialBalance,
        100000);
  });

  test('recentBalanceSeries 近 6 月序列', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addTransaction(Transaction(
      id: 'inc',
      type: TxType.income,
      amount: 100000,
      categoryId: 'salary',
      accountId: 'card',
      date: DateTime(2026, 3, 10),
    ));
    await state.addTransaction(Transaction(
      id: 'exp',
      type: TxType.expense,
      amount: 40000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2026, 8, 6),
    ));
    final series = state.recentBalanceSeries(DateTime(2026, 8), 6);
    expect(series.length, 6);
    expect(series.first.month.month, 3);
    expect(series.last.month.month, 8);
    expect(series[0].balance, 100000);
    expect(series[5].balance, -40000);
  });

  testWidgets('账户初始余额编辑后余额更新', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('现金'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('现金'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置初始余额'));
    await tester.pumpAndSettle();
    expect(find.text('现金 · 初始余额'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '500');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('¥500.00'), findsWidgets);
  });
 
  test('预算剩余/日均可用计算', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.setBudget(100000);
    expect(state.budgetRemaining, 100000);
    final now = DateTime.now();
    final last = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = last - now.day + 1;
    expect(state.budgetDaysLeft, daysLeft);
    expect(state.budgetDailyRemaining, 100000 ~/ daysLeft);

    // 超支后剩余归 0
    await state.addTransaction(Transaction(
      id: 'big',
      type: TxType.expense,
      amount: 120000,
      categoryId: 'home',
      accountId: 'alipay',
      date: now,
    ));
    expect(state.budgetRemaining, 0);
  });

  testWidgets('首页显示预算剩余/日均与结余走势', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.setBudget(100000);
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();

    expect(find.textContaining('结余走势'), findsWidgets);
    expect(find.textContaining('剩余 ¥1,000.00'), findsOneWidget);
    expect(find.textContaining('日均'), findsOneWidget);
  });

  testWidgets('明细左滑删除可撤销', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'c1',
      type: TxType.expense,
      amount: 1600,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '咖啡',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.textContaining('咖啡'), findsOneWidget);

    // 左滑删除
    await tester.drag(find.textContaining('咖啡'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('咖啡'), findsNothing);
    expect(state.transactions, isEmpty);

    // 撤销恢复
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    expect(state.transactions.length, 1);
    expect(find.textContaining('咖啡'), findsOneWidget);
  });
 
  test('多账本：创建/切换/隔离/删除', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();

    // 默认账本记一笔
    await state.addTransaction(Transaction(
      id: 'd1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2026, 8, 5),
    ));
    expect(state.currentBook.id, 'default');
    expect(state.ofMonth(DateTime(2026, 8)).length, 1);

    // 新建账本并切换
    await state.addBook('工作');
    final work = state.books.firstWhere((b) => b.name == '工作');
    await state.setCurrentBook(work.id);
    expect(state.currentBook.name, '工作');

    // 新账本下看不到默认账本的流水
    expect(state.ofMonth(DateTime(2026, 8)), isEmpty);
    expect(state.summaryOf(DateTime(2026, 8)).expense, 0);

    // 新账本记一笔
    await state.addTransaction(Transaction(
      id: 'w1',
      type: TxType.expense,
      amount: 3000,
      categoryId: 'comm',
      accountId: 'card',
      date: DateTime(2026, 8, 6),
    ));
    expect(state.ofMonth(DateTime(2026, 8)).length, 1);
    expect(state.summaryOf(DateTime(2026, 8)).expense, 3000);

    // 删除账本：流水并入默认账本，当前账本切回默认
    await state.removeBook(work.id);
    expect(state.currentBook.id, 'default');
    expect(state.books.any((b) => b.id == work.id), isFalse);
    expect(state.ofMonth(DateTime(2026, 8)).length, 2);
  });

  testWidgets('首页切换账本后支出变化', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addTransaction(Transaction(
      id: 'd1',
      type: TxType.expense,
      amount: 100000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime.now(),
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('¥1,000.00'), findsWidgets);

    // 新建并切到空账本
    await state.addBook('空账本');
    final b = state.books.firstWhere((x) => x.name == '空账本');
    await state.setCurrentBook(b.id);
    await tester.pumpAndSettle();
    expect(find.text('¥1,000.00'), findsNothing);
    expect(find.text('¥0.00'), findsWidgets);
  });

  test('预算按账本独立', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.setBudget(100000); // 默认账本 ¥1000
    expect(state.monthlyBudget, 100000);

    await state.addBook('工作');
    final work = state.books.firstWhere((b) => b.name == '工作');
    await state.setCurrentBook(work.id);
    expect(state.monthlyBudget, 0);
    await state.setBudget(200000); // 工作账本 ¥2000
    expect(state.monthlyBudget, 200000);

    await state.setCurrentBook('default');
    expect(state.monthlyBudget, 100000);

    // 重启持久化
    final state2 = AppState();
    await state2.load();
    expect(state2.monthlyBudget, 100000);
    await state2.setCurrentBook(work.id);
    expect(state2.monthlyBudget, 200000);

    // 删除账本后预算清理
    await state2.removeBook(work.id);
    await state2.setCurrentBook('default');
    expect(state2.monthlyBudget, 100000);
  });

  testWidgets('明细日期范围筛选入口与清除', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'r1',
      type: TxType.expense,
      amount: 1100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 1),
      note: '一号',
    ));
    await state.addTransaction(Transaction(
      id: 'r2',
      type: TxType.expense,
      amount: 2200,
      categoryId: 'transport',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '今天',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.text('日期：全部日期'), findsOneWidget);

    // 打开范围：预设「近 7 天」
    await tester.tap(find.textContaining('日期：'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('近 7 天'));
    await tester.pumpAndSettle();
    expect(find.textContaining('~ '), findsOneWidget);
    expect(find.textContaining('今天'), findsWidgets);
    // 8月1日的行在列表下方，先滚动到可见
    await tester.drag(
      find.byType(ListView).first,
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('一号'), findsWidgets);

    // 清除范围
    await tester.tap(find.text('清除'));
    await tester.pumpAndSettle();
    expect(find.text('日期：全部日期'), findsOneWidget);
  });

  test('最近使用分类与账本重命名', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'n1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 1),
    ));
    await state.addTransaction(Transaction(
      id: 'n2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'transport',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 2),
    ));
    // 最近分类按时间倒序
    expect(state.recentCategoryIds(TxType.expense), ['transport', 'food']);
    expect(state.recentCategoryIds(TxType.income), isEmpty);

    // 账本重命名
    await state.addBook('工作');
    final work = state.books.firstWhere((b) => b.name == '工作');
    await state.renameBook(work.id, '上班');
    expect(state.books.any((b) => b.name == '上班'), isTrue);
    expect(state.books.any((b) => b.name == '工作'), isFalse);
  });

  testWidgets('记一笔显示最近使用分类', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'n3',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 1),
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    expect(find.text('最近'), findsOneWidget);
    expect(find.text('餐饮'), findsWidgets);
  });

  test('预算通知开关持久化', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    expect(state.budgetNotify, isTrue);
    await state.setBudgetNotify(false);
    expect(state.budgetNotify, isFalse);
    final state2 = AppState();
    await state2.load();
    expect(state2.budgetNotify, isFalse);
  });

  testWidgets('明细全部时间视图', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'a1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 3),
      note: '本月流水',
    ));
    await state.addTransaction(Transaction(
      id: 'a2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month - 1, 10),
      note: '上月流水',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.textContaining('本月流水'), findsWidgets);
    expect(find.textContaining('上月流水'), findsNothing);
    // 切到全部时间
    await tester.tap(find.text('本月').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('上月流水'),
      200,
      scrollable: find.descendant(
        of: find.byType(LedgerPage),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('上月流水'), findsWidgets);
  });

  test('周支出聚合', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    // 8 月第 1 天 100 分，第 8 天 200 分
    await state.addTransaction(Transaction(
      id: 'w1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2026, 8, 1),
    ));
    await state.addTransaction(Transaction(
      id: 'w2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2026, 8, 8),
    ));
    final weekly = state.weeklyExpenseSeries(DateTime(2026, 8));
    expect(weekly.length, greaterThanOrEqualTo(2));
    expect(weekly[0].amount, 100);
    expect(weekly[1].amount, 200);
    expect(weekly[0].label, '第1周');
  });

  test('每日记账提醒开关持久化', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    expect(state.dailyReminder, isFalse);
    await state.setDailyReminder(true);
    expect(state.dailyReminder, isTrue);
    final state2 = AppState();
    await state2.load();
    expect(state2.dailyReminder, isTrue);
  });

  test('周期记账提醒开关持久化', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    expect(state.recurringRemind, isTrue);
    await state.setRecurringRemind(false);
    expect(state.recurringRemind, isFalse);
    final state2 = AppState();
    await state2.load();
    expect(state2.recurringRemind, isFalse);
  });

  testWidgets('记一笔复制上一条', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'c1',
      type: TxType.expense,
      amount: 1250,
      categoryId: 'transport',
      accountId: 'card',
      date: DateTime(now.year, now.month, now.day),
      note: '地铁',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    expect(find.text('复制上一条'), findsOneWidget);
    await tester.tap(find.text('复制上一条'));
    await tester.pumpAndSettle();
    // 金额输入框应显示 12.50
    expect(find.text('12.50'), findsOneWidget);
  });

  test('本周概览 weekSummary', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    // 今天一笔支出
    await state.addTransaction(Transaction(
      id: 'wd1',
      type: TxType.expense,
      amount: 5000,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
    ));
    // 上周一笔支出（不应计入本周）
    await state.addTransaction(Transaction(
      id: 'wd2',
      type: TxType.expense,
      amount: 9000,
      categoryId: 'food',
      accountId: 'alipay',
      date: now.subtract(const Duration(days: 8)),
    ));
    final week = state.weekSummary;
    expect(week, isNotNull);
    expect(week!.expense, 5000);
  });

  test('本周支出分类排行 weekCategoryRanking', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));
    // 本周：餐饮 500、购物 300
    await state.addTransaction(Transaction(
      id: 'wcr1',
      type: TxType.expense,
      amount: 500,
      categoryId: 'food',
      accountId: 'alipay',
      date: monday,
    ));
    await state.addTransaction(Transaction(
      id: 'wcr2',
      type: TxType.expense,
      amount: 300,
      categoryId: 'shopping',
      accountId: 'alipay',
      date: today,
    ));
    // 上周：餐饮 9999（不应计入本周）
    await state.addTransaction(Transaction(
      id: 'wcr3',
      type: TxType.expense,
      amount: 9999,
      categoryId: 'food',
      accountId: 'alipay',
      date: monday.subtract(const Duration(days: 7)),
    ));
    final ranking = state.weekCategoryRanking();
    expect(ranking.length, 2);
    expect(ranking[0].category.name, '餐饮');
    expect(ranking[0].amount, 500);
    expect(ranking[1].category.name, '购物');
    expect(ranking[1].amount, 300);
  });

  testWidgets('首页切换本周概览', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addTransaction(Transaction(
      id: 'hd1',
      type: TxType.expense,
      amount: 8800,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime.now(),
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('本月支出'), findsOneWidget);
    expect(find.text('本月支出分类'), findsOneWidget);
    await tester.tap(find.text('本周'));
    await tester.pumpAndSettle();
    expect(find.text('本周支出'), findsOneWidget);
    expect(find.text('本周支出分类'), findsOneWidget);
    expect(find.text('¥88.00'), findsWidgets);
  });

  testWidgets('明细长按复制为新的账目', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'lp1',
      type: TxType.expense,
      amount: 1500,
      categoryId: 'transport',
      accountId: 'card',
      date: DateTime(now.year, now.month, now.day),
      note: '地铁',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('地铁'));
    await tester.pumpAndSettle();
    expect(find.text('复制为新的账目'), findsOneWidget);
    await tester.tap(find.text('复制为新的账目'));
    await tester.pumpAndSettle();
    // 进入记一笔，金额已预填 15.00
    expect(find.text('15.00'), findsOneWidget);
    // 保存新增
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(state.transactions.length, 2);
  });

  test('每日收入序列 dailyIncomeSeries', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addTransaction(Transaction(
      id: 'inc1',
      type: TxType.income,
      amount: 3000,
      categoryId: 'salary',
      accountId: 'card',
      date: DateTime(2026, 8, 15),
    ));
    final s = state.dailyIncomeSeries(DateTime(2026, 8));
    expect(s.length, 31);
    expect(s[14], 3000);
    expect(s[0], 0);
  });

  test('JSON 全量备份与恢复', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addTransaction(Transaction(
      id: 'j1',
      type: TxType.expense,
      amount: 1234,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2026, 8, 6),
      note: 'json备份',
    ));
    await state.addBook('备份账本');
    await state.setBudget(50000);
    final json = state.exportJson();
    expect(json, contains('j1'));
    expect(json, contains('备份账本'));

    // 新实例恢复
    final state2 = AppState();
    await state2.load();
    await state2.clearAll();
    final err = await state2.importJson(json);
    expect(err, isNull);
    expect(state2.transactions.length, 1);
    expect(state2.transactions.first.note, 'json备份');
    expect(state2.books.any((b) => b.name == '备份账本'), isTrue);
    expect(state2.monthlyBudget, 50000);
  });

  testWidgets('明细按账户筛选', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'acc1',
      type: TxType.expense,
      amount: 1100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 3),
      note: '支付宝流水',
    ));
    await state.addTransaction(Transaction(
      id: 'acc2',
      type: TxType.expense,
      amount: 2200,
      categoryId: 'food',
      accountId: 'card',
      date: DateTime(now.year, now.month, 4),
      note: '银行卡流水',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.textContaining('支付宝流水'), findsWidgets);
    expect(find.textContaining('银行卡流水'), findsWidgets);
    await tester.tap(find.text('银行卡'));
    await tester.pumpAndSettle();
    expect(find.textContaining('银行卡流水'), findsWidgets);
    expect(find.textContaining('支付宝流水'), findsNothing);
  });

  testWidgets('记一笔常用金额快捷', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('+50'));
    await tester.pumpAndSettle();
    expect(find.text('50.00'), findsOneWidget);
    await tester.tap(find.text('+100'));
    await tester.pumpAndSettle();
    expect(find.text('150.00'), findsOneWidget);
  });

  testWidgets('统计页支出占比环图', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('支出占比'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('支出占比'), findsOneWidget);
  });

  testWidgets('我的账户点查看流水进入筛选后的明细', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'al1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 3),
      note: '支付宝A',
    ));
    await state.addTransaction(Transaction(
      id: 'al2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'food',
      accountId: 'card',
      date: DateTime(now.year, now.month, 4),
      note: '银行卡B',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('支付宝'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('支付宝'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看该账户流水'));
    await tester.pumpAndSettle();
    expect(find.text('支付宝 · 流水'), findsOneWidget);
    expect(find.textContaining('支付宝A'), findsWidgets);
    expect(find.textContaining('银行卡B'), findsNothing);
  });

  testWidgets('大字体 2.0x 无障碍冒烟：四页与记一笔无溢出', (tester) async {
    Intl.defaultLocale = 'zh_CN';
    await initializeDateFormatting('zh_CN');
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(
        tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    Future<void> pumpPage(Widget page) async {
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: page),
        ),
      ));
      await tester.pumpAndSettle();
    }
    await pumpPage(
        HomePage(
            onAdd: () {},
            onGoLedger: () {},
            onGoStats: () {},
            onGoProfile: () {},
          ));
    await pumpPage(const LedgerPage());
    await pumpPage(const StatsPage());
    await pumpPage(const ProfilePage());
    await pumpPage(const AddTransactionPage());
  });

  test('记一笔记住上次账户', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    expect(state.lastAccountId, 'alipay');
    await state.addTransaction(Transaction(
      id: 'la1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'card',
      date: DateTime(2026, 8, 6),
    ));
    expect(state.lastAccountId, 'card');
    final state2 = AppState();
    await state2.load();
    expect(state2.lastAccountId, 'card');
  });

  test('年度对比 yearComparison', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    // 2026 年 3 月支出 5000，2025 年 3 月支出 3000
    await state.addTransaction(Transaction(
      id: 'y1',
      type: TxType.expense,
      amount: 5000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2026, 3, 10),
    ));
    await state.addTransaction(Transaction(
      id: 'y2',
      type: TxType.expense,
      amount: 3000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2025, 3, 15),
    ));
    final cmp = state.yearComparison(2026);
    expect(cmp.length, 12);
    expect(cmp[2].month, 3);
    expect(cmp[2].thisYear, 5000);
    expect(cmp[2].lastYear, 3000);
    expect(cmp[0].thisYear, 0);
    // 收入对比：2026 年 3 月收入 9000，2025 年 3 月收入 4000
    await state.addTransaction(Transaction(
      id: 'y3',
      type: TxType.income,
      amount: 9000,
      categoryId: 'salary',
      accountId: 'alipay',
      date: DateTime(2026, 3, 12),
    ));
    await state.addTransaction(Transaction(
      id: 'y4',
      type: TxType.income,
      amount: 4000,
      categoryId: 'salary',
      accountId: 'alipay',
      date: DateTime(2025, 3, 16),
    ));
    final inc = state.yearComparison(2026, income: true);
    expect(inc[2].thisYear, 9000);
    expect(inc[2].lastYear, 4000);
    // 支出对比不受收入影响
    expect(state.yearComparison(2026)[2].thisYear, 5000);
  });

  test('本月小结文本 monthSummaryText', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addTransaction(Transaction(
      id: 's1',
      type: TxType.expense,
      amount: 5000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2026, 8, 6),
    ));
    await state.addTransaction(Transaction(
      id: 's2',
      type: TxType.income,
      amount: 20000,
      categoryId: 'salary',
      accountId: 'card',
      date: DateTime(2026, 8, 10),
    ));
    final text = state.monthSummaryText(DateTime(2026, 8));
    expect(text, contains('2026年8月 记账小结'));
    expect(text, contains('收入：200.00'));
    expect(text, contains('支出：50.00'));
    expect(text, contains('结余：150.00'));
    expect(text, contains('笔数：2 笔'));
    expect(text, contains('支出最多：餐饮 50.00'));
  });

 
  testWidgets('明细多选批量删除', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'm1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '待删1',
    ));
    await state.addTransaction(Transaction(
      id: 'm2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '待删2',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    // 长按进入多选
    await tester.longPress(find.textContaining('待删1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('多选删除'));
    await tester.pumpAndSettle();
    expect(find.text('已选 0 项'), findsOneWidget);
    // 全选
    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    expect(find.text('已选 2 项'), findsOneWidget);
    // 删除
    await tester.tap(find.byTooltip('删除选中'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(state.transactions, isEmpty);
    // 删除后退出多选，标题恢复
    expect(find.text('明细'), findsWidgets);
  });
 
  testWidgets('明细搜索按金额匹配', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'amt1',
      type: TxType.expense,
      amount: 4200,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '午餐',
    ));
    await state.addTransaction(Transaction(
      id: 'amt2',
      type: TxType.expense,
      amount: 1500,
      categoryId: 'transport',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '地铁',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    // 搜索金额 42 → 只显示 42.00 的流水
    await tester.enterText(find.byType(TextField).first, '42');
    await tester.pumpAndSettle();
    expect(find.textContaining('午餐'), findsWidgets);
    expect(find.textContaining('地铁'), findsNothing);
  });

  test('CsvExporter 头部信息行可被导入跳过', () {
    final txs = [
      Transaction(
        id: 'meta1',
        type: TxType.expense,
        amount: 100,
        categoryId: 'food',
        accountId: 'alipay',
        date: DateTime(2026, 8, 6),
      ),
    ];
    final csv = CsvExporter.exportCsv(
      txs,
      metaLines: ['导出时间：20260807', '范围：全部'],
    );
    expect(csv, contains('# 导出时间：20260807'));
    final r = CsvImporter.parseCsv(csv);
    expect(r.transactions.length, 1);
    expect(r.errors, isEmpty);
  });
 
  test('本周小结文本 weekSummaryText', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addTransaction(Transaction(
      id: 'wks1',
      type: TxType.expense,
      amount: 3000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime.now(),
    ));
    final text = state.weekSummaryText();
    expect(text, contains('本周记账小结'));
    expect(text, contains('支出：30.00'));
    expect(text, contains('笔数：1 笔'));
  });

  testWidgets('明细合计条显示结余', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'bl1',
      type: TxType.expense,
      amount: 500,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
    ));
    await state.addTransaction(Transaction(
      id: 'bl2',
      type: TxType.income,
      amount: 2000,
      categoryId: 'salary',
      accountId: 'card',
      date: DateTime(now.year, now.month, now.day),
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    // 合计条：支出 5.00 收入 20.00 结余 15.00
    expect(find.textContaining('结余'), findsWidgets);
    expect(find.textContaining('¥15.00'), findsWidgets);
  });
 
  testWidgets('记一笔日期快捷（今天/昨天）渲染', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    expect(find.text('今天'), findsWidgets);
    expect(find.text('昨天'), findsWidgets);
  });
 
  test('账本图标持久化', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.addBook('旅行', iconKey: 'flight');
    final book = state.books.firstWhere((b) => b.name == '旅行');
    expect(book.iconKey, 'flight');
    final state2 = AppState();
    await state2.load();
    final book2 = state2.books.firstWhere((b) => b.name == '旅行');
    expect(book2.iconKey, 'flight');
  });

  test('最近搜索去重置顶', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.recordSearch('咖啡');
    await state.recordSearch('地铁');
    await state.recordSearch('咖啡');
    expect(state.recentSearches, ['咖啡', '地铁']);
    await state.clearRecentSearches();
    expect(state.recentSearches, isEmpty);
  });
 
  testWidgets('明细按金额排序', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    await state.addTransaction(Transaction(
      id: 'srt1',
      type: TxType.expense,
      amount: 500,
      categoryId: 'food',
      accountId: 'alipay',
      date: today,
      note: '今日小额',
    ));
    await state.addTransaction(Transaction(
      id: 'srt2',
      type: TxType.expense,
      amount: 9000,
      categoryId: 'food',
      accountId: 'alipay',
      date: yesterday,
      note: '昨日大额',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    // 默认日期排序：今天的小额在前
    expect(
      tester
          .widgetList<TransactionTile>(find.byType(TransactionTile))
          .first
          .transaction
          .amount,
      500,
    );
    // 切到金额排序
    await tester.tap(find.text('日期'));
    await tester.pumpAndSettle();
    // 金额排序后跨天大额在前：第一个 TransactionTile 金额应 90.00
    final first =
        tester.widgetList<TransactionTile>(find.byType(TransactionTile)).first;
    expect(first.transaction.amount, 9000);
  });

  testWidgets('记一笔金额清除按钮', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '88');
    await tester.pumpAndSettle();
    expect(find.text('88'), findsOneWidget);
    await tester.tap(find.byTooltip('清除金额'));
    await tester.pumpAndSettle();
    expect(find.text('88'), findsNothing);
  });
  test('转账：余额双向变动、不计收支、总资产不变', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.setAccountInitialBalance('alipay', 10000);
    await state.setAccountInitialBalance('wechat', 20000);
    final tx = Transaction(
      id: 'tr1',
      type: TxType.transfer,
      amount: 5000,
      categoryId: 'transfer',
      accountId: 'alipay',
      transferToAccountId: 'wechat',
      date: DateTime(2026, 8, 6),
    );
    await state.addTransaction(tx);
    Account accountOf(String id) =>
        state.accounts.firstWhere((a) => a.id == id);
    expect(state.balanceOf(accountOf('alipay')), 5000);
    expect(state.balanceOf(accountOf('wechat')), 25000);
    expect(state.totalAssets, 30000);
    final s = state.summaryOf(DateTime(2026, 8));
    expect(s.expense, 0);
    expect(s.income, 0);
    // 编辑转账：改方向后余额随之变化
    await state.updateTransaction(tx.copyWith(
      accountId: 'wechat',
      transferToAccountId: 'alipay',
    ));
    expect(state.balanceOf(accountOf('alipay')), 15000);
    expect(state.balanceOf(accountOf('wechat')), 15000);
  });

  test('CSV 导出/导入支持转账往返', () {
    final tx = Transaction(
      id: 'tr2',
      type: TxType.transfer,
      amount: 3000,
      categoryId: 'transfer',
      accountId: 'alipay',
      transferToAccountId: 'wechat',
      date: DateTime(2026, 8, 7, 10, 30),
      note: '还钱',
    );
    final csv = CsvExporter.exportCsv([tx]);
    expect(csv.contains('转账'), isTrue);
    expect(csv.contains('微信'), isTrue); // 转入账户列
    final result = CsvImporter.parseCsv(csv);
    expect(result.errors, isEmpty);
    expect(result.transactions.length, 1);
    final back = result.transactions.first;
    expect(back.type, TxType.transfer);
    expect(back.accountId, 'alipay');
    expect(back.transferToAccountId, 'wechat');
    expect(back.amount, 3000);
  });

  testWidgets('明细页转账显示且不计入合计', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'w1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '午饭',
    ));
    await state.addTransaction(Transaction(
      id: 'w2',
      type: TxType.transfer,
      amount: 5000,
      categoryId: 'transfer',
      accountId: 'alipay',
      transferToAccountId: 'wechat',
      date: DateTime(now.year, now.month, now.day),
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.text('转账'), findsOneWidget);
    // 合计只算支出 ¥10，转账不计收支（收入为 0 不显示）
    expect(find.text('共 2 笔'), findsOneWidget);
    expect(find.text('支出 '), findsOneWidget);
    expect(find.text('收入 '), findsNothing); // 转账不计收入
  });

  testWidgets('记一笔转账模式显示转出/转入账户', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('转账'));
    await tester.pumpAndSettle();
    expect(find.text('转出账户'), findsOneWidget);
    expect(find.text('转入账户'), findsOneWidget);
    expect(find.text('转账仅调整账户余额，不计入收支统计'), findsOneWidget);
  });
  testWidgets('明细页分类筛选', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'cf1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '午饭',
    ));
    await state.addTransaction(Transaction(
      id: 'cf2',
      type: TxType.expense,
      amount: 2000,
      categoryId: 'transport',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '打车',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    // 默认全部：两条都在
    expect(find.textContaining('午饭'), findsOneWidget);
    expect(find.textContaining('打车'), findsOneWidget);
    // 点「餐饮」分类 chip（头部筛选行在流水行之前）
    await tester.tap(find.text('餐饮').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('午饭'), findsOneWidget);
    expect(find.textContaining('打车'), findsNothing);
    // 点「全部分类」恢复
    await tester.tap(find.text('全部分类'));
    await tester.pumpAndSettle();
    expect(find.textContaining('打车'), findsOneWidget);
  });

  testWidgets('明细页支持 initialCategoryId 预选分类（统计下钻入口）', (tester) async {
    Intl.defaultLocale = 'zh_CN';
    await initializeDateFormatting('zh_CN');
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'dr1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '午饭',
    ));
    await state.addTransaction(Transaction(
      id: 'dr2',
      type: TxType.expense,
      amount: 2000,
      categoryId: 'transport',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '打车',
    ));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider.value(
          value: state,
          child: LedgerPage(initialCategoryId: 'food'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // 预选「餐饮」分类：合计只剩 1 笔（午饭）
    expect(find.text('共 1 笔'), findsOneWidget);
    // 点「全部分类」恢复：合计回到 2 笔
    await tester.tap(find.text('全部分类'));
    await tester.pumpAndSettle();
    expect(find.text('共 2 笔'), findsOneWidget);
  });
  testWidgets('明细金额区间筛选', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'am1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '小额',
    ));
    await state.addTransaction(Transaction(
      id: 'am2',
      type: TxType.expense,
      amount: 2000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '中额',
    ));
    await state.addTransaction(Transaction(
      id: 'am3',
      type: TxType.expense,
      amount: 5000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '大额',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.text('共 3 笔'), findsOneWidget);
    // 打开金额区间弹层
    await tester.tap(find.textContaining('金额：全部金额'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField).evaluate().length, 3); // 搜索 + 最低 + 最高
    await tester.enterText(find.byType(TextField).at(1), '10');
    await tester.enterText(find.byType(TextField).at(2), '30');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    // 只保留 ¥20
    expect(find.text('共 1 笔'), findsOneWidget);
    expect(find.textContaining('中额'), findsOneWidget);
    expect(find.textContaining('小额'), findsNothing);
    expect(find.textContaining('大额'), findsNothing);
    // 清除金额筛选
    await tester.tap(find.text('清除'));
    await tester.pumpAndSettle();
    expect(find.text('共 3 笔'), findsOneWidget);
  });

  testWidgets('明细搜索支持账户名', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'ac1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '流水A',
    ));
    await state.addTransaction(Transaction(
      id: 'ac2',
      type: TxType.expense,
      amount: 2000,
      categoryId: 'transport',
      accountId: 'wechat',
      date: DateTime(now.year, now.month, now.day),
      note: '流水B',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.text('共 2 笔'), findsOneWidget);
    // 搜索账户名「支付宝」：只命中支付宝账户的流水
    await tester.enterText(find.byType(TextField).first, '支付宝');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('共 1 笔'), findsOneWidget);
    expect(find.textContaining('流水A'), findsOneWidget);
    expect(find.textContaining('流水B'), findsNothing);
  });
  testWidgets('统计柱状图查看当日流水', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'dd1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 5),
      note: '当天午餐',
    ));
    await state.addTransaction(Transaction(
      id: 'dd2',
      type: TxType.expense,
      amount: 2000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 5),
      note: '当天晚餐',
    ));
    await state.addTransaction(Transaction(
      id: 'dd3',
      type: TxType.expense,
      amount: 500,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 10),
      note: '其他日',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();
    // 滚动到每日图表 caption 的「查看流水」入口
    await tester.scrollUntilVisible(
      find.text('查看流水'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看流水'));
    await tester.pumpAndSettle();
    // 默认选中支出最高的一天（5 日）：弹层显示当日两笔，不含其他日
    expect(find.textContaining('当天午餐'), findsOneWidget);
    expect(find.textContaining('当天晚餐'), findsOneWidget);
    expect(find.textContaining('其他日'), findsNothing);
  });
  testWidgets('记一笔常用备注快捷填充', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('午餐'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('午餐'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '午餐'), findsOneWidget);
  });

  testWidgets('我的页账户显示本月支出/收入/笔数', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'p1',
      type: TxType.expense,
      amount: 1200,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 3),
      note: '午饭',
    ));
    await state.addTransaction(Transaction(
      id: 'p2',
      type: TxType.income,
      amount: 5000,
      categoryId: 'salary',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 5),
      note: '工资',
    ));
    await state.addTransaction(Transaction(
      id: 'p3',
      type: TxType.expense,
      amount: 800,
      categoryId: 'food',
      accountId: 'wechat',
      date: DateTime(now.year, now.month, 6),
      note: '早餐',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    // 支付宝：本月支出 12.00 · 收入 50.00 · 2 笔
    expect(find.textContaining('本月支出 12.00'), findsOneWidget);
    expect(find.textContaining('收入 50.00'), findsOneWidget);
    expect(find.textContaining('2 笔'), findsOneWidget);
    // 微信：本月支出 8.00 · 1 笔
    expect(find.textContaining('本月支出 8.00'), findsOneWidget);
  });
  test('周期日期推进（含月末钳制）', () {
    expect(RecurringRule.nextAfter(DateTime(2026, 8, 15), RecurFrequency.weekly),
        DateTime(2026, 8, 22));
    expect(RecurringRule.nextAfter(DateTime(2026, 8, 31), RecurFrequency.monthly),
        DateTime(2026, 9, 30));
    expect(RecurringRule.nextAfter(DateTime(2026, 1, 31), RecurFrequency.monthly),
        DateTime(2026, 2, 28));
    expect(RecurringRule.nextAfter(DateTime(2024, 1, 31), RecurFrequency.monthly),
        DateTime(2024, 2, 29));
    expect(RecurringRule.nextAfter(DateTime(2026, 8, 15), RecurFrequency.yearly),
        DateTime(2027, 8, 15));
  });

  test('周期规则生成到期流水且不重复', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addRecurringRule(RecurringRule(
      id: 'rr1',
      type: TxType.expense,
      amount: 100000,
      categoryId: 'home',
      accountId: 'alipay',
      note: '房租',
      date: DateTime(now.year, now.month - 2, 1),
      nextDate: DateTime(now.year, now.month - 1, 1),
      frequency: RecurFrequency.monthly,
    ));
    await state.addRecurringRule(RecurringRule(
      id: 'rr2',
      type: TxType.expense,
      amount: 5000,
      categoryId: 'food',
      accountId: 'wechat',
      note: '停用规则',
      date: DateTime(now.year, now.month - 2, 1),
      nextDate: DateTime(now.year, now.month - 1, 1),
      frequency: RecurFrequency.monthly,
      active: false,
    ));
    final before = state.transactions.length;
    // 上月 1 日 + 本月 1 日两期（今天必然 >= 1 日）
    final generated = await state.generateDueRecurring();
    expect(generated, 2);
    expect(state.transactions.length, before + 2);
    expect(state.transactions.where((t) => t.note == '房租').length, 2);
    expect(state.transactions.where((t) => t.note == '停用规则'), isEmpty);
    // 再次生成不重复
    expect(await state.generateDueRecurring(), 0);
    // nextDate 已推进到未来
    expect(
        state.recurringRules.first.nextDate.isAfter(DateTime(now.year, now.month, now.day)),
        isTrue);
  });

  test('周期规则持久化往返', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = TransactionRepository();
    await repo.saveRecurringRules([
      RecurringRule(
        id: 'rt1',
        type: TxType.expense,
        amount: 100000,
        categoryId: 'home',
        accountId: 'alipay',
        note: '房租',
        date: DateTime(2026, 8, 1),
        nextDate: DateTime(2026, 9, 1),
        frequency: RecurFrequency.monthly,
      ),
    ]);
    final loaded = await repo.loadRecurringRules();
    expect(loaded.length, 1);
    expect(loaded.first.frequency, RecurFrequency.monthly);
    expect(loaded.first.amount, 100000);
    expect(loaded.first.nextDate, DateTime(2026, 9, 1));
  });

  testWidgets('记一笔设置周期并保存创建规则', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('周期'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('周期'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('每月'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '100');
    await tester.ensureVisible(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(state.recurringRules.length, 1);
    expect(state.recurringRules.first.frequency, RecurFrequency.monthly);
  });

  testWidgets('我的页显示周期记账区块', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addRecurringRule(RecurringRule(
      id: 'pr1',
      type: TxType.expense,
      amount: 100000,
      categoryId: 'home',
      accountId: 'alipay',
      note: '房租',
      date: DateTime(2026, 8, 1),
      nextDate: DateTime(2026, 9, 1),
      frequency: RecurFrequency.monthly,
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('周期记账'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('周期记账'), findsOneWidget);
    expect(find.textContaining('每月 · 居住'), findsOneWidget);
    expect(find.textContaining('下次 9月1日'), findsOneWidget);
  });
  test('周期规则 copyWith 支持编辑字段', () {
    final r = RecurringRule(
      id: 'cw1',
      type: TxType.expense,
      amount: 100000,
      categoryId: 'home',
      accountId: 'alipay',
      note: '房租',
      date: DateTime(2026, 8, 1),
      nextDate: DateTime(2026, 9, 1),
      frequency: RecurFrequency.monthly,
    );
    final edited = r.copyWith(
      amount: 500,
      categoryId: 'food',
      frequency: RecurFrequency.weekly,
      nextDate: DateTime(2026, 9, 8),
    );
    expect(edited.id, r.id);
    expect(edited.amount, 500);
    expect(edited.categoryId, 'food');
    expect(edited.frequency, RecurFrequency.weekly);
    expect(edited.nextDate, DateTime(2026, 9, 8));
    // id 可覆盖（复制规则用）
    final copied = r.copyWith(id: 'cw2', note: '房租（副本）');
    expect(copied.id, 'cw2');
    expect(copied.note, '房租（副本）');
    expect(copied.amount, r.amount);
  });

  testWidgets('编辑周期规则保存生效', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addRecurringRule(RecurringRule(
      id: 'er1',
      type: TxType.expense,
      amount: 100000,
      categoryId: 'home',
      accountId: 'alipay',
      note: '房租',
      date: DateTime(2026, 8, 1),
      nextDate: DateTime(2026, 9, 1),
      frequency: RecurFrequency.monthly,
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    // 滚动到周期记账区块并点击规则行
    await tester.scrollUntilVisible(
      find.textContaining('每月 · 居住'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('每月 · 居住'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('每月 · 居住'));
    await tester.pumpAndSettle();
    expect(find.text('编辑周期规则'), findsOneWidget);
    // 改金额 2000 元、频率改为每年
    await tester.enterText(
        find.widgetWithText(TextField, '金额（元）'), '2000');
    await tester.tap(find.text('每年'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(state.recurringRules.first.amount, 200000);
    expect(state.recurringRules.first.frequency, RecurFrequency.yearly);
    expect(state.recurringRules.first.note, '房租');
  });
  test('周期规则后续发生日期预览', () {
    final monthly = RecurringRule.nextOccurrences(
        DateTime(2026, 9, 1), RecurFrequency.monthly,
        count: 3);
    expect(monthly, [
      DateTime(2026, 10, 1),
      DateTime(2026, 11, 1),
      DateTime(2026, 12, 1),
    ]);
    final weekly = RecurringRule.nextOccurrences(
        DateTime(2026, 8, 8), RecurFrequency.weekly,
        count: 2);
    expect(weekly, [DateTime(2026, 8, 15), DateTime(2026, 8, 22)]);
  });

  testWidgets('金额区间快捷预设筛选', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'ap1',
      type: TxType.expense,
      amount: 5000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '五十',
    ));
    await state.addTransaction(Transaction(
      id: 'ap2',
      type: TxType.expense,
      amount: 20000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '两百',
    ));
    await state.addTransaction(Transaction(
      id: 'ap3',
      type: TxType.expense,
      amount: 80000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '八百',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.text('共 3 笔'), findsOneWidget);
    await tester.tap(find.textContaining('金额：全部金额'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('100 ~ 500'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    // 100~500 元 → 只剩 ¥200
    expect(find.text('共 1 笔'), findsOneWidget);
    expect(find.textContaining('两百'), findsOneWidget);
    expect(find.textContaining('五十'), findsNothing);
    expect(find.textContaining('八百'), findsNothing);
  });
  testWidgets('明细多选批量修改账户', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'b1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'wechat',
      date: DateTime(now.year, now.month, now.day),
      note: '流水甲',
    ));
    await state.addTransaction(Transaction(
      id: 'b2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'food',
      accountId: 'wechat',
      date: DateTime(now.year, now.month, now.day),
      note: '流水乙',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('流水甲'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('多选删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    expect(find.text('已选 2 项'), findsOneWidget);
    await tester.tap(find.byTooltip('修改选中'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改账户'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('支付宝').last);
    await tester.pumpAndSettle();
    expect(state.transactions.every((t) => t.accountId == 'alipay'), isTrue);
    expect(find.text('已选 0 项'), findsNothing);
  });

  testWidgets('明细多选批量修改分类', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'bc1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'transport',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '分类甲',
    ));
    await state.addTransaction(Transaction(
      id: 'bc2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'shopping',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '分类乙',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('分类甲'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('多选删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    expect(find.text('已选 2 项'), findsOneWidget);
    await tester.tap(find.byTooltip('修改选中'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改分类'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('餐饮').last);
    await tester.pumpAndSettle();
    expect(state.transactions.every((t) => t.categoryId == 'food'), isTrue);
    expect(find.text('已选 0 项'), findsNothing);
  });
  testWidgets('统计页显示预算对比', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'bg1',
      type: TxType.expense,
      amount: 68000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '支出',
    ));
    await state.setBudget(100000); // 1000 元
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('预算对比'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('预算对比'), findsOneWidget);
    expect(find.textContaining('已用 68%'), findsOneWidget);
    expect(find.textContaining('剩余'), findsOneWidget);
  });
  test('周期规则立即生成本次且不重复', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await state.addRecurringRule(RecurringRule(
      id: 'gn1',
      type: TxType.expense,
      amount: 100000,
      categoryId: 'home',
      accountId: 'alipay',
      note: '房租',
      date: today,
      nextDate: DateTime(now.year, now.month, now.day + 5),
      frequency: RecurFrequency.monthly,
    ));
    final before = state.transactions.length;
    await state.generateRecurringNow('gn1');
    expect(state.transactions.length, before + 1);
    expect(state.transactions.first.note, '房租');
    expect(state.transactions.first.date, today);
    // nextDate 已推进到未来，正常补生成不再产生新流水
    final after = state.transactions.length;
    await state.generateDueRecurring();
    expect(state.transactions.length, after);
  });

  testWidgets('我的页周期规则可立即生成本次', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await state.addRecurringRule(RecurringRule(
      id: 'gn2',
      type: TxType.expense,
      amount: 5000,
      categoryId: 'food',
      accountId: 'wechat',
      note: '订阅',
      date: today,
      nextDate: DateTime(now.year, now.month, now.day + 3),
      frequency: RecurFrequency.weekly,
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('每周 · 餐饮'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('立即生成本次'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('立即生成本次'));
    await tester.pumpAndSettle();
    expect(state.transactions.any((t) => t.note == '订阅'), isTrue);
    expect(state.transactions.first.date, today);
  });
  test('自定义账户增删改与名称映射', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final before = state.accounts.length;
    await state.addAccount(name: '招商卡', iconKey: 'card_gift');
    expect(state.accounts.length, before + 1);
    final added = state.accounts.last;
    expect(added.isCustom, isTrue);
    expect(accountById(added.id).name, '招商卡');
    expect(accountIdByName('招商卡'), added.id);
    // 重命名
    await state.renameAccount(added.id, '招行卡', iconKey: 'laptop');
    expect(state.accounts.last.name, '招行卡');
    expect(accountIdByName('招行卡'), added.id);
    // 有流水禁止删除
    await state.addTransaction(Transaction(
      id: 'at1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: added.id,
      date: DateTime(2026, 8, 1),
    ));
    expect(await state.removeAccount(added.id), isFalse);
    // 无流水可删除
    await state.deleteTransaction('at1');
    expect(await state.removeAccount(added.id), isTrue);
    expect(state.accounts.length, before);
    expect(accountIdByName('招行卡'), isNull);
  });

  testWidgets('我的页新增自定义账户', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('新增账户'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, '账户名称'), '招商卡');
    await tester.ensureVisible(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(state.accounts.any((a) => a.name == '招商卡'), isTrue);
    expect(find.text('招商卡'), findsOneWidget);
  });
  test('yearSummary 年度汇总计算', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addTransaction(Transaction(
      id: 'y1',
      type: TxType.expense,
      amount: 10000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2026, 1, 15),
      note: '一月',
    ));
    await state.addTransaction(Transaction(
      id: 'y2',
      type: TxType.expense,
      amount: 20000,
      categoryId: 'home',
      accountId: 'alipay',
      date: DateTime(2026, 6, 10),
      note: '六月',
    ));
    await state.addTransaction(Transaction(
      id: 'y3',
      type: TxType.income,
      amount: 50000,
      categoryId: 'salary',
      accountId: 'alipay',
      date: DateTime(2026, 3, 1),
      note: '工资',
    ));
    await state.addTransaction(Transaction(
      id: 'y4',
      type: TxType.expense,
      amount: 999,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2025, 12, 31),
      note: '去年',
    ));
    final ys = state.yearSummary(2026);
    expect(ys.expense, 30000);
    expect(ys.income, 50000);
    expect(ys.count, 3);
    expect(ys.topCategoryName, '居住');
    expect(ys.dailyExpense, 30000 ~/ 365);
  });

  testWidgets('统计页显示年度汇总', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'wy1',
      type: TxType.expense,
      amount: 10000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 15),
      note: '本月一笔',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('${now.year} 年汇总'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('${now.year} 年汇总'), findsOneWidget);
    expect(find.text('总支出'), findsOneWidget);
    expect(find.textContaining('全年 1 笔'), findsOneWidget);
  });
  test('账户月度转账统计', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'tf1',
      type: TxType.transfer,
      amount: 5000,
      categoryId: 'transfer',
      accountId: 'alipay',
      transferToAccountId: 'wechat',
      date: DateTime(now.year, now.month, 3),
    ));
    await state.addTransaction(Transaction(
      id: 'tf2',
      type: TxType.transfer,
      amount: 3000,
      categoryId: 'transfer',
      accountId: 'wechat',
      transferToAccountId: 'alipay',
      date: DateTime(now.year, now.month, 5),
    ));
    await state.addTransaction(Transaction(
      id: 'tf3',
      type: TxType.transfer,
      amount: 2000,
      categoryId: 'transfer',
      accountId: 'alipay',
      transferToAccountId: 'wechat',
      date: DateTime(now.year, now.month - 1, 3),
    ));
    final alipay = state.monthlyTransferSummaryOfAccount(
        'alipay', DateTime(now.year, now.month));
    expect(alipay.outAmount, 5000);
    expect(alipay.outCount, 1);
    expect(alipay.inAmount, 3000);
    expect(alipay.inCount, 1);
    final wechat = state.monthlyTransferSummaryOfAccount(
        'wechat', DateTime(now.year, now.month));
    expect(wechat.outAmount, 3000);
    expect(wechat.inAmount, 5000);
  });

  testWidgets('账户菜单显示本月转账统计', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'tfw1',
      type: TxType.transfer,
      amount: 5000,
      categoryId: 'transfer',
      accountId: 'alipay',
      transferToAccountId: 'wechat',
      date: DateTime(now.year, now.month, 3),
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('支付宝'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('支付宝'));
    await tester.pumpAndSettle();
    expect(find.textContaining('本月转账：转出 50.00'), findsOneWidget);
    expect(find.textContaining('转入 0.00'), findsOneWidget);
  });
  test('周期规则跳过下次不生成流水', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addRecurringRule(RecurringRule(
      id: 'sk1',
      type: TxType.expense,
      amount: 100000,
      categoryId: 'home',
      accountId: 'alipay',
      note: '房租',
      date: DateTime(2026, 8, 1),
      nextDate: DateTime(2026, 9, 1),
      frequency: RecurFrequency.monthly,
    ));
    final before = state.transactions.length;
    await state.skipNextOccurrence('sk1');
    expect(state.transactions.length, before); // 不生成流水
    expect(state.recurringRules.first.nextDate, DateTime(2026, 10, 1));
  });

  testWidgets('编辑弹层跳过下次生效', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addRecurringRule(RecurringRule(
      id: 'sk2',
      type: TxType.expense,
      amount: 5000,
      categoryId: 'food',
      accountId: 'wechat',
      note: '订阅',
      date: DateTime(2026, 8, 1),
      nextDate: DateTime(2026, 9, 1),
      frequency: RecurFrequency.weekly,
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('每周 · 餐饮'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('每周 · 餐饮'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('每周 · 餐饮'));
    await tester.pumpAndSettle();
    expect(find.text('编辑周期规则'), findsOneWidget);
    await tester.ensureVisible(find.text('跳过下次（不生成本次）'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('跳过下次（不生成本次）'));
    await tester.pumpAndSettle();
    expect(state.recurringRules.first.nextDate, DateTime(2026, 9, 8));
  });
  testWidgets('明细多选导出选中项', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'ex1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '导出甲',
    ));
    await state.addTransaction(Transaction(
      id: 'ex2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'food',
      accountId: 'wechat',
      date: DateTime(now.year, now.month, now.day),
      note: '导出乙',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('导出甲'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('多选删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    expect(find.text('已选 2 项'), findsOneWidget);
    // 多选栏出现「导出选中」入口（导出流程复用 CsvExporter/exportCsvFile，文件写入由真机/浏览器验证）
    expect(find.byTooltip('导出选中'), findsOneWidget);
  });
  test('CsvImporter 未知账户占位', () {
    const csv = '日期,类型,分类,金额(元),账户,账本,备注,转入账户\n'
        '2026-08-01 10:00,支出,餐饮,20,招商卡,默认账本,午饭,\n';
    final result = CsvImporter.parseCsv(csv);
    expect(result.unknownAccountNames.length, 1);
    final ph = result.unknownAccountNames.keys.first;
    expect(result.unknownAccountNames[ph], '招商卡');
    expect(result.transactions.first.accountId, ph);
  });

  test('导入未知账户自动创建并映射', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    const csv = '日期,类型,分类,金额(元),账户,账本,备注,转入账户\n'
        '2026-08-01 10:00,支出,餐饮,20,招商卡,默认账本,午饭,\n'
        '2026-08-02 10:00,支出,交通,5,招商卡,默认账本,地铁,\n';
    final result = await state.importCsv(csv);
    expect(result.transactions.length, 2);
    expect(state.accounts.any((a) => a.name == '招商卡'), isTrue);
    final newId = state.accounts.firstWhere((a) => a.name == '招商卡').id;
    expect(state.transactions.every((t) => t.accountId == newId), isTrue);
    // 再导入同账户名不重复创建账户
    final before = state.accounts.length;
    await state.importCsv(csv);
    expect(state.accounts.length, before);
  });
  test('周期规则 CSV 导出内容', () {
    final rules = [
      RecurringRule(
        id: 'r1',
        type: TxType.expense,
        amount: 100000,
        categoryId: 'home',
        accountId: 'alipay',
        note: '房租',
        date: DateTime(2026, 8, 1),
        nextDate: DateTime(2026, 9, 1),
        frequency: RecurFrequency.monthly,
      ),
      RecurringRule(
        id: 'r2',
        type: TxType.income,
        amount: 500000,
        categoryId: 'salary',
        accountId: 'card',
        note: '工资',
        date: DateTime(2026, 8, 1),
        nextDate: DateTime(2026, 9, 1),
        frequency: RecurFrequency.monthly,
      ),
    ];
    final csv = CsvExporter.exportRecurringCsv(rules);
    expect(csv.contains('频率,类型,金额(元),分类,账户,下次日期,备注,转入账户'), isTrue);
    expect(
        csv.contains('每月,支出,1000.00,居住,支付宝,2026-09-01,房租,'), isTrue);
    expect(
        csv.contains('每月,收入,5000.00,工资,银行卡,2026-09-01,工资,'), isTrue);
  });

  testWidgets('我的页周期记账区有导出按钮', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addRecurringRule(RecurringRule(
      id: 'er1',
      type: TxType.expense,
      amount: 100000,
      categoryId: 'home',
      accountId: 'alipay',
      note: '房租',
      date: DateTime(2026, 8, 1),
      nextDate: DateTime(2026, 9, 1),
      frequency: RecurFrequency.monthly,
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('导出周期规则'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('导出周期规则'), findsOneWidget);
  });
  testWidgets('记一笔数字键盘输入/退格/小数点', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    // 键盘输入 1 2
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
    // 退格
    await tester.tap(find.text('⌫'));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsNothing);
    // 小数点 + 数字
    await tester.tap(find.text('.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(find.text('1.5'), findsOneWidget);
    // 重复小数点被忽略
    await tester.tap(find.text('.'));
    await tester.pumpAndSettle();
    expect(find.text('1.5'), findsOneWidget);
  });
  testWidgets('首页结余走势查看统计进入统计页', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('查看统计'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看统计'));
    await tester.pumpAndSettle();
    expect(find.text('预算对比'), findsOneWidget);
  });
  testWidgets('明细全部时间显示年份分组', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'yy1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '今年',
    ));
    await state.addTransaction(Transaction(
      id: 'yy2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year - 1, 12, 31),
      note: '去年',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    // 切到全部时间
    await tester.tap(find.text('本月').last);
    await tester.pumpAndSettle();
    expect(find.text('${now.year} 年'), findsOneWidget);
    // 滚动到去年部分
    await tester.scrollUntilVisible(
      find.text('${now.year - 1} 年'),
      200,
      scrollable: find.descendant(
        of: find.byType(LedgerPage),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('${now.year - 1} 年'), findsOneWidget);
    expect(find.textContaining('去年'), findsOneWidget);
  });
  test('周期规则 CSV 导出导入往返', () {
    final rules = [
      RecurringRule(
        id: 'r1',
        type: TxType.expense,
        amount: 100000,
        categoryId: 'home',
        accountId: 'alipay',
        note: '房租',
        date: DateTime(2026, 8, 1),
        nextDate: DateTime(2026, 9, 1),
        frequency: RecurFrequency.monthly,
      ),
      RecurringRule(
        id: 'r2',
        type: TxType.transfer,
        amount: 50000,
        categoryId: 'transfer',
        accountId: 'alipay',
        transferToAccountId: 'wechat',
        note: '定存',
        date: DateTime(2026, 8, 1),
        nextDate: DateTime(2026, 9, 1),
        frequency: RecurFrequency.weekly,
      ),
    ];
    final csv = CsvExporter.exportRecurringCsv(rules);
    expect(csv.contains('每周,转账,500.00,转账,支付宝,2026-09-01,定存,微信'), isTrue);
    final parsed = CsvImporter.parseRecurringCsv(csv);
    expect(parsed.length, 2);
    final back = parsed.first;
    expect(back.frequency, RecurFrequency.monthly);
    expect(back.amount, 100000);
    expect(back.categoryId, 'home');
    expect(back.accountId, 'alipay');
    expect(back.note, '房租');
    final transfer = parsed.last;
    expect(transfer.type, TxType.transfer);
    expect(transfer.transferToAccountId, 'wechat');
  });

  test('导入周期规则 CSV 去重', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    const csv = '频率,类型,金额(元),分类,账户,下次日期,备注,转入账户\n'
        '每月,支出,1000.00,居住,支付宝,2026-09-01,房租,\n'
        '每月,支出,1000.00,居住,支付宝,2026-09-01,房租,\n'
        '每年,支出,500.00,餐饮,微信,2026-09-01,订阅,\n';
    final added = await state.importRecurringCsv(csv);
    expect(added, 2); // 重复跳过
    expect(state.recurringRules.length, 2);
  });

  testWidgets('我的页有导入周期规则入口', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('导入周期规则 (CSV)'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('导入周期规则 (CSV)'), findsOneWidget);
  });
  testWidgets('记一笔保存后撤销删除', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    // 键盘输入 12
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    // 保存
    await tester.ensureVisible(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(state.transactions.length, 1);
    // SnackBar 含撤销与继续记一笔
    expect(find.text('撤销'), findsOneWidget);
    expect(find.text('继续记一笔'), findsOneWidget);
    // 撤销删除
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    expect(state.transactions.isEmpty, isTrue);
  });
  testWidgets('首页总资产点击进入我的账户', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('总资产'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('总资产'));
    await tester.pumpAndSettle();
    expect(find.text('我的'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('数据概况'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('数据概况'), findsOneWidget);
  });
  test('复制流水到其他账本', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addBook('旅行账本');
    await state.addTransaction(Transaction(
      id: 'cp1',
      type: TxType.expense,
      amount: 5000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2026, 8, 6),
      note: '复制我',
    ));
    final bookId = state.books.firstWhere((b) => b.name == '旅行账本').id;
    final ok = await state.copyTransactionToBook('cp1', bookId);
    expect(ok, isTrue);
    expect(state.transactions.where((t) => t.note == '复制我').length, 2);
    await state.setCurrentBook(bookId);
    expect(
        state.currentBookTransactions.any((t) => t.note == '复制我'), isTrue);
  });

  testWidgets('明细长按复制到其他账本', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addBook('旅行账本');
    await state.addTransaction(Transaction(
      id: 'lb1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '待复制',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('待复制'));
    await tester.pumpAndSettle();
    expect(find.text('复制到其他账本'), findsOneWidget);
    await tester.tap(find.text('复制到其他账本'));
    await tester.pumpAndSettle();
    expect(find.text('复制到账本'), findsOneWidget);
    await tester.tap(find.text('旅行账本'));
    await tester.pumpAndSettle();
    expect(state.transactions.where((t) => t.note == '待复制').length, 2);
  });
  testWidgets('我的页显示数据概况', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addTransaction(Transaction(
      id: 'do1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2026, 8, 1),
    ));
    await state.addTransaction(Transaction(
      id: 'do2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2026, 8, 2),
    ));
    await state.addRecurringRule(RecurringRule(
      id: 'dor1',
      type: TxType.expense,
      amount: 100000,
      categoryId: 'home',
      accountId: 'alipay',
      note: '房租',
      date: DateTime(2026, 8, 1),
      nextDate: DateTime(2026, 9, 1),
      frequency: RecurFrequency.monthly,
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('数据概况'), findsOneWidget);
    expect(find.text('2 笔'), findsOneWidget);
    expect(find.text('4 个'), findsOneWidget);
    expect(find.text('1 个'), findsOneWidget);
    expect(find.text('1 条'), findsOneWidget);
  });
  test('日期范围汇总与序列', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addTransaction(Transaction(
      id: 'r1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2026, 8, 1),
    ));
    await state.addTransaction(Transaction(
      id: 'r2',
      type: TxType.expense,
      amount: 2000,
      categoryId: 'home',
      accountId: 'alipay',
      date: DateTime(2026, 8, 3),
    ));
    await state.addTransaction(Transaction(
      id: 'r3',
      type: TxType.income,
      amount: 5000,
      categoryId: 'salary',
      accountId: 'alipay',
      date: DateTime(2026, 8, 5),
    ));
    await state.addTransaction(Transaction(
      id: 'r4',
      type: TxType.transfer,
      amount: 999,
      categoryId: 'transfer',
      accountId: 'alipay',
      transferToAccountId: 'wechat',
      date: DateTime(2026, 8, 6),
    ));
    final s = state.rangeSummary(DateTime(2026, 8, 1), DateTime(2026, 8, 5));
    expect(s.expense, 3000);
    expect(s.income, 5000);
    expect(s.count, 3); // 转账不计
    final series = state.rangeDailySeries(DateTime(2026, 8, 1), DateTime(2026, 8, 5));
    expect(series, [1000, 0, 2000, 0, 0]);
    final nets = state.rangeDailyNetSeries(DateTime(2026, 8, 1), DateTime(2026, 8, 5));
    // 逐日累计结余：8/1 -10、8/2 -10、8/3 -30、8/4 -30、8/5 +20（转账不计）
    expect([for (final e in nets) e.net], [-1000, -1000, -3000, -3000, 2000]);
    final incomeSeries = state.rangeDailyIncomeSeries(
        DateTime(2026, 8, 1), DateTime(2026, 8, 5));
    expect(incomeSeries, [0, 0, 0, 0, 5000]);
    final ranking = state.rangeCategoryRanking(DateTime(2026, 8, 1), DateTime(2026, 8, 5));
    expect(ranking.first.category.name, '居住');
  });

  testWidgets('统计页自定义日期范围', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'wr1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '范围支出',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自定义'));
    await tester.pumpAndSettle();
    // 起始日期（默认今天 → 确定）
    await tester.tap(find.text('起始日期'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    // 结束日期
    await tester.tap(find.text('结束日期'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    // 范围汇总出现
    expect(find.textContaining('汇总'), findsWidgets);
    expect(find.text('收入'), findsOneWidget);
    // 范围结余走势出现
    expect(find.text('结余走势（范围）'), findsOneWidget);
    // 范围每日支出 → 切收入 → 每日收入（图表在视口外，先滚动到切换钮）
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('rangeIncomeToggle')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rangeIncomeToggle')));
    await tester.pumpAndSettle();
    expect(find.text('每日收入'), findsOneWidget);
    expect(find.textContaining('范围支出'), findsNothing);
  });
  test('批量移动流水到其他账本', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addBook('旅行账本');
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'mv1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '移一',
    ));
    await state.addTransaction(Transaction(
      id: 'mv2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '移二',
    ));
    final bookId = state.books.firstWhere((b) => b.name == '旅行账本').id;
    await state.moveTransactionsToBook(['mv1', 'mv2'], bookId);
    // 当前账本已无
    expect(state.currentBookTransactions.any((t) => t.note == '移一'), isFalse);
    expect(state.transactions.length, 2);
    // 目标账本有
    await state.setCurrentBook(bookId);
    expect(state.currentBookTransactions.length, 2);
  });

  testWidgets('明细多选批量移动到其他账本', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addBook('旅行账本');
    await state.addTransaction(Transaction(
      id: 'wmv1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '批量移',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('批量移'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('多选删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('修改选中'));
    await tester.pumpAndSettle();
    expect(find.text('移动到其他账本'), findsOneWidget);
    await tester.tap(find.text('移动到其他账本'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('旅行账本'));
    await tester.pumpAndSettle();
    // 当前账本已无该笔
    expect(state.currentBookTransactions.any((t) => t.note == '批量移'), isFalse);
    final bookId = state.books.firstWhere((b) => b.name == '旅行账本').id;
    await state.setCurrentBook(bookId);
    expect(
        state.currentBookTransactions.any((t) => t.note == '批量移'), isTrue);
  });
  test('周期规则按月补生成历史流水（含去重）', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final anchor = DateTime(now.year, now.month - 6, 1);
    await state.addRecurringRule(RecurringRule(
      id: 'bf1',
      type: TxType.expense,
      amount: 5000,
      categoryId: 'food',
      accountId: 'alipay',
      note: '订阅',
      date: anchor,
      nextDate: anchor,
      frequency: RecurFrequency.monthly,
    ));
    // 预置一期已存在流水（-3 个月，同字段）→ 补生成应跳过
    await state.addTransaction(Transaction(
      id: 'dup1',
      type: TxType.expense,
      amount: 5000,
      categoryId: 'food',
      accountId: 'alipay',
      note: '订阅',
      date: DateTime(now.year, now.month - 3, 1),
    ));
    final info = state.recurringBackfillInfo('bf1');
    expect(info, isNotNull);
    // 锚点月起每月 1 日共 7 期，减去已存在的 1 期 → 6
    expect(info!.count, 6);
    final added = await state.backfillRecurring('bf1');
    expect(added, 6);
    final txs = state.transactions.where((t) => t.note == '订阅').toList();
    expect(txs.length, 7);
    expect(state.transactions.where((t) => t.id == 'dup1').length, 1);
    // nextDate 已推进到今天之后
    expect(state.recurringRules.first.nextDate.isAfter(today), isTrue);
    // 再次补生成无新增
    expect(state.recurringBackfillInfo('bf1'), isNull);
    expect(await state.backfillRecurring('bf1'), 0);
  });

  testWidgets('我的页周期规则补生成历史流水', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addRecurringRule(RecurringRule(
      id: 'bf2',
      type: TxType.expense,
      amount: 5000,
      categoryId: 'food',
      accountId: 'wechat',
      note: '补生测试',
      date: DateTime(now.year, now.month - 2, 1),
      nextDate: DateTime(now.year, now.month - 2, 1),
      frequency: RecurFrequency.monthly,
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('每月 · 餐饮'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('每月 · 餐饮'));
    await tester.pumpAndSettle();
    // 编辑弹层出现「补生成历史流水」
    await tester.ensureVisible(find.text('补生成历史流水'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('补生成历史流水'));
    await tester.pumpAndSettle();
    // 确认对话框（标题与按钮同文案）
    expect(find.text('补生成历史流水'), findsWidgets);
    await tester.tap(find.text('补生成'));
    await tester.pumpAndSettle();
    // 锚点月起 3 期（-2、-1、本月 1 日）已补生成
    expect(state.transactions.where((t) => t.note == '补生测试').length, 3);
  });
  testWidgets('明细按分类批量移动到其他账本', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addBook('旅行账本');
    await state.addTransaction(Transaction(
      id: 'cmv1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '餐一',
    ));
    await state.addTransaction(Transaction(
      id: 'cmv2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '餐二',
    ));
    await state.addTransaction(Transaction(
      id: 'cmv3',
      type: TxType.expense,
      amount: 300,
      categoryId: 'shopping',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '购物一',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('餐一'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('多选删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('修改选中'));
    await tester.pumpAndSettle();
    expect(find.text('按分类移动到其他账本'), findsOneWidget);
    await tester.ensureVisible(find.text('按分类移动到其他账本'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('按分类移动到其他账本'));
    await tester.pumpAndSettle();
    // 分类选择（弹层在最后，取 .last）
    await tester.tap(find.text('餐饮').last);
    await tester.pumpAndSettle();
    // 账本选择
    await tester.tap(find.text('旅行账本'));
    await tester.pumpAndSettle();
    // 确认对话框：餐饮分类 2 笔
    expect(find.textContaining('2 笔流水到「旅行账本」'), findsOneWidget);
    await tester.tap(find.text('移动'));
    await tester.pumpAndSettle();
    // 餐饮 2 笔已移动，购物分类保留在当前账本
    expect(state.currentBookTransactions.any((t) => t.note == '餐一'), isFalse);
    expect(state.currentBookTransactions.any((t) => t.note == '餐二'), isFalse);
    expect(state.currentBookTransactions.any((t) => t.note == '购物一'), isTrue);
    final bookId = state.books.firstWhere((b) => b.name == '旅行账本').id;
    await state.setCurrentBook(bookId);
    expect(state.currentBookTransactions.length, 2);
  });
  testWidgets('统计页年度支出/收入对比切换', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'wy1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 3),
    ));
    await state.addTransaction(Transaction(
      id: 'wy2',
      type: TxType.income,
      amount: 2000,
      categoryId: 'salary',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 5),
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();
    // 年度对比卡片存在（默认支出；卡片可能在视口外，需 skipOffstage）
    final yearCard = find.byWidgetPredicate(
        (w) => w is PaperGroup && w.title != null && w.title!.startsWith('年度'),
        skipOffstage: false);
    expect(yearCard, findsWidgets);
    // 卡片内「收入」切换
    final incomeTag = find.descendant(
        of: yearCard.first,
        matching: find.text('收入', skipOffstage: false),
        skipOffstage: false);
    expect(incomeTag, findsOneWidget);
    await tester.ensureVisible(incomeTag);
    await tester.pumpAndSettle();
    await tester.tap(incomeTag);
    await tester.pumpAndSettle();
    // 标题变为「年度收入对比」
    expect(
      find.byWidgetPredicate((w) =>
          w is PaperGroup &&
          w.title != null &&
          w.title!.startsWith('年度收入对比'),
          skipOffstage: false),
      findsWidgets,
    );
  });
  testWidgets('明细按分类批量修改账户', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'cac1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '餐一',
    ));
    await state.addTransaction(Transaction(
      id: 'cac2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '餐二',
    ));
    await state.addTransaction(Transaction(
      id: 'cac3',
      type: TxType.expense,
      amount: 300,
      categoryId: 'shopping',
      accountId: 'wechat',
      date: DateTime(now.year, now.month, now.day),
      note: '购物一',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('餐一'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('多选删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('修改选中'));
    await tester.pumpAndSettle();
    expect(find.text('按分类修改账户'), findsOneWidget);
    await tester.ensureVisible(find.text('按分类修改账户'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('按分类修改账户'));
    await tester.pumpAndSettle();
    // 分类选择（弹层在最后，取 .last）
    await tester.tap(find.text('餐饮').last);
    await tester.pumpAndSettle();
    // 账户选择
    await tester.tap(find.text('银行卡').last);
    await tester.pumpAndSettle();
    // 确认对话框：餐饮分类 2 笔改到银行卡
    expect(find.textContaining('2 笔流水改到「银行卡」'), findsOneWidget);
    await tester.tap(find.text('修改'));
    await tester.pumpAndSettle();
    // 餐饮 2 笔账户已改为银行卡，购物分类保留微信
    final foodTx = state.currentBookTransactions
        .where((t) => t.categoryId == 'food')
        .toList();
    expect(foodTx.length, 2);
    expect(foodTx.every((t) => t.accountId == 'card'), isTrue);
    expect(state.currentBookTransactions
        .firstWhere((t) => t.note == '购物一').accountId, 'wechat');
  });
  testWidgets('明细按分类批量删除（含撤销）', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'cdl1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '餐一',
    ));
    await state.addTransaction(Transaction(
      id: 'cdl2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, now.day),
      note: '餐二',
    ));
    await state.addTransaction(Transaction(
      id: 'cdl3',
      type: TxType.expense,
      amount: 300,
      categoryId: 'shopping',
      accountId: 'wechat',
      date: DateTime(now.year, now.month, now.day),
      note: '购物一',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('餐一'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('多选删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('修改选中'));
    await tester.pumpAndSettle();
    expect(find.text('按分类删除'), findsOneWidget);
    await tester.ensureVisible(find.text('按分类删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('按分类删除'));
    await tester.pumpAndSettle();
    // 分类选择（弹层在最后，取 .last）
    await tester.tap(find.text('餐饮').last);
    await tester.pumpAndSettle();
    // 强确认对话框
    expect(find.textContaining('「餐饮」分类的全部流水'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    // 餐饮 2 笔已删除，购物保留
    expect(state.currentBookTransactions.any((t) => t.note == '餐一'), isFalse);
    expect(state.currentBookTransactions.any((t) => t.note == '餐二'), isFalse);
    expect(state.currentBookTransactions.any((t) => t.note == '购物一'), isTrue);
    // 撤销恢复
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    expect(state.currentBookTransactions.where((t) => t.categoryId == 'food').length, 2);
  });
  testWidgets('我的页周期记账提醒开关', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('周期记账提醒（到期当天）'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    final row = find.widgetWithText(Row, '周期记账提醒（到期当天）');
    final sw = find.descendant(of: row, matching: find.byType(Switch));
    expect(sw, findsOneWidget);
    expect(state.recurringRemind, isTrue);
    await tester.tap(sw);
    await tester.pumpAndSettle();
    expect(state.recurringRemind, isFalse);
  });
  test('本周流水 weekTransactions', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));
    await state.addTransaction(Transaction(
      id: 'wt1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: today,
      note: '本周项',
    ));
    await state.addTransaction(Transaction(
      id: 'wt2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'shopping',
      accountId: 'alipay',
      date: monday.subtract(const Duration(days: 7)),
      note: '上周项',
    ));
    final week = state.weekTransactions;
    expect(week.length, 1);
    expect(week.first.note, '本周项');
  });

  testWidgets('首页本周最近流水过滤', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'hr1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
      note: '本周项',
    ));
    await state.addTransaction(Transaction(
      id: 'hr2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'shopping',
      accountId: 'alipay',
      date: now.subtract(const Duration(days: 20)),
      note: '上周项',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('本周'));
    await tester.pumpAndSettle();
    // 本周模式最近流水只显示本周项
    expect(find.textContaining('本周项'), findsOneWidget);
    expect(find.textContaining('上周项'), findsNothing);
  });
  test('统计自定义范围记忆持久化', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    expect(state.statsRangeMode, isFalse);
    await state.setStatsRange(
        mode: true,
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 7, 23, 59, 59));
    expect(state.statsRangeMode, isTrue);
    expect(state.statsRangeStart, DateTime(2026, 8, 1));
    final state2 = AppState();
    await state2.load();
    expect(state2.statsRangeMode, isTrue);
    expect(state2.statsRangeStart, DateTime(2026, 8, 1));
    expect(state2.statsRangeEnd, DateTime(2026, 8, 7, 23, 59, 59));
  });

  testWidgets('统计页恢复上次自定义范围', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.setStatsRange(
        mode: true,
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 7, 23, 59, 59));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();
    // 自定义范围已恢复：显示「从 8月1日」「至 8月7日」
    expect(find.textContaining('从 8月1日'), findsOneWidget);
    expect(find.textContaining('至 8月7日'), findsOneWidget);
  });
  test('账本汇总 bookMonthSummaries', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addBook('旅行账本');
    final now = DateTime.now();
    final m = DateTime(now.year, now.month, 5);
    await state.addTransaction(Transaction(
      id: 'bs1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: m,
      note: '默认',
    ));
    final tripId = state.books.firstWhere((b) => b.name == '旅行账本').id;
    await state.setCurrentBook(tripId);
    await state.addTransaction(Transaction(
      id: 'bs2',
      type: TxType.expense,
      amount: 2000,
      categoryId: 'food',
      accountId: 'alipay',
      date: m,
      note: '旅行',
    ));
    final defaultId = state.books.firstWhere((b) => b.name == '默认账本').id;
    await state.setCurrentBook(defaultId);
    await state.addTransaction(Transaction(
      id: 'bs3',
      type: TxType.income,
      amount: 5000,
      categoryId: 'salary',
      accountId: 'alipay',
      date: m,
      note: '工资',
    ));
    final rows = state.bookMonthSummaries(m);
    expect(rows.length, 2);
    final def = rows.firstWhere((r) => r.book.name == '默认账本');
    expect(def.summary.expense, 1000);
    expect(def.summary.income, 5000);
    final trip = rows.firstWhere((r) => r.book.name == '旅行账本');
    expect(trip.summary.expense, 2000);
    expect(trip.summary.income, 0);
  });

  testWidgets('首页账本汇总切换账本', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addBook('旅行账本');
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'bs4',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
      note: '默认项',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    // 多账本时首页出现「账本汇总」
    expect(find.text('账本汇总'), findsOneWidget);
    expect(find.text('旅行账本'), findsWidgets);
    // 点击旅行账本行切换当前账本
    final tripRow = find.text('旅行账本').last;
    await tester.ensureVisible(tripRow);
    await tester.pumpAndSettle();
    await tester.tap(tripRow);
    await tester.pumpAndSettle();
    final tripId = state.books.firstWhere((b) => b.name == '旅行账本').id;
    expect(state.currentBookId, tripId);
  });
  testWidgets('我的页周期规则可复制', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addRecurringRule(RecurringRule(
      id: 'cp1',
      type: TxType.expense,
      amount: 5000,
      categoryId: 'food',
      accountId: 'wechat',
      note: '订阅',
      date: now,
      nextDate: DateTime(now.year, now.month, now.day + 3),
      frequency: RecurFrequency.monthly,
    ));
    final before = state.recurringRuleCount;
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('每月 · 餐饮'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('每月 · 餐饮'));
    await tester.pumpAndSettle();
    // 编辑弹层「复制规则」
    await tester.ensureVisible(find.text('复制规则'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制规则'));
    await tester.pumpAndSettle();
    expect(state.recurringRuleCount, before + 1);
    final copied = state.recurringRules.last;
    expect(copied.id, isNot('cp1'));
    expect(copied.note, '订阅（副本）');
    expect(copied.amount, 5000);
    expect(copied.frequency, RecurFrequency.monthly);
  });
  testWidgets('统计页收入占比环图', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'dn1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 3),
    ));
    await state.addTransaction(Transaction(
      id: 'dn2',
      type: TxType.income,
      amount: 2000,
      categoryId: 'salary',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 5),
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();
    // 占比环图在列表中部，先滚动到「支出占比」
    await tester.scrollUntilVisible(
      find.text('支出占比'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('支出占比'), findsOneWidget);
    // 切到收入（收入切换钮带 Key，避免与年度卡片同名文本混淆）
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('incomeToggleTag')),
      -200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('incomeToggleTag')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('收入占比'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('收入占比'), findsOneWidget);
    expect(find.text('支出占比'), findsNothing);
  });
  test('今日概览 todaySummary/流水/排行', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await state.addTransaction(Transaction(
      id: 'td1',
      type: TxType.expense,
      amount: 500,
      categoryId: 'food',
      accountId: 'alipay',
      date: today,
      note: '今日项',
    ));
    await state.addTransaction(Transaction(
      id: 'td2',
      type: TxType.income,
      amount: 2000,
      categoryId: 'salary',
      accountId: 'alipay',
      date: today,
    ));
    await state.addTransaction(Transaction(
      id: 'td3',
      type: TxType.expense,
      amount: 9000,
      categoryId: 'shopping',
      accountId: 'alipay',
      date: today.subtract(const Duration(days: 1)),
      note: '昨日项',
    ));
    final s = state.todaySummary!;
    expect(s.expense, 500);
    expect(s.income, 2000);
    final txs = state.todayTransactions;
    expect(txs.length, 2);
    expect(txs.any((t) => t.note == '今日项'), isTrue);
    expect(txs.any((t) => t.note == '昨日项'), isFalse);
    final ranking = state.todayCategoryRanking();
    expect(ranking.length, 1);
    expect(ranking.first.category.name, '餐饮');
    expect(ranking.first.amount, 500);
  });

  testWidgets('首页今日概览', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'th1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
      note: '今日项',
    ));
    await state.addTransaction(Transaction(
      id: 'th2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'shopping',
      accountId: 'alipay',
      date: now.subtract(const Duration(days: 1)),
      note: '昨日项',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('今日'));
    await tester.pumpAndSettle();
    expect(find.text('今日支出'), findsOneWidget);
    expect(find.text('今日支出分类'), findsOneWidget);
    expect(find.textContaining('今日项'), findsOneWidget);
    expect(find.textContaining('昨日项'), findsNothing);
  });
  test('自定义常用金额增删持久化', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    expect(state.customQuickAmounts, isEmpty);
    await state.addCustomQuickAmount(128);
    await state.addCustomQuickAmount(66);
    await state.addCustomQuickAmount(128); // 去重
    expect(state.customQuickAmounts, [66, 128]); // 升序
    final state2 = AppState();
    await state2.load();
    expect(state2.customQuickAmounts, [66, 128]);
    await state2.removeCustomQuickAmount(66);
    expect(state2.customQuickAmounts, [128]);
  });

  testWidgets('记一笔添加自定义常用金额', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ 自定义').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '128');
    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();
    expect(state.customQuickAmounts, [128]);
    expect(find.text('+¥128'), findsOneWidget);
    // 点击自定义金额填入金额框
    await tester.tap(find.text('+¥128'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '128.00'), findsOneWidget);
  });
  test('自定义常用备注增删持久化', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    expect(state.customQuickNotes, isEmpty);
    await state.addCustomQuickNote('培训');
    await state.addCustomQuickNote('礼物');
    await state.addCustomQuickNote('培训'); // 去重
    expect(state.customQuickNotes, ['培训', '礼物']);
    final state2 = AppState();
    await state2.load();
    expect(state2.customQuickNotes, ['培训', '礼物']);
    await state2.removeCustomQuickNote('培训');
    expect(state2.customQuickNotes, ['礼物']);
  });

  testWidgets('记一笔添加自定义常用备注', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔'));
    await tester.pumpAndSettle();
    // 备注行的「+ 自定义」（金额行也有同名 chip，取最后一个）
    await tester.scrollUntilVisible(
      find.text('+ 自定义').last,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ 自定义').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '培训');
    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();
    expect(state.customQuickNotes, ['培训']);
    expect(find.text('培训'), findsWidgets);
    // 点击自定义备注填入备注框
    await tester.ensureVisible(find.text('培训'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('培训').last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '培训'), findsOneWidget);
  });
  testWidgets('明细全部账本切换', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addBook('旅行账本');
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'ab1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
      note: '默认本',
    ));
    final tripId = state.books.firstWhere((b) => b.name == '旅行账本').id;
    await state.setCurrentBook(tripId);
    await state.addTransaction(Transaction(
      id: 'ab2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'shopping',
      accountId: 'alipay',
      date: now,
      note: '旅行本',
    ));
    await state.setCurrentBook(state.books.first.id);
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    // 默认当前账本：只显示默认本
    expect(find.textContaining('默认本'), findsOneWidget);
    expect(find.textContaining('旅行本'), findsNothing);
    // 切全部账本：两账本流水都出现
    await tester.tap(find.text('全部账本'));
    await tester.pumpAndSettle();
    expect(find.textContaining('旅行本'), findsOneWidget);
    // 切回当前账本
    await tester.tap(find.text('当前账本'));
    await tester.pumpAndSettle();
    expect(find.textContaining('旅行本'), findsNothing);
  });
  test('报销标记模型与 JSON 往返', () {
    final t = Transaction(
      id: 'rb1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(2026, 8, 1),
      reimbursable: true,
    );
    expect(t.reimbursable, isTrue);
    final restored = Transaction.fromJson(t.toJson());
    expect(restored.reimbursable, isTrue);
    final copy = t.copyWith(reimbursable: false);
    expect(copy.reimbursable, isFalse);
    // 旧数据缺字段默认 false
    final legacy = Transaction.fromJson({
      'id': 'x',
      'type': 'expense',
      'amount': 1,
      'categoryId': 'food',
      'accountId': 'alipay',
      'date': '2026-08-01T00:00:00.000',
    });
    expect(legacy.reimbursable, isFalse);
  });

  testWidgets('记一笔可报销开关保存', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '88');
    await tester.pumpAndSettle();
    final row = find.widgetWithText(Row, '这笔可报销');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(state.transactions.first.reimbursable, isTrue);
  });

  testWidgets('明细报销筛选', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'rbA',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
      note: '报一',
      reimbursable: true,
    ));
    await state.addTransaction(Transaction(
      id: 'rbB',
      type: TxType.expense,
      amount: 200,
      categoryId: 'shopping',
      accountId: 'alipay',
      date: now,
      note: '报二',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    expect(find.textContaining('报一'), findsWidgets);
    expect(find.textContaining('报二'), findsWidgets);
    // 报销筛选：只显示可报销
    await tester.ensureVisible(find.text('报销：全部'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('报销：全部'));
    await tester.pumpAndSettle();
    expect(find.textContaining('报一'), findsWidgets);
    expect(find.textContaining('报二'), findsNothing);
    // 切回全部
    await tester.tap(find.text('报销：可报销'));
    await tester.pumpAndSettle();
    expect(find.textContaining('报二'), findsWidgets);
  });

  test('CSV 报销列往返', () {
    final txs = [
      Transaction(
        id: 'rbx1',
        type: TxType.expense,
        amount: 1000,
        categoryId: 'food',
        accountId: 'alipay',
        date: DateTime(2026, 8, 1),
        note: '可报销项',
        reimbursable: true,
      ),
      Transaction(
        id: 'rbx2',
        type: TxType.expense,
        amount: 500,
        categoryId: 'food',
        accountId: 'alipay',
        date: DateTime(2026, 8, 2),
        note: '普通项',
      ),
    ];
    final csv = CsvExporter.exportCsv(txs);
    expect(csv.contains(',报销'), isTrue);
    final result = CsvImporter.parseCsv(csv);
    expect(result.errors, isEmpty);
    expect(result.transactions.length, 2);
    expect(result.transactions.first.reimbursable, isTrue);
    expect(result.transactions.last.reimbursable, isFalse);
  });
  testWidgets('明细多选复制选中到其他账本', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addBook('旅行账本');
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'cb1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
      note: '复制一',
    ));
    await state.addTransaction(Transaction(
      id: 'cb2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'shopping',
      accountId: 'alipay',
      date: now,
      note: '复制二',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('复制一'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('多选删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('修改选中'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('复制选中到其他账本'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制选中到其他账本'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('旅行账本'));
    await tester.pumpAndSettle();
    expect(find.textContaining('复制选中的 2 笔到「旅行账本」'), findsOneWidget);
    await tester.tap(find.text('复制'));
    await tester.pumpAndSettle();
    // 原账本保留，目标账本 +2
    expect(state.currentBookTransactions.length, 2);
    final tripId = state.books.firstWhere((b) => b.name == '旅行账本').id;
    await state.setCurrentBook(tripId);
    expect(state.currentBookTransactions.length, 2);
  });
  test('周期提醒提前天数持久化', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    expect(state.recurringRemindLead, 0);
    await state.setRecurringRemindLead(3);
    expect(state.recurringRemindLead, 3);
    final state2 = AppState();
    await state2.load();
    expect(state2.recurringRemindLead, 3);
  });

  testWidgets('我的页周期提醒提前天数', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('提前提醒：'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(state.recurringRemindLead, 0);
    await tester.tap(find.text('3天'));
    await tester.pumpAndSettle();
    expect(state.recurringRemindLead, 3);
  });
  testWidgets('首页结余走势 6/12 月切换', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    final homePage = find.byType(HomePage);
    final homeTitle = find.descendant(
        of: homePage, matching: find.text('结余走势（近 6 月）'));
    await tester.ensureVisible(homeTitle);
    await tester.pumpAndSettle();
    expect(homeTitle, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('homeBalance12')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
          of: homePage, matching: find.text('结余走势（近 12 月）')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('homeBalance6')));
    await tester.pumpAndSettle();
    expect(homeTitle, findsOneWidget);
  });

  testWidgets('统计结余走势近 3 月切换', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'b3m1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: DateTime(now.year, now.month, 3),
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('结余走势（近 12 月）'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    final tag3 = find.byKey(const ValueKey('statsBalance3'));
    await tester.ensureVisible(tag3);
    await tester.pumpAndSettle();
    await tester.tap(tag3);
    await tester.pumpAndSettle();
    expect(find.text('结余走势（近 3 月）'), findsOneWidget);
  });
  testWidgets('明细多选批量标记可报销', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'rb1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
      note: '标一',
    ));
    await state.addTransaction(Transaction(
      id: 'rb2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'shopping',
      accountId: 'alipay',
      date: now,
      note: '标二',
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('标一'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('多选删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('修改选中'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('标记为可报销'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('标记为可报销'));
    await tester.pumpAndSettle();
    expect(state.currentBookTransactions.every((t) => t.reimbursable), isTrue);
    // 取消标记
    await tester.ensureVisible(find.textContaining('标一'));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('标一'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('多选删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('修改选中'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('取消报销标记'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消报销标记'));
    await tester.pumpAndSettle();
    expect(state.currentBookTransactions.every((t) => !t.reimbursable), isTrue);
  });
  test('待报销合计 reimbursableSummary', () async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'rs1',
      type: TxType.expense,
      amount: 500,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
      reimbursable: true,
    ));
    await state.addTransaction(Transaction(
      id: 'rs2',
      type: TxType.expense,
      amount: 300,
      categoryId: 'shopping',
      accountId: 'alipay',
      date: now,
      reimbursable: true,
    ));
    await state.addTransaction(Transaction(
      id: 'rs3',
      type: TxType.expense,
      amount: 9000,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
    ));
    final s = state.reimbursableSummary;
    expect(s.total, 800);
    expect(s.count, 2);
  });

  testWidgets('我的页显示待报销合计', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'rs5',
      type: TxType.expense,
      amount: 500,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
      reimbursable: true,
    ));
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.textContaining('待报销 5.00'), findsOneWidget);
  });
  testWidgets('明细全部账本模式显示账本名', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addBook('旅行账本');
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'bn1',
      type: TxType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
      note: '默认本',
    ));
    final tripId = state.books.firstWhere((b) => b.name == '旅行账本').id;
    await state.setCurrentBook(tripId);
    await state.addTransaction(Transaction(
      id: 'bn2',
      type: TxType.expense,
      amount: 200,
      categoryId: 'shopping',
      accountId: 'alipay',
      date: now,
      note: '旅行本',
    ));
    await state.setCurrentBook(state.books.first.id);
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明细'));
    await tester.pumpAndSettle();
    final ledger = find.byType(LedgerPage);
    // 当前账本：旅行本不可见
    expect(
      find.descendant(of: ledger, matching: find.textContaining('旅行本')),
      findsNothing,
    );
    // 切全部账本：旅行本出现且带账本名
    await tester.tap(find.text('全部账本'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: ledger, matching: find.textContaining('旅行本')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: ledger, matching: find.textContaining('旅行账本')),
      findsWidgets,
    );
  });
  testWidgets('首页账本汇总合计行', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded_v1': true});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await state.addBook('旅行账本');
    final now = DateTime.now();
    await state.addTransaction(Transaction(
      id: 'tt1',
      type: TxType.expense,
      amount: 1000,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
      note: '默认',
    ));
    final tripId = state.books.firstWhere((b) => b.name == '旅行账本').id;
    await state.setCurrentBook(tripId);
    await state.addTransaction(Transaction(
      id: 'tt2',
      type: TxType.expense,
      amount: 2000,
      categoryId: 'food',
      accountId: 'alipay',
      date: now,
      note: '旅行',
    ));
    await state.setCurrentBook(state.books.first.id);
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();
    final home = find.byType(HomePage);
    final totalRow = find.descendant(of: home, matching: find.text('合计'));
    await tester.ensureVisible(totalRow);
    await tester.pumpAndSettle();
    expect(totalRow, findsOneWidget);
    // 合计行汇总两账本本月支出 30.00
    expect(
      find.descendant(
          of: home, matching: find.textContaining('本月支出 30.00')),
      findsOneWidget,
    );
  });
}
