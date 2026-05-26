import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/shift.dart';
import '../providers/app_provider.dart';
import '../services/billing_service.dart';
import '../services/storage_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isYearView = false;
  int _taxPercent = 6;
  String _taxPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _loadTax();
  }

  Future<void> _loadTax() async {
    final prefs = await _TaxStorage.load();
    setState(() { _taxPercent = prefs.p; _taxPeriod = prefs.period; });
  }

  double _total(Shift s) => s.totalIncome;

  double _incomeForPeriod(Map<String, Shift> shifts, DateTime start, DateTime end) {
    double total = 0;
    shifts.forEach((k, s) {
      if (s.type == 'off') return;
      final d = DateTime.tryParse(k); if (d == null) return;
      if (!d.isBefore(start) && !d.isAfter(end)) total += _total(s);
    });
    return total;
  }

  void _copyTaxReport(Map<String, Shift> shifts, String currency) {
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
    final netIncome = income - tax;
    
    String taxLabel = '';
    if (_taxPercent == 4) taxLabel = 'НПД 4% (Физ. лица)';
    else if (_taxPercent == 6) taxLabel = 'НПД 6% / УСН (Юр. лица / ИП)';
    else if (_taxPercent == 13) taxLabel = 'ТК РФ (13%)';

    final report = '''
📋 Отчёт о доходах и налогах
Период: ${DateFormat('dd.MM.yyyy').format(start)} — ${DateFormat('dd.MM.yyyy').format(end)}
Система: $taxLabel

💰 Заработано грязными: ${income.toStringAsFixed(2)} $currency
💸 Удержан налог: ${tax.toStringAsFixed(2)} $currency
✅ Итого на руки: ${netIncome.toStringAsFixed(2)} $currency
''';

    Clipboard.setData(ClipboardData(text: report)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Отчёт скопирован в буфер обмена!'),
        backgroundColor: Colors.green,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final billing = context.watch<BillingService>();
    final shifts = app.shifts;
    final currency = app.currency;
    final isPlus = billing.isPlusActive;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF4F7FC);
    final accent = const Color(0xFF607D8B);
    final now = DateTime.now();

    double curTotal = 0;
    double curHours = 0;
    int workDays = 0, dayShifts = 0, nightShifts = 0, offDays = 0;

    Map<int, double> incByWd = {for (int i=1;i<=7;i++) i: 0};
    Map<int, int> cntByWd = {for (int i=1;i<=7;i++) i: 0};
    double maxAvgByWd = 0.001; // Avoid div by zero

    shifts.forEach((k, s) {
      final d = DateTime.tryParse(k); if (d == null) return;
      
      final inPeriod = _isYearView ? d.year == now.year : (d.year == now.year && d.month == now.month);
      if (inPeriod) {
        curTotal += _total(s);
        if (s.type != 'off') {
          workDays++;
          if (s.type == 'day') dayShifts++;
          if (s.type == 'night') nightShifts++;
          double h = s.type == '24h' ? 24 : () {
            final sp = s.startTime.split(':'), ep = s.endTime.split(':');
            double st = double.parse(sp[0]) + double.parse(sp[1]) / 60;
            double en = double.parse(ep[0]) + double.parse(ep[1]) / 60;
            if (en <= st) en += 24;
            return en - st;
          }();
          curHours += h;
        } else {
          offDays++;
        }
      }

      // Heatmap logic
      if (s.type != 'off' && inPeriod) {
        incByWd[d.weekday] = (incByWd[d.weekday] ?? 0) + _total(s);
        cntByWd[d.weekday] = (cntByWd[d.weekday] ?? 0) + 1;
      }
    });

    Map<int, double> avgByWd = {};
    for (int i=1; i<=7; i++) {
      double avg = cntByWd[i]! > 0 ? incByWd[i]! / cntByWd[i]! : 0;
      avgByWd[i] = avg;
      if (avg > maxAvgByWd) maxAvgByWd = avg;
    }

    final period = _isYearView ? 'Год (${now.year})' : DateFormat('LLLL yyyy', 'ru').format(now);
    final weekdays = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(period, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(backgroundColor: isDark ? const Color(0xFF263238) : Colors.grey.shade200),
                  onPressed: () => setState(() => _isYearView = !_isYearView),
                  child: Text(_isYearView ? 'Месяц' : 'Год',
                    style: TextStyle(color: isDark ? const Color(0xFF90A4AE) : Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Главый Дашборд Дохода
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF263238), const Color(0xFF37474F)] 
                    : [const Color(0xFF455A64), const Color(0xFF607D8B)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ЗАРАБОТАНО', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text('${curTotal.toStringAsFixed(0)} $currency',
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text('Отработано часов: ${curHours.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Быстрая статистика
            Row(
              children: [
                Expanded(child: _miniStatCard(Icons.work_history, 'Смены', '$workDays', isDark, card)),
                const SizedBox(width: 12),
                Expanded(child: _miniStatCard(Icons.wb_sunny, 'Дневные', '$dayShifts', isDark, card)),
                const SizedBox(width: 12),
                Expanded(child: _miniStatCard(Icons.mode_night, 'Ночные', '$nightShifts', isDark, card)),
              ],
            ),
            const SizedBox(height: 24),

            if (isPlus) ...[
              const Text('🔥 Активность по дням', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: List.generate(7, (i) {
                    final avg = avgByWd[i+1] ?? 0;
                    final pct = (avg / maxAvgByWd).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          SizedBox(width: 30, child: Text(weekdays[i], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 24,
                                  decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                                ),
                                FractionallySizedBox(
                                  widthFactor: pct > 0 ? pct : 0.001,
                                  child: Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: pct > 0 ? accent.withOpacity(0.5 + (0.5 * pct)) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 60, child: Text(avg > 0 ? '${avg.toStringAsFixed(0)}$currency' : '-', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              const Text('🧾 Умный расчёт налогов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF263238).withOpacity(0.5) : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? const Color(0xFF37474F) : Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Выберите вашу налоговую ставку:', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _taxChip(4, '4% НПД', 'Для самозанятых с физ. лицами'),
                        _taxChip(6, '6% НПД/УСН', 'Юр. лица и ИП'),
                        _taxChip(13, '13% ТК', 'По трудовому договору'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Период: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        SegmentedButton<String>(
                          style: SegmentedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          ),
                          segments: const [
                            ButtonSegment(value: 'month', label: Text('Месяц')), 
                            ButtonSegment(value: 'quarter', label: Text('Квартал'))
                          ],
                          selected: {_taxPeriod},
                          onSelectionChanged: (s) async {
                            await _TaxStorage.savePeriod(s.first);
                            setState(() => _taxPeriod = s.first);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? accent : Colors.blue.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => _copyTaxReport(shifts, currency),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Скопировать расчёт', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Placeholder for free users
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Продвинутая аналитика', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Тепловая карта, умные налоги и детальная статистика доступны в Plus+', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => PurchaseSheet.show(context),
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      child: const Text('Подробнее о Plus+'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _taxChip(int percent, String title, String tooltip) {
    final selected = _taxPercent == percent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        await _TaxStorage.savePercent(percent);
        setState(() => _taxPercent = percent);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? (isDark ? const Color(0xFF607D8B) : Colors.blue.shade600) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.transparent : (isDark ? const Color(0xFF37474F) : Colors.grey.shade300)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold)),
            Text(tooltip, style: TextStyle(fontSize: 10, color: selected ? Colors.white70 : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard(IconData icon, String title, String value, bool isDark, Color cardBg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(icon, color: isDark ? Colors.white70 : Colors.grey.shade600, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _TaxStorage {
  static Future<({int p, String period})> load() async {
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
