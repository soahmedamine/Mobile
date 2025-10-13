import 'package:flutter/material.dart';
import '../../../models/place_model.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PlaceCard({
    Key? key,
    required this.place,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _getPlaceIcon(place.type),
        title: Text(
          place.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.address),
            if (place.price != null) Text('Price: \$${place.price!.toStringAsFixed(2)}'),
            Text('Visit: ${_formatDate(place.visitDate)}'),
            if (place.rating != null) _buildRatingStars(place.rating!),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _getPlaceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return const Icon(Icons.restaurant, color: Colors.green);
      case 'hotel':
        return const Icon(Icons.hotel, color: Colors.blue);
      case 'attraction':
        return const Icon(Icons.attractions, color: Colors.orange);
      default:
        return const Icon(Icons.place, color: Colors.grey);
    }
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          size: 16,
          color: index < rating ? Colors.amber : Colors.grey,
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}