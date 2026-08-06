/// 流水单行：分类图标 + 名称/备注 + 右侧金额
library;

import 'package:flutter/material.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';
import 'amount_text.dart';
import 'category_icon.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
    this.showAccount = true,
  });

  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showAccount;

  @override
  Widget build(BuildContext context) {
    final category = TxCategories.byId(transaction.categoryId);
    final account = accountById(transaction.accountId);
    final isExpense = transaction.type == TxType.expense;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kSpace3, horizontal: kSpace4),
        child: Row(
          children: [
            CategoryIcon(category),
            const SizedBox(width: kSpace3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: kInkPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (transaction.note.isNotEmpty) transaction.note,
                      if (showAccount) account.name,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: kInkSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSpace3),
            AmountText(
              transaction.amount,
              size: 16,
              weight: FontWeight.w600,
              color: isExpense ? kInkPrimary : kSuccess,
              plusSign: !isExpense,
            ),
          ],
        ),
      ),
    );
  }
}
