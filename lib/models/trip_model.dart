class Trip {
  int? id;
  String title;
  String destination;
  DateTime startDate;
  DateTime endDate;
  double budget;
  String? imageUrl;

  Trip({
    this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budget,
    this.imageUrl,
  });

  // Pour affichage durée
  String get duration {
    final days = endDate.difference(startDate).inDays;
    return '$days jour${days > 1 ? 's' : ''}';
  }

  // Pour affichage dates
  String get dateRange {
    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

}