import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../models/shift.dart';
import '../models/goal.dart';
import '../providers/app_provider.dart';
import '../services/billing_service.dart';
import '../services/storage_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isYearView = false;
  int _taxPercent = 6;
  String _taxPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadTax();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTax() async {
    final prefs = await _TaxStorage.load();
    setState(() { _taxPercent = prefs.p; _taxPeriod = prefs.period; });
  }

  double _total(Shift s) => s.totalIncome;
  double _base(Shift s) => s.income;
  double _bonus(Shift s) => s.bonus;
  double _otMoney(Shift s) => s.overtime;
  double _penaltyMoney(Shift s) => s.penalty;

  Map<DateTime, double> _monthlyIncome(Map<String, Shift> shifts) {
    final Map<DateTime, double> m = {};
    shifts.forEach((k, s) {
      if (s.type == 'off') return;
      final d = DateTime.tryParse(k); if (d == null) return;
      final key = DateTime(d.year, d.month, 1);
      m[key] = (m[key] ?? 0) + _total(s);
    });
    return m;
  }

  Map<DateTime, double> _monthlyOvertime(Map<String, Shift> shifts) {
    final Map<DateTime, double> m = {};
    shifts.forEach((k, s) {
      if (s.type == 'off') return;
      final d = DateTime.tryParse(k); if (d == null) return;
      double ot = 0;
      if (s.type == '24h') { ot = 12; }
      else {
        final sp = s.startTime.split(':'), ep = s.endTime.split(':');
        double start = double.parse(sp[0]) + double.parse(sp[1]) / 60;
        double end = double.parse(ep[0]) + double.parse(ep[1]) / 60;
        if (end <= start) end += 24;
        if (end - start > 12) ot = end - start - 12;
      }
      final key = DateTime(d.year, d.month, 1);
      m[key] = (m[key] ?? 0) + ot;
    });
    return m;
  }

  double _incomeForPeriod(Map<String, Shift> shifts, DateTime start, DateTime end) {
    double total = 0;
    shifts.forEach((k, s) {
      if (s.type == 'off') return;
      final d = DateTime.tryParse(k); if (d == null) return;
      if (!d.isBefore(start) && !d.isAfter(end)) total += _total(s);
    });
    return total;
  }

  void _shareTaxReport(Map<String, Shift> shifts, String currency) async {
    final now = DateTime.now();
    DateTime start, end;
    if (_taxPeriod == 'month') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    } else {
      final q = ((now.month - 1) ~/ 3) + 1;
      final sm = (q - 1) * 3 + 1;
      start = DateTime(now.year, sm, 1);
      end = DateTime(now.year, sm + 3, 0);
    }
    final income = _incomeForPeriod(shifts, start, end);
    final tax = income * _taxPercent / 100;
    final clean = income - tax;
    final report = '''
📊 НАЛОГОВЫЙ ОТЧЁТ
━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 Период: ${DateFormat('dd.MM.yyyy').format(start)} — ${DateFormat('dd.MM.yyyy').format(end)}
📈 Ставка налога: $_taxPercent%

💰 ОБЩИЙ ДОХОД:        ${income.toStringAsFixed(2)} $currency
💸 НАЛОГ К УПЛАТЕ:      ${tax.toStringAsFixed(2)} $currency
🧾 ЧИСТАЯ ПРИБЫЛЬ:     ${clean.toStringAsFixed(2)} $currency

📉 Доля налога: ${income > 0 ? (tax / income * 100).toStringAsFixed(1) : 0}%
━━━━━━━━━━━━━━━━━━━━━━━━━━━
Отчёт сформирован в Kalendar 1.0.0
''';
    await Share.share(report, subject: 'Налоговый отчёт Kalendar');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<<AppProvider>();
    final billing = context.watch<BillingService>();
    final shifts = app.shifts;
    final goals = app.goals;
    final currency = app.currency;
    final isPlus = billing.isPlusActive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final accent = const Color(0xFF607D8B);
    final now = DateTime.now();

    double curTotal = 0, earnedAll = 0;
    double sumBase = 0, sumBonus = 0, sumOt = 0, sumPenalty = 0;
    double curHours = 0;
    int workDays = 0, dayShifts = 0, nightShifts = 0, tfShifts = 0, offDays = 0;
    int pastWithIncome = 0;
    double pastInc = 0;
    int futureWork = 0;
    double inc30 = 0;
    final ago30 = now.subtract(const Duration(days: 30));

    shifts.forEach((k, s) {
      final d = DateTime.tryParse(k); if (d == null) return;
      final inc = _total(s);
      earnedAll += inc;
      if (d.isAfter(ago30) && d.isBefore(now)) inc30 += inc;

      final inPeriod = _isYearView ? d.year == now.year : (d.year == now.year && d.month == now.month);
      if (inPeriod) {
        curTotal += inc;
        sumBase += _base(s);
        sumBonus += _bonus(s);
        sumOt += _otMoney(s);
        sumPenalty += _penaltyMoney(s);

        if (s.type != 'off') {
          workDays++;
          if (s.type == 'day') dayShifts++;
          if (s.type == 'night') nightShifts++;
          if (s.type == '24h') tfShifts++;
          double h = s.type == '24h' ? 24 : () {
            final sp = s.startTime.split(':'), ep = s.endTime.split(':');
            double st = double.parse(sp[0]) + double.parse(sp[1]) / 60;
            double en = double.parse(ep[0]) + double.parse(ep[1]) / 60;
            if (en <= st) en += 24;
            return en - st;
          }();
          curHours += h;
          if (d.isBefore(now) && inc > 0) { pastWithIncome++; pastInc += inc; }
          if (d.isAfter(now)) futureWork++;
        } else {
          offDays++;
        }
      }
    });

    final avg = pastWithIncome > 0 ? pastInc / pastWithIncome : 0.0;
    final forecast = curTotal + futureWork * avg;

    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    double prevTotal = 0;
    shifts.forEach((k, s) {
      final d = DateTime.tryParse(k); if (d == null) return;
      if (d.year == prevYear && d.month == prevMonth) prevTotal += _total(s);
    });
    final diff = curTotal - prevTotal;
    final diffPct = prevTotal > 0 ? diff / prevTotal * 100 : 0.0;

    final monthlyInc = _monthlyIncome(shifts);
    final sortedM = monthlyInc.keys.toList()..sort();
    final spots = [for (int i = 0; i < sortedM.length; i++) FlSpot(i.toDouble(), monthlyInc[sortedM[i]]!)];
    double maxInc = sortedM.isEmpty ? 1 : sortedM.map((m) => monthlyInc[m]!).reduce((a, b) => a > b ? a : b);

    final monthlyOt = _monthlyOvertime(shifts);
    final sortedO = monthlyOt.keys.toList()..sort();
    final otBars = [for (int i = 0; i < sortedO.length; i++)
      BarChartGroupData(x: i, barRods: [BarChartRodData(
        toY: monthlyOt[sortedO[i]]!,
        color: isDark ? const Color(0xFFEF5350) : Colors.red,
        width: 16, borderRadius: BorderRadius.circular(4),
      )])
    ];
    double maxOt = sortedO.isEmpty ? 1 : sortedO.map((m) => monthlyOt[m]!).reduce((a, b) => a > b ? a : b);

    Map<int, double> incByWd = {for (int i=1;i<=7;i++) i: 0};
    Map<int, int> cntByWd = {for (int i=1;i<=7;i++) i: 0};
    shifts.forEach((k, s) {
      final d = DateTime.tryParse(k); if (d == null) return;
      if (s.type == 'off') return;
      incByWd[d.weekday] = (incByWd[d.weekday] ?? 0) + _total(s);
      cntByWd[d.weekday] = (cntByWd[d.weekday] ?? 0) + 1;
    });
    Map<int, double> avgByWd = {for (int i=1;i<=7;i++) i: cntByWd[i]! > 0 ? incByWd[i]! / cntByWd[i]! : 0};

    double yearFc = 0;
    shifts.forEach((k, s) {
      if (s.type == 'off') return;
      final d = DateTime.tryParse(k); if (d == null) return;
      if (d.isAfter(now)) yearFc += _total(s);
    });
    if (yearFc == 0 && avg > 0) {
      final remDays = DateTime(now.year, 12, 31).difference(now).inDays;
      yearFc = (remDays ~/ 7) * 2 * avg;
    }

    final period = _isYearView ? 'Год (${now.year})' : DateFormat('LLLL yyyy', 'ru').format(now);
    final weekdays = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Аналитика', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: accent,
          labelColor: accent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Сводка'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Графики'),
            Tab(icon: Icon(Icons.local_fire_department), text: 'Тепловая'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Налоги'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildSummaryTab(curTotal, forecast, diffPct, workDays, dayShifts, nightShifts, tfShifts, offDays, curHours, sumBase, sumBonus, sumOt, sumPenalty, currency, isDark, card, accent, period, goals, inc30, yearFc),
          _buildChartsTab(spots, sortedM, maxInc, otBars, sortedO, maxOt, isDark, card, accent),
          _buildHeatmapTab(avgByWd, weekdays, currency, isDark, card),
          _buildTaxTab(shifts, currency, isDark, card),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(double curTotal, double forecast, double diffPct, int workDays, int dayShifts, int nightShifts, int tfShifts, int offDays, double curHours, double sumBase, double sumBonus, double sumOt, double sumPenalty, String currency, bool isDark, Color card, Color accent, String period, List<<Goal> goals, double inc30, double yearFc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(period, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              FilledButton.tonal(
                style: FilledButton.styleFrom(backgroundColor: isDark ? const Color(0xFF263238) : null),
                onPressed: () => setState(() => _isYearView = !_isYearView),
                child: Text(_isYearView ? 'За Месяц' : 'За Год',
                  style: TextStyle(color: isDark ? const Color(0xFF90A4AE) : null)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark ? [const Color(0xFF263238), const Color(0xFF37474F)] : [const Color(0xFF455A64), const Color(0xFF607D8B)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ДОХОД', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    if (!_isYearView)
                      Row(children: [
                        Icon(diffPct >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: diffPct >= 0 ? const Color(0xFFA5D6A7) : Colors.redAccent, size: 16),
                        const SizedBox(width: 4),
                        Text('${diffPct >= 0 ? '+' : ''}${diffPct.toStringAsFixed(1)}% vs прошлый мес.',
                          style: TextStyle(color: diffPct >= 0 ? const Color(0xFFA5D6A7) : Colors.redAccent, fontSize: 12)),
                      ]),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${curTotal.toStringAsFixed(0)} $currency',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Прогноз: ${forecast.toStringAsFixed(0)} $currency',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _miniStat('База', '${sumBase.toStringAsFixed(0)} $currency', Colors.white70),
                    _miniStat('Премия', '${sumBonus.toStringAsFixed(0)} $currency', const Color(0xFFFFCC80)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _miniStat('Перераб.', '${sumOt.toStringAsFixed(0)} $currency', const Color(0xFFA5D6A7)),
                    _miniStat('Штраф', '${sumPenalty.toStringAsFixed(0)} $currency', Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
            children: [
              _statCard(Icons.work_outline, accent, 'Смены', '$workDays', card),
              _statCard(Icons.wb_sunny_outlined, const Color(0xFF90CAF9), 'Дневных', '$dayShifts', card),
              _statCard(Icons.nights_stay_outlined, const Color(0xFFB39DDB), 'Ночных', '$nightShifts', card),
              _statCard(Icons.weekend_outlined, const Color(0xFFFFCC80), 'Выходных', '$offDays', card),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Часы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _hoursBar('Всего', curHours, curHours, accent),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (goals.isNotEmpty) ...[
            _sectionTitle('🎯 Мои цели'),
            ...goals.map((g) => _goalCard(g, currency, inc30, isDark, card)),
          ],

          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B5E20).withOpacity(0.3) : Colors.green.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔮 Прогноз до конца года', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('~ ${yearFc.toStringAsFixed(0)} $currency',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5D6A7) : Colors.green)),
                const SizedBox(height: 4),
                Text('На основе средней смены и запланированных дат',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildChartsTab(List<<FlSpot> spots, List<DateTime> sortedM, double maxInc, List<<BarChartGroupData> otBars, List<DateTime> sortedO, double maxOt, bool isDark, Color card, Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📈 Доход по месяцам'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
            child: spots.length < 2
                ? const Padding(padding: EdgeInsets.all(16), child: Text('Мало данных. Добавьте смены!', style: TextStyle(color: Colors.grey)))
                : SizedBox(
                    height: 220,
                    child: LineChart(LineChartData(
                      minY: 0, maxY: maxInc * 1.2,
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= sortedM.length) return const Text('');
                          return Text(DateFormat('MMM', 'ru').format(sortedM[i]), style: const TextStyle(fontSize: 10));
                        })),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
                          getTitlesWidget: (v, _) => v == 0 ? const Text('') : Text('${(v/1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 10)))),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [LineChartBarData(
                        spots: spots, isCurved: true, curveSmoothness: 0.35,
                        color: accent, barWidth: 4, isStrokeCapRound: true,
                        belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                          colors: [accent.withOpacity(0.4), accent.withOpacity(0)],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        )),
                        dotData: const FlDotData(show: true),
                      )],
                    )),
                  ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('🔥 Переработки по месяцам'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
            child: otBars.isEmpty || maxOt == 0
                ? const Padding(padding: EdgeInsets.all(16), child: Text('Нет данных о переработках', style: TextStyle(color: Colors.grey)))
                : SizedBox(
                    height: 220,
                    child: BarChart(BarChartData(
                      maxY: maxOt * 1.2,
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= sortedO.length) return const Text('');
                          return Text(DateFormat('MMM', 'ru').format(sortedO[i]), style: const TextStyle(fontSize: 10));
                        })),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: otBars,
                    )),
                  ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeatmapTab(Map<int, double> avgByWd, List<String> weekdays, String currency, bool isDark, Color card) {
    final maxAvg = avgByWd.values.isEmpty ? 1 : avgByWd.values.reduce((a, b) => a > b ? a : b);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🌡 Тепловая карта доходов'),
          const SizedBox(height: 8),
          Text('Средний доход по дням недели. Чем ярче — тем больше зарабатываете.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: List.generate(7, (i) {
                final wd = i + 1;
                final avg = avgByWd[wd] ?? 0;
                final intensity = maxAvg > 0 ? avg / maxAvg : 0.0;
                final color = isDark
                    ? Color.lerp(const Color(0xFF1E1E1E), const Color(0xFFA5D6A7), intensity)!
                    : Color.lerp(Colors.grey.shade200, Colors.green, intensity)!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: Text(weekdays[i], style: const TextStyle(fontWeight: FontWeight.bold))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text('${avg.toStringAsFixed(0)} $currency',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: intensity > 0.5 ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTaxTab(Map<String, Shift> shifts, String currency, bool isDark, Color card) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🧾 Налоговый отчёт'),
          const SizedBox(height: 8),
          Text('Сформируйте отчёт для бухгалтерии или самозанятости.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF263238).withOpacity(0.5) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Ставка: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  SegmentedButton<int>(
                    segments: const [ButtonSegment(value: 6, label: Text('6%')), ButtonSegment(value: 13, label: Text('13%'))],
                    selected: {_taxPercent},
                    onSelectionChanged: (s) async {
                      await _TaxStorage.savePercent(s.first);
                      setState(() => _taxPercent = s.first);
                    },
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  const Text('Период: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  SegmentedButton<String>(
                    segments: const [ButtonSegment(value: 'month', label: Text('Месяц')), ButtonSegment(value: 'quarter', label: Text('Квартал'))],
                    selected: {_taxPeriod},
                    onSelectionChanged: (s) async {
                      await _TaxStorage.savePeriod(s.first);
                      setState(() => _taxPeriod = s.first);
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF455A64) : Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _shareTaxReport(shifts, currency),
                    icon: const Icon(Icons.copy_all),
                    label: const Text('Скопировать отчёт', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _legacyGoalCard(AppProvider app, String currency, bool isDark, double curTotal) {
    final prog = app.legacyGoalPrice > 0 ? (curTotal / app.legacyGoalPrice).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isDark ? [const Color(0xFF263238), const Color(0xFF37474F)] : [const Color(0xFF455A64), const Color(0xFF607D8B)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('ЦЕЛЬ: ${app.legacyGoalName.toUpperCase()}', style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1.5)),
            Text('${app.legacyGoalPrice.toStringAsFixed(0)} $currency', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Text('${curTotal.toStringAsFixed(0)} $currency', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: prog, minHeight: 8, backgroundColor: Colors.white24, color: const Color(0xFFA5D6A7)),
          ),
        ],
      ),
    );
  }

  Widget _goalCard(Goal g, String currency, double inc30, bool isDark, Color card) {
    final avgDaily = inc30 / 30.0;
    final dailyForGoal = avgDaily * (g.distributionPercent / 100.0);
    final remaining = g.targetAmount - g.currentAmount;
    String prediction;
    if (remaining <= 0) { prediction = 'Достигнуто! 🎉'; }
    else if (dailyForGoal <= 0) { prediction = 'Нет отчислений'; }
    else {
      final days = (remaining / dailyForGoal).ceil();
      final dt = DateTime.now().add(Duration(days: days));
      prediction = '~${DateFormat('d MMM yyyy', 'ru').format(dt)}';
    }
    final prog = (g.currentAmount / g.targetAmount).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('${g.distributionPercent}% дохода', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${g.currentAmount.toStringAsFixed(0)} / ${g.targetAmount.toStringAsFixed(0)} $currency',
            style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('📅 $prediction', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: prog, minHeight: 8,
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade300,
            color: isDark ? const Color(0xFFA5D6A7) : Colors.green,
          ),
        ),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: color, fontSize: 11)),
      Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _statCard(IconData icon, Color color, String title, String value, Color bg) => Container(
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 22)),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      ]),
    ]),
  );

  Widget _hoursBar(String title, double hours, double total, Color color) {
    if (total == 0) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: TextStyle(color: Colors.grey.shade500)),
        Text('${hours.toStringAsFixed(1)} ч', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
        value: (hours / total).clamp(0, 1), minHeight: 8, color: color, backgroundColor: color.withOpacity(0.1),
      )),
    ]);
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );
}

class _TaxStorage {
  static Future<<({int p, String period})> load() async {
    final t = await StorageService.loadTaxSettings();
    return (p: t.percent, period: t.period);
  }
  static Future<void> savePercent(int v) async {
    final t = await StorageService.loadTaxSettings();
    await StorageService.saveTaxSettings(v, t.period);
  }
  static Future<void> savePeriod(String v) async {
    final t = await StorageService.loadTaxSettings();
    await StorageService.saveTaxSettings(t.percent, v);
  }
}
