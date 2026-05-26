import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/billing_service.dart';

class PurchaseSheet extends StatelessWidget {
  const PurchaseSheet({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PurchaseSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final price = billing.plusProduct?.price ?? '—';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF455A64), Color(0xFF90A4AE)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kalendar Plus+',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Однократная покупка • Навсегда',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 24),

            ..._features.map((f) => _FeatureRow(icon: f.$1, title: f.$2, subtitle: f.$3)),
            const SizedBox(height: 24),

            if (billing.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(billing.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ),
                  ],
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: billing.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF607D8B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => context.read<BillingService>().buyPlus(),
                      child: Text(
                        'Купить за $price',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
            const SizedBox(height: 12),

            TextButton(
              onPressed: () => context.read<BillingService>().restorePurchases(),
              child: const Text('Восстановить покупку', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            Text(
              'Оплата через Google Play.\nПокупка не требует подписки.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  static const _features = [
    (Icons.bar_chart, 'Продвинутая аналитика', 'Полностью переработанный удобный дашборд'),
    (Icons.view_comfy_alt_outlined, 'Тепловая карта активности', 'Интенсивность заработка по дням недели'),
    (Icons.list_alt, 'Мульти-цели', 'Авторасчёт вклада каждой смены'),
    (Icons.currency_exchange, 'Валюты мира (+50 стран)', 'Расширенный выбор валют'),
    (Icons.tune, 'Кастомизация редактора смен', 'Скрыть ненужные поля'),
    (Icons.mood, 'Трекер настроения', 'Отмечайте как себя чувствовали на смене'),
    (Icons.request_quote, 'Умный налоговый отчёт', '4%, 6% и 13% в один клик'),
  ];
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF607D8B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF90A4AE), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFFA5D6A7), size: 18),
        ],
      ),
    );
  }
}
