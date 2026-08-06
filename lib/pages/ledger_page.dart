/// 明细页：按月分组流水列表，可按收支筛选
library;

import 'dart:async';
import 'dart:collection';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';
import '../services/csv_exporter.dart';
import '../services/export_target.dart';
import '../widgets/amount_text.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_selector.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_page.dart';

enum _Filter { all, expense, income }

class LedgerPage extends StatefulWidget {
  const LedgerPage({
    super.key,
    this.initialAccountId,
    this.initialCategoryId,
  });

  /// 打开时预置的账户筛选
  final String? initialAccountId;

  /// 打开时预置的分类筛选
  final String? initialCategoryId;

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  late DateTime _month;
  _Filter _filter = _Filter.all;
  final _searchController = TextEditingController();
  String _query = '';
  Timer? _searchDebounce;
  bool _showAll = false;
  String _accountFilter = 'all';
  String _categoryFilter = 'all';
  int? _amountMin;
  int? _amountMax;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  bool _sortByAmount = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    if (widget.initialAccountId != null) {
      _accountFilter = widget.initialAccountId!;
    }
    if (widget.initialCategoryId != null) {
      _categoryFilter = widget.initialCategoryId!;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
    if (_accountFilter != 'all') {
      byType = [
        for (final t in byType)
          if (t.accountId == _accountFilter) t,
      ];
    }
    if (_categoryFilter != 'all') {
      byType = [
        for (final t in byType)
          if (t.categoryId == _categoryFilter) t,
      ];
    }
    if (_amountMin != null || _amountMax != null) {
      byType = [
        for (final t in byType)
          if ((_amountMin == null || t.amount >= _amountMin!) &&
              (_amountMax == null || t.amount <= _amountMax!))
            t,
      ];
    }
    if (_query.isEmpty) return byType;
    final q = _query.toLowerCase();
    // 金额搜索：纯数字（支持小数）时按金额匹配
    if (RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(q)) {
      final parts = q.split('.');
      final yuan = int.tryParse(parts[0]) ?? 0;
      final fen = parts.length > 1
          ? int.tryParse(parts[1].padRight(2, '0').substring(0, 2)) ?? 0
          : 0;
      final cents = yuan * 100 + fen;
      return [for (final t in byType) if (t.amount == cents) t];
    }

    final matched = [
      for (final t in byType)
        if (t.note.toLowerCase().contains(q) ||
            TxCategories.byId(t.categoryId).name.contains(q) ||
            accountById(t.accountId).name.contains(q))
          t,
    ];
    if (_sortByAmount) {
      matched.sort((a, b) => b.amount.compareTo(a.amount));
    }
    return matched;
  }

  Map<DateTime, List<Transaction>> _groupByDay(
    List<Transaction> list, {
    bool byAmount = false,
  }) {
    final map = <DateTime, List<Transaction>>{};
    for (final t in list) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(key, () => []).add(t);
    }
    final sorted = map.entries.toList();
    if (byAmount) {
      // 金额排序：分组按组内最大金额降序（组内已按金额降序）
      sorted.sort((a, b) => _groupMaxAmount(b.value)
          .compareTo(_groupMaxAmount(a.value)));
    } else {
      sorted.sort((a, b) => b.key.compareTo(a.key));
    }
    return LinkedHashMap.fromEntries(sorted);
  }

  int _groupMaxAmount(List<Transaction> items) {
    var max = 0;
    for (final t in items) {
      if (t.amount > max) max = t.amount;
    }
    return max;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final monthTx = _showAll
        ? state.currentBookTransactions
        : state.ofMonth(_month);
    final visible = _visible(monthTx);
    if (_sortByAmount) {
      visible.sort((a, b) => b.amount.compareTo(a.amount));
    }
    final groups = _groupByDay(visible, byAmount: _sortByAmount);
    int sumExpense = 0, sumIncome = 0;
    for (final t in visible) {
      switch (t.type) {
        case TxType.expense:
          sumExpense += t.amount;
        case TxType.income:
          sumIncome += t.amount;
        case TxType.transfer:
          break;
      }
    }
    return Scaffold(
      backgroundColor: kPageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectionMode) _buildSelectionBar(),
          Expanded(
            child: (monthTx.isEmpty ||
                    (visible.isEmpty && _query.isNotEmpty))
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderColumn(),
                        const SizedBox(height: kSpace3),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: kSpace6),
                          child: EmptyState(
                            title: _query.isNotEmpty
                                ? '没有找到相关流水'
                                : '本月还没有流水',
                            message: _query.isNotEmpty
                                ? '换个关键词或清除搜索试试'
                                : '回到首页点击「记一笔」开始记录',
                            onAction: null,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(
                        top: kSpace3, bottom: kSpace6),
                    children: [
                      _buildHeaderColumn(),
                      if (visible.isNotEmpty) ...[
                        const SizedBox(height: kSpace3),
                        _LedgerSummary(
                          count: visible.length,
                          expense: sumExpense,
                          income: sumIncome,
                        ),
                      ],
                      const SizedBox(height: kSpace3),
                      for (final group in groups.entries) ...[
                        if (group.key != groups.keys.first)
                          const SizedBox(height: kSpace3),
                        _DayGroup(
                          date: group.key,
                          items: group.value,
                          onTapItem: _onRowTap,
                          onDismiss: _deleteWithUndo,
                          onLongPressItem: _longPress,
                          selectedIds: _selectedIds,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      color: kPaperSurface,
      padding: const EdgeInsets.symmetric(horizontal: kSpace2, vertical: 2),
      child: Row(
        children: [
          IconButton(
            tooltip: '取消多选',
            onPressed: _exitSelection,
            icon: const Icon(Icons.close_rounded,
                size: 20, color: kInkPrimary),
          ),
          Expanded(
            child: Text('已选 ${_selectedIds.length} 项',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: _selectAllVisible,
            child: const Text('全选',
                style: TextStyle(fontSize: 13, color: kAccentBlue)),
          ),
          IconButton(
            tooltip: '删除选中',
            onPressed: _deleteSelected,
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: kDanger),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderColumn() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          kPagePadding, kSpace3, kPagePadding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('明细',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: kInkPrimary)),
              ),
              IconButton(
                tooltip: '导出当前筛选结果',
                onPressed: _exportVisible,
                icon: const Icon(Icons.ios_share_outlined,
                    size: 20, color: kInkPrimary),
              ),
            ],
          ),
          const SizedBox(height: kSpace2),
          MonthSelector(
            month: _month,
            onChanged: (m) => setState(() => _month = m),
          ),
          const SizedBox(height: kSpace2),
          _buildSearchField(),
          if (_query.isEmpty) _buildRecentSearches(),
          const SizedBox(height: kSpace2),
          _buildTimeRow(),
          const SizedBox(height: kSpace2),
          _buildFilterRow(),
          const SizedBox(height: kSpace2),
          _buildAccountFilterRow(),
          const SizedBox(height: kSpace2),
          _buildRangeRow(),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    final recents = context.watch<AppState>().recentSearches;
    if (recents.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: kSpace2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('最近搜索',
                  style:
                      TextStyle(fontSize: 12, color: kInkSecondary)),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    context.read<AppState>().clearRecentSearches(),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 28),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('清除',
                    style:
                        TextStyle(fontSize: 12, color: kInkDisabled)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: kSpace2,
            runSpacing: kSpace2,
            children: [
              for (final s in recents)
                InkWell(
                  onTap: () {
                    _searchController.text = s;
                    setState(() => _query = s);
                  },
                  borderRadius: BorderRadius.circular(kRadiusTable),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: kSpace3, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1EF),
                      borderRadius: BorderRadius.circular(kRadiusTable),
                    ),
                    child: Text(s,
                        style: const TextStyle(
                            fontSize: 12, color: kInkPrimary)),
                  ),
                ),
            ],
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
        onChanged: (v) {
          setState(() => _query = v.trim());
          _searchDebounce?.cancel();
          _searchDebounce = Timer(const Duration(milliseconds: 600), () {
            final t = v.trim();
            if (t.isNotEmpty) {
              context.read<AppState>().recordSearch(t);
            }
          });
        },
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

  Widget _buildAccountFilterRow() {
    final cats = switch (_filter) {
      _Filter.all => [
        ...TxCategories.of(TxType.expense),
        ...TxCategories.of(TxType.income),
      ],
      _Filter.expense => TxCategories.of(TxType.expense),
      _Filter.income => TxCategories.of(TxType.income),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterTag(
            label: '全部账户',
            selected: _accountFilter == 'all',
            onTap: () => setState(() => _accountFilter = 'all'),
          ),
          const SizedBox(width: kSpace2),
          for (final a in kDefaultAccounts)
            Padding(
              padding: const EdgeInsets.only(right: kSpace2),
              child: _FilterTag(
                label: a.name,
                selected: _accountFilter == a.id,
                onTap: () => setState(() => _accountFilter = a.id),
              ),
            ),
          const SizedBox(width: kSpace2),
          Container(
            width: 1,
            height: 18,
            color: kDividerDefault,
          ),
          const SizedBox(width: kSpace2),
          _FilterTag(
            label: '全部分类',
            selected: _categoryFilter == 'all',
            onTap: () => setState(() => _categoryFilter = 'all'),
          ),
          const SizedBox(width: kSpace2),
          for (final c in cats)
            Padding(
              padding: const EdgeInsets.only(right: kSpace2),
              child: _FilterTag(
                label: c.name,
                selected: _categoryFilter == c.id,
                onTap: () => setState(() => _categoryFilter = c.id),
              ),
            ),
        ],
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
    final hasAmount = _amountMin != null || _amountMax != null;
    final fmt = DateFormat('M月d日', 'zh_CN');
    final dateLabel = hasRange
        ? '${fmt.format(_rangeStart!)} ~ ${fmt.format(_rangeEnd!)}'
        : '全部日期';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _rangeChip(
            icon: Icons.date_range_outlined,
            label: '日期：$dateLabel',
            onTap: _showRangeSheet,
          ),
          if (hasRange)
            _clearFilterButton(() => setState(() {
              _rangeStart = null;
              _rangeEnd = null;
            })),
          const SizedBox(width: kSpace3),
          _rangeChip(
            icon: Icons.payments_outlined,
            label: '金额：${hasAmount ? _amountRangeLabel() : '全部金额'}',
            onTap: _showAmountSheet,
          ),
          if (hasAmount)
            _clearFilterButton(() => setState(() {
              _amountMin = null;
              _amountMax = null;
            })),
        ],
      ),
    );
  }

  Widget _rangeChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusTable),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: kInkSecondary),
            const SizedBox(width: 6),
            Text(label,
                style:
                    const TextStyle(fontSize: 13, color: kInkPrimary)),
            const Icon(Icons.expand_more_rounded,
                size: 16, color: kInkSecondary),
          ],
        ),
      ),
    );
  }

  Widget _clearFilterButton(VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 32),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: const Text('清除',
          style: TextStyle(fontSize: 13, color: kAccentBlue)),
    );
  }

  String _amountRangeLabel() {
    String fmt(int v) => AmountText.format(v, showSymbol: false);
    if (_amountMin != null && _amountMax != null) {
      return '${fmt(_amountMin!)} ~ ${fmt(_amountMax!)}';
    }
    if (_amountMin != null) return '≥ ${fmt(_amountMin!)}';
    return '≤ ${fmt(_amountMax!)}';
  }

  Future<void> _showRangeSheet() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final preset = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding:
                  EdgeInsets.fromLTRB(kSpace4, kSpace4, kSpace4, kSpace2),
              child: Text('日期范围',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(height: 1),
            _presetTile(context, '本月', 'month', () => setRange(
                DateTime(now.year, now.month, 1), today)),
            _presetTile(context, '上月', 'lastMonth', () => setRange(
                DateTime(now.year, now.month - 1, 1),
                DateTime(now.year, now.month, 0))),
            _presetTile(context, '近 7 天', 'week7', () => setRange(
                today.subtract(const Duration(days: 6)), today)),
            _presetTile(context, '近 30 天', 'month30', () => setRange(
                today.subtract(const Duration(days: 29)), today)),
            _presetTile(context, '自定义', 'custom', () =>
                Navigator.of(context).pop('custom')),
          ],
        ),
      ),
    );
    if (preset == null || !mounted) return;
    if (preset == 'custom') {
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
      setRange(
          DateTime(pickedStart.year, pickedStart.month, pickedStart.day),
          DateTime(pickedEnd.year, pickedEnd.month, pickedEnd.day));
    }
  }

  void setRange(DateTime start, DateTime end) {
    setState(() {
      _rangeStart = start;
      _rangeEnd = end;
    });
  }

  Widget _presetTile(BuildContext context, String label, String value,
      VoidCallback onTap) {
    return ListTile(
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right_rounded,
          size: 18, color: kInkDisabled),
      onTap: () {
        if (value == 'custom') {
          onTap();
        } else {
          Navigator.of(context).pop(value);
          onTap();
        }
      },
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
              onTap: () => setState(() {
                _filter = f;
                _categoryFilter = 'all';
              }),
            ),
          ),
        const Spacer(),
        _FilterTag(
          label: _sortByAmount ? '金额' : '日期',
          selected: _sortByAmount,
          onTap: () => setState(() => _sortByAmount = !_sortByAmount),
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

  void _onRowTap(Transaction tx) {
    if (_selectionMode) {
      setState(() {
        if (!_selectedIds.remove(tx.id)) _selectedIds.add(tx.id);
      });
    } else {
      _edit(tx);
    }
  }

  void _enterSelection() {
    setState(() {
      _selectionMode = true;
      _selectedIds.clear();
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _selectAllVisible() {
    final state = context.read<AppState>();
    final source = _showAll
        ? state.currentBookTransactions
        : state.ofMonth(_month);
    final ids = _visible(source).map((t) => t.id).toSet();
    setState(() => _selectedIds.addAll(ids));
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除选中的流水？',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text('将删除选中的 ${_selectedIds.length} 笔流水，无法恢复。',
            style: const TextStyle(fontSize: 14, color: kInkSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kDanger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final state = context.read<AppState>();
      for (final id in _selectedIds.toList()) {
        await state.deleteTransaction(id);
      }
      if (mounted) _exitSelection();
    }
  }

  Future<void> _longPress(Transaction tx) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(kSpace4, kSpace3, kSpace4, kSpace2),
              child: Text(
                '${AmountText.format(tx.amount)} · ${TxCategories.byId(tx.categoryId).name}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  size: 20, color: kInkPrimary),
              title: const Text('编辑'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.content_copy_rounded,
                  size: 20, color: kInkPrimary),
              title: const Text('复制为新的账目'),
              onTap: () => Navigator.of(context).pop('copy'),
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded,
                  size: 20, color: kInkPrimary),
              title: const Text('多选删除'),
              onTap: () {
                Navigator.of(context).pop();
                _enterSelection();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, size: 20, color: kDanger),
              title: const Text('删除',
                  style: TextStyle(color: kDanger)),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      await _edit(tx);
    } else if (action == 'copy') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddTransactionPage(copyFrom: tx),
        ),
      );
    } else if (action == 'delete') {
      await _deleteWithUndo(tx);
    }

  }
  Future<void> _showAmountSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => _AmountSheet(
        initialMin: _amountMin,
        initialMax: _amountMax,
        onApply: (min, max) {
          setState(() {
            _amountMin = min;
            _amountMax = max;
          });
        },
      ),
    );
  }

  Future<void> _exportVisible() async {
    final state = context.read<AppState>();
    final source = _showAll
        ? state.currentBookTransactions
        : state.ofMonth(_month);
    final txs = _visible(source);
    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前筛选暂无数据可导出')),
      );
      return;
    }
    final now = DateTime.now();
    final stamp = '${now.year}${_p2(now.month)}${_p2(now.day)}';
    final csv = CsvExporter.exportCsv(
      txs,
      bookNames: {for (final b in state.books) b.id: b.name},
      metaLines: ['导出时间：$stamp', '范围：当前筛选'],
    );
    try {
      final where = await exportCsvFile(
        csv,
        '记账本流水_筛选_$stamp.csv',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出 ${txs.length} 条 → $where')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }

  static String _p2(int v) => v.toString().padLeft(2, '0');



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
    required this.selectedIds,
    required this.onLongPressItem,
    required this.onDismiss,
  });

  final DateTime date;
  final List<Transaction> items;
  final ValueChanged<Transaction> onTapItem;
  final Set<String> selectedIds;
  final ValueChanged<Transaction> onLongPressItem;
  final ValueChanged<Transaction> onDismiss;

  @override
  Widget build(BuildContext context) {
    int expense = 0, income = 0;
    for (final t in items) {
      switch (t.type) {
        case TxType.expense:
          expense += t.amount;
        case TxType.income:
          income += t.amount;
        case TxType.transfer:
          break;
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
                onLongPress: () => onLongPressItem(items[i]),
                selected: selectedIds.contains(items[i].id),
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
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('共 $count 笔',
              style: const TextStyle(
                  fontSize: 12, color: kInkSecondary)),
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
          if (income != expense) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: kSpace2),
              child: Text('·',
                  style: TextStyle(fontSize: 12, color: kInkSecondary)),
            ),
            const Text('结余 ',
                style: TextStyle(fontSize: 12, color: kInkSecondary)),
            AmountText(
              income - expense,
              size: 13,
              weight: FontWeight.w600,
              color: income - expense > 0 ? kSuccess : kDanger,
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.initialMin,
    required this.initialMax,
    required this.onApply,
  });

  final int? initialMin;
  final int? initialMax;
  final void Function(int? min, int? max) onApply;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
      text: widget.initialMin == null
          ? ''
          : (widget.initialMin! / 100).toStringAsFixed(2),
    );
    _maxCtrl = TextEditingController(
      text: widget.initialMax == null
          ? ''
          : (widget.initialMax! / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  int? _parseYuan(String s) {
    final v = double.tryParse(s.trim());
    if (v == null || v < 0) return null;
    return (v * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(kSpace4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('金额区间（元）',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: kSpace3),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '最低',
                      isDense: true,
                      prefixText: '¥ ',
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: kSpace2),
                  child: Text('~'),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '最高',
                      isDense: true,
                      prefixText: '¥ ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSpace3),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      widget.onApply(null, null);
                      Navigator.of(context).pop();
                    },
                    child: const Text('清除'),
                  ),
                ),
                const SizedBox(width: kSpace2),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final min = _parseYuan(_minCtrl.text);
                      final max = _parseYuan(_maxCtrl.text);
                      if (min != null && max != null && min > max) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('最低金额不能大于最高金额')),
                        );
                        return;
                      }
                      widget.onApply(min, max);
                      Navigator.of(context).pop();
                    },
                    child: const Text('确定'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
