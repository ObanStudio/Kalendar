import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/shift.dart';

class NextShiftWidget extends StatefulWidget {
  final Map<String, Shift> shifts;
  const NextShiftWidget({Key? key, required this.shifts}) : super(key: key);

  @override
  _NextShiftWidgetState createState() => _NextShiftWidgetState();
}

class _NextShiftWidgetState extends State<NextShiftWidget> {
  Timer? _timer;
  DateTime? _nextShift;

  @override
  void initState() {
    super.initState();
    _calculate();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(_calculate);
    });
  }

  @override
  void didUpdateWidget(NextShiftWidget old) {
    super.didUpdateWidget(old);
    _calculate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculate() {
    final now = DateTime.now();
    DateTime? closest;

    widget.shifts.forEach((key, shift) {
      if (shift.type == 'off') return;
      final parts = key.split('-');
      final tParts = shift.startTime.split(':');
      final dt = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]),
        int.parse(tParts[0]), int.parse(tParts[1]),
      );
      if (dt.isAfter(now) && (closest == null || dt.isBefore(closest!))) {
        closest = dt;
      }
    });

    _nextShift = closest;
  }

  @override
  Widget build(BuildContext context) {
    if (_nextShift == null) return const SizedBox.shrink();
    final diff = _nextShift!.difference(DateTime.now());
    if (diff.isNegative) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF90A4AE) : const Color(0xFF455A64);

    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, color: accent, size: 18),
          const SizedBox(width: 8),
          Text(
            'До смены: ${hours}ч ${minutes}мин  |  ${DateFormat('d MMM', 'ru').format(_nextShift!)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: accent),
          ),
        ],
      ),
    );
  }
}
