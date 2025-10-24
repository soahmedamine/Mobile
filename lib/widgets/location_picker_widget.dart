import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// Conditional imports for web
import 'location_picker_stub.dart'
    if (dart.library.html) 'location_picker_web.dart';

class LocationPickerWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double latitude, double longitude) onLocationSelected;

  const LocationPickerWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  double? _selectedLat;
  double? _selectedLng;
  String? _viewId;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLatitude ?? 36.8065; // Default: Tunis
    _selectedLng = widget.initialLongitude ?? 10.1815;

    if (kIsWeb) {
      _viewId = 'map-picker-${DateTime.now().millisecondsSinceEpoch}';
      registerMapView(_viewId!, _selectedLat!, _selectedLng!, (lat, lng) {
        if (mounted) {
          setState(() {
            _selectedLat = lat;
            _selectedLng = lng;
          });
          widget.onLocationSelected(lat, lng);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emplacement sur la carte',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cliquez sur la carte ou faites glisser le marqueur pour sélectionner l\'emplacement',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        Container(
          height: 350,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb && _viewId != null
                ? HtmlElementView(viewType: _viewId!)
                : _buildMobileMap(),
          ),
        ),

        const SizedBox(height: 12),

        // Display selected coordinates
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lat: ${_selectedLat?.toStringAsFixed(6) ?? '---'}, Lng: ${_selectedLng?.toStringAsFixed(6) ?? '---'}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileMap() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(_selectedLat ?? 36.8065, _selectedLng ?? 10.1815),
        initialZoom: 13.0,
        onTap: (tapPosition, point) {
          setState(() {
            _selectedLat = point.latitude;
            _selectedLng = point.longitude;
          });
          widget.onLocationSelected(point.latitude, point.longitude);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.smarttravel.app',
          additionalOptions: const {
            'attribution': '© OpenStreetMap contributors © CARTO',
          },
          maxNativeZoom: 20,
          maxZoom: 20,
        ),
        MarkerLayer(
          markers: [
            if (_selectedLat != null && _selectedLng != null)
              Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(_selectedLat!, _selectedLng!),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40.0,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
