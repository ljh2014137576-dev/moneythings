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
    this.selected = false,
  });

  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showAccount;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isTransfer = transaction.type == TxType.transfer;
    final category = isTransfer
        ? TxCategories.byId('transfer')
        : TxCategories.byId(transaction.categoryId);
    final account = accountById(transaction.accountId);
    final toAccount = isTransfer && transaction.transferToAccountId != null
        ? accountById(transaction.transferToAccountId!)
        : null;
    final isExpense = transaction.type == TxType.expense;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: selected ? kAccentSoft : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: kSpace3, horizontal: kSpace4),
        child: Row(
          children: [
            CategoryIcon(category),
            const SizedBox(width: kSpace3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isTransfer ? '转账' : category.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: kInkPrimary,
                          ),
                        ),
                      ),
                      if (transaction.reimbursable) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: kAccentSoft,
                            borderRadius: BorderRadius.circular(3),
                            border:
                                Border.all(color: kAccentBlue, width: 0.5),
                          ),
                          child: const Text('报',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: kAccentBlue)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (transaction.note.isNotEmpty) transaction.note,
                      if (isTransfer && toAccount != null)
                        '${account.name} → ${toAccount.name}'
                      else if (showAccount)
                        account.name,
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
              color: isExpense || isTransfer ? kInkPrimary : kSuccess,
              plusSign: !isExpense && !isTransfer,
            ),
          ],
        ),
        ),
      ),
    );
  }
}
