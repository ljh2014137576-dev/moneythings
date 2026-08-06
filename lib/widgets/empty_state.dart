/// 空状态：解释原因 + 明确下一步
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kSpace8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1EF),
                borderRadius: BorderRadius.circular(kRadiusTable),
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 26, color: kInkSecondary),
            ),
            const SizedBox(height: kSpace4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kInkPrimary,
              ),
            ),
            const SizedBox(height: kSpace2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: kInkSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: kSpace5),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
