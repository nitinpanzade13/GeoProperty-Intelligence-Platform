import 'package:equatable/equatable.dart';

class OwnerModel extends Equatable {
  final String ownerName;
  final String? khataNumber;
  final double totalArea;
  final double potKharaba;

  const OwnerModel({
    required this.ownerName,
    this.khataNumber,
    required this.totalArea,
    required this.potKharaba,
  });

  factory OwnerModel.fromJson(Map<String, dynamic> json) {
    return OwnerModel(
      ownerName: json['owner_name'] as String? ?? 'Unknown',
      khataNumber: json['khata_number'] as String?,
      totalArea: (json['total_area'] as num?)?.toDouble() ?? 0.0,
      potKharaba: (json['pot_kharaba'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_name': ownerName,
      'khata_number': khataNumber,
      'total_area': totalArea,
      'pot_kharaba': potKharaba,
    };
  }

  @override
  List<Object?> get props => [
        ownerName,
        khataNumber,
        totalArea,
        potKharaba,
      ];
}
