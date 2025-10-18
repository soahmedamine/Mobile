class Expense {
  final int? id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final int tripId;
  final String? notes;

  Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.tripId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'tripId': tripId,
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      description: map['description'],
      amount: map['amount']?.toDouble(),
      category: map['category'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      tripId: map['tripId'],
      notes: map['notes'],
    );
  }
}