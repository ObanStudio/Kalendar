class Shift {
  final String type;
  final double income;
  final double bonus;
  final double overtime;
  final double penalty;
  final String startTime;
  final String endTime;
  final String note;
  final String? mood;

  const Shift({
    required this.type,
    this.income = 0,
    this.bonus = 0,
    this.overtime = 0,
    this.penalty = 0,
    this.startTime = '08:00',
    this.endTime = '20:00',
    this.note = '',
    this.mood,
  });

  double get totalIncome => income + bonus + overtime - penalty;

  Map<String, dynamic> toJson() => {
    'type': type,
    'income': income,
    'bonus': bonus,
    'overtime': overtime,
    'penalty': penalty,
    'startTime': startTime,
    'endTime': endTime,
    'note': note,
    if (mood != null) 'mood': mood,
  };

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
    type: json['type'] ?? 'day',
    income: (json['income'] as num? ?? 0).toDouble(),
    bonus: (json['bonus'] as num? ?? 0).toDouble(),
    overtime: (json['overtime'] as num? ?? 0).toDouble(),
    penalty: (json['penalty'] as num? ?? 0).toDouble(),
    startTime: json['startTime'] ?? '08:00',
    endTime: json['endTime'] ?? '20:00',
    note: json['note'] ?? '',
    mood: json['mood'],
  );
}
