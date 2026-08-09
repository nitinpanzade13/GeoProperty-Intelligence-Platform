class PropertyIdentifyModel {
  final String surveyNumber;
  final String propertyId;
  final String plotId;
  final double areaSqMeters;
  final String? ownerName;
  final String? khataNumber;
  final Map<String, dynamic> geometry;

  const PropertyIdentifyModel({
    required this.surveyNumber,
    required this.propertyId,
    required this.plotId,
    required this.areaSqMeters,
    required this.ownerName,
    required this.khataNumber,
    required this.geometry,
  });

  factory PropertyIdentifyModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return PropertyIdentifyModel(
      surveyNumber: json["survey_number"] ?? "",
      propertyId: json["property_id"] ?? "",
      plotId: json["plot_id"] ?? "",
      areaSqMeters: (json["area_sq_meters"] as num?)?.toDouble() ?? 0,
      ownerName: json["owner_name"],
      khataNumber: json["khata_number"],
      geometry: Map<String, dynamic>.from(
        json["geometry"] ?? {},
      ),
    );
  }
}
