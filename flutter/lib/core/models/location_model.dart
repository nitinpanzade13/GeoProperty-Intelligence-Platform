import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String? district;
  final String? taluka;
  final String? village;
  final String? state;
  final String? pincode;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.district,
    this.taluka,
    this.village,
    this.state = 'Maharashtra',
    this.pincode,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      district: json['district'] as String?,
      taluka: json['taluka'] as String?,
      village: json['village'] as String?,
      state: json['state'] as String? ?? 'Maharashtra',
      pincode: json['pincode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'district': district,
      'taluka': taluka,
      'village': village,
      'state': state,
      'pincode': pincode,
    };
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        address,
        district,
        taluka,
        village,
        state,
        pincode,
      ];
}
