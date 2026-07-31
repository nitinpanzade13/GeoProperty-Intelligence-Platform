import 'package:equatable/equatable.dart';
import 'survey_model.dart';
import 'owner_model.dart';
import 'polygon_model.dart';

class PropertyModel extends Equatable {
  final String propertyId;
  final String title;
  final SurveyModel surveyDetails;
  final List<OwnerModel> owners;
  final double totalAreaHectares;
  final List<PolygonPointModel> boundaryPoints;
  final double? valuationEstimateInr;
  final String status;

  const PropertyModel({
    required this.propertyId,
    required this.title,
    required this.surveyDetails,
    required this.owners,
    required this.totalAreaHectares,
    required this.boundaryPoints,
    this.valuationEstimateInr,
    this.status = 'Verified',
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      propertyId: json['property_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      surveyDetails: SurveyModel.fromJson(json['survey_details'] as Map<String, dynamic>),
      owners: (json['owners'] as List<dynamic>?)
              ?.map((e) => OwnerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAreaHectares: (json['total_area_hectares'] as num?)?.toDouble() ?? 0.0,
      boundaryPoints: (json['boundary_points'] as List<dynamic>?)
              ?.map((e) => PolygonPointModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      valuationEstimateInr: (json['valuation_estimate_inr'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'Verified',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'property_id': propertyId,
      'title': title,
      'survey_details': surveyDetails.toJson(),
      'owners': owners.map((e) => e.toJson()).toList(),
      'total_area_hectares': totalAreaHectares,
      'boundary_points': boundaryPoints.map((e) => e.toJson()).toList(),
      'valuation_estimate_inr': valuationEstimateInr,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        propertyId,
        title,
        surveyDetails,
        owners,
        totalAreaHectares,
        boundaryPoints,
        valuationEstimateInr,
        status,
      ];
}
