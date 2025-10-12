class SecuriteSante {
  String? id;
  String pays;
  String vaccinsRecommandes;
  String precautionsGenerales;
  String zonesARisque;
  String urgenceContact;

  SecuriteSante({
    this.id,
    required this.pays,
    required this.vaccinsRecommandes,
    required this.precautionsGenerales,
    required this.zonesARisque,
    required this.urgenceContact,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'pays': pays,
        'vaccinsRecommandes': vaccinsRecommandes,
        'precautionsGenerales': precautionsGenerales,
        'zonesARisque': zonesARisque,
        'urgenceContact': urgenceContact,
      };

  factory SecuriteSante.fromMap(Map<String, dynamic> map) => SecuriteSante(
        id: map['id']?.toString(),
        pays: map['pays'] ?? '',
        vaccinsRecommandes: map['vaccinsRecommandes'] ?? '',
        precautionsGenerales: map['precautionsGenerales'] ?? '',
        zonesARisque: map['zonesARisque'] ?? '',
        urgenceContact: map['urgenceContact'] ?? '',
      );
}
