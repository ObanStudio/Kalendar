import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shift.dart';
import '../providers/app_provider.dart';
import '../services/billing_service.dart';

class EditShiftSheet extends StatefulWidget {
  final String dateKey;
  final bool isMultiple;
  final Shift? initialShift;
  final Function(Shift) onSave;
  final VoidCallback onDelete;

  const EditShiftSheet({
    Key? key,
    required this.dateKey,
    this.isMultiple = false,
    this.initialShift,
    required this.onSave,
    required this.onDelete,
  }) : super(key: key);

  @override
  _EditShiftSheetState createState() => _EditShiftSheetState();
}

class _EditShiftSheetState extends State<<EditShiftSheet> {
  late String _type;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _incomeCtrl;
  late TextEditingController _noteCtrl;
  late TextEditingController _bonusCtrl;
  late TextEditingController _overtimeCtrl;
  late TextEditingController _penaltyCtrl;
  String? _mood;

  static const _moodOptions = [
    ('great', Icons.sentiment_very_satisfied, 'Отлично'),
    ('good', Icons.sentiment_satisfied, 'Хорошо'),
    ('tired', Icons.sentiment_dissatisfied, 'Устал'),
    ('sick', Icons.sick, 'Плохо'),
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.initialShift;
    _type = s?.type ?? 'day';
    _mood = s?.mood;
    _incomeCtrl = TextEditingController(text: s?.income != 0 ? s?.income.toStringAsFixed(0) : '');
    _noteCtrl = TextEditingController(text: s?.note ?? '');
    _bonusCtrl = TextEditingController(text: s?.bonus != 0 ? s?.bonus.toStringAsFixed(0) : '');
    _overtimeCtrl = TextEditingController(text: s?.overtime != 0 ? s?.overtime.toStringAsFixed(0) : '');
    _penaltyCtrl = TextEditingController(text: s?.penalty != 0 ? s?.penalty.toStringAsFixed(0) : '');
    
    if (s != null) {
      final sp = s.startTime.split(':');
      final ep = s.endTime.split(':');
      _startTime = TimeOfDay(hour: int.parse(sp[0]), minute: int.parse(sp[1]));
      _endTime = TimeOfDay(hour: int.parse(ep[0]), minute: int.parse(ep[1]));
    } else {
      _applyDefaultTimes(_type);
    }
  }

  void _applyDefaultTimes(String type) {
    switch (type) {
      case 'day':
        _startTime = const TimeOfDay(hour: 8, minute: 0);
        _endTime = const TimeOfDay(hour: 20, minute: 0);
        break;
      case 'night':
        _startTime = const TimeOfDay(hour: 20, minute: 0);
        _endTime = const TimeOfDay(hour: 8, minute: 0);
        break;
      default:
        _startTime = const TimeOfDay(hour: 8, minute: 0);
        _endTime = const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  void _save() {
    final shift = Shift(
      type: _type,
      income: double.tryParse(_incomeCtrl.text) ?? 0,
      bonus: double.tryParse(_bonusCtrl.text) ?? 0,
      overtime: double.tryParse(_overtimeCtrl.text) ?? 0,
      penalty: double.tryParse(_penaltyCtrl.text) ?? 0,
      startTime: _fmt(_startTime),
      endTime: _fmt(_endTime),
      note: _noteCtrl.text,
      mood: _mood,
    );
    widget.onSave(shift);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<<AppProvider>();
    final billing = context.watch<BillingService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final card = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100;
    final accent = const Color(0xFF607D8B);
    final toggles = app.featureToggles;
    final currency = app.currency;
    final isPlus = billing.isPlusActive;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 16,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              widget.isMultiple ? 'Назначить смену' : 'Редактор смены',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  _typeBtn('day', Icons.wb_sunny_rounded, 'День', accent),
                  _typeBtn('night', Icons.nights_stay_rounded, 'Ночь', accent),
                  _typeBtn('24h', Icons.sync_rounded, 'Сутки', accent),
                  _typeBtn('off', Icons.weekend_rounded, 'Выходной', accent),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_type != 'off') ...[
              Row(
                children: [
                  Expanded(child: _timeCard('Начало', _fmt(_startTime), () => _pickTime(true), isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _timeCard('Конец', _fmt(_endTime), () => _pickTime(false), isDark)),
                ],
              ),
              const SizedBox(height: 16),

              _inputField(_incomeCtrl, 'Ставка за смену ($currency)', isDark),
              const SizedBox(height: 12),

              if (toggles['bonus'] == true) ...[
                _inputField(_bonusCtrl, 'Премия ($currency)', isDark),
                const SizedBox(height: 12),
              ],

              if (toggles['overtime'] == true) ...[
                _inputField(_overtimeCtrl, 'Переработка ($currency)', isDark),
                const SizedBox(height: 12),
              ],

              if (toggles['penalty'] == true) ...[
                _inputField(_penaltyCtrl, 'Штраф ($currency)', isDark),
                const SizedBox(height: 12),
              ],
            ],

            _inputField(_noteCtrl, 'Заметка', isDark, maxLines: 2),
            const SizedBox(height: 16),

            if (isPlus && toggles['mood'] == true && _type != 'off') ...[
              const Text('Настроение', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _moodOptions.map((opt) {
                  final selected = _mood == opt.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _mood = selected ? null : opt.$1),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selected ? accent.withOpacity(0.15) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: selected ? accent : Colors.transparent, width: 2),
                          ),
                          child: Icon(opt.$2, color: selected ? accent : Colors.grey, size: 28),
                        ),
                        const SizedBox(height: 4),
                        Text(opt.$3, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? accent : Colors.grey)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                if (!widget.isMultiple)
                  TextButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    label: const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
                  ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _save,
                  child: const Text('Сохранить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(String type, IconData icon, String label, Color accent) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          if (type != 'off') _applyDefaultTimes(type);
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: selected ? Colors.white : Colors.grey),
              const SizedBox(height: 4),
              Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeCard(String label, String time, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, bool isDark, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: maxLines == 1 ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF607D8B)),
        ),
      ),
    );
  }
}
