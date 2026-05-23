import 'package:flutter/material.dart';

class TrainingScreen extends StatelessWidget {
  final bool isPlus;
  const TrainingScreen({Key? key, required this.isPlus}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = const Color(0xFF607D8B);
    return Scaffold(
      appBar: AppBar(title: Text(isPlus ? 'Обучение — Plus+' : 'Обучение')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _item(Icons.loop, 'Автозаполнение графика',
            'Нажмите кнопку "Цикл" (🔄) в календаре. Выберите период и паттерн (2x2, 5x2, 3x3 и др.) — приложение само заполнит смены.', isDark, accent),
          _item(Icons.checklist, 'Мультивыбор',
            'Кнопка ✅ в календаре. Выберите несколько дат и назначьте одну смену сразу на все.', isDark, accent),
          _item(Icons.check_circle_outline, 'Смена завершена',
            'Зелёная галочка появляется автоматически после окончания смены — даже ночной, которая переходит на следующий день.', isDark, accent),
          _item(Icons.trending_up, 'Прогноз дохода',
            'Берётся средний заработок за прошлые смены и умножается на число будущих. Добавьте доход к сменам — прогноз станет точнее.', isDark, accent),
          if (!isPlus) _item(Icons.workspace_premium, 'Plus+ Премиум',
            'Plus+ открывает: мульти-цели, графики, тепловую карту, трекер настроения, налоговый отчёт и настройку валюты.', isDark, Colors.amber),
          if (isPlus) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF455A64), Color(0xFF607D8B)]), borderRadius: BorderRadius.circular(16)),
              child: const Text('✨ Эксклюзивно в Plus+', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 16),
            _item(Icons.list_alt, 'Мульти-цели',
               'В настройках добавьте цели и укажите % отчислений.\nПри каждой записи смены сумма автоматически распределяется по целям.', isDark, const Color(0xFFB39DDB)),
            _item(Icons.mood, 'Трекер настроения',
              'При редактировании смены выберите настроение. Оно отображается иконкой в ячейке календаря.', isDark, const Color(0xFFB39DDB)),
            _item(Icons.bar_chart, 'Графики доходов',
              'В Аналитике — линейный график помесячного дохода и столбчатый график переработок.', isDark, const Color(0xFFB39DDB)),
             _item(Icons.request_quote, 'Налоговый отчёт',
              'Выберите ставку (6% / 13%) и период (месяц / квартал). Получите готовый отчёт для отправки.', isDark, const Color(0xFFB39DDB)),
          ],
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
               color: isDark ? const Color(0xFF3E2723) : Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent, width: 2),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
               const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ВАЖНО', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                const SizedBox(height: 8),
                Text('Приложение работает локально.\nДанные хранятся только на устройстве. При удалении приложения или сбросе устройства данные будут утеряны.',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.4)),
              ])),
            ]),
          ),
          const SizedBox(height: 40),
        ],
       ),
    );
  }

  Widget _item(IconData icon, String title, String text, bool isDark, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E1E) : color.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
        side: isDark ? const BorderSide(color: Color(0xFF2C2C2C)) : BorderSide.none),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        children: [Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)),
        )],
      ),
    );
  }
}
