// Web implementation for map view
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

void registerMapView(
  String viewId,
  double lat,
  double lng,
  Function(double, double) onLocationSelected,
) {
  // Register the view factory for web
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final mapHtml = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        <style>
          html, body { height: 100%; margin: 0; padding: 0; }
          #map { height: 100%; width: 100%; }
        </style>
      </head>
      <body>
        <div id="map"></div>
        <script>
          var map = L.map('map').setView([$lat, $lng], 13);
          
          L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors',
            maxZoom: 19
          }).addTo(map);
          
          var marker = L.marker([$lat, $lng], {
            draggable: true
          }).addTo(map);
          
          function updateLocation(lat, lng) {
            window.parent.postMessage({
              type: 'locationSelected',
              lat: lat,
              lng: lng
            }, '*');
          }
          
          map.on('click', function(e) {
            marker.setLatLng(e.latlng);
            updateLocation(e.latlng.lat, e.latlng.lng);
          });
          
          marker.on('dragend', function(e) {
            var position = marker.getLatLng();
            updateLocation(position.lat, position.lng);
          });
        </script>
      </body>
      </html>
    ''';

    final iframe = html.IFrameElement()
      ..style.border = 'none'
      ..style.height = '100%'
      ..style.width = '100%'
      ..srcdoc = mapHtml;

    // Listen for messages from iframe
    html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is Map && data['type'] == 'locationSelected') {
        final latitude = (data['lat'] as num).toDouble();
        final longitude = (data['lng'] as num).toDouble();
        onLocationSelected(latitude, longitude);
      }
    });

    return iframe;
  });
}

