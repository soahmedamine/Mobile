class ProfilCulturel {
  String? id;
  String pays;
  String traditions;
  String gastronomie;
  String comportementsAAdopter;
  String comportementsAEviter;
  String? imageUrl;

  ProfilCulturel({
    this.id,
    required this.pays,
    required this.traditions,
    required this.gastronomie,
    required this.comportementsAAdopter,
    required this.comportementsAEviter,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'pays': pays,
        'traditions': traditions,
        'gastronomie': gastronomie,
        'comportementsAAdopter': comportementsAAdopter,
        'comportementsAEviter': comportementsAEviter,
        'imageUrl': imageUrl,
      };

  factory ProfilCulturel.fromMap(Map<String, dynamic> map) => ProfilCulturel(
        id: map['id']?.toString(),
        pays: map['pays'] ?? '',
        traditions: map['traditions'] ?? '',
        gastronomie: map['gastronomie'] ?? '',
        comportementsAAdopter: map['comportementsAAdopter'] ?? '',
        comportementsAEviter: map['comportementsAEviter'] ?? '',
        imageUrl: map['imageUrl'] as String?,
      );
}
