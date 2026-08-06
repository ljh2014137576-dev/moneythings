import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneythings_goal/data/app_state.dart';
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
import 'package:moneythings_goal/models/transaction.dart';
import 'package:moneythings_goal/services/csv_exporter.dart';
import 'package:moneythings_goal/services/csv_importer.dart';
import 'package:moneythings_goal/widgets/amount_text.dart';
import 'package:moneythings_goal/widgets/transaction_tile.dart';
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
    await tester.tap(find.text('确认导入').last);
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

    expect(find.text('结余走势'), findsOneWidget);
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
    await tester.tap(find.text('本周'));
    await tester.pumpAndSettle();
    expect(find.text('本周支出'), findsOneWidget);
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
        HomePage(onAdd: () {}, onGoLedger: () {}, onGoStats: () {}));
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
}


