class ExpressionLocale {
  String? id;
  String langue;
  String expression;
  String traduction;
  String categorie;
  String? imageUrl;

  ExpressionLocale({
    this.id,
    required this.langue,
    required this.expression,
    required this.traduction,
    required this.categorie,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'langue': langue,
        'expression': expression,
        'traduction': traduction,
        'categorie': categorie,
        'imageUrl': imageUrl,
      };

  factory ExpressionLocale.fromMap(Map<String, dynamic> map) => ExpressionLocale(
        id: map['id']?.toString(),
        langue: map['langue'] ?? '',
        expression: map['expression'] ?? '',
        traduction: map['traduction'] ?? '',
        categorie: map['categorie'] ?? '',
        imageUrl: map['imageUrl'] as String?,
      );
}
