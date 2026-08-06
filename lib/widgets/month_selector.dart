/// 月份切换器：‹ 2026年8月 ›；点击月份打开年份/月份快速跳转
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

  Future<void> _pick(BuildContext context) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthPickerDialog(initial: month),
    );
    if (picked != null) onChanged(picked);
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
            child: InkWell(
              onTap: () => _pick(context),
              borderRadius: BorderRadius.circular(kRadiusTable),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kSpace3, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCurrent ? '$label · 本月' : label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kInkPrimary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.expand_more_rounded,
                        size: 18, color: kInkSecondary),
                  ],
                ),
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

/// 年份 + 12 个月份网格
class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initial});

  final DateTime initial;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: '上一年',
            onPressed: () => setState(() => _year--),
            icon: const Icon(Icons.chevron_left_rounded,
                size: 20, color: kInkPrimary),
          ),
          Text('$_year 年',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600)),
          IconButton(
            tooltip: '下一年',
            onPressed: () => setState(() => _year++),
            icon: const Icon(Icons.chevron_right_rounded,
                size: 20, color: kInkPrimary),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: kSpace2,
          crossAxisSpacing: kSpace2,
          childAspectRatio: 1.6,
          children: [
            for (int m = 1; m <= 12; m++)
              _MonthCell(
                label: '$m月',
                selected: _year == widget.initial.year &&
                    m == widget.initial.month,
                isNow: _year == now.year && m == now.month,
                onTap: () =>
                    Navigator.of(context).pop(DateTime(_year, m)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.isNow,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isNow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusTable),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: selected ? kAccentSoft : const Color(0xFFF0F1EF),
          borderRadius: BorderRadius.circular(kRadiusTable),
          border: selected
              ? Border.all(color: kAccentBlue, width: 1.5)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected || isNow ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? kAccentBlue
                  : (isNow ? kInkPrimary : kInkSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
