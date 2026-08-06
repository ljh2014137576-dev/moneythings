/// 我的页：总资产 / 账户 / 预算 / 数据管理
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../data/app_state.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';
import '../widgets/amount_text.dart';
import '../widgets/budget_dialog.dart';
import '../widgets/book_switcher.dart';
import '../widgets/category_dialog.dart';
import '../services/csv_exporter.dart';
import '../services/csv_importer.dart';
import '../services/export_target.dart';
import '../services/notification_service.dart';
import '../widgets/paper_group.dart';
import 'ledger_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _editBudget() async {
    final state = context.read<AppState>();
    final v = await showBudgetDialog(context, state.monthlyBudget);
    if (v != null && mounted) {
      await state.setBudget(v);
    }
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除全部数据？',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: const Text('将删除所有流水，且无法恢复。',
            style: TextStyle(fontSize: 14, color: kInkSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kDanger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppState>().clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已清除全部流水')),
        );
      }
    }
  }

  Future<void> _importCsv() async {
    final pasted = await showDialog<String>(
      context: context,
      builder: (context) => const _CsvImportDialog(),
    );
    if (pasted == null || pasted.trim().isEmpty || !mounted) return;

    final state = context.read<AppState>();
    // 解析预览 + 确认
    final preview = CsvImporter.parseCsv(pasted);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认导入',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '将导入 ${preview.transactions.length} 笔，跳过 ${preview.skipped} 行'
              '${preview.errors.isNotEmpty ? '，错误 ${preview.errors.length} 行' : ''}。',
              style: const TextStyle(
                  fontSize: 14, color: kInkSecondary, height: 1.5),
            ),
            if (preview.errors.isNotEmpty) ...[
              const SizedBox(height: kSpace3),
              const Text('错误示例：',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              for (final e in preview.errors.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(e,
                      style: const TextStyle(
                          fontSize: 11, color: kDanger, height: 1.4)),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认导入'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final result = await state.importCsv(pasted);
    if (!mounted) return;
    final parts = [
      '导入 ${result.transactions.length} 笔',
      if (result.skipped > 0) '跳过 ${result.skipped} 行',
      if (result.errors.isNotEmpty) '错误 ${result.errors.length} 行',
    ];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(parts.join('，'))),
    );
  }

  Future<void> _backupJson() async {
    final state = context.read<AppState>();
    final json = state.exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已备份到剪贴板（JSON）')),
      );
    }
  }

  Future<void> _restoreJson() async {
    final state = context.read<AppState>();
    final pasted = await showDialog<String>(
      context: context,
      builder: (context) => const _JsonRestoreDialog(),
    );
    if (pasted == null || pasted.trim().isEmpty || !mounted) return;
    final error = await state.importJson(pasted);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? '已从备份恢复全部数据')),
    );
  }

  Future<void> _exportCsv() async {
    final state = context.read<AppState>();
    final scope = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding:
                  EdgeInsets.fromLTRB(kSpace4, kSpace4, kSpace4, kSpace2),
              child: Text('导出范围',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined,
                  size: 20, color: kInkPrimary),
              title: Text('当前账本（${state.currentBook.name}）',
                  style: const TextStyle(fontSize: 15)),
              onTap: () => Navigator.of(context).pop('current'),
            ),
            ListTile(
              leading: const Icon(Icons.library_books_outlined,
                  size: 20, color: kInkPrimary),
              title: const Text('全部账本',
                  style: TextStyle(fontSize: 15)),
              onTap: () => Navigator.of(context).pop('all'),
            ),
          ],
        ),
      ),
    );
    if (scope == null || !mounted) return;
    final txs = scope == 'all'
        ? state.transactions
        : state.currentBookTransactions;
    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所选范围暂无数据可导出')),
      );
      return;
    }
    final now = DateTime.now();
    final stamp = '${now.year}${_p2(now.month)}${_p2(now.day)}';
    final csv = CsvExporter.exportCsv(
      txs,
      bookNames: {for (final b in state.books) b.id: b.name},
    );
    try {
      final namePart = scope == 'all' ? '全部' : state.currentBook.name;
      final where = await exportCsvFile(
        csv,
        '记账本流水_${namePart}_$stamp.csv',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出 ${txs.length} 条流水 → $where')),
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            kPagePadding, kSpace3, kPagePadding, kSpace6),
        children: [
          const Text('我的',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: kInkPrimary)),
          const SizedBox(height: kSpace3),
          _buildAssets(state),
          const SizedBox(height: kSpace4),
          _buildAccounts(state),
          const SizedBox(height: kSpace4),
          _buildBook(state),
          const SizedBox(height: kSpace4),
          _buildBudget(state),
          const SizedBox(height: kSpace4),
          _buildCategories(state),
          const SizedBox(height: kSpace4),
          _buildData(state),
        ],
      ),
    );
  }

  Widget _buildAssets(AppState state) {
    return PaperGroup(
      padding: const EdgeInsets.fromLTRB(kSpace4, kSpace5, kSpace4, kSpace5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('总资产',
              style: TextStyle(fontSize: 13, color: kInkSecondary)),
          const SizedBox(height: 6),
          AmountText(state.totalAssets, size: 38, weight: FontWeight.w700),
          const SizedBox(height: kSpace2),
          const Text('本地保存 · 不上传云端',
              style: TextStyle(fontSize: 12, color: kInkSecondary)),
        ],
      ),
    );
  }

  Widget _buildAccounts(AppState state) {
    final accounts = state.accounts;
    return PaperGroup(
      title: '账户',
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < accounts.length; i++) ...[
            if (i > 0) const Divider(indent: 64),
            _AccountRow(
              account: accounts[i],
              balance: state.balanceOf(accounts[i]),
              onTap: () => _accountMenu(accounts[i]),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _accountMenu(Account account) async {
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
              child: Text(account.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined,
                  size: 20, color: kInkPrimary),
              title: const Text('查看该账户流水'),
              onTap: () => Navigator.of(context).pop('ledger'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  size: 20, color: kInkPrimary),
              title: const Text('设置初始余额'),
              onTap: () => Navigator.of(context).pop('balance'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'ledger') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: kPageBackground,
            appBar: AppBar(
              backgroundColor: kPageBackground,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text('${account.name} · 流水',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
            ),
            body: LedgerPage(initialAccountId: account.id),
          ),
        ),
      );
    } else if (action == 'balance') {
      await _editAccountBalance(account);
    }
  }

  Future<void> _editAccountBalance(Account account) async {
    final cents = await showDialog<int>(
      context: context,
      builder: (context) => _InitialBalanceDialog(account: account),
    );
    if (cents != null && mounted) {
      await context
          .read<AppState>()
          .setAccountInitialBalance(account.id, cents);
    }
  }

  Widget _buildBook(AppState state) {
    return PaperGroup(
      title: '账本',
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => showBookSwitcher(context),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: kSpace4, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.menu_book_outlined,
                  size: 20, color: kInkPrimary),
              const SizedBox(width: kSpace3),
              const Expanded(
                child: Text('当前账本',
                    style: TextStyle(fontSize: 14, color: kInkPrimary)),
              ),
              Text(state.currentBook.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: kInkDisabled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudget(AppState state) {
    final budget = state.monthlyBudget;
    final spent = state.currentMonthExpense;
    final ratio =
        budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final over = budget > 0 && spent > budget;

    return PaperGroup(
      title: '预算管理',
      padding: const EdgeInsets.all(kSpace4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _editBudget,
            child: Row(
              children: [
                const Icon(Icons.track_changes_outlined,
                    size: 20, color: kInkSecondary),
                const SizedBox(width: kSpace3),
                const Expanded(
                  child: Text('每月预算',
                      style:
                          TextStyle(fontSize: 14, color: kInkPrimary)),
                ),
                Text(
                  budget > 0 ? AmountText.format(budget) : '未设置',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: budget > 0 ? kInkPrimary : kInkDisabled,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: kInkDisabled),
              ],
            ),
          ),
          if (budget > 0) ...[
            const SizedBox(height: kSpace4),
            Row(
              children: [
                Text('本月已用',
                    style: TextStyle(
                        fontSize: 12,
                        color: over ? kDanger : kInkSecondary)),
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
                      child: Container(
                          color: over ? kDanger : kInkPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: kSpace2),
            Text(
              over
                  ? '已超出预算 ¥${AmountText.format(spent - budget, showSymbol: false)}'
                  : '剩余 ¥${AmountText.format(state.budgetRemaining, showSymbol: false)} · 日均可用 ¥${AmountText.format(state.budgetDailyRemaining, showSymbol: false)}',
              style: TextStyle(
                  fontSize: 11,
                  color: over ? kDanger : kInkDisabled),
            ),
          ],
          const Divider(height: 1, indent: kSpace4, endIndent: kSpace4),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kSpace4, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.notifications_outlined,
                    size: 20, color: kInkSecondary),
                const SizedBox(width: kSpace3),
                const Expanded(
                  child: Text('超支系统通知',
                      style: TextStyle(fontSize: 14, color: kInkPrimary)),
                ),
                Switch(
                  value: state.budgetNotify,
                  activeTrackColor: kAccentBlue,
                  onChanged: (v) async {
                    await state.setBudgetNotify(v);
                    if (v) {
                      await NotificationService.instance.requestPermission();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(AppState state) {
    return PaperGroup(
      title: '分类管理',
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategorySection(
            title: '支出分类',
            categories: TxCategories.of(TxType.expense),
            onAdd: () => _addCategory(TxType.expense),
            onTap: _tapCategory,
          ),
          const Divider(indent: kSpace4, endIndent: kSpace4),
          _CategorySection(
            title: '收入分类',
            categories: TxCategories.of(TxType.income),
            onAdd: () => _addCategory(TxType.income),
            onTap: _tapCategory,
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory(TxType type) async {
    final cat = await showCategoryDialog(context, type: type);
    if (cat != null && mounted) {
      await context.read<AppState>().addCustomCategory(
            name: cat.name,
            iconKey: cat.iconKey ?? 'more',
            isExpense: type == TxType.expense,
          );
    }
  }

  Future<void> _tapCategory(TxCategory c) async {
    if (!c.isCustom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('预设分类不可修改')),
      );
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(kSpace4, kSpace3, kSpace4, kSpace2),
              child: Text(c.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  size: 20, color: kInkPrimary),
              title: const Text('编辑分类'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, size: 20, color: kDanger),
              title: const Text('删除分类',
                  style: TextStyle(color: kDanger)),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    final state = context.read<AppState>();
    if (action == 'edit') {
      final edited = await showCategoryDialog(context, editing: c);
      if (edited != null && mounted) {
        await state.updateCustomCategory(edited);
      }
    } else if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('删除这个分类？',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          content: const Text('该分类下的历史账目会归入「其他」。',
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
        await state.removeCustomCategory(c.id);
      }
    }
  }

  Widget _buildData(AppState state) {
    return PaperGroup(
      title: '数据',
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kSpace4, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.alarm_outlined,
                    size: 20, color: kInkSecondary),
                const SizedBox(width: kSpace3),
                const Expanded(
                  child: Text('每日记账提醒（20:00）',
                      style: TextStyle(fontSize: 14, color: kInkPrimary)),
                ),
                Switch(
                  value: state.dailyReminder,
                  activeTrackColor: kAccentBlue,
                  onChanged: (v) async {
                    await state.setDailyReminder(v);
                    if (v) {
                      await NotificationService.instance.requestPermission();
                      await NotificationService.instance.scheduleDailyReminder();
                    } else {
                      await NotificationService.instance.cancelDailyReminder();
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(indent: kSpace4, endIndent: kSpace4),
          if (state.transactions.isEmpty)
            _DataRow(
              icon: Icons.auto_awesome_outlined,
              label: '载入示例数据',
              color: kAccentBlue,
              onTap: () async {
                await context.read<AppState>().loadSampleData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已载入示例数据，可在明细中查看')),
                  );
                }
              },
            ),
          _DataRow(
            icon: Icons.upload_file_outlined,
            label: '备份到剪贴板 (JSON)',
            color: kInkPrimary,
            onTap: _backupJson,
          ),
          _DataRow(
            icon: Icons.restore_outlined,
            label: '从备份恢复 (JSON)',
            color: kInkPrimary,
            onTap: _restoreJson,
          ),
          _DataRow(
            icon: Icons.upload_file_outlined,
            label: '导入数据 (CSV)',
            color: kInkPrimary,
            onTap: _importCsv,
          ),
          _DataRow(
            icon: Icons.ios_share_outlined,
            label: '导出数据 (CSV)',
            color: kInkPrimary,
            onTap: _exportCsv,
          ),
          _DataRow(
            icon: Icons.delete_sweep_outlined,
            label: '清除全部数据',
            color: kDanger,
            onTap: _confirmClear,
          ),
          const Divider(indent: 64),
          _DataRow(
            icon: Icons.info_outline_rounded,
            label: '关于',
            color: kInkPrimary,
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于记账本',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本 1.1.0',
                style: TextStyle(fontSize: 14, color: kInkPrimary)),
            SizedBox(height: kSpace2),
            Text('一款本地记账应用：所有数据仅保存在设备上，不上传云端。',
                style: TextStyle(fontSize: 13, color: kInkSecondary, height: 1.5)),
            SizedBox(height: kSpace3),
            Text('更新日志',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(height: kSpace2),
            Text('v2.2 本周概览 · 导入预览 · 预算剩余天数\nv2.1 复制上一条 · 每周统计 · 每日记账提醒\nv2.0 全部时间 · 系统通知 · 多账本完善\nv1.x 明细搜索/左滑删除/统计/自定义分类等',
                style: TextStyle(fontSize: 11, color: kInkSecondary, height: 1.6)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.balance,
    required this.onTap,
  });

  final Account account;
  final int balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace3),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1EF),
                borderRadius: BorderRadius.circular(kRadiusTable),
              ),
              child: Icon(account.icon, size: 18, color: kInkPrimary),
            ),
            const SizedBox(width: kSpace3),
            Expanded(
              child: Text(account.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ),
            AmountText(balance, size: 15, weight: FontWeight.w600),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: kSpace3),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 14, color: color)),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: kInkDisabled),
          ],
        ),
      ),
    );
  }
}


 
class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.categories,
    required this.onAdd,
    required this.onTap,
  });

  final String title;
  final List<TxCategory> categories;
  final VoidCallback onAdd;
  final ValueChanged<TxCategory> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSpace4, kSpace3, kSpace4, kSpace4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, color: kInkSecondary)),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: kAccentBlue,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('新增'),
              ),
            ],
          ),
          const SizedBox(height: kSpace2),
          Wrap(
            spacing: kSpace3,
            runSpacing: kSpace3,
            children: [
              for (final c in categories) _CategoryItem(category: c, onTap: () => onTap(c)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.category, required this.onTap});

  final TxCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = category.isCustom ? kAccentBlue : kInkPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusTable),
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1EF),
                    borderRadius: BorderRadius.circular(kRadiusTable),
                  ),
                  child: Icon(category.icon, size: 20, color: color),
                ),
                if (category.isCustom)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: kAccentBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 11, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    category.isCustom ? FontWeight.w600 : FontWeight.w400,
                color: category.isCustom ? kAccentBlue : kInkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
class _CsvImportDialog extends StatefulWidget {
  const _CsvImportDialog();

  @override
  State<_CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<_CsvImportDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入 CSV',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '粘贴「导出数据 (CSV)」生成的内容（首行表头可选），重复流水会自动跳过。',
                style:
                    TextStyle(fontSize: 12, color: kInkSecondary, height: 1.5),
              ),
              const SizedBox(height: kSpace3),
              TextField(
                controller: _controller,
                maxLines: 6,
                maxLength: 200000,
                style: const TextStyle(fontSize: 12, height: 1.4),
                decoration: const InputDecoration(
                  hintText: '日期,类型,分类,金额(元),账户,备注\n'
                      '2026-08-06 12:30,支出,餐饮,42.00,支付宝,午饭',
                  hintStyle: TextStyle(fontSize: 12, color: kInkDisabled),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('导入'),
        ),
      ],
    );
  }
}

 
/// 初始余额输入对话框（自持 controller，避免关闭动画期间 dispose）
class _InitialBalanceDialog extends StatefulWidget {
  const _InitialBalanceDialog({required this.account});

  final Account account;

  @override
  State<_InitialBalanceDialog> createState() => _InitialBalanceDialogState();
}

class _InitialBalanceDialogState extends State<_InitialBalanceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.account.initialBalance > 0
          ? (widget.account.initialBalance / 100).toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parse() {
    final text = _controller.text.trim();
    if (text.isEmpty) return null;
    final parts = text.split('.');
    final yuan = int.tryParse(parts[0].replaceAll(',', '')) ?? 0;
    final fenStr =
        parts.length > 1 ? parts[1].padRight(2, '0').substring(0, 2) : '00';
    final fen = int.tryParse(fenStr) ?? 0;
    return yuan * 100 + fen;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.account.name} · 初始余额',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        decoration: const InputDecoration(prefixText: '¥ ', hintText: '0.00'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () {
            final v = _parse();
            if (v == null) return;
            Navigator.of(context).pop(v);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}


class _JsonRestoreDialog extends StatefulWidget {
  const _JsonRestoreDialog();

  @override
  State<_JsonRestoreDialog> createState() => _JsonRestoreDialogState();
}

class _JsonRestoreDialogState extends State<_JsonRestoreDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('从备份恢复',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '粘贴之前「备份到剪贴板」生成的 JSON 内容，将覆盖当前全部数据。',
              style: TextStyle(fontSize: 12, color: kInkSecondary, height: 1.5),
            ),
            const SizedBox(height: kSpace3),
            TextField(
              controller: _controller,
              maxLines: 6,
              maxLength: 1000000,
              style: const TextStyle(fontSize: 11, height: 1.4),
              decoration: const InputDecoration(
                hintText: '{"version":1,...}',
                hintStyle: TextStyle(fontSize: 11, color: kInkDisabled),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('恢复'),
        ),
      ],
    );
  }
}
