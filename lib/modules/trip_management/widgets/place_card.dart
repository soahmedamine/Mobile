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
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getPlaceColor(place.type).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getPlaceIcon(place.type) as IconData?,
            color: _getPlaceColor(place.type),
            size: 20,
          ),
        ),
        title: Text(
          place.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.address,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (place.price != null)
                  Text(
                    '\$${place.price!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                if (place.price != null) const Text(' • '),
                Text('Visite: ${_formatDate(place.visitDate)}'),
              ],
            ),
            if (place.rating != null) _buildRatingStars(place.rating!),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
          onPressed: onDelete,
          tooltip: 'Supprimer le lieu',
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  IconData _getPlaceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'attraction':
        return Icons.attractions;
      case 'museum':
        return Icons.museum;
      case 'beach':
        return Icons.beach_access;
      case 'shop':
        return Icons.shopping_cart;
      case 'park':
        return Icons.park;
      default:
        return Icons.place;
    }
  }

  Color _getPlaceColor(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Colors.green;
      case 'hotel':
        return Colors.blue;
      case 'attraction':
        return Colors.orange;
      case 'museum':
        return Colors.purple;
      case 'beach':
        return Colors.cyan;
      case 'shop':
        return Colors.brown;
      case 'park':
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          size: 14,
          color: index < rating ? Colors.amber : Colors.grey[300],
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}