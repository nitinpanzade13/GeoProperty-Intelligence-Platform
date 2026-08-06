import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/providers/service_providers.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/models/property_model.dart';
import '../../core/utils/result.dart';
import '../../core/utils/geojson_parser.dart';
import '../../core/constants/defaults.dart';
import 'widgets/map_controls.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String? initialSurveyNumber;
  final String? initialGisCode;
  final double? initialLatitude;
  final double? initialLongitude;

  const MapScreen({
    super.key,
    this.initialSurveyNumber,
    this.initialGisCode,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  LatLng _userLocation = LatLng(Defaults.latitude, Defaults.longitude);
  List<Marker> _markers = [];
  List<Polygon> _polygons = [];
  List<VillagePolygon> _villageFeatures = [];
  List<Polygon> _highlightedPolygons = [];
  VillagePolygon? _selectedFeature;

  bool _isLoadingProperty = false;
  PropertyModel? _loadedProperty;
  String? _gisCode;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _userLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    _gisCode = widget.initialGisCode;
    _initUserLocationAndProperty();
  }

  Future<void> _initUserLocationAndProperty() async {
    // Always show the current GPS marker.
    _updateUserLocationMarker(_userLocation);

    // If we opened the map from "View on Map",
    // DO NOT move to the user's location.
    if (widget.initialSurveyNumber != null && widget.initialGisCode != null) {
      await _fetchPropertyDetails();
      return;
    }

    // Otherwise this is a normal map screen.
    await _locateMe(moveCamera: true);
  }

  void _updateUserLocationMarker(LatLng position) {
    setState(() {
      _userLocation = position;
      _rebuildMarkers();
    });
  }

  void _rebuildMarkers() {
    final List<Marker> newMarkers = [
      // Current Location GPS Marker (Blue Dot)
      Marker(
        point: _userLocation,
        width: 52,
        height: 52,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.blueAccent, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.my_location_rounded,
              color: Colors.blue,
              size: 26,
            ),
          ),
        ),
      ),
    ];

    // Survey Marker if property loaded
    if (_loadedProperty != null && _loadedProperty!.boundaryPoints.isNotEmpty) {
      final firstPoint = _loadedProperty!.boundaryPoints.first;
      final surveyLatLng = LatLng(firstPoint.latitude, firstPoint.longitude);

      newMarkers.add(
        Marker(
          point: surveyLatLng,
          width: 44,
          height: 44,
          child: Tooltip(
            message:
                'Survey No. ${_loadedProperty!.surveyDetails.surveyNumber}',
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      );
    }

    _markers = newMarkers;
  }

  Future<void> _loadVillageMap() async {
    if (_gisCode == null) return;

    final propertyRepo = ref.read(propertyRepositoryProvider);

    final result = await propertyRepo.getVillageMap(
      _gisCode!,
    );

    if (result is Success<Map<String, dynamic>>) {
      setState(() {
        _villageFeatures = GeoJsonParser.parse(result.data);
      });

      debugPrint(
        "Village features loaded: ${_villageFeatures.length}",
      );
    }
  }

  Future<void> _locateMe({bool moveCamera = true}) async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final pos = await locationService.getCurrentPosition();

      if (pos != null) {
        final newPos = LatLng(pos.latitude, pos.longitude);
        _updateUserLocationMarker(newPos);

        if (moveCamera) {
          _mapController.move(newPos, 16.0);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Location error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _fetchPropertyDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingProperty = true);

    try {
      final propertyRepo = ref.read(propertyRepositoryProvider);
      final sNum = widget.initialSurveyNumber ?? Defaults.surveyNumber;
      final gis = widget.initialGisCode ?? Defaults.gisCode;

      final result = await propertyRepo.getPropertyDetails(
        '${Defaults.surveyIdPrefix}$sNum',
        gisCode: gis,
        surveyNumber: sNum,
      );

      if (result is Success<PropertyModel>) {
        final prop = result.data;
        setState(() {
          _loadedProperty = prop;
          _gisCode = gis;
        });

        if (prop.boundaryPoints.isNotEmpty) {
          final List<LatLng> surveyPoints = prop.boundaryPoints
              .map((pt) => LatLng(pt.latitude, pt.longitude))
              .toList();

          setState(() {
            // Layer 2: Base Property Polygon
            _polygons = [
              Polygon(
                points: surveyPoints,
                borderStrokeWidth: 2.0,
                borderColor: AppColors.secondary.withValues(alpha: 0.6),
                color: AppColors.secondary.withValues(alpha: 0.2),
              ),
            ];

            // Layer 3: Selected Polygon Highlight (Vibrant Amber Outline on top of WMS)
            _highlightedPolygons = [
              Polygon(
                points: surveyPoints,
                borderStrokeWidth: 4.0,
                borderColor: Colors.amberAccent,
                color: Colors.amberAccent.withValues(alpha: 0.35),
              ),
            ];

            _rebuildMarkers();
          });

          // Automatically fit camera zoom to selected property
          _autoFitPolygon(surveyPoints);
          await _loadVillageMap();
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingProperty = false);
    }
  }

  void _autoFitPolygon(List<LatLng> points) {
    if (points.isEmpty) return;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      try {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(60.0),
          ),
        );
      } catch (_) {
        _mapController.move(points.first, 16.0);
      }
    });
  }

  void _selectVillageFeature(VillagePolygon feature) {
    setState(() {
      _selectedFeature = feature;

      _highlightedPolygons = [
        Polygon(
          points: feature.polygon.points,
          borderStrokeWidth: 4,
          borderColor: Colors.amberAccent,
          color: Colors.amberAccent.withOpacity(0.35),
        ),
      ];
    });

    _autoFitPolygon(feature.polygon.points);

    _showPropertyBottomSheet(feature);
  }

  void _showPropertyBottomSheet(
    VillagePolygon feature,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Survey ${feature.surveyNumber}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _infoTile(
                  "Property ID",
                  feature.propertyId,
                ),
                _infoTile(
                  "Plot ID",
                  feature.plotId,
                ),
                _infoTile(
                  "Area",
                  "${feature.areaSqMeters} sq.m",
                ),
                _infoTile(
                  "Owner",
                  feature.ownerName.isEmpty ? "-" : feature.ownerName,
                ),
                _infoTile(
                  "Khata",
                  feature.khataNumber.isEmpty ? "-" : feature.khataNumber,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _zoomIn() {
    try {
      final currentZoom = _mapController.camera.zoom;
      _mapController.move(_mapController.camera.center, currentZoom + 1.0);
    } catch (_) {}
  }

  void _zoomOut() {
    try {
      final currentZoom = _mapController.camera.zoom;
      _mapController.move(_mapController.camera.center, currentZoom - 1.0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // FlutterMap Layer Ordering:
          // 1. OpenStreetMap Base Layer
          // 2. Village GeoJSON Polygon Layer
          // 3. Selected Property Polygon
          // 4. Highlight Layer
          // 5. Marker Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 16.0,
              // minZoom: 4.0,
              // maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Base Property Polygons Layer

              // 1. OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.geoproperty.intelligence',
              ),

              // 2. Village polygons
              if (_villageFeatures.isNotEmpty)
                PolygonLayer(
                  polygons: _villageFeatures
                      .map((feature) => feature.polygon)
                      .toList(),
                ),

              // 3. Selected property
              PolygonLayer(polygons: _polygons),

              // 4. Highlight
              if (_highlightedPolygons.isNotEmpty)
                PolygonLayer(polygons: _highlightedPolygons),

              // 5. Markers
              MarkerLayer(markers: _markers),
            ],
          ),

          // Top Floating GlassCard Header
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'GIS Land Intelligence Map',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          _isLoadingProperty
                              ? 'Loading village GeoJSON...'
                              : 'Village: ${_gisCode ?? "Map"}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingProperty)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.secondary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Floating Map Controls (Locate Me, Zoom In, Zoom Out)
          Positioned(
            right: 16,
            bottom: 40,
            child: MapControls(
              onLocateMe: () => _locateMe(moveCamera: true),
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
