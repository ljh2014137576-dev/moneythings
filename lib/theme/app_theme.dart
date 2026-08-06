/// 全局主题：将设计令牌映射到 Material ThemeData
library;


import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 关键数字：表格数字特性，避免数字宽度跳动
TextStyle amountStyle({
  double size = 34,
  FontWeight weight = FontWeight.w600,
  Color color = kInkPrimary,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// 主题构建
ThemeData buildAppTheme() {
  final ColorScheme scheme = const ColorScheme.light(
    primary: kAccentBlue,
    onPrimary: Colors.white,
    onPrimaryContainer: kAccentBlue,
    primaryContainer: kAccentSoft,
    surface: kPaperSurface,
    onSurface: kInkPrimary,
    onSurfaceVariant: kInkSecondary,
    outline: kDividerDefault,
    outlineVariant: kDividerSubtle,
    error: kDanger,
    onError: Colors.white,
    secondary: kInkPrimary,
    onSecondary: Colors.white,
  );

  final ThemeData base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kPageBackground,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      // 页面大标题
      headlineMedium: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: kInkPrimary,
        height: 1.2,
      ),
      // 模块标题
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: kInkPrimary,
        height: 1.3,
      ),
      // 卡片标题
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: kInkPrimary,
        height: 1.3,
      ),
      // 正文
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: kInkPrimary,
        height: 1.4,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: kInkSecondary,
        height: 1.4,
      ),
      labelLarge: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: kInkPrimary,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: kInkSecondary,
      ),
    ),
    dividerColor: kDividerSubtle,
    dividerTheme: const DividerThemeData(
      color: kDividerSubtle,
      thickness: 1,
      space: 1,
    ),
    // 输入框：白底、灰 1dp 边框、4dp 圆角；焦点 2dp 蓝描边
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kPaperSurface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: const TextStyle(color: kInkDisabled, fontSize: 15),
      labelStyle: const TextStyle(color: kInkSecondary, fontSize: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusTable),
        borderSide: const BorderSide(color: kDividerDefault, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusTable),
        borderSide: const BorderSide(color: kAccentBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusTable),
        borderSide: const BorderSide(color: kDanger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusTable),
        borderSide: const BorderSide(color: kDanger, width: 2),
      ),
    ),
    // 主按钮：蓝底白字、4dp 圆角、无阴影
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kAccentBlue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kInkDisabled,
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusTable),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    // 次按钮：白底黑字、1dp 灰边框
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kInkPrimary,
        backgroundColor: kPaperSurface,
        side: const BorderSide(color: kDividerDefault, width: 1),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusTable),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    // 文字按钮
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kAccentBlue,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    // 底部弹层
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kPaperSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusSheet)),
      ),
      showDragHandle: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kPaperSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusSheet),
      ),
    ),
    // 日期选择器保持白底、小圆角
    datePickerTheme: DatePickerThemeData(
      backgroundColor: kPaperSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusSheet),
      ),
      headerBackgroundColor: kInkPrimary,
      headerForegroundColor: Colors.white,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: kPaperSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kInkPrimary,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusTable)),
    ),
    splashColor: kAccentBlue.withValues(alpha: 0.08),
    highlightColor: kAccentBlue.withValues(alpha: 0.06),
  );
}

