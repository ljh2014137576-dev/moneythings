/// 新增 / 编辑自定义分类对话框
library;

import 'package:flutter/material.dart';

import '../models/category_icons.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';

/// 返回新增/编辑后的分类；取消返回 null
Future<TxCategory?> showCategoryDialog(
  BuildContext context, {
  TxType? type,
  TxCategory? editing,
}) {
  return showDialog<TxCategory>(
    context: context,
    builder: (context) => _CategoryDialog(type: type, editing: editing),
  );
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.type, this.editing});

  final TxType? type;
  final TxCategory? editing;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _name;
  late TxType _type;
  late String _iconKey;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _type = e?.isExpense == false ? TxType.income : (widget.type ?? TxType.expense);
    _iconKey = e?.iconKey ?? kCategoryIconChoices.first.$1;
    _name = TextEditingController(text: e?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入分类名称')),
      );
      return;
    }
    Navigator.of(context).pop(
      TxCategory.custom(
        id: widget.editing?.id ?? '',
        name: name,
        iconKey: _iconKey,
        isExpense: _type == TxType.expense,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? '编辑分类' : '新增分类',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isEdit)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: kDividerDefault, width: 1),
                    borderRadius: BorderRadius.circular(kRadiusTable),
                  ),
                  child: Row(
                    children: [
                      for (final t in TxType.values)
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _type = t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _type == t
                                    ? kAccentSoft
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                    kRadiusTable - 1),
                              ),
                              child: Text(
                                t.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _type == t
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: _type == t
                                      ? kAccentBlue
                                      : kInkSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (!_isEdit) const SizedBox(height: kSpace3),
              TextField(
                controller: _name,
                autofocus: !_isEdit,
                maxLength: 8,
                decoration: const InputDecoration(
                  hintText: '分类名称',
                  counterText: '',
                ),
              ),
              const SizedBox(height: kSpace3),
              const Text('选择图标',
                  style: TextStyle(fontSize: 13, color: kInkSecondary)),
              const SizedBox(height: kSpace2),
              Wrap(
                spacing: kSpace2,
                runSpacing: kSpace2,
                children: [
                  for (final c in kCategoryIconChoices)
                    InkWell(
                      onTap: () => setState(() => _iconKey = c.$1),
                      borderRadius: BorderRadius.circular(kRadiusTable),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _iconKey == c.$1
                              ? kAccentSoft
                              : const Color(0xFFF0F1EF),
                          borderRadius: BorderRadius.circular(kRadiusTable),
                          border: _iconKey == c.$1
                              ? Border.all(color: kAccentBlue, width: 1.5)
                              : null,
                        ),
                        child: Icon(
                          c.$2,
                          size: 20,
                          color: _iconKey == c.$1
                              ? kAccentBlue
                              : kInkPrimary,
                        ),
                      ),
                    ),
                ],
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
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
