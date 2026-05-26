import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/billing_service.dart';

class PromoCountdownWidget extends StatefulWidget {
  const PromoCountdownWidget({Key? key}) : super(key: key);

  @override
  _PromoCountdownWidgetState createState() => _PromoCountdownWidgetState();
}

class _PromoCountdownWidgetState extends State<PromoCountdownWidget> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final billing = context.read<BillingService>();
    if (billing.promoExpiryDate != null) {
      final now = DateTime.now();
      final diff = billing.promoExpiryDate!.difference(now);
      if (mounted) {
        setState(() {
          _timeLeft = diff.isNegative ? Duration.zero : diff;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingService>();
    if (!billing.isPlusActive || billing.promoExpiryDate == null || _timeLeft.isNegative || _timeLeft == Duration.zero) {
      return const SizedBox.shrink();
    }

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final days = _timeLeft.inDays;
    final hours = twoDigits(_timeLeft.inHours.remainder(24));
    final minutes = twoDigits(_timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(_timeLeft.inSeconds.remainder(60));
    
    final timeStr = days > 0 
      ? '$days дн. $hours:$minutes:$seconds'
      : '$hours:$minutes:$seconds';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF455A64), Color(0xFF607D8B)]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            'Plus+ активно: $timeStr',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
