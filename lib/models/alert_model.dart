class AlertModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'event', 'logement', 'culture', etc.
  final String itemId; // ID of the related item
  final String action; // 'added', 'updated', 'deleted'

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.itemId,
    required this.action,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'general',
      itemId: map['itemId'] ?? '',
      action: map['action'] ?? 'updated',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'itemId': itemId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
