/// 记一笔 / 编辑账目页
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/recurring_rule.dart';
import '../theme/app_colors.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/amount_text.dart';
import '../widgets/category_icon.dart';

/// 金额输入：最多两位小数
class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text)) return oldValue;
    return newValue;
  }
}

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key, this.editing, this.copyFrom});

  /// 传入则进入编辑模式
  final Transaction? editing;

  /// 传入则预填内容但作为新账目保存（日期保持今天）
  final Transaction? copyFrom;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late TxType _type;
  late String _categoryId;
  late String _accountId;
  late String _toAccountId;
  late DateTime _date;
  RecurFrequency _recur = RecurFrequency.none;
  String _note = '';
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    final src = e ?? widget.copyFrom;
    _type = src?.type ?? TxType.expense;
    _categoryId = src?.categoryId ?? TxCategories.expense.first.id;
    _accountId = src?.accountId ??
        context.read<AppState>().lastAccountId;
    final accounts = context.read<AppState>().accounts;
    _toAccountId = src?.transferToAccountId ??
        (accounts.firstWhere((a) => a.id != _accountId,
            orElse: () => accounts.last).id);
        context.read<AppState>().lastAccountId;
    _date = e?.date ?? DateTime.now();
    _note = src?.note ?? '';
    _noteController.text = _note;
    if (src != null && src.amount > 0) {
      _amountController.text = (src.amount / 100).toStringAsFixed(2);
    }
    // 编辑模式进入时聚焦金额输入
    if (e != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _amountFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  int _parseAmount() {
    final text = _amountController.text.trim();
    if (text.isEmpty || text == '.') return 0;
    final parts = text.split('.');
    final yuan = int.tryParse(parts[0]) ?? 0;
    final fenStr =
        parts.length > 1 ? parts[1].padRight(2, '0').substring(0, 2) : '00';
    final fen = int.tryParse(fenStr) ?? 0;
    return yuan * 100 + fen;
  }

  List<(String, DateTime)> _quickDates() {
    final now = DateTime.now();
    return [
      ('今天', now),
      ('昨天', now.subtract(const Duration(days: 1))),
    ];
  }

  Future<void> _pickRecur() async {
    final selected = await showModalBottomSheet<RecurFrequency>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in RecurFrequency.values)
              ListTile(
                leading: Icon(
                  f == RecurFrequency.none
                      ? Icons.block_rounded
                      : Icons.repeat_rounded,
                  color: kInkSecondary,
                ),
                title: Text(f.label),
                trailing: _recur == f
                    ? const Icon(Icons.check_rounded,
                        color: kAccentBlue, size: 20)
                    : null,
                onTap: () => Navigator.of(context).pop(f),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _recur = selected);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: '选择日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickToAccount() async {
    final state = context.read<AppState>();
    final selected = await showModalBottomSheet<Account>(
      context: context,
      builder: (context) => _AccountSheet(
        accounts: state.accounts,
        selectedId: _toAccountId,
        balances: {
          for (final a in state.accounts) a.id: state.balanceOf(a),
        },
      ),
    );
    if (selected != null && mounted) {
      setState(() => _toAccountId = selected.id);
    }
  }

  Future<void> _pickAccount() async {
    final state = context.read<AppState>();

    final selected = await showModalBottomSheet<Account>(
      context: context,
      builder: (context) => _AccountSheet(
        accounts: state.accounts,
        selectedId: _accountId,
        balances: {
          for (final a in state.accounts) a.id: state.balanceOf(a),
        },
      ),
    );
    if (selected != null && mounted) {
      setState(() => _accountId = selected.id);
    }
  }

  Future<void> _save() async {
    final amount = _parseAmount();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }
    final state = context.read<AppState>();
    if (_type == TxType.transfer && _toAccountId == _accountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('转出与转入账户不能相同')),
      );
      return;
    }
 
    // 预算超额提醒：仅当月支出且已设置预算
    final now = DateTime.now();
    final isThisMonth =
        _date.year == now.year && _date.month == now.month;
    if (isThisMonth &&
        _type == TxType.expense &&
        state.monthlyBudget > 0) {
      var spent = state.summaryOf(DateTime(now.year, now.month)).expense;
      // 编辑时扣除该笔原有金额，避免重复计算
      final e = widget.editing;
      if (e != null &&
          e.date.year == now.year &&
          e.date.month == now.month) {
        spent -= e.amount;
      }
      final projected = spent + amount;
      if (projected > state.monthlyBudget) {
        final over = projected - state.monthlyBudget;
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('超出本月预算',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            content: Text(
              '本月预算 ${AmountText.format(state.monthlyBudget)}，'
              '保存这笔支出后将超出 ${AmountText.format(over)}。仍要保存吗？',
              style: const TextStyle(
                  fontSize: 14, color: kInkSecondary, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: kDanger),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('继续保存'),
              ),
            ],
          ),
        );
        if (ok != true || !mounted) return;
        if (context.read<AppState>().budgetNotify) {
          await NotificationService.instance.notifyBudgetOverrun(over);
        }
      }
    }
    String? createdRuleId;
    final tx = Transaction(
      id: widget.editing?.id ?? _newId(),
      type: _type,
      amount: amount,
      categoryId: _categoryId,
      accountId: _accountId,
      note: _noteController.text.trim(),
      transferToAccountId: _type == TxType.transfer ? _toAccountId : null,
      date: _date,
    );
    if (_isEdit) {
      await state.updateTransaction(tx);
    } else {
      await state.addTransaction(tx);
      if (_recur != RecurFrequency.none) {
        final rule = RecurringRule(
          id: 'rc_${DateTime.now().microsecondsSinceEpoch}',
          type: _type,
          amount: amount,
          categoryId: _categoryId,
          accountId: _accountId,
          transferToAccountId:
              _type == TxType.transfer ? _toAccountId : null,
          note: _noteController.text.trim(),
          date: _date,
          nextDate: RecurringRule.nextAfter(_date, _recur),
          frequency: _recur,
          bookId: state.currentBookId,
        );
        createdRuleId = rule.id;
        await state.addRecurringRule(rule);
      }
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(
                child: Text('已保存 ${AmountText.format(amount)}'),
              ),
              if (!_isEdit) ...[
                TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: kAccentBlue),
                  onPressed: () {
                    state.deleteTransaction(tx.id);
                    if (createdRuleId != null) {
                      state.deleteRecurringRule(createdRuleId);
                    }
                  },
                  child: const Text('撤销'),
                ),
              ],
              TextButton(
                style:
                    TextButton.styleFrom(foregroundColor: kAccentBlue),
                onPressed: () {
                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionPage(),
                    ),
                  );
                },
                child: const Text('继续记一笔'),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这笔账目？',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: const Text('删除后无法恢复。',
            style: TextStyle(fontSize: 14, color: kInkSecondary)),
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
      await context.read<AppState>().deleteTransaction(widget.editing!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  static String _newId() =>
      'tx-${DateTime.now().microsecondsSinceEpoch}';

  @override
  Widget build(BuildContext context) {
    final categories = TxCategories.of(_type);

    return Scaffold(
      backgroundColor: kPageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    kPagePadding, 0, kPagePadding, kSpace6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTypeToggle(),
                    const SizedBox(height: kSpace3),
                    _buildLastRow(),
                    _buildAmountField(),
                    _buildQuickAmountRow(),
                    const SizedBox(height: kSpace3),
                    _buildKeypad(),
                    const SizedBox(height: kSpace3),
                    if (_type == TxType.transfer) ...[
                      _buildTransferHint(),
                    ] else ...[
                      const SizedBox(height: kSpace4),
                      _buildRecentRow(categories),
                      const SizedBox(height: kSpace3),
                      _buildCategoryGrid(categories),
                    ],
                    const SizedBox(height: kSpace4),
                    _buildMetaRows(),
                    const SizedBox(height: kSpace4),
                    _buildQuickNoteRow(),
                    const SizedBox(height: kSpace2),
                    TextField(
                      controller: _noteController,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        hintText: '备注（可选）',
                        counterText: '',
                        prefixIcon: Icon(Icons.edit_note_outlined,
                            size: 20, color: kInkSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpace2, vertical: kSpace2),
      child: Row(
        children: [
          Semantics(
            container: true,
            button: true,
            label: '关闭',
            child: IconButton(
              tooltip: '关闭',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded,
                  color: kInkPrimary, size: 22),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                _isEdit ? '编辑账目' : '记一笔',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: kInkPrimary,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: _isEdit
                ? Semantics(
                    container: true,
                    button: true,
                    label: '删除账目',
                    child: IconButton(
                      tooltip: '删除账目',
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: kDanger, size: 22),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kDividerDefault, width: 1),
        borderRadius: BorderRadius.circular(kRadiusTable),
      ),
      child: Row(
        children: [
          for (final type in TxType.values)
            Expanded(
              child: _TypeSegment(
                type: type,
                selected: _type == type,
                onTap: () {
                  if (_type == type) return;
                  setState(() {
                    _type = type;
                    final cats = TxCategories.of(type);
                    if (cats.isNotEmpty) _categoryId = cats.first.id;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLastRow() {
    final last = context.read<AppState>().lastTransactionOf(_type);
    if (last == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _fillFromLast(last),
        icon: const Icon(Icons.content_copy_rounded, size: 16),
        label: const Text('复制上一条'),
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 36),
          padding: const EdgeInsets.symmetric(horizontal: kSpace2),
          foregroundColor: kAccentBlue,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  void _fillFromLast(Transaction last) {
    if (last.type == TxType.transfer) {
      _toAccountId = last.transferToAccountId ?? _toAccountId;
    }
    setState(() {
      _categoryId = last.categoryId;
      _accountId = last.accountId;
      _noteController.text = last.note;
      _note = last.note;
      _amountController.text = (last.amount / 100).toStringAsFixed(2);
    });
  }

  Widget _buildQuickAmountRow() {
    return Row(
      children: [
        for (final v in const [10, 50, 100, 500])
          Padding(
            padding: const EdgeInsets.only(right: kSpace2),
            child: _QuickAmountChip(
              label: '+$v',
              onTap: () => _addAmount(v),
            ),
          ),
      ],
    );
  }

  void _addAmount(int yuan) {
    final current = _parseAmount();
    final next = (current + yuan * 100).clamp(0, 99999999);
    _amountController.text = (next / 100).toStringAsFixed(2);
    setState(() {});
  }

  Widget _buildKeypad() {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];
    return Container(
      decoration: BoxDecoration(
        color: kPaperSurface,
        border: Border.all(color: kDividerDefault, width: 1),
        borderRadius: BorderRadius.circular(kRadiusTable),
      ),
      child: Column(
        children: [
          for (int r = 0; r < keys.length; r++) ...[
            if (r > 0) const Divider(height: 1, color: kDividerSubtle),
            Row(
              children: [
                for (int c = 0; c < keys[r].length; c++) ...[
                  if (c > 0)
                    const VerticalDivider(
                        width: 1, color: kDividerSubtle),
                  Expanded(
                    child: _KeypadKey(
                      label: keys[r][c],
                      onTap: () {
                        final k = keys[r][c];
                        if (k == '⌫') {
                          _backspaceAmount();
                        } else {
                          _appendToAmount(k);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _appendToAmount(String ch) {
    var text = _amountController.text;
    if (ch == '.') {
      if (text.contains('.')) return;
      text = text.isEmpty ? '0.' : '$text.';
    } else {
      text = text == '0' ? ch : '$text$ch';
    }
    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text)) return;
    _amountController.text = text;
    setState(() {});
  }

  void _backspaceAmount() {
    final t = _amountController.text;
    if (t.isEmpty) return;
    _amountController.text = t.substring(0, t.length - 1);
    setState(() {});
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: kPaperSurface,
        border: Border.all(color: kDividerDefault, width: 1),
        borderRadius: BorderRadius.circular(kRadiusTable),
      ),
      padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('¥',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w600, color: kInkPrimary)),
          const SizedBox(width: kSpace2),
          Expanded(
            child: GestureDetector(
              onLongPress: () {
                final text = _amountController.text;
                if (text.isNotEmpty) {
                  _amountController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: text.length,
                  );
                }
              },
              child: TextField(
              controller: _amountController,
              focusNode: _amountFocus,
              autofocus: !_isEdit,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.none,
              inputFormatters: [_AmountInputFormatter()],
              style: amountStyle(size: 32),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: const TextStyle(color: kInkDisabled, fontSize: 32),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                suffixIcon: _amountController.text.isNotEmpty
                    ? IconButton(
                        tooltip: '清除金额',
                        onPressed: () {
                          _amountController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: kInkSecondary),
                      )
                    : null,
              ),
            ),
            ),
          ),
          Text(
            _type.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _type == TxType.income ? kSuccess : kInkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRow(List<TxCategory> categories) {
    final recentIds = context.read<AppState>().recentCategoryIds(_type);
    if (recentIds.isEmpty) return const SizedBox.shrink();
    final recentCats = <TxCategory>[
      for (final id in recentIds)
        for (final c in categories)
          if (c.id == id) c,
    ];
    if (recentCats.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('最近',
            style: TextStyle(fontSize: 12, color: kInkSecondary)),
        const SizedBox(height: kSpace2),
        Row(
          children: [
            for (final c in recentCats)
              Padding(
                padding: const EdgeInsets.only(right: kSpace2),
                child: _RecentChip(
                  category: c,
                  selected: _categoryId == c.id,
                  onTap: () => setState(() => _categoryId = c.id),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(List<TxCategory> categories) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: kSpace3,
      crossAxisSpacing: kSpace3,
      childAspectRatio: 1.05,
      children: [
        for (final c in categories)
          _CategoryCell(
            category: c,
            selected: _categoryId == c.id,
            onTap: () => setState(() => _categoryId = c.id),
          ),
      ],
    );
  }

  Widget _buildTransferHint() {
    return const Text(
      '转账仅调整账户余额，不计入收支统计',
      style: TextStyle(fontSize: 12, color: kInkSecondary),
    );
  }

  Widget _buildMetaRows() {
    final dateFmt = DateFormat('M月d日 EEEE', 'zh_CN');
    final account = accountById(_accountId);
    return Container(
      decoration: BoxDecoration(
        color: kPaperSurface,
        border: Border.all(color: kDividerDefault, width: 1),
        borderRadius: BorderRadius.circular(kRadiusTable),
      ),
      child: Column(
        children: [
          _SelectRow(
            icon: Icons.calendar_today_outlined,
            label: '日期',
            value: dateFmt.format(_date),
            onTap: _pickDate,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(kSpace4, kSpace2, kSpace4, kSpace2),
            child: Row(
              children: [
                for (final q in _quickDates())
                  Padding(
                    padding: const EdgeInsets.only(right: kSpace2),
                    child: _QuickAmountChip(
                      label: q.$1,
                      onTap: () => setState(() => _date = q.$2),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(indent: 52),
          if (_type == TxType.transfer) ...[
            _SelectRow(
              icon: Icons.output_rounded,
              label: '转出账户',
              value: accountById(_accountId).name,
              onTap: _pickAccount,
            ),
            const Divider(indent: 52),
            _SelectRow(
              icon: Icons.input_rounded,
              label: '转入账户',
              value: accountById(_toAccountId).name,
              onTap: _pickToAccount,
            ),
          ] else ...[
            _SelectRow(
              icon: Icons.account_balance_wallet_outlined,
              label: '账户',
              value: account.name,
              onTap: _pickAccount,
            ),
          ],
          const Divider(indent: 52),
          _SelectRow(
            icon: Icons.repeat_rounded,
            label: '周期',
            value: _recur.label,
            onTap: _pickRecur,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNoteRow() {
    const presets = ['午餐', '晚餐', '早餐', '地铁', '打车', '超市', '房租', '水电', '话费', '咖啡'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final n in presets)
            Padding(
              padding: const EdgeInsets.only(right: kSpace2),
              child: _QuickAmountChip(
                label: n,
                onTap: () {
                  _noteController.text = n;
                  _note = n;
                  setState(() {});
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kPaperSurface,
        border: Border(top: BorderSide(color: kDividerDefault, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kPagePadding, kSpace3, kPagePadding, kSpace3),
          child: FilledButton(
            onPressed: _save,
            child: Text(_isEdit ? '保存修改' : '保存'),
          ),
        ),
      ),
    );
  }
}

class _TypeSegment extends StatelessWidget {
  const _TypeSegment({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final TxType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kAccentSoft : Colors.transparent,
          border: Border(
            right: type != TxType.values.last
                ? const BorderSide(color: kDividerDefault, width: 1)
                : BorderSide.none,
          ),
        ),
        child: Text(
          type.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? kAccentBlue : kInkSecondary,
          ),
        ),
      ),
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TxCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? kAccentBlue : kInkPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusTable),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected ? kAccentSoft : const Color(0xFFF0F1EF),
              borderRadius: BorderRadius.circular(kRadiusTable),
              border: selected
                  ? Border.all(color: kAccentBlue, width: 1.5)
                  : null,
            ),
            child: Icon(category.icon, size: 22, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? kAccentBlue : kInkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kInkSecondary),
            const SizedBox(width: kSpace3),
            Text(label,
                style: const TextStyle(fontSize: 14, color: kInkPrimary)),
            const Spacer(),
            Text(value,
                style: const TextStyle(fontSize: 14, color: kInkPrimary)),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: kInkDisabled),
          ],
        ),
      ),
    );
  }
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet({
    required this.accounts,
    required this.selectedId,
    required this.balances,
  });

  final List<Account> accounts;
  final String selectedId;
  final Map<String, int> balances;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(kSpace4, kSpace4, kSpace4, kSpace2),
            child: Text(
              '选择账户',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(),
          for (final a in accounts)
            InkWell(
              onTap: () => Navigator.of(context).pop(a),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace3),
                child: Row(
                  children: [
                    CategoryIcon(
                      TxCategory.expense(a.id, a.name, a.icon),
                      size: 36,
                    ),
                    const SizedBox(width: kSpace3),
                    Expanded(
                      child: Text(a.name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                    ),
                    Text(
                      AmountText.format(balances[a.id] ?? 0),
                      style: const TextStyle(
                          fontSize: 14, color: kInkSecondary),
                    ),
                    if (a.id == selectedId) ...[
                      const SizedBox(width: kSpace2),
                      const Icon(Icons.check_rounded,
                          size: 18, color: kAccentBlue),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: kSpace2),
        ],
      ),
    );
  }
}






class _RecentChip extends StatelessWidget {
  const _RecentChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TxCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? kAccentBlue : kInkPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusTable),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: kSpace3, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kAccentSoft : const Color(0xFFF0F1EF),
          borderRadius: BorderRadius.circular(kRadiusTable),
          border: selected
              ? Border.all(color: kAccentBlue, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(category.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                )),
          ],
        ),
      ),
    );
  }
}


class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusTable),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: kSpace3, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F1EF),
          borderRadius: BorderRadius.circular(kRadiusTable),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kInkPrimary,
                fontFeatures: [FontFeature.tabularFigures()])),
      ),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label == '⌫' ? '删除一位' : '数字 $label',
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: kInkPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
