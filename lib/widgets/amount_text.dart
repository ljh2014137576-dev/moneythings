/// 金额展示：分 -> ¥1,234.56，表格数字避免跳动
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';

class AmountText extends StatelessWidget {
  const AmountText(
    this.cents, {
    super.key,
    this.size = 16,
    this.weight = FontWeight.w600,
    this.color = kInkPrimary,
    this.showSymbol = true,
    this.plusSign = false,
    this.decimals = 2,
  });

  final int cents;
  final double size;
  final FontWeight weight;
  final Color color;
  final bool showSymbol;
  final bool plusSign;
  final int decimals;

  static String format(int cents, {bool showSymbol = true, int decimals = 2}) {
    final value = cents / 100;
    final nf = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '',
      decimalDigits: decimals,
    );
    final digits = nf.format(value.abs());
    final sign = value < 0 ? '-' : '';
    final prefix = showSymbol ? '¥' : '';
    return '$sign$prefix$digits';
  }

  @override
  Widget build(BuildContext context) {
    final value = cents / 100;
    final nf = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '',
      decimalDigits: decimals,
    );
    final digits = nf.format(value.abs());
    final sign = value < 0 ? '-' : (plusSign ? '+' : '');
    final prefix = showSymbol ? '¥' : '';
    return Text.rich(
      TextSpan(
        children: [
          if (sign.isNotEmpty)
            TextSpan(text: sign, style: TextStyle(fontSize: size * 0.78)),
          if (prefix.isNotEmpty)
            TextSpan(text: prefix, style: TextStyle(fontSize: size * 0.68)),
          TextSpan(text: digits),
        ],
      ),
      style: TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
