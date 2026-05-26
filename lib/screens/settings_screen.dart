import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../services/billing_service.dart';
import '../widgets/purchase_sheet.dart';
import 'goals_screen.dart';
import 'training_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  static const freeCurrencies = ['₽', 'TJS', 'UZS', '₸', '\$'];
  static const paidCurrencies = [
    '€', '£', '¥', '₴', 'Br', 'kr', 'Rs', 'Rp', '₪', '₺', 'KGS', 'AMD', 'GEL', 'AZN', 'MDL', 
    'RON', 'BGN', 'RSD', 'ALL', 'BAM', 'MKD', 'CZK', 'PLN', 'HUF', 'CHF', 'DKK', 'NOK', 'SEK', 
    'ISK', 'CAD', 'AUD', 'NZD', 'SGD', 'HKD', 'TWD', 'KRW', 'CNY', 'INR', 'PKR', 'BDT', 'LKR', 
    'MVR', 'AFN', 'IRR', 'IQD', 'SAR', 'AED', 'QAR', 'KWD', 'BHD', 'OMR', 'JOD', 'LBP', 'EGP', 
    'ZAR', 'NGN', 'KES', 'GHS', 'UGX', 'TZS', 'MAD', 'DZD', 'TND', 'LYD', 'SDG', 'ETB', 'ARS', 
    'BRL', 'CLP', 'COP', 'PEN', 'UYU', 'MXN', 'CUP', 'DOP'
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final billing = context.watch<BillingService>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPlus = billing.isPlusActive;
    final currency = app.currency;
    final toggles = app.featureToggles;

    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade300;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Настройки', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),

        _Section(card: card, border: border, children: [
          SwitchListTile(
            secondary: _LeadIcon(Icons.dark_mode, const Color(0xFF90A4AE), isDark ? const Color(0xFF263238) : Colors.blue.shade50),
            title: const Text('Тёмная тема', style: TextStyle(fontWeight: FontWeight.w600)),
            value: isDark,
            activeColor: const Color(0xFF90A4AE),
            onChanged: (v) => app.setTheme(v),
          ),
          _Divider(border),
          ListTile(
            leading: _LeadIcon(Icons.track_changes, const Color(0xFFA5D6A7), isDark ? const Color(0xFF1B5E20) : Colors.green.shade50),
            title: const Text('Копилка на цель', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(app.legacyGoalName.isEmpty ? 'Не установлена' : '${app.legacyGoalName} (${app.legacyGoalPrice.toStringAsFixed(0)} $currency)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editLegacyGoal(context, app, currency),
          ),
        ]),
        const SizedBox(height: 20),

        _Section(
          card: card,
          border: isPlus ? const Color(0xFF607D8B) : border,
          borderWidth: isPlus ? 2 : 1,
          children: [
            ListTile(
              leading: _LeadIcon(Icons.workspace_premium, const Color(0xFFFFCC80), isDark ? const Color(0xFF3E2723) : Colors.amber.shade50),
              title: const Text('Plus+ Премиум', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(isPlus ? 'Активирован ✓' : 'Откройте все возможности'),
              trailing: isPlus
                  ? const Icon(Icons.check_circle, color: Color(0xFFA5D6A7))
                  : FilledButton(
                      onPressed: () => PurchaseSheet.show(context),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF607D8B)),
                      child: const Text('Купить'),
                    ),
            ),
            _Divider(border),
            ListTile(
              leading: _LeadIcon(Icons.vpn_key, const Color(0xFFFFCC80), isDark ? const Color(0xFF3E2723) : Colors.orange.shade50),
              title: const Text('Ввести промокод', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Временная активация Plus+'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => _showPromoDialog(context, billing),
            ),
            _Divider(border),
            ListTile(
              leading: _LeadIcon(Icons.currency_exchange, const Color(0xFF80CBC4), isDark ? const Color(0xFF004D40) : Colors.teal.shade50),
              title: const Text('Валюта приложения', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Текущая: $currency (Доступно ${isPlus ? "50+" : "5"} валют)'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => _changeCurrency(context, app, isPlus),
            ),
            _Divider(border),
            ListTile(
              leading: _LeadIcon(Icons.list_alt, const Color(0xFFB39DDB), isDark ? const Color(0xFF311B92) : Colors.purple.shade50),
              title: Text(isPlus ? 'Мои цели (Plus+)' : 'Мульти-цели', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(isPlus ? 'Управление целями и долями' : 'Доступно в Plus+'),
              trailing: Icon(isPlus ? Icons.chevron_right : Icons.lock_outline, color: Colors.grey),
              onTap: isPlus
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalsScreen(goals: app.goals, onSave: app.setGoals)))
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (isPlus) ...[
          _Section(card: card, border: border, children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.tune, color: Color(0xFF90A4AE)),
                SizedBox(width: 8),
                Text('Поля редактора смен', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
            ),
            SwitchListTile(title: const Text('Поле "Премия"'), value: toggles['bonus'] ?? true,
              activeColor: const Color(0xFF90A4AE), onChanged: (v) => app.setToggle('bonus', v)),
            SwitchListTile(title: const Text('Поле "Переработка"'), value: toggles['overtime'] ?? true,
              activeColor: const Color(0xFF90A4AE), onChanged: (v) => app.setToggle('overtime', v)),
            SwitchListTile(title: const Text('Поле "Штраф"'), value: toggles['penalty'] ?? true,
              activeColor: const Color(0xFF90A4AE), onChanged: (v) => app.setToggle('penalty', v)),
            SwitchListTile(title: const Text('Трекер настроения'), value: toggles['mood'] ?? true,
              activeColor: const Color(0xFF90A4AE), onChanged: (v) => app.setToggle('mood', v)),
          ]),
          const SizedBox(height: 20),
        ],

        _Section(card: card, border: border, children: [
          ListTile(
            leading: _LeadIcon(Icons.school, const Color(0xFFFFCC80), isDark ? const Color(0xFF3E2723) : Colors.orange.shade50),
            title: const Text('Обучение', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrainingScreen(isPlus: isPlus))),
          ),
          _Divider(border),
          ListTile(
            leading: _LeadIcon(Icons.telegram, const Color(0xFF90CAF9), isDark ? const Color(0xFF0D47A1) : Colors.blue.shade50),
            title: const Text('Telegram-канал', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Промокоды и обновления', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            onTap: () => _launch('https://t.me/Oban_Studio'),
          ),
          _Divider(border),
          ListTile(
            leading: _LeadIcon(Icons.delete_forever, const Color(0xFFEF9A9A), isDark ? const Color(0xFFB71C1C) : Colors.red.shade50),
            title: const Text('Очистить данные', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () => _confirmClear(context, app),
          ),
        ]),

        const SizedBox(height: 40),
        Center(child: Text('Kalendar v1.0.0 • ObanStudio', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
        const SizedBox(height: 20),
      ],
    );
  }

  void _editLegacyGoal(BuildContext context, AppProvider app, String currency) {
    final nameCtrl = TextEditingController(text: app.legacyGoalName);
    final priceCtrl = TextEditingController(text: app.legacyGoalPrice > 0 ? app.legacyGoalPrice.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Моя цель'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'На что копим?', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: priceCtrl, keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Стоимость ($currency)', border: const OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () { app.setLegacyGoal('', 0); Navigator.pop(ctx); }, child: const Text('Удалить', style: TextStyle(color: Colors.red))),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(onPressed: () { app.setLegacyGoal(nameCtrl.text, double.tryParse(priceCtrl.text) ?? 0); Navigator.pop(ctx); }, child: const Text('Сохранить')),
        ],
      ),
    );
  }

  void _showPromoDialog(BuildContext context, BillingService billing) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Активация промокода'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Введите код', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              final success = await billing.applyPromoCode(ctrl.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(success ? 'Промокод активирован! Plus+ открыт.' : 'Неверный код.'),
                backgroundColor: success ? const Color(0xFFA5D6A7) : Colors.redAccent,
              ));
            },
            child: const Text('Активировать'),
          ),
        ],
      ),
    );
  }

  void _changeCurrency(BuildContext context, AppProvider app, bool isPlus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выберите валюту'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Бесплатные:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: freeCurrencies.map((c) => ActionChip(
                  label: Text(c, style: const TextStyle(fontSize: 18)),
                  onPressed: () { app.setCurrency(c); Navigator.pop(ctx); },
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Доступно в Plus+:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: paidCurrencies.map((c) => ActionChip(
                  label: Text(c, style: const TextStyle(fontSize: 18)),
                  backgroundColor: isPlus ? null : Colors.grey.shade300,
                  onPressed: isPlus ? () { app.setCurrency(c); Navigator.pop(ctx); } : null,
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, AppProvider app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить данные?'),
        content: const Text('Все смены будут удалены безвозвратно.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { app.clearAllShifts(); Navigator.popctx); },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Не удалось открыть $url');
    }
  }
}

class _Section extends StatelessWidget {
  final Color card, border;
  final double borderWidth;
  final List<Widget> children;
  const _Section({required this.card, required this.border, this.borderWidth = 1, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: border, width: borderWidth)),
    child: Column(children: children),
  );
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider(this.color);
  @override
  Widget build(BuildContext c) => Divider(height: 1, indent: 20, endIndent: 20, color: color);
}

class _LeadIcon extends StatelessWidget {
  final IconData icon;
  final Color iconColor, bg;
  const _LeadIcon(this.icon, this.iconColor, this.bg);
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
    child: Icon(icon, color: iconColor),
  );
}
