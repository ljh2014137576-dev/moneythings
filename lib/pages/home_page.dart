/// 首页：本月概览 + 记一笔 + 最近流水 + 支出分类 + 结余走势
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';
import '../widgets/amount_text.dart';
import '../widgets/book_switcher.dart';
import '../widgets/budget_dialog.dart';
import '../widgets/category_ranking.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_selector.dart';
import '../widgets/paper_group.dart';
import '../widgets/transaction_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onAdd,
    required this.onGoLedger,
    required this.onGoStats,
    required this.onGoProfile,
  });

  final VoidCallback onAdd;
  final VoidCallback onGoLedger;
  final VoidCallback onGoStats;
  final VoidCallback onGoProfile;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _month;
  bool _weekly = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = _weekly
        ? (state.weekSummary ??
            MonthSummary(expense: 0, income: 0))
        : state.summaryOf(_month);
    final recent = (_weekly
            ? state.weekTransactions
            : state.ofMonth(_month))
        .take(6)
        .toList();
    final ranking = _weekly
        ? state.weekCategoryRanking()
        : state.categoryExpenseRanking(_month);
    final isCurrentMonth = _isCurrent(_month);
    final budget = isCurrentMonth ? state.monthlyBudget : 0;
    final spent = isCurrentMonth ? state.currentMonthExpense : 0;
    final balanceSeries = state.recentBalanceSeries(DateTime.now(), 6);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            kPagePadding, kSpace3, kPagePadding, kSpace6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: kSpace2),
            if (!_weekly) ...[
              MonthSelector(
                month: _month,
                onChanged: (m) => setState(() => _month = m),
              ),
            ],
            const SizedBox(height: kSpace2),
            Row(
              children: [
                _HomeModeTag(
                  label: '本月',
                  selected: !_weekly,
                  onTap: () => setState(() => _weekly = false),
                ),
                const SizedBox(width: kSpace2),
                _HomeModeTag(
                  label: '本周',
                  selected: _weekly,
                  onTap: () => setState(() => _weekly = true),
                ),
              ],
            ),
            const SizedBox(height: kSpace3),
            _buildSummary(
              summary,
              budget,
              spent,
              isCurrentMonth,
              state.budgetRemaining,
              state.budgetDailyRemaining,
            ),
            const SizedBox(height: kSpace3),
            FilledButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('记一笔'),
            ),
            const SizedBox(height: kSpace6),
            _buildRecent(recent, weekly: _weekly),
            const SizedBox(height: kSpace4),
            _buildRanking(
              ranking,
              title: _weekly ? '本周支出分类' : '本月支出分类',
            ),
            const SizedBox(height: kSpace4),
            _buildBalanceMini(balanceSeries),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final dateFmt = DateFormat('M月d日 EEEE', 'zh_CN');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('记账本',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: kInkPrimary,
                      height: 1.2)),
              const SizedBox(height: 2),
              Text(dateFmt.format(now),
                  style:
                      const TextStyle(fontSize: 13, color: kInkSecondary)),
            ],
          ),
        ),
        InkWell(
          onTap: () => showBookSwitcher(context),
          borderRadius: BorderRadius.circular(kRadiusTable),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: kSpace3, vertical: 8),
            decoration: BoxDecoration(
              color: kPaperSurface,
              border: Border.all(color: kDividerDefault, width: 1),
              borderRadius: BorderRadius.circular(kRadiusTable),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.read<AppState>().currentBook.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 2),
                const Icon(Icons.expand_more_rounded,
                    size: 18, color: kInkSecondary),
              ],
            ),
          ),
        ),
        ],
    );
  }

  Widget _buildSummary(MonthSummary summary, int budget, int spent,
      bool isCurrentMonth, int remaining, int daily) {
    return PaperGroup(
      padding: const EdgeInsets.fromLTRB(kSpace4, kSpace5, kSpace4, kSpace4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_weekly ? '本周支出' : '本月支出',
              style:
                  const TextStyle(fontSize: 13, color: kInkSecondary)),
          const SizedBox(height: 4),
          AmountText(summary.expense, size: 36, weight: FontWeight.w700),
          const SizedBox(height: kSpace3),
          Row(
            children: [
              _MiniStat(label: '收入', value: summary.income, color: kSuccess),
              const _VDivider(),
              _MiniStat(
                  label: '结余', value: summary.balance, color: kInkPrimary),
            ],
          ),
          const SizedBox(height: kSpace4),
          const Divider(color: kDividerSubtle),
          const SizedBox(height: kSpace3),
          if (!isCurrentMonth)
            const Text('仅展示当月概览，预算仅对本月生效',
                style: TextStyle(fontSize: 12, color: kInkSecondary))
          else if (budget <= 0)
            InkWell(
              onTap: () async {
                final v = await showBudgetDialog(context, budget);
                if (v != null && mounted) {
                  await context.read<AppState>().setBudget(v);
                }
              },
              child: const Row(
                children: [
                  Text('设置每月预算',
                      style:
                          TextStyle(fontSize: 13, color: kAccentBlue)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: kAccentBlue),
                ],
              ),
            )
          else
            _BudgetBar(
              budget: budget,
              spent: spent,
              remaining: remaining,
              daily: daily,
            ),
        ],
      ),
    );
  }

  Widget _buildRecent(List<Transaction> recent, {required bool weekly}) {
    return PaperGroup(
      title: '最近流水',
      padding: EdgeInsets.zero,
      trailing: TextButton(
        onPressed: widget.onGoLedger,
        style: TextButton.styleFrom(
          foregroundColor: kAccentBlue,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(48, 36),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('全部'),
            Icon(Icons.chevron_right_rounded, size: 16),
          ],
        ),
      ),
      child: recent.isEmpty
          ? EmptyState(
              title: weekly ? '本周还没有流水' : '本月还没有流水',
              message: '点击上方「记一笔」开始记录',
              actionLabel: '去记一笔',
              onAction: widget.onAdd,
            )
          : Column(
              children: [
                for (int i = 0; i < recent.length; i++) ...[
                  if (i > 0) const Divider(indent: 68),
                  TransactionTile(
                    transaction: recent[i],
                    onTap: widget.onGoLedger,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildRanking(
      List<({TxCategory category, int amount})> ranking, {
      required String title}) {
    return PaperGroup(
      title: title,
      padding: const EdgeInsets.all(kSpace4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CategoryRanking(items: ranking, maxItems: 5),
          if (ranking.isNotEmpty) ...[
            const SizedBox(height: kSpace3),
            TextButton(
              onPressed: widget.onGoStats,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 40),
                padding: EdgeInsets.zero,
              ),
              child: const Text('查看完整统计 ›'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceMini(
      List<({DateTime month, int balance})> series) {
    final maxAbs = series.fold<int>(
        0, (m, e) => e.balance.abs() > m ? e.balance.abs() : m);
    return PaperGroup(
      title: '结余走势',
      padding: const EdgeInsets.all(kSpace4),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: widget.onGoProfile,
            borderRadius: BorderRadius.circular(kRadiusTable),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '总资产 ${AmountText.format(context.read<AppState>().totalAssets)}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kInkPrimary,
                    fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ),
          ),
          const SizedBox(width: kSpace2),
          InkWell(
            onTap: widget.onGoStats,
            borderRadius: BorderRadius.circular(kRadiusTable),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('查看统计',
                      style: TextStyle(
                          fontSize: 12, color: kAccentBlue)),
                  Icon(Icons.chevron_right_rounded,
                      size: 14, color: kAccentBlue),
                ],
              ),
            ),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onGoStats,
        borderRadius: BorderRadius.circular(kRadiusTable),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final e in series)
              Expanded(
                child: _MiniBar(
                  month: e.month,
                  balance: e.balance,
                  maxAbs: maxAbs,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static bool _isCurrent(DateTime m) {
    final now = DateTime.now();
    return m.year == now.year && m.month == now.month;
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: kInkSecondary)),
          const SizedBox(height: 2),
          AmountText(value,
              size: 16, weight: FontWeight.w600, color: color),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: kDividerSubtle);
  }
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.daily,
  });

  final int budget;
  final int spent;
  final int remaining;
  final int daily;

  @override
  Widget build(BuildContext context) {
    final ratio = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final over = spent > budget;
    final nearLimit = !over && ratio >= 0.8;
    final color = over ? kDanger : kInkPrimary;
    return InkWell(
      onTap: () async {
        final v = await showBudgetDialog(context, budget);
        if (v != null && context.mounted) {
          await context.read<AppState>().setBudget(v);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('本月预算',
                  style: TextStyle(fontSize: 12, color: kInkSecondary)),
              const Spacer(),
              Text(
                '${AmountText.format(spent, showSymbol: false)} / ${AmountText.format(budget, showSymbol: false)}'
                ' · ${(ratio * 100).round()}%',
                style: TextStyle(
                    fontSize: 12,
                    color: over ? kDanger : kInkSecondary,
                    fontWeight: over ? FontWeight.w600 : FontWeight.w400),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Container(color: kDividerSubtle),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    alignment: Alignment.centerLeft,
                    child: Container(color: color),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            over
                ? '已超出预算 ¥${AmountText.format(spent - budget, showSymbol: false)}'
                : nearLimit
                    ? '已用 ${(ratio * 100).round()}%，注意控制'
                    : '剩余 ¥${AmountText.format(remaining, showSymbol: false)} · 日均 ¥${AmountText.format(daily, showSymbol: false)} · 剩 ${context.read<AppState>().budgetDaysLeft} 天',
            style: TextStyle(
                fontSize: 11, color: over ? kDanger : kInkDisabled),
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({
    required this.month,
    required this.balance,
    required this.maxAbs,
  });

  final DateTime month;
  final int balance;
  final int maxAbs;

  @override
  Widget build(BuildContext context) {
    final ratio = maxAbs == 0
        ? 0.0
        : (balance.abs() / maxAbs).clamp(0.0, 1.0);
    final barH = (ratio * 56).clamp(2.0, 56.0);
    final isPos = balance >= 0;
    return Column(
      children: [
        Text('${month.month}月',
            style: const TextStyle(fontSize: 10, color: kInkSecondary)),
        const SizedBox(height: kSpace2),
        SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: isPos ? barH : 1.5,
                color: isPos ? kInkPrimary : kDividerSubtle,
              ),
              Container(width: 10, height: 1, color: kDividerDefault),
              Container(
                width: 10,
                height: isPos ? 1.5 : barH,
                color: isPos ? kDividerSubtle : kDanger,
              ),
            ],
          ),
        ),
        const SizedBox(height: kSpace2),
        Text('${(balance / 100).round()}',
            style: TextStyle(
              fontSize: 9,
              color: isPos ? kInkSecondary : kDanger,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
      ],
    );
  }
}


class _HomeModeTag extends StatelessWidget {
  const _HomeModeTag({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusTable),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kAccentSoft : kPaperSurface,
          borderRadius: BorderRadius.circular(kRadiusTable),
          border: Border.all(
            color: selected ? kAccentBlue : kDividerDefault,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? kAccentBlue : kInkSecondary,
          ),
        ),
      ),
    );
  }
}
