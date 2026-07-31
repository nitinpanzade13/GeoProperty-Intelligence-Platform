import 'package:equatable/equatable.dart';

class OwnerModel extends Equatable {
  final String ownerId;
  final String fullName;
  final double ownershipPercentage;
  final String? khataNumber;
  final String? contactPhone;

  const OwnerModel({
    required this.ownerId,
    required this.fullName,
    required this.ownershipPercentage,
    this.khataNumber,
    this.contactPhone,
  });

  factory OwnerModel.fromJson(Map<String, dynamic> json) {
    return OwnerModel(
      ownerId: json['owner_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Unknown',
      ownershipPercentage: (json['ownership_percentage'] as num?)?.toDouble() ?? 100.0,
      khataNumber: json['khata_number'] as String?,
      contactPhone: json['contact_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'full_name': fullName,
      'ownership_percentage': ownershipPercentage,
      'khata_number': khataNumber,
      'contact_phone': contactPhone,
    };
  }

  @override
  List<Object?> get props => [
        ownerId,
        fullName,
        ownershipPercentage,
        khataNumber,
        contactPhone,
      ];
}
