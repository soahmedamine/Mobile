import 'package:intl/intl.dart';

class Event {
  final int? id;
  final String? remoteId;
  final String title;
  final String? description;
  final String? city;
  final String? venue;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? price;
  final String? currency;
  final String? imageUrl;
  final String? externalUrl;
  final bool isFavorite;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Event({
    this.id,
    this.remoteId,
    required this.title,
    this.description,
    this.city,
    this.venue,
    this.category,
    this.startDate,
    this.endDate,
    this.price,
    this.currency,
    this.imageUrl,
    this.externalUrl,
    this.isFavorite = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Event copyWith({
    int? id,
    String? remoteId,
    String? title,
    String? description,
    String? city,
    String? venue,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    double? price,
    String? currency,
    String? imageUrl,
    String? externalUrl,
    bool? isFavorite,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      venue: venue ?? this.venue,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      externalUrl: externalUrl ?? this.externalUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remoteId': remoteId,
      'title': title,
      'description': description,
      'city': city,
      'venue': venue,
      'category': category,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'price': price,
      'currency': currency,
      'imageUrl': imageUrl,
      'externalUrl': externalUrl,
      'isFavorite': isFavorite ? 1 : 0,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is String && value.isEmpty) {
        return null;
      }
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    double? parseDouble(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value.toString());
    }

    return Event(
      id: map['id'] as int?,
      remoteId: map['remoteId'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      city: map['city'] as String?,
      venue: map['venue'] as String?,
      category: map['category'] as String?,
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      price: parseDouble(map['price']),
      currency: map['currency'] as String?,
      imageUrl: map['imageUrl'] as String?,
      externalUrl: map['externalUrl'] as String?,
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      isActive: (map['isActive'] ?? 1) == 1,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  static Event fromApiJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? nameData = json['name'] as Map<String, dynamic>?;
    final Map<String, dynamic>? descriptionData = json['description'] as Map<String, dynamic>?;
    final Map<String, dynamic>? startData = json['start'] as Map<String, dynamic>?;
    final Map<String, dynamic>? endData = json['end'] as Map<String, dynamic>?;
    final Map<String, dynamic>? venueData = json['venue'] as Map<String, dynamic>?;
    final Map<String, dynamic>? venueAddress = venueData == null ? null : venueData['address'] as Map<String, dynamic>?;
    final Map<String, dynamic>? categoryData = json['category'] as Map<String, dynamic>?;
    final Map<String, dynamic>? availability = json['ticket_availability'] as Map<String, dynamic>?;
    final Map<String, dynamic>? priceData = availability == null ? null : availability['minimum_ticket_price'] as Map<String, dynamic>?;
    final Map<String, dynamic>? logoData = json['logo'] as Map<String, dynamic>?;

    DateTime? parseDate(String? value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        return null;
      }
    }

    double? parsePrice(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is num) {
        return value.toDouble();
      }
      final parsed = double.tryParse(value.toString());
      if (parsed != null) {
        return parsed;
      }
      final currencyFormat = NumberFormat.decimalPattern();
      return currencyFormat.parse(value.toString()).toDouble();
    }

    final priceValue = priceData == null ? null : parsePrice(priceData['major_value']);

    return Event(
      remoteId: json['id']?.toString(),
      title: nameData == null ? '' : (nameData['text'] as String? ?? ''),
      description: descriptionData == null ? null : descriptionData['text'] as String?,
      city: venueAddress == null ? null : venueAddress['city'] as String?,
      venue: venueData == null ? null : venueData['name'] as String?,
      category: categoryData == null ? null : categoryData['name'] as String?,
      startDate: parseDate(startData == null ? null : startData['local'] as String?),
      endDate: parseDate(endData == null ? null : endData['local'] as String?),
      price: priceValue,
      currency: priceData == null ? null : priceData['currency'] as String?,
      imageUrl: logoData == null ? null : logoData['url'] as String?,
      externalUrl: json['url'] as String?,
      isFavorite: false,
      isActive: json['status'] == null ? true : json['status'].toString().toLowerCase() != 'canceled',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
