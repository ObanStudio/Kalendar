import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../providers/app_provider.dart';

class GoalsScreen extends StatefulWidget {
  final List<<Goal> goals;
  final Function(List<<Goal>) onSave;
  const GoalsScreen({Key? key, required this.goals, required this.onSave}) : super(key: key);

  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<<GoalsScreen> {
  late List<<Goal> _goals;
  late List<TextEditingController> _names, _targets, _percents;

  @override
  void initState() {
    super.initState();
    _goals = List.from(widget.goals);
    _sync();
  }

  void _sync() {
    _names = _goals.map((g) => TextEditingController(text: g.name)).toList();
    _targets = _goals.map((g) => TextEditingController(text: g.targetAmount.toStringAsFixed(0))).toList();
    _percents = _goals.map((g) => TextEditingController(text: g.distributionPercent.toString())).toList();
  }

  void _add() {
    _goals.add(Goal(id: DateTime.now().millisecondsSinceEpoch.toString(), name: 'Новая цель', targetAmount: 10000, distributionPercent: 0));
    _recalc();
    setState(_sync);
  }

  void _remove(int i) {
    _goals.removeAt(i);
    _recalc();
    setState(_sync);
  }

  void _recalc() {
    if (_goals.isEmpty) return;
    int used = _goals.fold(0, (s, g) => s + g.distributionPercent);
    int rem = 100 - used;
    if (rem != 0) _goals.last.distributionPercent = (_goals.last.distributionPercent + rem).clamp(0, 100);
  }

  void _save() {
    widget.onSave(_goals);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<<AppProvider>().currency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Мои цели'), actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)]),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _goals.length + 1,
        itemBuilder: (_, i) {
          if (i == _goals.length) {
            return Center(child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF607D8B)),
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('Добавить цель'),
              ),
            ));
          }
          final g = _goals[i];
          return Card(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: isDark ? 0 : 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
              side: isDark ? const BorderSide(color: Color(0xFF2C2C2C)) : BorderSide.none),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Expanded(child: TextField(
                    controller: _names[i],
                    onChanged: (v) => g.name = v,
                    decoration: InputDecoration(labelText: 'Название', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  )),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _remove(i)),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _targets[i],
                  keyboardType: TextInputType.number,
                  onChanged: (v) => g.targetAmount = double.tryParse(v) ?? 0,
                  decoration: InputDecoration(labelText: 'Сумма ($currency)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Slider(
                    value: g.distributionPercent.toDouble(), min: 0, max: 100, divisions: 100,
                    activeColor: const Color(0xFF607D8B), label: '${g.distributionPercent}%',
                    onChanged: (v) => setState(() {
                      g.distributionPercent = v.toInt();
                      _percents[i].text = v.toInt().toString();
                      _recalc();
                      for (int j = 0; j < _goals.length; j++) _percents[j].text = _goals[j].distributionPercent.toString();
                    }),
                  )),
                  SizedBox(width: 70, child: TextField(
                    controller: _percents[i], keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {
                      g.distributionPercent = (int.tryParse(v) ?? 0).clamp(0, 100);
                      _recalc();
                      for (int j = 0; j < _goals.length; j++) _percents[j].text = _goals[j].distributionPercent.toString();
                    }),
                    decoration: InputDecoration(labelText: '%', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  )),
                ]),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                  value: (g.currentAmount / g.targetAmount).clamp(0.0, 1.0), minHeight: 6,
                  backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade300,
                  color: isDark ? const Color(0xFFA5D6A7) : Colors.green,
                )),
                const SizedBox(height: 6),
                Text('Накоплено: ${g.currentAmount.toStringAsFixed(0)} $currency', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
          );
        },
      ),
    );
  }
}
