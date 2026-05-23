class Goal {
  String id;
  String name;
  double targetAmount;
  double currentAmount;
  int distributionPercent;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.distributionPercent,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'distributionPercent': distributionPercent,
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'],
    name: json['name'],
    targetAmount: (json['targetAmount'] as num).toDouble(),
    currentAmount: (json['currentAmount'] as num? ?? 0).toDouble(),
    distributionPercent: json['distributionPercent'],
  );
}
