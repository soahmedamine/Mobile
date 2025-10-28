class NoteModel {
  final String id;
  final String? userId;
  final String subject;
  final String message;
  final String status;
  final String? adminResponse;
  final String? imageUrl;
  final String? imageData;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    this.userId,
    required this.subject,
    required this.message,
    this.status = 'active',
    this.adminResponse,
    this.imageUrl,
    this.imageData,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from Map (from database)
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      subject: map['subject'] as String,
      message: map['message'] as String,
      status: map['status'] as String? ?? 'active',
      adminResponse: map['admin_response'] as String?,
      imageUrl: map['image_url'] as String?,
      imageData: map['image_data'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Convert to Map (for database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'subject': subject,
      'message': message,
      'status': status,
      'admin_response': adminResponse,
      'image_url': imageUrl,
      'image_data': imageData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with method for updates
  NoteModel copyWith({
    String? id,
    String? userId,
    String? subject,
    String? message,
    String? status,
    String? adminResponse,
    String? imageUrl,
    String? imageData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      imageUrl: imageUrl ?? this.imageUrl,
      imageData: imageData ?? this.imageData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'NoteModel(id: $id, subject: $subject, status: $status, createdAt: $createdAt)';
  }
}
