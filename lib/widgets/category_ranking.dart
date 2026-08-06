/// 分类排行：标签左、金额右、黑色进度条 + 浅灰轨道
library;

import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../theme/app_colors.dart';
import 'amount_text.dart';
import 'category_icon.dart';

class CategoryRanking extends StatelessWidget {
  const CategoryRanking({
    super.key,
    required this.items,
    this.maxItems = 5,
    this.onTapCategory,
  });

  final List<({TxCategory category, int amount})> items;
  final int maxItems;

  /// 点击某分类时回调（用于跳转查看该分类流水）
  final ValueChanged<TxCategory>? onTapCategory;

  @override
  Widget build(BuildContext context) {
    final list = items.take(maxItems).toList();
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: kSpace4),
        child: Text('本月暂无支出',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kInkSecondary)),
      );
    }
    final max = list.first.amount;

    return Column(
      children: [
        for (int i = 0; i < list.length; i++) ...[
          if (i > 0) const SizedBox(height: kSpace3),
          _RankRow(
            item: list[i],
            max: max,
            rank: i + 1,
            onTap: onTapCategory == null
                ? null
                : () => onTapCategory!(list[i].category),
          ),
        ],
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.item,
    required this.max,
    required this.rank,
    this.onTap,
  });

  final ({TxCategory category, int amount}) item;
  final int max;
  final int rank;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : item.amount / max;
    return InkWell(
      onTap: onTap,
      child: Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            '$rank',
            style: const TextStyle(fontSize: 12, color: kInkDisabled),
          ),
        ),
        CategoryIcon(item.category, size: 32),
        const SizedBox(width: kSpace3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.category.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  AmountText(item.amount,
                      size: 14,
                      weight: FontWeight.w500,
                      color: kInkPrimary),
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
                        child: Container(color: kInkPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }
}
