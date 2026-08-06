import 'package:flutter_map/flutter_map.dart';

class VillagePolygon {
  /// Polygon drawn on flutter_map
  final Polygon polygon;

  /// Complete GeoJSON properties
  final Map<String, dynamic> properties;

  const VillagePolygon({
    required this.polygon,
    required this.properties,
  });

  // --------------------------------------------------
  // Frequently used properties
  // --------------------------------------------------

  String get surveyNumber => properties["survey_number"]?.toString() ?? "";

  String get propertyId => properties["property_id"]?.toString() ?? "";

  String get plotId => properties["plot_id"]?.toString() ?? "";

  double get areaSqMeters =>
      (properties["area_sq_meters"] as num?)?.toDouble() ?? 0.0;

  // --------------------------------------------------
  // Future properties
  // --------------------------------------------------

  String get ownerName => properties["owner_name"]?.toString() ?? "";

  String get khataNumber => properties["khata_number"]?.toString() ?? "";

  @override
  String toString() {
    return "VillagePolygon(survey: $surveyNumber)";
  }
}
