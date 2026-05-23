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

  static const _freeCurrencies = [
    ('₽', 'Россия (RUB)'),
    ('SM', 'Таджикистан (TJS)'),
    ("so'm", 'Узбекистан (UZS)'),
    ('₸', 'Казахстан (KZT)'),
    ('\$', 'США (USD)'),
  ];

  static const _premiumCurrencies = [
    ('€', 'Евросоюз (EUR)'),
    ('£', 'Великобритания (GBP)'),
    ('¥', 'Япония (JPY)'),
    ('₩', 'Южная Корея (KRW)'),
    ('₴', 'Украина (UAH)'),
    ('Br', 'Беларусь (BYN)'),
    ('₹', 'Индия (INR)'),
    ('元', 'Китай (CNY)'),
    ('R\$', 'Бразилия (BRL)'),
    ('Mex\$', 'Мексика (MXN)'),
    ('C\$', 'Канада (CAD)'),
    ('A\$', 'Австралия (AUD)'),
    ('CHF', 'Швейцария (CHF)'),
    ('kr', 'Швеция (SEK)'),
    ('kr', 'Норвегия (NOK)'),
    ('kr', 'Дания (DKK)'),
    ('zł', 'Польша (PLN)'),
    ('Kč', 'Чехия (CZK)'),
    ('Ft', 'Венгрия (HUF)'),
    ('lei', 'Румыния (RON)'),
    ('лв', 'Болгария (BGN)'),
    ('kn', 'Хорватия (HRK)'),
    ('₺', 'Турция (TRY)'),
    ('د.إ', 'ОАЭ (AED)'),
    ('﷼', 'Саудовская Аравия (SAR)'),
    ('﷼', 'Катар (QAR)'),
    ('د.ك', 'Кувейт (KWD)'),
    ('د.ب', 'Бахрейн (BHD)'),
    ('ر.ع.', 'Оман (OMR)'),
    ('د.ا', 'Иордания (JOD)'),
    ('ج.م', 'Египет (EGP)'),
    ('R', 'ЮАР (ZAR)'),
    ('₦', 'Нигерия (NGN)'),
    ('KSh', 'Кения (KES)'),
    ('GH₵', 'Гана (GHS)'),
    ('د.م.', 'Марокко (MAD)'),
    ('د.ج', 'Алжир (DZD)'),
    ('د.ت', 'Тунис (TND)'),
    ('ل.ل', 'Ливан (LBP)'),
    ('₪', 'Израиль (ILS)'),
    ('RM', 'Малайзия (MYR)'),
    ('S\$', 'Сингапур (SGD)'),
    ('฿', 'Таиланд (THB)'),
    ('Rp', 'Индонезия (IDR)'),
    ('₱', 'Филиппины (PHP)'),
    ('₫', 'Вьетнам (VND)'),
    ('₨', 'Пакистан (PKR)'),
    ('৳', 'Бангладеш (BDT)'),
    ('₨', 'Шри-Ланка (LKR)'),
    ('₨', 'Непал (NPR)'),
    ('K', 'Мьянма (MMK)'),
    ('៛', 'Камбоджа (KHR)'),
    ('₭', 'Лаос (LAK)'),
    ('₮', 'Монголия (MNT)'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<<AppProvider>();
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
              subtitle: Text(isPlus ? 'Активирован навсегда ✓' : 'Мульти-цели, графики, валюта, настроение'),
              trailing: isPlus
                  ? const Icon(Icons.check_circle, color: Color(0xFFA5D6A7))
                  : FilledButton(
                      onPressed: () => PurchaseSheet.show(context),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF607D8B)),
                      child: const Text('Купить'),
                    ),
            ),
            if (billing.isPromoActive) ...[
              _Divider(border),
              ListTile(
                leading: _LeadIcon(Icons.timer, const Color(0xFFFFCC80), isDark ? const Color(0xFF3E2723) : Colors.amber.shade50),
                title: const Text('Plus+ по промокоду', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Осталось: ${billing.promoRemaining}', style: const TextStyle(color: Color(0xFF607D8B))),
              ),
            ],
            _Divider(border),
            ListTile(
              leading: _LeadIcon(Icons.vpn_key, const Color(0xFFFFCC80), isDark ? const Color(0xFF3E2723) : Colors.orange.shade50),
              title: const Text('Ввести промокод', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Активация Plus+'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => _showPromoDialog(context, billing),
            ),
            _Divider(border),
            ListTile(
              leading: _LeadIcon(Icons.currency_exchange, const Color(0xFF80CBC4), isDark ? const Color(0xFF004D40) : Colors.teal.shade50),
              title: const Text('Валюта приложения', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(currency),
              trailing: const Icon(Icons.chevron_right),
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
            subtitle: const Text('Подпишись, там есть промокоды на Plus+', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            onTap: () => _launch('https://t.me/Oban_Studio'),
          ),
          _Divider(border),
          ListTile(
            leading: _LeadIcon(Icons.support_agent, const Color(0xFFB39DDB), isDark ? const Color(0xFF311B92) : Colors.deepPurple.shade50),
            title: const Text('Поддержка', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            onTap: () => _launch('mailto:obanstudio.0@gmail.com?subject=Поддержка Kalendar'),
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
        title: const Text('Промокод'),
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
                content: Text(success ? 'Промокод активирован! Plus+ открыт.' : 'Неверный или просроченный код.'),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('Бесплатные валюты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: _freeCurrencies.map((c) => ActionChip(
                    label: Text('${c.$1} ${c.$2}', style: const TextStyle(fontSize: 13)),
                    backgroundColor: app.currency == c.$1 ? const Color(0xFF607D8B) : null,
                    labelStyle: TextStyle(color: app.currency == c.$1 ? Colors.white : null),
                    onPressed: () { app.setCurrency(c.$1); Navigator.pop(ctx); },
                  )).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Text('Премиум валюты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    if (!isPlus) const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                if (!isPlus)
                  Text('Доступно с Plus+', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: _premiumCurrencies.map((c) {
                    final selected = app.currency == c.$1;
                    return ActionChip(
                      label: Text('${c.$1} ${c.$2}', style: const TextStyle(fontSize: 12)),
                      backgroundColor: selected && isPlus ? const Color(0xFF607D8B) : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
                      labelStyle: TextStyle(color: selected && isPlus ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                      avatar: !isPlus ? const Icon(Icons.lock, size: 14, color: Colors.grey) : null,
                      onPressed: isPlus ? () { app.setCurrency(c.$1); Navigator.pop(ctx); } : null,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
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
            onPressed: () { app.clearAllShifts(); Navigator.pop(ctx); },
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
  final List<<Widget> children;
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
