/// 记一笔 / 编辑账目页
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';
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
  const AddTransactionPage({super.key, this.editing});

  /// 传入则进入编辑模式
  final Transaction? editing;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late TxType _type;
  late String _categoryId;
  late String _accountId;
  late DateTime _date;
  String _note = '';
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _type = e?.type ?? TxType.expense;
    _categoryId = e?.categoryId ?? TxCategories.expense.first.id;
    _accountId = e?.accountId ?? 'alipay';
    _date = e?.date ?? DateTime.now();
    _note = e?.note ?? '';
    _noteController.text = _note;
    if (e != null && e.amount > 0) {
      _amountController.text = (e.amount / 100).toStringAsFixed(2);
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

  Future<void> _pickAccount() async {
    final state = context.read<AppState>();
    final selected = await showModalBottomSheet<Account>(
      context: context,
      builder: (context) => _AccountSheet(
        accounts: kDefaultAccounts,
        selectedId: _accountId,
        balances: {
          for (final a in kDefaultAccounts) a.id: state.balanceOf(a),
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
    final tx = Transaction(
      id: widget.editing?.id ?? _newId(),
      type: _type,
      amount: amount,
      categoryId: _categoryId,
      accountId: _accountId,
      note: _noteController.text.trim(),
      date: _date,
    );
    if (_isEdit) {
      await state.updateTransaction(tx);
    } else {
      await state.addTransaction(tx);
    }
    if (mounted) Navigator.of(context).pop();
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
                    _buildAmountField(),
                    const SizedBox(height: kSpace4),
                    _buildCategoryGrid(categories),
                    const SizedBox(height: kSpace4),
                    _buildMetaRows(),
                    const SizedBox(height: kSpace4),
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
                    _categoryId = TxCategories.of(type).first.id;
                  });
                },
              ),
            ),
        ],
      ),
    );
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
            child: TextField(
              controller: _amountController,
              focusNode: _amountFocus,
              autofocus: !_isEdit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_AmountInputFormatter()],
              style: amountStyle(size: 32),
              decoration: const InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: kInkDisabled, fontSize: 32),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          Text(
            _type.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _type == TxType.expense ? kInkSecondary : kSuccess,
            ),
          ),
        ],
      ),
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
          const Divider(indent: 52),
          _SelectRow(
            icon: Icons.account_balance_wallet_outlined,
            label: '账户',
            value: account.name,
            onTap: _pickAccount,
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
            right: type == TxType.expense
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



