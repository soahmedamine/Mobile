import 'package:flutter/material.dart';
import '../../../models/place_model.dart';
import '../services/free_map_service.dart';

class FreeMapWidget extends StatelessWidget {
  final List<Place> places;
  final VoidCallback? onPlaceSelected;

  const FreeMapWidget({
    Key? key,
    required this.places,
    this.onPlaceSelected,
  }) : super(key: key);

  get FreeMapService => null;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Vue Géographique',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (places.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.location_off, size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Aucun lieu à afficher',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Statistics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Lieux', '${places.length}'),
                      _buildStatItem('Emplacements', '${_countUniqueLocations()}'),
                      _buildStatItem('Distance', '${FreeMapService.calculateTotalDistance(places).toStringAsFixed(1)}km'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Places List
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: places.length,
                      itemBuilder: (context, index) {
                        final place = places[index];
                        return ListTile(
                          leading: Icon(
                            _getPlaceIcon(place.type),
                            color: _getPlaceColor(place.type),
                          ),
                          title: Text(place.name),
                          subtitle: Text('${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}'),
                          trailing: Text(
                            place.type.toUpperCase(),
                            style: TextStyle(
                              color: _getPlaceColor(place.type),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => onPlaceSelected?.call(),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  int _countUniqueLocations() {
    final locations = places.map((p) => '${p.latitude}-${p.longitude}').toSet();
    return locations.length;
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
      default:
        return Colors.grey;
    }
  }
}