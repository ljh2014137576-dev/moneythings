/// 我的页：总资产 / 账户 / 预算 / 数据管理
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/account.dart';
import '../theme/app_colors.dart';
import '../widgets/amount_text.dart';
import '../widgets/budget_dialog.dart';
import '../services/csv_exporter.dart';
import '../services/export_target.dart';
import '../widgets/paper_group.dart';

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

  Future<void> _exportCsv() async {
    final state = context.read<AppState>();
    if (state.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无数据可导出')),
      );
      return;
    }
    final now = DateTime.now();
    final stamp = '${now.year}${_p2(now.month)}${_p2(now.day)}';
    final csv = CsvExporter.exportCsv(state.transactions);
    try {
      final where = await exportCsvFile(
        csv,
        '记账本流水_$stamp.csv',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出 ${state.transactions.length} 条流水 → $where')),
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
          _buildBudget(state),
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
    return PaperGroup(
      title: '账户',
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < kDefaultAccounts.length; i++) ...[
            if (i > 0) const Divider(indent: 64),
            _AccountRow(
              account: kDefaultAccounts[i],
              balance: state.balanceOf(kDefaultAccounts[i]),
            ),
          ],
        ],
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
          ],
        ],
      ),
    );
  }

  Widget _buildData(AppState state) {
    return PaperGroup(
      title: '数据',
      padding: EdgeInsets.zero,
      child: Column(
        children: [
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
            Text('版本 1.0.0',
                style: TextStyle(fontSize: 14, color: kInkPrimary)),
            SizedBox(height: kSpace2),
            Text('一款本地记账应用：所有数据仅保存在设备上，不上传云端。',
                style: TextStyle(fontSize: 13, color: kInkSecondary, height: 1.5)),
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
  const _AccountRow({required this.account, required this.balance});

  final Account account;
  final int balance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace3),
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


