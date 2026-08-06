/// 账本切换与管理弹层
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/book.dart';
import '../models/category_icons.dart';
import '../theme/app_colors.dart';

/// 打开账本切换弹层（列表 + 新建 + 删除）
Future<void> showBookSwitcher(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => const _BookSwitcherSheet(),
  );
}

class _BookSwitcherSheet extends StatelessWidget {
  const _BookSwitcherSheet();

  Future<void> _create(BuildContext context) async {
    final state = context.read<AppState>();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => const _NewBookDialog(),
    );
    if (result != null && result.$1.trim().isNotEmpty) {
      await state.addBook(result.$1, iconKey: result.$2);
    }
  }

  Future<void> _remove(BuildContext context, Book book) async {
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除账本？',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text('「${book.name}」的流水会并入「默认账本」。',
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
    if (ok == true) {
      await state.removeBook(book.id);
    }

  }
  Future<void> _rename(BuildContext context, Book book) async {
    final state = context.read<AppState>();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => _NewBookDialog(
        title: '重命名账本',
        initialName: book.name,
        initialIconKey: book.iconKey,
      ),
    );
    if (result != null && result.$1.trim().isNotEmpty) {
      await state.renameBook(book.id, result.$1,
          iconKey: result.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(kSpace4, kSpace4, kSpace4, kSpace2),
            child: Text('账本',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const Divider(),
          for (final b in state.books)
            ListTile(
              dense: true,
              leading: Icon(categoryIconByKey(b.iconKey),
                  size: 20, color: kInkPrimary),
              title: Text(b.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: b.id == state.currentBook.id
                        ? FontWeight.w600
                        : FontWeight.w400,
                  )),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (b.id == state.currentBook.id)
                    const Icon(Icons.check_rounded,
                        size: 18, color: kAccentBlue),
                  if (b.id != kDefaultBook.id) ...[
                    IconButton(
                      tooltip: '重命名账本',
                      onPressed: () => _rename(context, b),
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: kInkDisabled),
                    ),
                    IconButton(
                      tooltip: '删除账本',
                      onPressed: () => _remove(context, b),
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: kInkDisabled),
                    ),
                  ],
                ],
              ),
              onTap: () async {
                await state.setCurrentBook(b.id);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          const Divider(),
          TextButton.icon(
            onPressed: () => _create(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('新建账本'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: kAccentBlue,
            ),
          ),
          const SizedBox(height: kSpace1),
        ],
      ),
    );
  }
}

class _NewBookDialog extends StatefulWidget {
  const _NewBookDialog({
    this.title = '新建账本',
    this.initialName,
    this.initialIconKey,
  });

  final String title;
  final String? initialName;
  final String? initialIconKey;

  @override
  State<_NewBookDialog> createState() => _NewBookDialogState();
}

class _NewBookDialogState extends State<_NewBookDialog> {
  late final _controller = TextEditingController(text: widget.initialName ?? '');
  late String _iconKey = widget.initialIconKey ?? kCategoryIconChoices.first.$1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 12,
            decoration: const InputDecoration(
                hintText: '账本名称，如：工作、旅行', counterText: ''),
          ),
          const SizedBox(height: kSpace3),
          const Text('选择图标',
              style: TextStyle(fontSize: 12, color: kInkSecondary)),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _iconKey == c.$1
                          ? kAccentSoft
                          : const Color(0xFFF0F1EF),
                      borderRadius: BorderRadius.circular(kRadiusTable),
                      border: _iconKey == c.$1
                          ? Border.all(color: kAccentBlue, width: 1.5)
                          : null,
                    ),
                    child: Icon(c.$2,
                        size: 19,
                        color: _iconKey == c.$1
                            ? kAccentBlue
                            : kInkPrimary),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop((name, _iconKey));
          },
          child: const Text('创建'),
        ),
      ],
    );
  }
}
