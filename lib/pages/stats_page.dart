/// 统计页：月度概览 + 每日支出柱状图 + 分类排行
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/amount_text.dart';
import '../widgets/category_ranking.dart';
import '../widgets/month_selector.dart';
import '../widgets/paper_group.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late DateTime _month;
  int _selectedDay = -1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final monthTx = state.ofMonth(_month);
    final summary = state.summaryOf(_month);
    final ranking = state.categoryExpenseRanking(_month);
    final series = state.dailyExpenseSeries(_month);
    final days = series.length;

    // 默认选中支出最高的一天
    if (_selectedDay < 0 || _selectedDay >= days) {
      int best = 0;
      for (int i = 1; i < days; i++) {
        if (series[i] > series[best]) best = i;
      }
      _selectedDay = best;
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                kPagePadding, kSpace3, kPagePadding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('统计',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: kInkPrimary)),
                const SizedBox(height: kSpace2),
                MonthSelector(
                  month: _month,
                  onChanged: (m) => setState(() => _month = m),
                ),
              ],
            ),
          ),
          const SizedBox(height: kSpace3),
          Expanded(
            child: monthTx.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.bar_chart_rounded,
                            size: 44, color: kInkDisabled),
                        SizedBox(height: kSpace3),
                        Text('本月暂无数据',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: kInkPrimary)),
                        SizedBox(height: kSpace1),
                        Text('记录几笔后这里会出现图表',
                            style: TextStyle(
                                fontSize: 13, color: kInkSecondary)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        kPagePadding, 0, kPagePadding, kSpace6),
                    children: [
                      _buildSummaryStrip(
                        summary,
                        monthTx.length,
                        state.expenseDeltaOf(_month),
                      ),
                      const SizedBox(height: kSpace3),
                      _buildBarChart(series),
                      const SizedBox(height: kSpace4),
                      PaperGroup(
                        title: '支出分类排行',
                        padding: const EdgeInsets.all(kSpace4),
                        child: CategoryRanking(items: ranking, maxItems: 8),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStrip(MonthSummary summary, int count, int delta) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final daily = count == 0 ? 0 : summary.expense ~/ daysInMonth;
    return PaperGroup(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 96,
        child: Row(
          children: [
            _StatCell(
              label: '总支出',
              value: AmountText.format(summary.expense),
              color: kInkPrimary,
              subtitle: delta == 0
                  ? '与上月持平'
                  : '较上月 ${delta > 0 ? '+' : ''}${AmountText.format(delta.abs(), showSymbol: false)}',
              subtitleColor: delta > 0 ? kDanger : kSuccess,
            ),
            const _VSep(),
            _StatCell(
              label: '日均支出',
              value: AmountText.format(daily),
              color: kInkPrimary,
            ),
            const _VSep(),
            _StatCell(label: '交易笔数', value: '$count', color: kInkPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<int> seriesCents) {
    final days = seriesCents.length;
    final seriesYuan = [for (final c in seriesCents) c / 100.0];
    final maxValue =
        seriesYuan.fold<double>(0, (a, b) => a > b ? a : b);
    final niceMax = _niceMax(maxValue);

    return PaperGroup(
      title: '每日支出',
      padding: const EdgeInsets.fromLTRB(kSpace3, kSpace2, kSpace3, kSpace4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSelectionCaption(seriesCents),
          const SizedBox(height: kSpace3),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: niceMax,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                barGroups: [
                  for (int i = 0; i < days; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: seriesYuan[i],
                          width: days > 28 ? 5 : 8,
                          color: i == _selectedDay ? kAccentBlue : kInkPrimary,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2)),
                        ),
                      ],
                    ),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: niceMax / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: kDividerSubtle,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: niceMax / 4,
                      getTitlesWidget: (value, meta) {
                        if (value <= 0) return const SizedBox.shrink();
                        return Text(
                          _compact(value),
                          style: const TextStyle(
                              fontSize: 10, color: kInkDisabled),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final day = value.toInt() + 1;
                        final show = days > 28
                            ? day % 5 == 1 || day == days
                            : day % 2 == 1 || day == days;
                        if (!show) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('$day',
                              style: const TextStyle(
                                  fontSize: 10, color: kInkDisabled)),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => kInkPrimary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = group.x + 1;
                      return BarTooltipItem(
                        '${DateFormat('M月d日', 'zh_CN').format(DateTime(_month.year, _month.month, day))}\n'
                        '${AmountText.format((rod.toY * 100).round())}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent &&
                        response != null &&
                        response.spot != null) {
                      final x = response.spot!.touchedBarGroup.x;
                      if (x >= 0 && x < days && x != _selectedDay) {
                        setState(() => _selectedDay = x);
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCaption(List<int> series) {
    if (_selectedDay < 0 || _selectedDay >= series.length) {
      return const SizedBox.shrink();
    }
    final day = _selectedDay + 1;
    final isToday = DateTime(_month.year, _month.month, day)
            .difference(DateTime.now()).inDays ==
        0;
    return Row(
      children: [
        Text(
          '${DateFormat('M月d日', 'zh_CN').format(DateTime(_month.year, _month.month, day))}'
          '${isToday ? ' · 今天' : ''}',
          style: const TextStyle(fontSize: 13, color: kInkSecondary),
        ),
        const Spacer(),
        AmountText(series[_selectedDay],
            size: 18, weight: FontWeight.w700, color: kAccentBlue),
      ],
    );
  }

  static double _niceMax(double max) {
    if (max <= 0) return 100;
    const steps = [
      1.0, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000,
    ];
    for (final s in steps) {
      if (max <= s * 4) return s * 4;
    }
    return (max / 20000).ceil() * 80000.0;
  }

  static String _compact(double yuan) {
    if (yuan >= 10000) {
      final w = yuan / 10000;
      return '${w.toStringAsFixed(w >= 10 ? 0 : 1)}w';
    }
    if (yuan >= 1000) {
      return '${(yuan / 1000).toStringAsFixed(1)}k';
    }
    if (yuan >= 100) return '${yuan.round()}';
    return yuan.toStringAsFixed(yuan == yuan.roundToDouble() ? 0 : 1);
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
    this.subtitleColor = kInkSecondary,
  });

  final String label;
  final String value;
  final Color color;
  final String? subtitle;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: kInkSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VSep extends StatelessWidget {
  const _VSep();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: kDividerSubtle);
  }
}


