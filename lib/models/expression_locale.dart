class ExpressionLocale {
  String? id;
  String langue;
  String expression;
  String traduction;
  String categorie;

  ExpressionLocale({
    this.id,
    required this.langue,
    required this.expression,
    required this.traduction,
    required this.categorie,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'langue': langue,
        'expression': expression,
        'traduction': traduction,
        'categorie': categorie,
      };

  factory ExpressionLocale.fromMap(Map<String, dynamic> map) => ExpressionLocale(
        id: map['id']?.toString(),
        langue: map['langue'] ?? '',
        expression: map['expression'] ?? '',
        traduction: map['traduction'] ?? '',
        categorie: map['categorie'] ?? '',
      );
}
