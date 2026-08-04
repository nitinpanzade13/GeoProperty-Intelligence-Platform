import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GeoJsonParser {
  static List<Polygon> parse(Map<String, dynamic> geoJson) {
    final List<Polygon> polygons = [];

    final features = geoJson['features'] as List<dynamic>? ?? [];

    for (final feature in features) {
      try {
        final geometry = feature['geometry'];

        if (geometry == null) continue;

        if (geometry['type'] != 'Polygon') continue;

        final coordinates = geometry['coordinates'];

        if (coordinates == null) continue;

        final ring = coordinates.first as List<dynamic>;

        final points = ring.map((point) {
          return LatLng(
            (point[1] as num).toDouble(),
            (point[0] as num).toDouble(),
          );
        }).toList();

        final survey = feature['properties']['survey_number']?.toString() ?? '';

        polygons.add(
          Polygon(
            points: points,

            // Save survey number inside label
            label: survey,

            borderStrokeWidth: 0.8,

            borderColor: Colors.grey.shade700,

            color: Colors.green.withOpacity(0.15),
          ),
        );
      } catch (_) {}
    }

    return polygons;
  }
}
