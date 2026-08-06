/// 明细页：按月分组流水列表，可按收支筛选
library;

import 'dart:collection';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';
import '../widgets/amount_text.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_selector.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_page.dart';

enum _Filter { all, expense, income }

class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  late DateTime _month;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  List<Transaction> _visible(List<Transaction> all) {
    return switch (_filter) {
      _Filter.all => all,
      _Filter.expense =>
        all.where((t) => t.type == TxType.expense).toList(),
      _Filter.income => all.where((t) => t.type == TxType.income).toList(),
    };
  }

  Map<DateTime, List<Transaction>> _groupByDay(List<Transaction> list) {
    final map = <DateTime, List<Transaction>>{};
    for (final t in list) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(key, () => []).add(t);
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return LinkedHashMap.fromEntries(sorted);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final monthTx = state.ofMonth(_month);
    final visible = _visible(monthTx);
    final groups = _groupByDay(visible);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                kPagePadding, kSpace3, kPagePadding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('明细',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: kInkPrimary)),
                const SizedBox(height: kSpace2),
                MonthSelector(
                  month: _month,
                  onChanged: (m) => setState(() => _month = m),
                ),
                const SizedBox(height: kSpace3),
                _buildFilterRow(),
              ],
            ),
          ),
          const SizedBox(height: kSpace3),
          Expanded(
            child: monthTx.isEmpty
                ? EmptyState(
                    title: '本月还没有流水',
                    message: '点击底部「记一笔」开始记录',
                    onAction: null,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        kPagePadding, 0, kPagePadding, kSpace6),
                    children: [
                      for (final group in groups.entries) ...[
                        if (group.key != groups.keys.first)
                          const SizedBox(height: kSpace3),
                        _DayGroup(
                          date: group.key,
                          items: group.value,
                          onTapItem: (tx) => _edit(tx),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        for (final f in _Filter.values)
          Padding(
            padding: const EdgeInsets.only(right: kSpace2),
            child: _FilterTag(
              label: switch (f) {
                _Filter.all => '全部',
                _Filter.expense => '支出',
                _Filter.income => '收入',
              },
              selected: _filter == f,
              onTap: () => setState(() => _filter = f),
            ),
          ),
      ],
    );
  }

  Future<void> _edit(Transaction tx) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddTransactionPage(editing: tx)),
    );
  }
}

class _FilterTag extends StatelessWidget {
  const _FilterTag({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.date,
    required this.items,
    required this.onTapItem,
  });

  final DateTime date;
  final List<Transaction> items;
  final ValueChanged<Transaction> onTapItem;

  @override
  Widget build(BuildContext context) {
    int expense = 0, income = 0;
    for (final t in items) {
      if (t.type == TxType.expense) {
        expense += t.amount;
      } else {
        income += t.amount;
      }
    }
    final fmt = DateFormat('M月d日 EEEE', 'zh_CN');

    return Container(
      decoration: BoxDecoration(
        color: kPaperSurface,
        borderRadius: BorderRadius.circular(kRadiusTable),
        border: Border.all(color: kDividerDefault, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(kSpace4, kSpace3, kSpace4, kSpace2),
            child: Row(
              children: [
                Text(fmt.format(date),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (expense > 0)
                  Text('支出 ${AmountText.format(expense, showSymbol: false)}',
                      style: const TextStyle(
                          fontSize: 12, color: kInkSecondary)),
                if (expense > 0 && income > 0)
                  const Text('  ·  ',
                      style: TextStyle(fontSize: 12, color: kInkSecondary)),
                if (income > 0)
                  Text('收入 ${AmountText.format(income, showSymbol: false)}',
                      style: const TextStyle(
                          fontSize: 12, color: kSuccess)),
              ],
            ),
          ),
          const Divider(indent: kSpace4, endIndent: kSpace4),
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(indent: 68),
            TransactionTile(
              transaction: items[i],
              onTap: () => onTapItem(items[i]),
            ),
          ],
        ],
      ),
    );
  }
}

