/// Centralized fallback/default values used across the application.
/// All hardcoded fallback values should reference this class instead of
/// being scattered across individual files.
class Defaults {
  Defaults._();

  // GPS Fallback (Pune, Maharashtra)
  static const double latitude = 18.5204;
  static const double longitude = 73.8567;

  // Administrative Hierarchy
  static const String state = 'Maharashtra';
  static const String district = 'Pune';
  static const String taluka = 'Haveli';
  static const String village = 'Shivajinagar';
  static const String pincode = '411005';
  static const String fallbackAddress = 'Shivajinagar, Pune, Maharashtra 411005';

  // GIS Codes
  static const String gisCode = 'RVM0501270500010046290000';
  static const String legacyGisCode = 'MH-2701-270101-52001';

  // Survey
  static const String surveyNumber = '142';
  static const String subdivisionNumber = '1';
  static const String surveyIdPrefix = 'SURV-';
  static const String landType = 'Agricultural';
  static const double defaultAreaSqMeters = 4500.0;

  // Property
  static const String propertyStatus = 'Verified';

  // Owner
  static const String unknownOwner = 'Unknown';
  static const double fullOwnership = 100.0;

  // User
  static const String userRole = 'Land Surveyor / Analyst';
  static const String preferredMapType = 'hybrid';

  // Map
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapPackageName = 'com.example.geopropertyintelligence';
}
