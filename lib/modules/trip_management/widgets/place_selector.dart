import 'package:flutter/material.dart';
import '../../../models/place_model.dart';

class PlaceSelector extends StatefulWidget {
  final List<Place> places;
  final ValueChanged<Place?> onPlaceSelected;
  final String? label;

  const PlaceSelector({
    Key? key,
    required this.places,
    required this.onPlaceSelected,
    this.label = 'Sélectionner un lieu',
  }) : super(key: key);

  @override
  _PlaceSelectorState createState() => _PlaceSelectorState();
}

class _PlaceSelectorState extends State<PlaceSelector> {
  Place? _selectedPlace;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Place>(
              value: _selectedPlace,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              hint: const Text('Choisir un lieu'),
              items: [
                const DropdownMenuItem<Place>(
                  value: null,
                  child: Text('Aucun lieu sélectionné'),
                ),
                ...widget.places.map((place) {
                  return DropdownMenuItem<Place>(
                    value: place,
                    child: Row(
                      children: [
                        Icon(
                          _getPlaceIcon(place.type),
                          color: _getPlaceColor(place.type),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${place.type} • ${_formatDate(place.visitDate)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (Place? place) {
                setState(() {
                  _selectedPlace = place;
                });
                widget.onPlaceSelected(place);
              },
            ),
          ),
        ),
        if (_selectedPlace != null) ...[
          const SizedBox(height: 12),
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedPlace!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Adresse: ${_selectedPlace!.address}'),
                  if (_selectedPlace!.price != null)
                    Text('Prix: \$${_selectedPlace!.price!.toStringAsFixed(2)}'),
                  if (_selectedPlace!.rating != null)
                    Text('Note: ${_selectedPlace!.rating}/5'),
                ],
              ),
            ),
          ),
        ],
      ],
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
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}