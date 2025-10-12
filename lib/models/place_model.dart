class Place {

  int? id;
  String name;
  String description;
  double lat;
  double lon;
  String category;
  double rating;

  Place({
    this.id,
    required this.name,
    required this.description,
    required this.lat,
    required this.lon,
    required this.category,
    this.rating = 0.0,
  });

}