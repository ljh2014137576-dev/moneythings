/// 纸面数据组：白底 + 1dp 灰边框 + 4dp 圆角，无阴影
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PaperGroup extends StatelessWidget {
  const PaperGroup({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(kSpace4),
    this.title,
    this.trailing,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? title;
  final Widget? trailing;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kPaperSurface,
        borderRadius: BorderRadius.circular(kRadiusTable),
        border: border
            ? Border.all(color: kDividerDefault, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || trailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(kSpace4, kSpace3, kSpace4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kInkPrimary,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

