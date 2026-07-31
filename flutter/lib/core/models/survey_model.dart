import 'package:equatable/equatable.dart';
import 'location_model.dart';
import 'owner_model.dart';
import 'polygon_model.dart';

class SurveyModel extends Equatable {
  final String id;
  final String surveyNumber;
  final String? subdivisionNumber;
  final String district;
  final String taluka;
  final String village;
  final double areaSqMeters;
  final String landType;
  final LocationModel location;
  final List<OwnerModel> owners;
  final List<PolygonPointModel> polygonCoordinates;
  final bool isFavorite;

  const SurveyModel({
    required this.id,
    required this.surveyNumber,
    this.subdivisionNumber,
    required this.district,
    required this.taluka,
    required this.village,
    required this.areaSqMeters,
    required this.landType,
    required this.location,
    this.owners = const [],
    this.polygonCoordinates = const [],
    this.isFavorite = false,
  });

  factory SurveyModel.fromJson(Map<String, dynamic> json) {
    return SurveyModel(
      id: json['id'] as String? ?? '',
      surveyNumber: json['survey_number'] as String? ?? '',
      subdivisionNumber: json['subdivision_number'] as String?,
      district: json['district'] as String? ?? '',
      taluka: json['taluka'] as String? ?? '',
      village: json['village'] as String? ?? '',
      areaSqMeters: (json['area_sq_meters'] as num?)?.toDouble() ?? 0.0,
      landType: json['land_type'] as String? ?? 'Agricultural',
      location: LocationModel.fromJson(json['location'] as Map<String, dynamic>),
      owners: (json['owners'] as List<dynamic>?)
              ?.map((e) => OwnerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      polygonCoordinates: (json['polygon_coordinates'] as List<dynamic>?)
              ?.map((e) => PolygonPointModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'survey_number': surveyNumber,
      'subdivision_number': subdivisionNumber,
      'district': district,
      'taluka': taluka,
      'village': village,
      'area_sq_meters': areaSqMeters,
      'land_type': landType,
      'location': location.toJson(),
      'owners': owners.map((e) => e.toJson()).toList(),
      'polygon_coordinates': polygonCoordinates.map((e) => e.toJson()).toList(),
      'is_favorite': isFavorite,
    };
  }

  SurveyModel copyWith({
    String? id,
    String? surveyNumber,
    String? subdivisionNumber,
    String? district,
    String? taluka,
    String? village,
    double? areaSqMeters,
    String? landType,
    LocationModel? location,
    List<OwnerModel>? owners,
    List<PolygonPointModel>? polygonCoordinates,
    bool? isFavorite,
  }) {
    return SurveyModel(
      id: id ?? this.id,
      surveyNumber: surveyNumber ?? this.surveyNumber,
      subdivisionNumber: subdivisionNumber ?? this.subdivisionNumber,
      district: district ?? this.district,
      taluka: taluka ?? this.taluka,
      village: village ?? this.village,
      areaSqMeters: areaSqMeters ?? this.areaSqMeters,
      landType: landType ?? this.landType,
      location: location ?? this.location,
      owners: owners ?? this.owners,
      polygonCoordinates: polygonCoordinates ?? this.polygonCoordinates,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
        id,
        surveyNumber,
        subdivisionNumber,
        district,
        taluka,
        village,
        areaSqMeters,
        landType,
        location,
        owners,
        polygonCoordinates,
        isFavorite,
      ];
}
