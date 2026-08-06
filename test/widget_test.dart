import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneythings_goal/data/app_state.dart';
import 'package:moneythings_goal/main.dart';
import 'package:moneythings_goal/models/transaction.dart';
import 'package:moneythings_goal/services/csv_exporter.dart';
import 'package:moneythings_goal/services/csv_importer.dart';
import 'package:moneythings_goal/widgets/amount_text.dart';
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

  test('CsvExporter 生成 CSV（含转义）', () {
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
      ),
    ];
    final csv = CsvExporter.exportCsv(txs);
    expect(csv, startsWith('\uFEFF'));
    expect(csv, contains('日期,类型,分类,金额(元),账户,备注'));
    expect(csv, contains('2026-08-06 12:30,支出,餐饮,1234.56,支付宝,"午饭,咖啡"'));
    expect(csv, contains('2026-08-10 09:00,收入,工资,5.00,银行卡,'));
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
    expect(find.text('¥42.00'), findsWidgets);

    await tester.tap(find.text('明细').first);
    await tester.pumpAndSettle();
    expect(find.text('¥42.00'), findsWidgets);

    await tester.tap(find.text('¥42.00').first);
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

    await tester.tap(find.textContaining('本月'));
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
    expect(find.textContaining('日均可用'), findsOneWidget);
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
}


