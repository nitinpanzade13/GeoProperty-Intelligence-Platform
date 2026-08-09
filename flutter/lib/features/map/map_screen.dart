import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/providers/service_providers.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/models/property_model.dart';
import '../../core/models/property_identify_model.dart';
import '../../core/utils/result.dart';
import '../../core/utils/geojson_parser.dart';
import '../../core/constants/defaults.dart';
import '../../core/utils/polygon_utils.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/routing/routes.dart';
import 'widgets/map_controls.dart';
import './models/village_polygon.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String? initialSurveyNumber;
  final String? initialGisCode;
  final double? initialLatitude;
  final double? initialLongitude;

  final String? district;
  final String? taluka;
  final String? village;

  const MapScreen({
    super.key,
    this.initialSurveyNumber,
    this.initialGisCode,
    this.initialLatitude,
    this.initialLongitude,
    this.district,
    this.taluka,
    this.village,
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
  String? _district;
  String? _taluka;
  String? _village;
  bool _isIdentifyingProperty = false;
  bool _isSatellite = true;

  double _currentZoom = 16.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _userLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    _gisCode = widget.initialGisCode;
    _district = widget.district;
    _taluka = widget.taluka;
    _village = widget.village;
    _initUserLocationAndProperty();
  }

  Future<void> _initUserLocationAndProperty() async {
    // Always show current marker
    _updateUserLocationMarker(_userLocation);

    // If a village GIS code is supplied, always load the village GeoJSON.
    if (widget.initialGisCode != null) {
      _gisCode = widget.initialGisCode;

      await _loadVillageMap();

      // If a survey is also supplied, highlight that survey.
      if (widget.initialSurveyNumber != null) {
        await _fetchPropertyDetails();
      }

      return;
    }

    // Standalone map
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
      final features = GeoJsonParser.parse(result.data);

      setState(() {
        _villageFeatures = features;
      });

      debugPrint(
        "Village features loaded: ${features.length}",
      );

      // Move camera to village
      if (features.isNotEmpty) {
        final List<LatLng> allPoints = [];

        for (final feature in features) {
          allPoints.addAll(feature.polygon.points);
        }

        _autoFitPolygon(allPoints);
      }
    }
  }

  Future<void> _identifyProperty(LatLng point) async {
    if (_gisCode == null) return;

    setState(() {
      _isIdentifyingProperty = true;
    });

    try {
      final repo = ref.read(propertyRepositoryProvider);

      // First API
      final identifyResult = await repo.identifyProperty(
        _gisCode!,
        point.latitude,
        point.longitude,
      );

      if (identifyResult is! Success<PropertyIdentifyModel>) {
        return;
      }

      final identified = identifyResult.data;

      // 2. Find the corresponding GeoJSON polygon
      final feature = _villageFeatures.firstWhere(
        (f) => f.propertyId == identified.propertyId,
      );

      // Second API
      final detailsResult = await repo.getPropertyDetails(
        identified.propertyId,
        gisCode: _gisCode!,
        surveyNumber: identified.surveyNumber,
      );

      if (detailsResult is! Success<PropertyModel>) {
        return;
      }

      final property = detailsResult.data;

      if (mounted) {
        setState(() {
          _loadedProperty = property;
        });
      }

      // Highlight the selected property polygon on the map
      _selectVillageFeature(feature);

      // Show the bottom sheet with property details
      _showPropertyBottomSheet(
        feature,
        property,
      );
    } catch (e) {
      debugPrint('Property identification failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isIdentifyingProperty = false;
        });
      }
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
                borderStrokeWidth: 3.0,
                borderColor: AppColors.secondary,
                color: AppColors.secondary.withValues(alpha: 0.12),
              ),
            ];

            // Layer 3: Selected Polygon Highlight (Vibrant Amber Outline on top of WMS)
            _highlightedPolygons = [
              // Outer glow
              Polygon(
                points: surveyPoints,
                borderStrokeWidth: 8.0,
                borderColor: Colors.amberAccent.withValues(alpha: 0.35),
                color: Colors.transparent,
              ),

              // Main selected boundary
              Polygon(
                points: surveyPoints,
                borderStrokeWidth: 3.0,
                borderColor: Colors.amberAccent,
                color: Colors.amberAccent.withValues(alpha: 0.15),
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

  void _selectVillageFeature(VillagePolygon feature) {
    setState(() {
      _selectedFeature = feature;

      _highlightedPolygons = [
        // Outer glow
        Polygon(
          points: feature.polygon.points,
          borderStrokeWidth: 8,
          borderColor: Colors.amberAccent.withValues(alpha: 0.35),
          color: Colors.transparent,
        ),

        // Main boundary
        Polygon(
          points: feature.polygon.points,
          borderStrokeWidth: 3,
          borderColor: Colors.amberAccent,
          color: Colors.amberAccent.withValues(alpha: 0.18),
        ),
      ];
    });

    _autoFitPolygon(feature.polygon.points);
  }

  void _showPropertyBottomSheet(
    VillagePolygon feature,
    PropertyModel property,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.30,
          maxChildSize: 0.90,
          builder: (context, scrollController) {
            return SafeArea(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  24,
                ),
                child: Column(
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
                      "${feature.areaSqMeters.toStringAsFixed(2)} sq.m",
                    ),

                    const SizedBox(height: 12),

                    // Owner section
                    const Text(
                      "Registered Owners",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (property.owners.isEmpty)
                      _infoTile(
                        "Owner",
                        "No Data Found",
                      )
                    else
                      ...property.owners.asMap().entries.map((entry) {
                        final index = entry.key;
                        final owner = entry.value;

                        final ownerName = owner.fullName.trim().isEmpty
                            ? "No Data Found"
                            : owner.fullName;

                        final khata = owner.khataNumber == null ||
                                owner.khataNumber!.trim().isEmpty
                            ? "No Data Found"
                            : owner.khataNumber!;

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              _infoTile(
                                "Owner ${index + 1}",
                                ownerName,
                              ),
                              _infoTile(
                                "Khata",
                                khata,
                              ),
                              _infoTile(
                                "Ownership",
                                "${owner.ownershipPercentage.toStringAsFixed(2)}%",
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 8),

                    // Primary Khata
                    _infoTile(
                      "Khata",
                      property.owners.isNotEmpty &&
                              property.owners.first.khataNumber != null &&
                              property.owners.first.khataNumber!
                                  .trim()
                                  .isNotEmpty
                          ? property.owners.first.khataNumber!
                          : "No Data Found",
                    ),

                    const SizedBox(height: 20),

                    // View full details button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: "View Full Property Details",
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          Navigator.of(sheetContext).pop();

                          context.push(
                            Routes.propertySearchDetails,
                            extra: {
                              'property': property,
                              'district':
                                  _district ?? property.surveyDetails.district,
                              'taluka':
                                  _taluka ?? property.surveyDetails.taluka,
                              'village':
                                  _village ?? property.surveyDetails.village,
                              'surveyNumber':
                                  property.surveyDetails.surveyNumber,
                              'gisCode': property.gisCode,
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
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

  List<VillagePolygon> _visibleSurveyLabels() {
    // Level 1: Zoomed out
    // Hide all survey numbers.
    if (_currentZoom < 15.5) {
      return [];
    }

    // Level 2: Medium zoom
    // Show only a limited number of survey numbers.
    if (_currentZoom < 17.0) {
      return _villageFeatures
          .asMap()
          .entries
          .where((entry) => entry.key % 5 == 0)
          .map((entry) => entry.value)
          .toList();
    }

    // Level 3: Highly zoomed in
    // Show all survey numbers.
    return _villageFeatures;
  }

  @override
  Widget build(BuildContext context) {
    final visibleSurveyLabels = _visibleSurveyLabels();
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
              onPositionChanged: (position, hasGesture) {
                final zoom = position.zoom;

                if (zoom != _currentZoom) {
                  setState(() {
                    _currentZoom = zoom;
                  });
                }
              },
              onTap: (tapPosition, latLng) {
                _identifyProperty(latLng);
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Base Property Polygons Layer

              // 1. Satellite / Real-world imagery
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.geoproperty.intelligence',
                tileProvider: NetworkTileProvider(),
                maxZoom: 18,
              ),

              // 2. Village polygons
              if (_villageFeatures.isNotEmpty)
                PolygonLayer(
                  polygons: _villageFeatures.map((feature) {
                    return Polygon(
                      points: feature.polygon.points,
                      color: Colors.white.withValues(alpha: 0.03),
                      borderColor: Colors.yellowAccent.withValues(alpha: 0.85),
                      borderStrokeWidth: 1,
                    );
                  }).toList(),
                ),

              PolygonLayer(
                polygons: _polygons,
              ),

              // 3. Zoom-dependent Survey Number Labels

              if (visibleSurveyLabels.isNotEmpty)
                MarkerLayer(
                  markers: visibleSurveyLabels.map((feature) {
                    final center = PolygonUtils.centroid(
                      feature.polygon.points,
                    );

                    return Marker(
                      point: center,
                      width: 50,
                      height: 22,
                      child: IgnorePointer(
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            feature.surveyNumber,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              // 4. Highlight Polygon
              if (_highlightedPolygons.isNotEmpty)
                PolygonLayer(polygons: _highlightedPolygons),

              // 5. User Markers
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

          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton.extended(
              heroTag: 'mapStyleButton',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (context) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Map Type',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            RadioListTile<bool>(
                              value: false,
                              groupValue: _isSatellite,
                              title: const Text('Street Map'),
                              secondary: const Icon(Icons.map_outlined),
                              onChanged: (value) {
                                if (value == null) return;

                                setState(() {
                                  _isSatellite = value;
                                });

                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<bool>(
                              value: true,
                              groupValue: _isSatellite,
                              title: const Text('Satellite'),
                              secondary: const Icon(Icons.satellite_alt),
                              onChanged: (value) {
                                if (value == null) return;

                                setState(() {
                                  _isSatellite = value;
                                });

                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              icon: Icon(
                _isSatellite ? Icons.satellite_alt : Icons.map_outlined,
              ),
              label: Text(
                _isSatellite ? 'Satellite' : 'Street',
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
