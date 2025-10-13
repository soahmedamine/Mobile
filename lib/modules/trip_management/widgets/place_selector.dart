import 'package:flutter/material.dart';
import '../../../models/place_model.dart';

class PlaceSelector extends StatefulWidget {
  final List<Place> places;
  final ValueChanged<Place?> onPlaceSelected;

  const PlaceSelector({
    Key? key,
    required this.places,
    required this.onPlaceSelected,
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
        const Text(
          'Select Place:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Place>(
          value: _selectedPlace,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          items: [
            const DropdownMenuItem<Place>(
              value: null,
              child: Text('Select a place'),
            ),
            ...widget.places.map((place) {
              return DropdownMenuItem<Place>(
                value: place,
                child: Text(place.name),
              );
            }),
          ],
          onChanged: (Place? place) {
            setState(() {
              _selectedPlace = place;
            });
            widget.onPlaceSelected(place);
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a place';
            }
            return null;
          },
        ),
      ],
    );
  }
}