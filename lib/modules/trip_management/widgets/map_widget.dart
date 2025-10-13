import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../models/place_model.dart';

class MapWidget extends StatefulWidget {
  final List<Place> places;
  final double initialLatitude;
  final double initialLongitude;
  final double initialZoom;

  const MapWidget({
    Key? key,
    required this.places,
    this.initialLatitude = 0.0,
    this.initialLongitude = 0.0,
    this.initialZoom = 10.0,
  }) : super(key: key);

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places) {
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    _markers.clear();
    for (var place in widget.places) {
      final marker = Marker(
        markerId: MarkerId(place.id?.toString() ?? '${place.name}_${place.latitude}'),
        position: LatLng(place.latitude, place.longitude),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.address,
        ),
        icon: _getMarkerIcon(place.type),
      );
      _markers.add(marker);
    }
    setState(() {});
  }

  BitmapDescriptor _getMarkerIcon(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'hotel':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'attraction':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.initialLatitude, widget.initialLongitude),
        zoom: widget.initialZoom,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}