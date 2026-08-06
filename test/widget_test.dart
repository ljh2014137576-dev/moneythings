import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneythings_goal/data/app_state.dart';
import 'package:moneythings_goal/main.dart';
import 'package:moneythings_goal/models/transaction.dart';
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
      SharedPreferences.setMockInitialValues({});
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
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.load();
      expect(state.transactions.length, greaterThan(20));
      expect(state.dailyExpenseSeries(DateTime(2026, 8)).length, 31);
    });

    test('预算设置与读取', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.load();
      await state.setBudget(300000);
      expect(state.monthlyBudget, 300000);
    });
  });

  testWidgets('记一笔 -> 明细 -> 编辑 -> 删除 全流程', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    await state.clearAll();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();

    // 记一笔：金额 42，分类餐饮
    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '42');
    await tester.tap(find.text('餐饮'));
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('¥42.00'), findsWidgets);

    // 切到明细，账目应出现
    await tester.tap(find.text('明细').first);
    await tester.pumpAndSettle();
    expect(find.text('¥42.00'), findsWidgets);

    // 点行进入编辑
    await tester.tap(find.text('¥42.00').first);
    await tester.pumpAndSettle();
    expect(find.text('编辑账目'), findsOneWidget);

    // 删除并确认
    await tester.tap(find.byTooltip('删除账目'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(find.text('¥42.00'), findsNothing);
  });

  testWidgets('应用启动并渲染首页概览', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MoneyApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('记账本'), findsOneWidget);
    expect(find.text('本月支出'), findsOneWidget);
    expect(find.text('记一笔'), findsWidgets);
    // 底部导航四个入口
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('明细'), findsOneWidget);
    expect(find.text('统计'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}



