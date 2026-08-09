import 'package:latlong2/latlong.dart';

class PolygonUtils {
  static LatLng centroid(List<LatLng> points) {
    double lat = 0;
    double lng = 0;

    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }

    return LatLng(
      lat / points.length,
      lng / points.length,
    );
  }
}
