/// 月份切换器：‹ 2026年8月 ›
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.month,
    required this.onChanged,
  });

  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  void _shift(BuildContext context, int delta) {
    onChanged(DateTime(month.year, month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('yyyy年M月', 'zh_CN').format(month);
    final isCurrent = _sameMonth(month, DateTime.now());

    return Row(
      children: [
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          tooltip: '上个月',
          onTap: () => _shift(context, -1),
        ),
        Expanded(
          child: Center(
            child: Text(
              isCurrent ? '$label · 本月' : label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kInkPrimary,
              ),
            ),
          ),
        ),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          tooltip: '下个月',
          onTap: () => _shift(context, 1),
        ),
      ],
    );
  }

  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: kInkPrimary),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      splashRadius: 18,
    );
  }
}

