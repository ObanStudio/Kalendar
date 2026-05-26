import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/shift.dart';
import '../providers/app_provider.dart';
import '../services/billing_service.dart';
import '../widgets/edit_shift_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  bool _isMultiSelect = false;
  final Set<String> _selectedDates = {};

  void _changeMonth(int d) =>
      setState(() => _currentDate = DateTime(_currentDate.year, _currentDate.month + d, 1));

  List<DateTime?> _buildGrid() {
    final first = DateTime(_currentDate.year, _currentDate.month, 1);
    final last = DateTime(_currentDate.year, _currentDate.month + 1, 0);

    final offset = (first.weekday + 6) % 7;
    final List<DateTime?> dates = List.filled(offset, null, growable: true);

    for (int i = 1; i <= last.day; i++) dates.add(DateTime(_currentDate.year, _currentDate.month, i));
    while (dates.length % 7 != 0) dates.add(null);

    return dates;
  }

  bool _isCompleted(String dateKey, Shift? shift) {
    if (shift == null || shift.type == 'off') return false;
    final p = dateKey.split('-');
    final base = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    final ep = shift.endTime.split(':');
    var end = DateTime(base.year, base.month, base.day, int.parse(ep[0]), int.parse(ep[1]));
    if (shift.type == 'night' || shift.type == '24h') end = end.add(const Duration(days: 1));
    return DateTime.now().isAfter(end);
  }

  void _openSheet({String? single, List<String>? multi}) {
    final app = context.read<AppProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: app,
        child: EditShiftSheet(
          dateKey: single ?? '',
          isMultiple: multi != null,
          initialShift: single != null ? app.shifts[single] : null,
          onSave: (shift) {
            Navigator.pop(context);
            if (multi != null) {
              final batch = {for (var k in multi) k: shift};
              app.setBatchShifts(batch);
              if (context.read<BillingService>().isPlusActive) {
                app.distributeIncome(shift);
              }
              setState(() { _isMultiSelect = false; _selectedDates.clear(); });
            } else {
              app.setShift(single!, shift);
              if (context.read<BillingService>().isPlusActive) {
                app.distributeIncome(shift);
              }
            }
          },
          onDelete: single != null
              ? () { Navigator.pop(context); app.deleteShift(single); }
              : () {},
        ),
      ),
    );
  }

  void _openLoopSheet() {
    DateTime loopStart = DateTime.now();
    DateTime loopEnd = DateTime.now().add(const Duration(days: 30));
    String pattern = '2x2';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, set) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final txt = isDark ? Colors.white : Colors.black87;

          Future<void> pick(bool isStart) async {
            final d = await showDatePicker(
              context: ctx,
              initialDate: isStart ? loopStart : loopEnd,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (d != null) set(() => isStart ? loopStart = d : loopEnd = d);
          }

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 24, right: 24, top: 16,
            ),
            decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text('Зациклить график', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: txt)),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: _dateTile('Начало', loopStart, () => pick(true), isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _dateTile('Конец', loopEnd, () => pick(false), isDark)),
                  ]),
                  const SizedBox(height: 20),
                  const Text('Паттерн', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade700), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: pattern,
                        isExpanded: true,
                        dropdownColor: bg,
                        style: TextStyle(color: txt, fontSize: 16),
                        items: const [
                          DropdownMenuItem(value: '2x2', child: Text('2 Дня / 2 Выходных')),
                          DropdownMenuItem(value: '1d1n2off', child: Text('1 День / 1 Ночь / 2 Выходных')),
                          DropdownMenuItem(value: '5x2', child: Text('5 рабочих / 2 выходных')),
                          DropdownMenuItem(value: '3x3', child: Text('3 рабочих / 3 выходных')),
                        ],
                        onChanged: (v) { if (v != null) set(() => pattern = v); },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF455A64),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () { _applyLoop(loopStart, loopEnd, pattern); Navigator.pop(ctx); },
                      child: const Text('Заполнить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dateTile(String label, DateTime date, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade700),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(DateFormat('dd.MM.yyyy').format(date),
              style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  void _applyLoop(DateTime start, DateTime end, String pid) {
    final day = Shift(type: 'day', startTime: '08:00', endTime: '20:00');
    final night = Shift(type: 'night', startTime: '20:00', endTime: '08:00');
    final off = const Shift(type: 'off');

    List<Shift> seq;
    switch (pid) {
      case '2x2':    seq = [day, day, off, off]; break;
      case '1d1n2off': seq = [day, night, off, off]; break;
      case '5x2':    seq = [day, day, day, day, day, off, off]; break;
      case '3x3':    seq = [day, day, day, off, off, off]; break;
      default: return;
    }

    final Map<String, Shift> batch = {};
    var cur = start;
    int i = 0;
    while (!cur.isAfter(end)) {
      batch[DateFormat('yyyy-MM-dd').format(cur)] = seq[i % seq.length];
      cur = cur.add(const Duration(days: 1));
      i++;
    }
    context.read<AppProvider>().setBatchShifts(batch);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final shifts = app.shifts;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = const Color(0xFF607D8B);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final selectedKeyStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final selectedShift = shifts[selectedKeyStr];
    final note = selectedShift?.note ?? '';
    final isCompleted = _isCompleted(selectedKeyStr, selectedShift);

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('LLLL yyyy', 'ru').format(_currentDate).toUpperCase(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.loop, color: isDark ? const Color(0xFF90A4AE) : const Color(0xFF455A64)),
                        onPressed: _openLoopSheet,
                        tooltip: 'Автозаполнение',
                      ),
                      IconButton(
                        icon: Icon(Icons.checklist, color: _isMultiSelect ? accent : Colors.grey),
                        onPressed: () => setState(() { _isMultiSelect = !_isMultiSelect; _selectedDates.clear(); }),
                        tooltip: 'Мультивыбор',
                      ),
                      IconButton(icon: const Icon(Icons.chevron_left, color: Colors.grey), onPressed: () => _changeMonth(-1)),
                      IconButton(icon: const Icon(Icons.chevron_right, color: Colors.grey), onPressed: () => _changeMonth(1)),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'].map((e) => Expanded(
                  child: Center(child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13))),
                )).toList(),
              ),
            ),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8,
                ),
                itemCount: _buildGrid().length,
                itemBuilder: (_, idx) {
                  final dates = _buildGrid();
                  final date = dates[idx];
                  if (date == null) return const SizedBox();

                  final key = DateFormat('yyyy-MM-dd').format(date);
                  final shift = shifts[key];
                  final isToday = key == todayStr;
                  final isSingleSel = !_isMultiSelect && key == selectedKeyStr;
                  final isMultiSel = _selectedDates.contains(key);
                  final done = _isCompleted(key, shift);
                  
                  IconData? moodIcon = _moodIcon(shift?.mood);

                  Color bg = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;
                  Color tc = isDark ? Colors.white : Colors.black87;

                  if (shift != null) {
                    switch (shift.type) {
                      case 'day':
                        bg = isDark ? const Color(0xFF263238) : const Color(0xFFE3F2FD);
                        tc = isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
                        break;
                      case 'night':
                        bg = isDark ? const Color(0xFF37474F) : const Color(0xFFE8EAF6);
                        tc = isDark ? const Color(0xFFB39DDB) : const Color(0xFF283593);
                        break;
                      case '24h':
                        bg = isDark ? const Color(0xFF1B5E20).withOpacity(0.5) : const Color(0xFFE0F2F1);
                        tc = isDark ? const Color(0xFFA5D6A7) : const Color(0xFF00695C);
                        break;
                      case 'off':
                        bg = isDark ? const Color(0xFF3E2723).withOpacity(0.5) : const Color(0xFFFFF3E0);
                        tc = isDark ? const Color(0xFFFFCC80) : const Color(0xFFE65100);
                        break;
                    }
                  }

                  if (done && shift?.type != 'off') {
                    bg = bg.withOpacity(isDark ? 0.4 : 0.6);
                    tc = tc.withOpacity(0.6);
                  }
                  if (isMultiSel) bg = accent.withOpacity(0.3);

                  Color border = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200;
                  if (isSingleSel || isToday) border = accent;
                  if (isMultiSel) border = accent;

                  return InkWell(
                    onTap: () {
                      if (_isMultiSelect) {
                        setState(() {
                          _selectedDates.contains(key) ? _selectedDates.remove(key) : _selectedDates.add(key);
                        });
                      } else {
                        setState(() => _selectedDate = date);
                        _openSheet(single: key);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border, width: isSingleSel || isToday || isMultiSel ? 2 : 1),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(child: Text('${date.day}',
                            style: TextStyle(fontWeight: isToday || shift != null ? FontWeight.bold : FontWeight.normal, color: tc, fontSize: 16))),
                          if (done && shift?.type != 'off')
                            const Positioned(bottom: 2, right: 2, child: Icon(Icons.check_circle, size: 10, color: Color(0xFFA5D6A7))),
                          if (moodIcon != null)
                            Positioned(top: 2, left: 3, child: Icon(moodIcon, size: 12, color: tc.withOpacity(0.7))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (!_isMultiSelect)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, -4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.edit_note, color: accent, size: 20),
                          const SizedBox(width: 8),
                          Text(DateFormat('d MMMM', 'ru').format(_selectedDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Text('Завершена', style: TextStyle(color: Color(0xFFA5D6A7), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note.isEmpty ? 'Нажмите на дату, чтобы добавить заметку.' : note,
                      style: TextStyle(
                        fontSize: 14,
                        color: note.isEmpty ? Colors.grey : (isDark ? Colors.white70 : Colors.black87),
                        fontStyle: note.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        if (_isMultiSelect && _selectedDates.isNotEmpty)
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.edit_calendar),
              label: Text('Назначить смену (${_selectedDates.length} дн.)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () => _openSheet(multi: _selectedDates.toList()),
            ),
          ),
      ],
    );
  }

  IconData? _moodIcon(String? mood) {
    switch (mood) {
      case 'great': return Icons.sentiment_very_satisfied;
      case 'good': return Icons.sentiment_satisfied;
      case 'tired': return Icons.sentiment_dissatisfied;
      case 'sick': return Icons.sick;
      default: return null;
    }
  }
}
