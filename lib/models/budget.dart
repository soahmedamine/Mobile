class Budget {
  final int? id;
  final String travelId;
  final String category;
  final double amount;
  final String currency;
  final DateTime date;
  final String? description;
  final String type; // 'income' or 'expense'
  final DateTime createdAt;

  Budget({
    this.id,
    required this.travelId,
    required this.category,
    required this.amount,
    this.currency = 'USD',
    required this.date,
    this.description,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'travelId': travelId,
      'category': category,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'description': description,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      travelId: map['travelId'],
      category: map['category'],
      amount: map['amount'] is int ? (map['amount'] as int).toDouble() : map['amount'],
      currency: map['currency'] ?? 'USD',
      date: DateTime.parse(map['date']),
      description: map['description'],
      type: map['type'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Budget copyWith({
    int? id,
    String? travelId,
    String? category,
    double? amount,
    String? currency,
    DateTime? date,
    String? description,
    String? type,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      travelId: travelId ?? this.travelId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// List of budget categories
const List<String> budgetCategories = [
  'Accommodation',
  'Food',
  'Transport',
  'Activities',
  'Shopping',
  'Groceries',
  'Entertainment',
  'Other',
];
