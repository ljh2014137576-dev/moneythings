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
  final _searchController = TextEditingController();
  String _query = '';
  bool _showAll = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _visible(List<Transaction> all) {
    var byType = switch (_filter) {
      _Filter.all => all,
      _Filter.expense =>
        all.where((t) => t.type == TxType.expense).toList(),
      _Filter.income => all.where((t) => t.type == TxType.income).toList(),
    };
    if (_rangeStart != null || _rangeEnd != null) {
      final s = _rangeStart ?? DateTime(2000);
      final e = _rangeEnd ?? DateTime(2100);
      byType = [
        for (final t in byType)
          if (!t.date.isBefore(s) && !t.date.isAfter(e)) t,
      ];
    }
    if (_query.isEmpty) return byType;
    final q = _query.toLowerCase();
    return [
      for (final t in byType)
        if (t.note.toLowerCase().contains(q) ||
            TxCategories.byId(t.categoryId).name.contains(q))
          t,
    ];
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
    final monthTx = _showAll
        ? state.currentBookTransactions
        : state.ofMonth(_month);
    final visible = _visible(monthTx);
    final groups = _groupByDay(visible);
    int sumExpense = 0, sumIncome = 0;
    for (final t in visible) {
      if (t.type == TxType.expense) {
        sumExpense += t.amount;
      } else {
        sumIncome += t.amount;
      }
    }

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
                const SizedBox(height: kSpace3),
                _buildSearchField(),
                const SizedBox(height: kSpace3),
                _buildTimeRow(),
                _buildFilterRow(),
                const SizedBox(height: kSpace3),
                _buildRangeRow(),
              ],
            ),
          ),
          const SizedBox(height: kSpace3),
          if (visible.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  kPagePadding, 0, kPagePadding, kSpace2),
              child: _LedgerSummary(
                count: visible.length,
                expense: sumExpense,
                income: sumIncome,
              ),
            ),
          Expanded(
            child: (monthTx.isEmpty || (visible.isEmpty && _query.isNotEmpty))
                ? EmptyState(
                    title: _query.isNotEmpty ? "没有找到相关流水" : "本月还没有流水",
                    message: _query.isNotEmpty
                        ? "换个关键词或清除搜索试试"
                        : "回到首页点击「记一笔」开始记录",
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
                          onDismiss: _deleteWithUndo,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: kPaperSurface,
        border: Border.all(color: kDividerDefault, width: 1),
        borderRadius: BorderRadius.circular(kRadiusTable),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v.trim()),
        decoration: InputDecoration(
          hintText: '搜索备注或分类',
          hintStyle: const TextStyle(fontSize: 14, color: kInkDisabled),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: kInkSecondary),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  tooltip: '清除搜索',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: kInkSecondary),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: kSpace3, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildTimeRow() {
    return Row(
      children: [
        const Text('时间：',
            style: TextStyle(fontSize: 13, color: kInkSecondary)),
        _FilterTag(
          label: _showAll ? '全部时间' : '本月',
          selected: _showAll,
          onTap: () => setState(() => _showAll = !_showAll),
        ),
      ],
    );
  }

  Widget _buildRangeRow() {
    final hasRange = _rangeStart != null || _rangeEnd != null;
    final fmt = DateFormat('M月d日', 'zh_CN');
    final label = hasRange
        ? '${fmt.format(_rangeStart!)} ~ ${fmt.format(_rangeEnd!)}'
        : '全部日期';
    return Row(
      children: [
        InkWell(
          onTap: _showRangeSheet,
          borderRadius: BorderRadius.circular(kRadiusTable),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.date_range_outlined,
                    size: 18, color: kInkSecondary),
                const SizedBox(width: 6),
                Text('日期：$label',
                    style: const TextStyle(
                        fontSize: 13, color: kInkPrimary)),
                const Icon(Icons.expand_more_rounded,
                    size: 16, color: kInkSecondary),
              ],
            ),
          ),
        ),
        if (hasRange)
          TextButton(
            onPressed: () => setState(() {
              _rangeStart = null;
              _rangeEnd = null;
            }),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('清除',
                style: TextStyle(fontSize: 13, color: kAccentBlue)),
          ),
      ],
    );
  }

  Future<void> _showRangeSheet() async {
    final now = DateTime.now();
    final start = _rangeStart ?? DateTime(now.year, now.month, 1);
    final end = _rangeEnd ?? now;
    final pickedStart = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: '选择开始日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (pickedStart == null || !mounted) return;
    final pickedEnd = await showDatePicker(
      context: context,
      initialDate: pickedStart.isAfter(end) ? pickedStart : end,
      firstDate: pickedStart,
      lastDate: now,
      helpText: '选择结束日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (pickedEnd == null || !mounted) return;
    setState(() {
      _rangeStart =
          DateTime(pickedStart.year, pickedStart.month, pickedStart.day);
      _rangeEnd =
          DateTime(pickedEnd.year, pickedEnd.month, pickedEnd.day);
    });
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

  Future<void> _deleteWithUndo(Transaction tx) async {
    final state = context.read<AppState>();
    await state.deleteTransaction(tx.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('已删除 ${AmountText.format(tx.amount)}'),
          action: SnackBarAction(
            label: '撤销',
            textColor: kAccentBlue,
            onPressed: () => state.addTransaction(tx),
          ),
        ),
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
    required this.onDismiss,
  });

  final DateTime date;
  final List<Transaction> items;
  final ValueChanged<Transaction> onTapItem;
  final ValueChanged<Transaction> onDismiss;

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
            Dismissible(
              key: ValueKey(items[i].id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: kDanger,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: kSpace4),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white, size: 22),
              ),
              onDismissed: (_) => onDismiss(items[i]),
              child: TransactionTile(
                transaction: items[i],
                onTap: () => onTapItem(items[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

 
class _LedgerSummary extends StatelessWidget {
  const _LedgerSummary({
    required this.count,
    required this.expense,
    required this.income,
  });

  final int count;
  final int expense;
  final int income;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace2),
      decoration: BoxDecoration(
        color: kPaperSurface,
        border: Border.all(color: kDividerDefault, width: 1),
        borderRadius: BorderRadius.circular(kRadiusTable),
      ),
      child: Row(
        children: [
          Text('共 $count 笔',
              style: const TextStyle(
                  fontSize: 12, color: kInkSecondary)),
          const Spacer(),
          if (expense > 0) ...[
            const Text('支出 ',
                style: TextStyle(fontSize: 12, color: kInkSecondary)),
            AmountText(expense,
                size: 13, weight: FontWeight.w600, color: kInkPrimary),
          ],
          if (expense > 0 && income > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: kSpace2),
              child: Text('·',
                  style: TextStyle(fontSize: 12, color: kInkSecondary)),
            ),
          if (income > 0) ...[
            const Text('收入 ',
                style: TextStyle(fontSize: 12, color: kInkSecondary)),
            AmountText(income,
                size: 13, weight: FontWeight.w600, color: kSuccess),
          ],
        ],
      ),
    );
  }
}
