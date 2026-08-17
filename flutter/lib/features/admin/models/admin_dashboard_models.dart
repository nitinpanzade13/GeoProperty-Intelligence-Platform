class AdminDashboardSummary {
  final int districts;
  final int talukas;
  final int villages;
  final int properties;
  final int owners;
  final int villageMaps;

  const AdminDashboardSummary({
    required this.districts,
    required this.talukas,
    required this.villages,
    required this.properties,
    required this.owners,
    required this.villageMaps,
  });

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummary(
      districts: json['districts'] ?? 0,
      talukas: json['talukas'] ?? 0,
      villages: json['villages'] ?? 0,
      properties: json['properties'] ?? 0,
      owners: json['owners'] ?? 0,
      villageMaps: json['village_maps'] ?? 0,
    );
  }
}

class AdminDistrictOverview {
  final String districtCode;
  final String districtName;
  final int talukaCount;
  final int villageCount;
  final int mapCount;
  final String syncStatus;

  const AdminDistrictOverview({
    required this.districtCode,
    required this.districtName,
    required this.talukaCount,
    required this.villageCount,
    required this.mapCount,
    required this.syncStatus,
  });

  factory AdminDistrictOverview.fromJson(Map<String, dynamic> json) {
    return AdminDistrictOverview(
      districtCode: json['district_code']?.toString() ?? '',
      districtName: json['district_name']?.toString() ?? '',
      talukaCount: json['taluka_count'] ?? 0,
      villageCount: json['village_count'] ?? 0,
      mapCount: json['map_count'] ?? 0,
      syncStatus: json['sync_status']?.toString() ?? 'not_synced',
    );
  }

  bool get isSynced => syncStatus == 'synced';

  bool get isPartiallySynced => syncStatus == 'partially_synced';
}
