/// 统计页：月度概览 + 每日支出柱状图 + 分类排行
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/transaction.dart';
import 'ledger_page.dart';
import 'add_transaction_page.dart';
import '../theme/app_colors.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/amount_text.dart';
import '../widgets/category_ranking.dart';
import '../widgets/month_selector.dart';
import '../widgets/paper_group.dart';
import '../widgets/budget_dialog.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late DateTime _month;
  int _selectedDay = -1;
  int _selectedWeek = -1;
  bool _weekly = false;
  bool _incomeChart = false;
  int _balanceMonths = 12;
  bool _rangeMode = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  void _openCategory(TxCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LedgerPage(initialCategoryId: category.id),
      ),
    );
  }

  Future<void> _showSelectionDay() async {
    final day = _selectedDay + 1;
    if (day < 1) return;
    final date = DateTime(_month.year, _month.month, day);
    final txs = context
        .read<AppState>()
        .ofMonth(_month)
        .where((t) =>
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    await _showTransactionsSheet(date, txs);
  }

  Future<void> _showSelectionWeekly() async {
    final week = _selectedWeek;
    if (week < 0) return;
    final last = DateTime(_month.year, _month.month + 1, 0).day;
    final startDay = week * 7 + 1;
    final endDay = startDay + 6 > last ? last : startDay + 6;
    final txs = context
        .read<AppState>()
        .ofMonth(_month)
        .where((t) => t.date.day >= startDay && t.date.day <= endDay)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    await _showTransactionsSheet(DateTime(_month.year, _month.month, startDay), txs);
  }

  Future<void> _showTransactionsSheet(
      DateTime date, List<Transaction> txs) async {
    int exp = 0, inc = 0;
    for (final t in txs) {
      if (t.type == TxType.expense) {
        exp += t.amount;
      } else if (t.type == TxType.income) {
        inc += t.amount;
      }
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  kSpace4, kSpace4, kSpace4, kSpace2),
              child: Row(
                children: [
                  Text(
                    DateFormat('M月d日 EEEE', 'zh_CN').format(date),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: kSpace2),
                  Text('${txs.length} 笔',
                      style: const TextStyle(
                          fontSize: 12, color: kInkSecondary)),
                  const Spacer(),
                  if (exp > 0)
                    Text('支出 ${AmountText.format(exp, showSymbol: false)}',
                        style: const TextStyle(
                            fontSize: 12, color: kInkSecondary)),
                  if (exp > 0 && inc > 0)
                    const Text(' · ',
                        style: TextStyle(fontSize: 12)),
                  if (inc > 0)
                    Text('收入 ${AmountText.format(inc, showSymbol: false)}',
                        style: const TextStyle(
                            fontSize: 12, color: kSuccess)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: txs.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: kSpace6),
                        child: Text('当日暂无流水',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: kInkSecondary)),
                      )
                    : Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: kPagePadding),
                        decoration: BoxDecoration(
                          color: kPaperSurface,
                          borderRadius: BorderRadius.circular(kRadiusTable),
                          border: Border.all(
                              color: kDividerDefault, width: 1),
                        ),
                        child: Column(
                          children: [
                            for (final t in txs)
                              TransactionTile(
                                transaction: t,
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddTransactionPage(editing: t),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: kSpace3),
          ],
        ),
      ),
    );
  }

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
    final incomeRanking = state.categoryIncomeRanking(_month);
    final balanceSeries = state.recentBalanceSeries(_month, _balanceMonths);
    final yearData = state.yearComparison(_month.year);
    final weekSeries = state.weeklyExpenseSeries(_month);
    final series = state.dailyExpenseSeries(_month);
    final incomeSeries = state.dailyIncomeSeries(_month);
    final days = series.length;

    final rangeActive =
        _rangeMode && _rangeStart != null && _rangeEnd != null;
    final rangeSummary = rangeActive
        ? state.rangeSummary(_rangeStart!, _rangeEnd!)
        : null;
    final rangeRanking = rangeActive
        ? state.rangeCategoryRanking(_rangeStart!, _rangeEnd!)
        : const <({TxCategory category, int amount})>[];
    final rangeIncomeRanking = rangeActive
        ? state.rangeCategoryRanking(_rangeStart!, _rangeEnd!,
            income: true)
        : const <({TxCategory category, int amount})>[];
    final rangeSeries = rangeActive
        ? state.rangeDailySeries(_rangeStart!, _rangeEnd!)
        : const <int>[];
    final rangeNet = rangeActive
        ? state.rangeDailyNetSeries(_rangeStart!, _rangeEnd!)
        : const <({DateTime date, int net})>[];

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
                const SizedBox(height: kSpace2),
                _buildRangeToggle(),
              ],
            ),
          ),
          const SizedBox(height: kSpace3),
          Expanded(
            child: (rangeActive ? rangeSummary!.count == 0 : monthTx.isEmpty)
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
                      if (rangeActive) ...[
                        _buildRangeSummaryStrip(
                            rangeSummary!, _rangeStart!, _rangeEnd!),
                        const SizedBox(height: kSpace3),
                        _buildRangeBalanceChart(rangeNet),
                        const SizedBox(height: kSpace3),
                        _buildRangeBarChart(rangeSeries),
                        const SizedBox(height: kSpace4),
                        PaperGroup(
                          title: '支出分类排行',
                          padding: const EdgeInsets.all(kSpace4),
                          child: CategoryRanking(
                            items: rangeRanking,
                            maxItems: 8,
                            onTapCategory: _openCategory,
                          ),
                        ),
                        if (rangeIncomeRanking.isNotEmpty) ...[
                          const SizedBox(height: kSpace4),
                          PaperGroup(
                            title: '收入分类排行',
                            padding: const EdgeInsets.all(kSpace4),
                            child: CategoryRanking(
                              items: rangeIncomeRanking,
                              maxItems: 8,
                              onTapCategory: _openCategory,
                            ),
                          ),
                        ],
                      ] else ...[
                      _buildSummaryStrip(
                        summary,
                        monthTx.length,
                        state.expenseDeltaOf(_month),
                      ),
                      const SizedBox(height: kSpace3),
                      _buildBudgetCard(state, summary),
                      const SizedBox(height: kSpace3),
                      _buildBalanceChart(balanceSeries),
                      const SizedBox(height: kSpace3),
                      _buildYearChart(yearData),
                      const SizedBox(height: kSpace3),
                      _buildDailyWeeklyToggle(),
                      const SizedBox(height: kSpace3),
                      _buildIncomeToggle(),
                      const SizedBox(height: kSpace3),
                      _buildBarChart(series,
                          weekly: weekSeries,
                          incomeSeries: incomeSeries),
                      const SizedBox(height: kSpace4),
                      if (ranking.isNotEmpty) ...[
                        const SizedBox(height: kSpace4),
                        _buildDonut(ranking),
                      ],
                      const SizedBox(height: kSpace4),
                      PaperGroup(
                        title: '支出分类排行',
                        padding: const EdgeInsets.all(kSpace4),
                        child: CategoryRanking(
                          items: ranking,
                          maxItems: 8,
                          onTapCategory: _openCategory,
                        ),
                      ),
                      if (incomeRanking.isNotEmpty) ...[
                        const SizedBox(height: kSpace4),
                        PaperGroup(
                          title: '收入分类排行',
                          padding: const EdgeInsets.all(kSpace4),
                          child: CategoryRanking(
                            items: incomeRanking,
                            maxItems: 8,
                            onTapCategory: _openCategory,
                          ),
                        ),
                      ],
                      const SizedBox(height: kSpace4),
                      _buildYearSummaryCard(state, _month.year),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSummaryStrip(
      ({int expense, int income, int count, int dailyExpense}) s,
      DateTime start, DateTime end) {
    final fmt = DateFormat('M月d日', 'zh_CN');
    return PaperGroup(
      padding: const EdgeInsets.all(kSpace4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${fmt.format(start)} ~ ${fmt.format(end)} 汇总',
              style: const TextStyle(
                  fontSize: 13, color: kInkSecondary)),
          const SizedBox(height: 4),
          AmountText(s.expense, size: 36, weight: FontWeight.w700),
          const SizedBox(height: kSpace3),
          Row(
            children: [
              _ysCell('收入', AmountText.format(s.income), kSuccess),
              _ysCell('结余', AmountText.format(s.income - s.expense), kInkPrimary),
              _ysCell('笔数', '${s.count} 笔', kInkPrimary),
              _ysCell('日均支出', AmountText.format(s.dailyExpense), kInkSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRangeBarChart(List<int> series) {
    final maxV = series.fold<int>(0, (m, e) => e > m ? e : m);
    final niceMax = _niceMax(maxV / 100.0);
    return PaperGroup(
      title: '每日支出',
      padding: const EdgeInsets.fromLTRB(kSpace3, kSpace2, kSpace3, kSpace4),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: niceMax,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            barGroups: [
              for (int i = 0; i < series.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: series[i] / 100.0,
                      width: series.length > 31 ? 4 : 8,
                      color: kInkPrimary,
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
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: kDividerSubtle, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: niceMax / 4,
                  getTitlesWidget: (value, meta) {
                    if (value <= 0) return const SizedBox.shrink();
                    return Text(_compact(value),
                        style: const TextStyle(
                            fontSize: 10, color: kInkDisabled));
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= series.length) {
                      return const SizedBox.shrink();
                    }
                    final show = series.length > 31
                        ? i % 5 == 0 || i == series.length - 1
                        : i % 2 == 0 || i == series.length - 1;
                    if (!show) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              fontSize: 10, color: kInkDisabled)),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeBalanceChart(List<({DateTime date, int net})> series) {
    final data = [
      for (int i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].net / 100.0),
    ];
    double maxV = 0, minV = 0;
    for (final d in data) {
      if (d.y > maxV) maxV = d.y;
      if (d.y < minV) minV = d.y;
    }
    final pad = (maxV - minV) * 0.18 + 10;
    final fmt = DateFormat('M月d日', 'zh_CN');
    return PaperGroup(
      title: '结余走势（范围）',
      padding: const EdgeInsets.fromLTRB(kSpace3, kSpace2, kSpace3, kSpace4),
      child: SizedBox(
        height: 170,
        child: LineChart(
          LineChartData(
            minY: minV - pad,
            maxY: maxV + pad,
            lineBarsData: [
              LineChartBarData(
                spots: data,
                isCurved: true,
                curveSmoothness: 0.3,
                color: kAccentBlue,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: kAccentBlue.withValues(alpha: 0.08),
                ),
              ),
            ],
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval:
                  ((maxV - minV) / 4).abs().clamp(1, double.infinity),
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: kDividerSubtle, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(
                      _compact(value),
                      style:
                          const TextStyle(fontSize: 10, color: kInkDisabled),
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
                    final i = value.toInt();
                    if (i < 0 || i >= data.length) {
                      return const SizedBox.shrink();
                    }
                    final show = data.length > 31
                        ? i % 7 == 0 || i == data.length - 1
                        : i % 2 == 0 || i == data.length - 1;
                    if (!show) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        fmt.format(series[i].date),
                        style: const TextStyle(
                            fontSize: 10, color: kInkDisabled),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => kInkPrimary,
                getTooltipItems: (touchedSpots) => [
                  for (final s in touchedSpots)
                    if (s.spotIndex >= 0 && s.spotIndex < series.length)
                      LineTooltipItem(
                        '${DateFormat('yyyy年M月d日', 'zh_CN').format(series[s.spotIndex].date)}\n'
                        '结余 ${AmountText.format(series[s.spotIndex].net)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildYearSummaryCard(AppState state, int year) {
    final ys = state.yearSummary(year);
    if (ys.count == 0) return const SizedBox.shrink();
    return PaperGroup(
      title: '$year 年汇总',
      padding: const EdgeInsets.all(kSpace4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ysCell('总支出', AmountText.format(ys.expense), kInkPrimary),
              _ysCell('总收入', AmountText.format(ys.income), kSuccess),
            ],
          ),
          const SizedBox(height: kSpace3),
          Row(
            children: [
              _ysCell(
                  '结余',
                  AmountText.format(ys.income - ys.expense),
                  kInkPrimary),
              _ysCell(
                  '日均支出',
                  AmountText.format(ys.dailyExpense),
                  kInkSecondary),
            ],
          ),
          const SizedBox(height: kSpace3),
          Text(
            '全年 ${ys.count} 笔 · 支出最多：${ys.topCategoryName}',
            style: const TextStyle(fontSize: 12, color: kInkSecondary),
          ),
        ],
      ),
    );
  }

  Widget _ysCell(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: kInkSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  Widget _buildDonut(
      List<({TxCategory category, int amount})> ranking) {
    final top = ranking.take(5).toList();
    final other = ranking.skip(5).fold<int>(0, (s, e) => s + e.amount);
    final total = ranking.fold<int>(0, (s, e) => s + e.amount);
    final maxAmt = ranking.first.amount;
    const grays = [
      Color(0xFF8A8E8B),
      Color(0xFFA9ADA9),
      Color(0xFFC2C5C1),
      Color(0xFFD9DBD8),
      Color(0xFFE7E8E6),
    ];
    final sections = <PieChartSectionData>[
      for (int i = 0; i < top.length; i++)
        PieChartSectionData(
          value: top[i].amount.toDouble(),
          color: top[i].amount == maxAmt
              ? kAccentBlue
              : grays[i % grays.length],
          radius: 40,
          showTitle: false,
        ),
      if (other > 0)
        PieChartSectionData(
          value: other.toDouble(),
          color: const Color(0xFFEFEFED),
          radius: 40,
          showTitle: false,
        ),
    ];
    return PaperGroup(
      title: '支出占比',
      padding: const EdgeInsets.all(kSpace4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 44,
                sectionsSpace: 2,
                startDegreeOffset: -90,
              ),
            ),
          ),
          const SizedBox(width: kSpace4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < top.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: top[i].amount == maxAmt
                                ? kAccentBlue
                                : grays[i % grays.length],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(top[i].category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: kInkSecondary)),
                        ),
                        Text(
                          '${(top[i].amount / total * 100).round()}%',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kInkPrimary,
                              fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeToggle() {
    return Row(
      children: [
        _ChartModeTag(
          label: '支出',
          selected: !_incomeChart,
          onTap: () => setState(() => _incomeChart = false),
        ),
        const SizedBox(width: kSpace2),
        _ChartModeTag(
          label: '收入',
          selected: _incomeChart,
          onTap: () => setState(() => _incomeChart = true),
        ),
      ],
    );
  }

  Widget _buildDailyWeeklyToggle() {
    return Row(
      children: [
        _ChartModeTag(
          label: '每日',
          selected: !_weekly,
          onTap: () => setState(() => _weekly = false),
        ),
        const SizedBox(width: kSpace2),
        _ChartModeTag(
          label: '每周',
          selected: _weekly,
          onTap: () => setState(() => _weekly = true),
        ),
      ],
    );
  }

  Widget _buildYearChart(
      List<({int month, int thisYear, int lastYear})> data) {
    int maxV = 0;
    for (final e in data) {
      if (e.thisYear > maxV) maxV = e.thisYear;
      if (e.lastYear > maxV) maxV = e.lastYear;
    }
    final niceMax = _niceMax(maxV / 100.0);
    final curYear = _month.year;
    return PaperGroup(
      title: '年度对比（$curYear vs ${curYear - 1}）',
      padding: const EdgeInsets.fromLTRB(kSpace3, kSpace2, kSpace3, kSpace4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                maxY: niceMax,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                barGroups: [
                  for (int i = 0; i < data.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i].thisYear / 100.0,
                          width: 5,
                          color: kInkPrimary,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2)),
                        ),
                        BarChartRodData(
                          toY: data[i].lastYear / 100.0,
                          width: 5,
                          color: const Color(0xFFC9CCC9),
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
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: kDividerSubtle, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: niceMax / 4,
                      getTitlesWidget: (value, meta) {
                        if (value <= 0) return const SizedBox.shrink();
                        return Text(_compact(value),
                            style: const TextStyle(
                                fontSize: 10, color: kInkDisabled));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final m = value.toInt() + 1;
                        if (m % 2 == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('$m月',
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
                      final i = group.x;
                      if (i < 0 || i >= data.length) return null;
                      final label = rodIndex == 0 ? '$curYear 年' : '${curYear - 1} 年';
                      return BarTooltipItem(
                        '$label\n'
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
                      final m = response.spot!.touchedBarGroup.x + 1;
                      if (m >= 1 && m <= 12) {
                        setState(() => _month = DateTime(_month.year, m));
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: kSpace2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: kInkPrimary, label: '$curYear 年'),
              const SizedBox(width: kSpace4),
              _LegendDot(color: const Color(0xFFC9CCC9),
                  label: '${curYear - 1} 年'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChart(
      List<({DateTime month, int balance})> series) {
    final data = [
      for (final e in series) (m: e.month, yuan: e.balance / 100.0),
    ];
    double maxV = 0, minV = 0;
    for (final d in data) {
      if (d.yuan > maxV) maxV = d.yuan;
      if (d.yuan < minV) minV = d.yuan;
    }
    final pad = (maxV - minV) * 0.18 + 20;

    return PaperGroup(
      title: '结余走势（近 $_balanceMonths 月）',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChartModeTag(
            label: '6月',
            selected: _balanceMonths == 6,
            onTap: () => setState(() => _balanceMonths = 6),
          ),
          const SizedBox(width: 6),
          _ChartModeTag(
            label: '12月',
            selected: _balanceMonths == 12,
            onTap: () => setState(() => _balanceMonths = 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(kSpace3, kSpace2, kSpace3, kSpace4),
      child: SizedBox(
        height: 170,
        child: BarChart(
          BarChartData(
            minY: minV - pad,
            maxY: maxV + pad,
            alignment: BarChartAlignment.spaceAround,
            barGroups: [
              for (int i = 0; i < data.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      fromY: 0,
                      toY: data[i].yuan,
                      width: 16,
                      color: data[i].yuan >= 0 ? kInkPrimary : kDanger,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2)),
                    ),
                  ],
                ),
            ],
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: ((maxV - minV) / 4).abs().clamp(1, double.infinity),
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: kDividerSubtle, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(
                      _compact(value),
                      style:
                          const TextStyle(fontSize: 10, color: kInkDisabled),
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
                    final i = value.toInt();
                    if (i < 0 || i >= data.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('M月', 'zh_CN').format(data[i].m),
                        style: const TextStyle(
                            fontSize: 10, color: kInkDisabled),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => kInkPrimary,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final i = group.x;
                  if (i < 0 || i >= data.length) return null;
                  return BarTooltipItem(
                    '${DateFormat('yyyy年M月', 'zh_CN').format(data[i].m)}\n'
                    '${AmountText.format(rod.toY.round() * 100)}',
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
                  final i = response.spot!.touchedBarGroup.x;
                  if (i >= 0 && i < data.length) {
                    setState(() => _month = data[i].m);
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetCard(AppState state, MonthSummary summary) {
    final budget = state.monthlyBudget;
    final spent = summary.expense;
    final now = DateTime.now();
    final isCurrent =
        _month.year == now.year && _month.month == now.month;
    if (!isCurrent) return const SizedBox.shrink();
    final ratio = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final over = budget > 0 && spent > budget;
    return PaperGroup(
      title: '预算对比',
      padding: const EdgeInsets.all(kSpace4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (budget <= 0)
            InkWell(
              onTap: () async {
                final v = await showBudgetDialog(context, budget);
                if (v != null && mounted) {
                  await context.read<AppState>().setBudget(v);
                }
              },
              child: const Row(
                children: [
                  Text('设置每月预算',
                      style:
                          TextStyle(fontSize: 13, color: kAccentBlue)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: kAccentBlue),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Text(
                  '预算 ${AmountText.format(budget, showSymbol: false)}',
                  style: const TextStyle(
                      fontSize: 12, color: kInkSecondary),
                ),
                const Spacer(),
                Text(
                  '已用 ${(ratio * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: over ? kDanger : kAccentBlue,
                  ),
                ),
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
                      child: Container(
                          color: over ? kDanger : kInkPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              over
                  ? '已超出预算 ¥'
                  : '已用 ¥ · 剩余 ¥',
              style: const TextStyle(
                  fontSize: 11, color: kInkSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRangeToggle() {
    final fmt = DateFormat('M月d日', 'zh_CN');
    return Row(
      children: [
        const Text('范围：',
            style: TextStyle(fontSize: 13, color: kInkSecondary)),
        _ChartModeTag(
          label: '本月',
          selected: !_rangeMode,
          onTap: () => setState(() => _rangeMode = false),
        ),
        const SizedBox(width: kSpace2),
        _ChartModeTag(
          label: '自定义',
          selected: _rangeMode,
          onTap: () => setState(() => _rangeMode = true),
        ),
        if (_rangeMode) ...[
          const SizedBox(width: kSpace2),
          InkWell(
            onTap: _pickRangeStart,
            borderRadius: BorderRadius.circular(kRadiusTable),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _rangeStart == null
                    ? '起始日期'
                    : '从 ${fmt.format(_rangeStart!)}',
                style: const TextStyle(
                    fontSize: 13, color: kAccentBlue),
              ),
            ),
          ),
          const SizedBox(width: kSpace2),
          InkWell(
            onTap: _pickRangeEnd,
            borderRadius: BorderRadius.circular(kRadiusTable),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _rangeEnd == null
                    ? '结束日期'
                    : '至 ${fmt.format(_rangeEnd!)}',
                style: const TextStyle(
                    fontSize: 13, color: kAccentBlue),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickRangeStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeStart ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: '起始日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null && mounted) {
      setState(() {
        _rangeStart = picked;
        if (_rangeEnd != null && _rangeEnd!.isBefore(_rangeStart!)) {
          _rangeEnd = _rangeStart;
        }
      });
    }
  }

  Future<void> _pickRangeEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeEnd ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: '结束日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null && mounted) {
      setState(() {
        _rangeEnd = DateTime(
            picked.year, picked.month, picked.day, 23, 59, 59);
        if (_rangeStart != null &&
            _rangeEnd!.isBefore(_rangeStart!)) {
          _rangeStart = DateTime(picked.year, picked.month, picked.day);
        }
      });
    }
  }

  Widget _buildSummaryStrip(MonthSummary summary, int count, int delta) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final daily = count == 0 ? 0 : summary.expense ~/ daysInMonth;
    return PaperGroup(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kSpace3),
        child: Row(
          children: [
            _StatCell(
              label: '总支出',
              value: AmountText.format(summary.expense),
              color: kInkPrimary,
              subtitle: delta == 0
                  ? '与上月持平'
                  : '较上月 ${delta > 0 ? '+' : '-'}${AmountText.format(delta.abs(), showSymbol: false)}',
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

  Widget _buildBarChart(
    List<int> seriesCents, {
    required List<({String label, int amount})> weekly,
    required List<int> incomeSeries,
  }) {
    final useWeekly = _weekly && weekly.isNotEmpty;
    final useIncome = _incomeChart && !useWeekly;
    final days = seriesCents.length;
    final n = useWeekly ? weekly.length : days;
    double valueAt(int i) => useWeekly
        ? weekly[i].amount / 100.0
        : (useIncome ? incomeSeries[i] : seriesCents[i]) / 100.0;
    final maxValue = [
      for (int i = 0; i < n; i++) valueAt(i),
    ].fold<double>(0, (a, b) => a > b ? a : b);
    final niceMax = _niceMax(maxValue);
    if (_selectedWeek < 0 && useWeekly) {
      int best = 0;
      for (int i = 1; i < n; i++) {
        if (valueAt(i) > valueAt(best)) best = i;
      }
      _selectedWeek = best;
    }

    return PaperGroup(
      title: useWeekly ? '每周支出' : (useIncome ? '每日收入' : '每日支出'),
      padding: const EdgeInsets.fromLTRB(kSpace3, kSpace2, kSpace3, kSpace4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSelectionCaption(
              useIncome ? incomeSeries : seriesCents,
              weekly: weekly,
              onView: useWeekly
                  ? _showSelectionWeekly
                  : _showSelectionDay),
          const SizedBox(height: kSpace3),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: niceMax,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                barGroups: [
                  for (int i = 0; i < n; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: valueAt(i),
                          width: useWeekly ? 28 : (days > 28 ? 5 : 8),
                          color: useWeekly
                              ? (i == _selectedWeek
                                  ? kAccentBlue
                                  : kInkPrimary)
                              : (i == _selectedDay
                                  ? kAccentBlue
                                  : kInkPrimary),
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
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
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
                        final i = value.toInt();
                        if (i < 0 || i >= n) {
                          return const SizedBox.shrink();
                        }
                        if (useWeekly) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(weekly[i].label,
                                style: const TextStyle(
                                    fontSize: 10, color: kInkDisabled)),
                          );
                        }
                        final day = i + 1;
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
                      final i = group.x;
                      if (i < 0 || i >= n) return null;
                      final title = useWeekly
                          ? weekly[i].label
                          : DateFormat('M月d日', 'zh_CN')
                              .format(DateTime(_month.year, _month.month, i + 1));
                      return BarTooltipItem(
                        '$title\n'
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
                      if (x >= 0 && x < n) {
                        if (useWeekly) {
                          if (x != _selectedWeek) {
                            setState(() => _selectedWeek = x);
                          }
                        } else if (x != _selectedDay) {
                          setState(() => _selectedDay = x);
                        }
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

  Widget _buildSelectionCaption(
    List<int> series, {
    required List<({String label, int amount})> weekly,
    VoidCallback? onView,
  }) {
    if (_weekly && weekly.isNotEmpty) {
      if (_selectedWeek < 0 || _selectedWeek >= weekly.length) {
        return const SizedBox.shrink();
      }
      return Row(
        children: [
          Text(weekly[_selectedWeek].label,
              style:
                  const TextStyle(fontSize: 13, color: kInkSecondary)),
          const Spacer(),
          AmountText(weekly[_selectedWeek].amount,
              size: 18, weight: FontWeight.w700, color: kAccentBlue),
          if (onView != null) _viewHint(onView),
        ],
      );
    }
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
        if (onView != null) _viewHint(onView),
      ],
    );
  }

  Widget _viewHint(VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: kSpace3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusTable),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('查看流水',
                style: TextStyle(fontSize: 12, color: kAccentBlue)),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: kAccentBlue),
          ],
        ),
      ),
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
    final sign = yuan < 0 ? '-' : '';
    final v = yuan.abs();
    if (v >= 10000) {
      final w = v / 10000;
      return '$sign${w.toStringAsFixed(w >= 10 ? 0 : 1)}w';
    }
    if (v >= 1000) {
      return '$sign${(v / 1000).toStringAsFixed(1)}k';
    }
    if (v >= 100) return '$sign${v.round()}';
    return '$sign${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1)}';
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


class _ChartModeTag extends StatelessWidget {
  const _ChartModeTag({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusTable),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kAccentSoft : kPaperSurface,
          borderRadius: BorderRadius.circular(kRadiusTable),
          border: Border.all(
            color: selected ? kAccentBlue : kDividerDefault,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? kAccentBlue : kInkSecondary,
          ),
        ),
      ),
    );
  }
}


class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: kInkSecondary)),
      ],
    );
  }
}
