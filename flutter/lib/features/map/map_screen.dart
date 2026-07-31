import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/providers/service_providers.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/models/property_model.dart';
import '../../core/utils/result.dart';
import 'widgets/map_controls.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String? initialSurveyNumber;

  const MapScreen({super.key, this.initialSurveyNumber});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.hybrid;
  LatLng _currentLocation = const LatLng(18.5204, 73.8567);
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};
  bool _isLoadingProperty = false;

  @override
  void initState() {
    super.initState();
    _initMapLayers();
    _fetchLocationAndProperty();
  }

  void _initMapLayers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLocation,
        infoWindow: const InfoWindow(title: 'Current Location', snippet: 'Shivajinagar, Pune'),
      ),
    );
  }

  Future<void> _fetchLocationAndProperty() async {
    if (!mounted) return;
    setState(() => _isLoadingProperty = true);

    try {
      final locationService = ref.read(locationServiceProvider);
      final pos = await locationService.getCurrentPosition();

      if (pos != null) {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLocation,
            infoWindow: const InfoWindow(title: 'Live GPS Fix'),
          ),
        );
      }
    } catch (_) {}

    try {
      final propertyRepo = ref.read(propertyRepositoryProvider);
      final sNum = widget.initialSurveyNumber ?? '142';
      final result = await propertyRepo.getPropertyDetails('SURV-$sNum', surveyNumber: sNum);

      if (result is Success<PropertyModel>) {
        final prop = result.data;
        if (prop.boundaryPoints.isNotEmpty) {
          final List<LatLng> polyLatLngs = prop.boundaryPoints
              .map((pt) => LatLng(pt.latitude, pt.longitude))
              .toList();

          if (mounted) {
            setState(() {
              _polygons.clear();
              _polygons.add(
                Polygon(
                  polygonId: PolygonId('poly_${prop.propertyId}'),
                  points: polyLatLngs,
                  strokeWidth: 3,
                  strokeColor: AppColors.secondary,
                  fillColor: AppColors.secondary.withValues(alpha: 0.35),
                ),
              );

              _markers.add(
                Marker(
                  markerId: MarkerId('plot_${prop.propertyId}'),
                  position: polyLatLngs.first,
                  infoWindow: InfoWindow(
                    title: 'Survey No. ${prop.surveyDetails.surveyNumber}',
                    snippet: 'Area: ${prop.surveyDetails.areaSqMeters} sq.m',
                  ),
                ),
              );
            });
          }

          _fitCameraToBounds(polyLatLngs);
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingProperty = false);
    }
  }

  void _fitCameraToBounds(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _mapController == null) return;
      try {
        double minLat = points.first.latitude;
        double maxLat = points.first.latitude;
        double minLng = points.first.longitude;
        double maxLng = points.first.longitude;

        for (var pt in points) {
          if (pt.latitude < minLat) minLat = pt.latitude;
          if (pt.latitude > maxLat) maxLat = pt.latitude;
          if (pt.longitude < minLng) minLng = pt.longitude;
          if (pt.longitude > maxLng) maxLng = pt.longitude;
        }

        final bounds = LatLngBounds(
          southwest: LatLng(minLat - 0.001, minLng - 0.001),
          northeast: LatLng(maxLat + 0.001, maxLng + 0.001),
        );

        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      } catch (_) {
        // Fallback safely to center target position without crashing
        _mapController?.animateCamera(CameraUpdate.newLatLng(points.first));
      }
    });
  }

  void _zoomIn() {
    try {
      _mapController?.animateCamera(CameraUpdate.zoomIn());
    } catch (_) {}
  }

  void _zoomOut() {
    try {
      _mapController?.animateCamera(CameraUpdate.zoomOut());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map Widget
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 16.0,
            ),
            mapType: _currentMapType,
            markers: _markers,
            polygons: _polygons,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_polygons.isNotEmpty) {
                _fitCameraToBounds(_polygons.first.points);
              }
            },
          ),

          // Top Floating Bar
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          _isLoadingProperty
                              ? 'Fetching BhuNaksha GIS Extents...'
                              : 'Live Layer: Survey Boundary Polygons',
                          style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Side Map Controls
          Positioned(
            right: 16,
            bottom: 40,
            child: MapControls(
              currentMapType: _currentMapType,
              onMapTypeChanged: (type) {
                setState(() => _currentMapType = type);
              },
              onLocateMe: _fetchLocationAndProperty,
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
            ),
          ),
        ],
      ),
    );
  }
}
