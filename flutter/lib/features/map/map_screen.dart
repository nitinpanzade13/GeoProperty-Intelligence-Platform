import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/providers/service_providers.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/models/property_model.dart';
import '../../core/utils/result.dart';
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

  LatLng _userLocation = const LatLng(18.5204, 73.8567);
  List<Marker> _markers = [];
  List<Polygon> _polygons = [];
  List<Polygon> _highlightedPolygons = [];

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
    _updateUserLocationMarker(_userLocation);
    if (widget.initialLatitude == null || widget.initialLongitude == null) {
      await _locateMe(moveCamera: false);
    } else {
      _mapController.move(_userLocation, 16.0);
    }
    await _fetchPropertyDetails();
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
      final sNum = widget.initialSurveyNumber ?? '142';
      final gis = widget.initialGisCode ?? 'RVM0501270500010046290000';

      final result = await propertyRepo.getPropertyDetails(
        'SURV-$sNum',
        gisCode: gis,
        surveyNumber: sNum,
      );

      if (result is Success<PropertyModel>) {
        final prop = result.data;
        _loadedProperty = prop;
        _gisCode = gis;

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
    // Resolve dynamic FastAPI backend base URL for WMS proxy
    final apiClient = ref.read(apiClientProvider);
    final String apiBaseUrl = apiClient.config.apiBaseUrl;
    final String wmsProxyBaseUrl = '$apiBaseUrl/map/wms?';

    return Scaffold(
      body: Stack(
        children: [
          // FlutterMap Layer Ordering:
          // 1. Base OSM Tile Layer + Official BhuNaksha WMS Backend Proxy Layer
          // 2. Property Polygons Layer
          // 3. Selected Polygon Highlight Layer (Amber Accent)
          // 4. Current Location Marker Layer (Blue GPS Pin)
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
              // 1a. Base OpenStreetMap Layer
              // TileLayer(
              //   urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              //   userAgentPackageName: 'com.example.geopropertyintelligence',
              // ),

              // 1b. Official BhuNaksha WMS Layer via FastAPI Backend Proxy
              if (_gisCode != null && _gisCode!.isNotEmpty)
                TileLayer(
                  wmsOptions: WMSTileLayerOptions(
                    baseUrl: wmsProxyBaseUrl,
                    version: '1.3.0',
                    crs: const Epsg3857(),
                    layers: const [
                      'VILLAGE_MAP',
                    ],
                    styles: const [
                      'VILLAGE_MAP',
                    ],
                    format: 'image/png',
                    transparent: true,
                    otherParameters: {
                      'gis_code': _gisCode!,
                    },
                  ),
                ),

              // 2. Base Property Polygons Layer
              PolygonLayer(polygons: _polygons),

              // 3. Selected Property Polygon Highlight Layer
              if (_highlightedPolygons.isNotEmpty)
                PolygonLayer(polygons: _highlightedPolygons),

              // 4. Current Location & Survey Markers Layer
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
                              ? 'Fetching BhuNaksha WMS Proxy & Polygon Extents...'
                              : 'Backend WMS Proxy: ${_gisCode ?? "Village Map"}',
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
}
