import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../models/trip_model.dart';
import '../../../models/place_model.dart';
import '../services/trip_service.dart';

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

  @override
  void initState() {
    super.initState();
    _places = widget.places;
  }

  @override
  Widget build(BuildContext context) {
    final center = _computeCenter(_places);
    final points = _sortedPoints(_places);

    return Scaffold(
      appBar: AppBar(
        title: Text('Explore - ${widget.trip.destination}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _places.isEmpty
          ? const Center(child: Text('Aucun lieu à afficher'))
          : FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                  userAgentPackageName: 'smart_travel_weather_app',
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
                if (points.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(points: points, color: Colors.blue, strokeWidth: 4),
                    ],
                  ),
                MarkerLayer(
                  markers: _places
                      .map(
                        (p) => Marker(
                          point: ll.LatLng(p.latitude, p.longitude),
                          width: 40,
                          height: 40,
                          child: Tooltip(
                            message: '${p.name} (${p.type})',
                            child: const Icon(Icons.place, color: Colors.red),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
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
          if (_places.isNotEmpty)
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

  ll.LatLng _computeCenter(List<Place> places) {
    if (places.isEmpty) return const ll.LatLng(0, 0);
    double lat = 0, lng = 0;
    for (final p in places) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return ll.LatLng(lat / places.length, lng / places.length);
  }

  List<ll.LatLng> _sortedPoints(List<Place> places) {
    final sorted = [...places]..sort((a, b) => a.visitDate.compareTo(b.visitDate));
    return sorted.map((p) => ll.LatLng(p.latitude, p.longitude)).toList();
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
}