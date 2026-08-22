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

  factory AdminDashboardSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminDashboardSummary(
      districts: _toInt(json['districts']),
      talukas: _toInt(json['talukas']),
      villages: _toInt(json['villages']),
      properties: _toInt(json['properties']),
      owners: _toInt(json['owners']),
      villageMaps: _toInt(json['village_maps']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// ============================================================
// DISTRICT
// ============================================================

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

  AdminDistrictOverview copyWith({
    String? districtCode,
    String? districtName,
    int? talukaCount,
    int? villageCount,
    int? mapCount,
    String? syncStatus,
  }) {
    return AdminDistrictOverview(
      districtCode: districtCode ?? this.districtCode,
      districtName: districtName ?? this.districtName,
      talukaCount: talukaCount ?? this.talukaCount,
      villageCount: villageCount ?? this.villageCount,
      mapCount: mapCount ?? this.mapCount,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  factory AdminDistrictOverview.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminDistrictOverview(
      districtCode: json['district_code']?.toString() ?? '',
      districtName: json['district_name']?.toString() ?? '',
      talukaCount: _toInt(json['taluka_count']),
      villageCount: _toInt(json['village_count']),
      mapCount: _toInt(json['map_count']),
      syncStatus: json['sync_status']?.toString() ?? 'not_synced',
    );
  }

  bool get isSynced => syncStatus == 'synced';

  bool get isPartiallySynced => syncStatus == 'partially_synced';

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// ============================================================
// TALUKA
// ============================================================

class AdminTalukaOverview {
  final String talukaCode;
  final String talukaName;
  final int villageCount;
  final int mapCount;
  final String syncStatus;

  const AdminTalukaOverview({
    required this.talukaCode,
    required this.talukaName,
    required this.villageCount,
    required this.mapCount,
    required this.syncStatus,
  });

  factory AdminTalukaOverview.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminTalukaOverview(
      talukaCode: json['taluka_code']?.toString() ?? '',
      talukaName: json['taluka_name']?.toString() ?? '',
      villageCount: _toInt(json['village_count']),
      mapCount: _toInt(json['map_count']),
      syncStatus: json['sync_status']?.toString() ?? 'not_synced',
    );
  }

  bool get isSynced => syncStatus == 'synced';

  bool get isPartiallySynced => syncStatus == 'partially_synced';

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// ============================================================
// VILLAGE
// ============================================================

class AdminVillageOverview {
  final String gisCode;
  final String villageName;
  final String talukaCode;

  final int propertyCount;
  final int ownerCount;
  final int surveyCount;

  final String syncStatus;

  const AdminVillageOverview({
    required this.gisCode,
    required this.villageName,
    required this.talukaCode,
    required this.propertyCount,
    required this.ownerCount,
    required this.surveyCount,
    required this.syncStatus,
  });

  factory AdminVillageOverview.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminVillageOverview(
      gisCode: json['gis_code']?.toString() ?? '',
      villageName: json['village_name']?.toString() ?? '',
      talukaCode: json['taluka_code']?.toString() ?? '',
      propertyCount: _toInt(
        json['property_count'],
      ),
      ownerCount: _toInt(
        json['owner_count'],
      ),
      surveyCount: _toInt(
        json['survey_count'],
      ),
      syncStatus: json['map_status']?.toString() ?? 'not_synced',
    );
  }

  bool get isSynced => syncStatus == 'synced';

  bool get isPartiallySynced => syncStatus == 'partially_synced';

  bool get isNotSynced => syncStatus == 'not_synced';

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}
