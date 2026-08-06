/// 统一分类图标块：中性灰方形底 + 黑白线性图标
library;

import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../theme/app_colors.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon(this.category, {super.key, this.size = 40});

  final TxCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1EF),
        borderRadius: BorderRadius.circular(kRadiusTable),
      ),
      child: Icon(category.icon, size: size * 0.52, color: kInkPrimary),
    );
  }
}
