import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
                : _buildFallbackInput(),
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

  Widget _buildFallbackInput() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Carte interactive (Web uniquement)',
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _selectedLat?.toString()),
                  onChanged: (value) {
                    final lat = double.tryParse(value);
                    if (lat != null) {
                      setState(() => _selectedLat = lat);
                      if (_selectedLng != null) {
                        widget.onLocationSelected(lat, _selectedLng!);
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _selectedLng?.toString()),
                  onChanged: (value) {
                    final lng = double.tryParse(value);
                    if (lng != null) {
                      setState(() => _selectedLng = lng);
                      if (_selectedLat != null) {
                        widget.onLocationSelected(_selectedLat!, lng);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
