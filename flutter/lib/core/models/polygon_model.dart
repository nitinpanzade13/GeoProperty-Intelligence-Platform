import 'package:equatable/equatable.dart';

class PolygonPointModel extends Equatable {
  final double latitude;
  final double longitude;

  const PolygonPointModel({
    required this.latitude,
    required this.longitude,
  });

  factory PolygonPointModel.fromJson(Map<String, dynamic> json) {
    return PolygonPointModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  List<Object?> get props => [latitude, longitude];
}

class PolygonModel extends Equatable {
  final String id;
  final List<PolygonPointModel> points;
  final String? fillColorHex;
  final String? strokeColorHex;

  const PolygonModel({
    required this.id,
    required this.points,
    this.fillColorHex,
    this.strokeColorHex,
  });

  factory PolygonModel.fromJson(Map<String, dynamic> json) {
    return PolygonModel(
      id: json['id'] as String? ?? '',
      points: (json['points'] as List<dynamic>?)
              ?.map((e) => PolygonPointModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      fillColorHex: json['fillColorHex'] as String?,
      strokeColorHex: json['strokeColorHex'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((e) => e.toJson()).toList(),
      'fillColorHex': fillColorHex,
      'strokeColorHex': strokeColorHex,
    };
  }

  @override
  List<Object?> get props => [id, points, fillColorHex, strokeColorHex];
}
