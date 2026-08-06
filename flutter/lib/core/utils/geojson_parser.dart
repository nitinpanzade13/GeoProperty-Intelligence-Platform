import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '/features/map/models/village_polygon.dart';

class GeoJsonParser {
  static List<VillagePolygon> parse(
    Map<String, dynamic> geoJson,
  ) {
    final List<VillagePolygon> features = [];

    final rawFeatures = geoJson['features'] as List<dynamic>? ?? [];

    for (final feature in rawFeatures) {
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

        final properties = Map<String, dynamic>.from(
          feature['properties'] ?? {},
        );

        final polygon = Polygon(
          points: points,
          borderStrokeWidth: 0.8,
          borderColor: Colors.grey.shade700,
          color: Colors.green.withOpacity(0.15),
        );

        features.add(
          VillagePolygon(
            polygon: polygon,
            properties: properties,
          ),
        );
      } catch (e, stackTrace) {
        debugPrint(
          'Failed to parse GeoJSON feature: $e\n$stackTrace',
        );
      }
    }

    return features;
  }
}
