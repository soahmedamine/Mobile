import 'package:flutter/material.dart';
import '../../../models/trip_model.dart';
import '../../../models/place_model.dart';
import '../services/trip_service.dart';
import '../widgets/free_map_widget.dart';
import '../services/free_map_service.dart';

class MapExplorerScreen extends StatefulWidget {
  final Trip trip;
  final List<Place> places;

  const MapExplorerScreen({
    Key? key,
    required this.trip,
    required this.places,
  }) : super(key: key);

  @override
  _MapExplorerScreenState createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  final TripService _tripService = TripService();
  List<Place> _places = [];

  get FreeMapService => null;

  @override
  void initState() {
    super.initState();
    _places = widget.places;
  }

  @override
  Widget build(BuildContext context) {
    final center = FreeMapService.getCenter(_places);

    return Scaffold(
      appBar: AppBar(
        title: Text('Explore - ${widget.trip.destination}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FreeMapWidget(
        places: _places,
        initialLatitude: center.latitude,
        initialLongitude: center.longitude,
        initialZoom: _places.isEmpty ? 10.0 : 12.0,
        onTap: (latlng) {
          _showAddPlaceDialog(latlng);
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _addSamplePlaces,
            tooltip: 'Add Sample Places',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _clearAllPlaces,
            tooltip: 'Clear All Places',
            backgroundColor: Colors.red,
            child: const Icon(Icons.clear),
          ),
        ],
      ),
    );
  }

  void _showAddPlaceDialog(LatLng position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Place'),
        content: const Text('Tap the + button to add sample places for testing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addSamplePlaces() {
    final newPlaces = [
      Place(
        name: 'Sample Restaurant',
        address: '123 Main Street',
        latitude: 36.8065 + (0.01 * _places.length),
        longitude: 10.1815 + (0.01 * _places.length),
        type: 'restaurant',
        price: 25.0,
        tripId: widget.trip.id!,
        visitDate: DateTime.now().add(Duration(days: _places.length)),
        rating: 4,
        notes: 'Great food!',
      ),
      Place(
        name: 'Sample Hotel',
        address: '456 Beach Road',
        latitude: 36.8065 - (0.01 * _places.length),
        longitude: 10.1815 - (0.01 * _places.length),
        type: 'hotel',
        price: 120.0,
        tripId: widget.trip.id!,
        visitDate: DateTime.now().add(Duration(days: _places.length + 1)),
        rating: 5,
        notes: 'Luxury accommodation',
      ),
    ];

    setState(() {
      _places.addAll(newPlaces);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sample places added!')),
    );
  }

  void _clearAllPlaces() {
    setState(() {
      _places.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All places cleared!')),
    );
  }

  Widget? FreeMapWidget({required List<Place> places, required initialLatitude, required initialLongitude, required double initialZoom, required Null Function(dynamic latlng) onTap}) {}
}

class LatLng {
}