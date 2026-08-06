/// 预算设置对话框
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'amount_text.dart';

/// 返回设置后的预算（分），取消返回 null
Future<int?> showBudgetDialog(BuildContext context, int currentCents) {
  return showDialog<int>(
    context: context,
    builder: (context) => _BudgetDialog(currentCents: currentCents),
  );
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.currentCents});
  final int currentCents;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    final value = widget.currentCents / 100;
    _controller = TextEditingController(
      text: value > 0 ? value.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  int? _parse() {
    final text = _controller.text.trim();
    if (text.isEmpty) return null;
    final parts = text.split('.');
    final yuan = int.tryParse(parts[0].replaceAll(',', '')) ?? 0;
    final fenStr = parts.length > 1 ? parts[1].padRight(2, '0').substring(0, 2) : '00';
    final fen = int.tryParse(fenStr) ?? 0;
    return yuan * 100 + fen;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('每月预算',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: const InputDecoration(
              prefixText: '¥ ',
              hintText: '0.00',
            ),
          ),
          const SizedBox(height: kSpace2),
          Text(
            widget.currentCents > 0
                ? '当前预算：${AmountText.format(widget.currentCents)}'
                : '未设置预算，输入金额后保存',
            style: const TextStyle(fontSize: 12, color: kInkSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(96, 44),
          ),
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

