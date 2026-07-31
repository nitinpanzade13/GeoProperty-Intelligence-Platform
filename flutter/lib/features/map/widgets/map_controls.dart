import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';

class MapControls extends StatelessWidget {
  final MapType currentMapType;
  final ValueChanged<MapType> onMapTypeChanged;
  final VoidCallback onLocateMe;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapControls({
    super.key,
    required this.currentMapType,
    required this.onMapTypeChanged,
    required this.onLocateMe,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Map Type Toggle Button
        _buildFab(
          icon: Icons.layers_rounded,
          onPressed: () {
            final next = currentMapType == MapType.normal
                ? MapType.satellite
                : (currentMapType == MapType.satellite ? MapType.hybrid : MapType.normal);
            onMapTypeChanged(next);
          },
          tooltip: 'Switch Map Layer',
        ),
        const SizedBox(height: 10),
        // Locate Me Button
        _buildFab(
          icon: Icons.my_location_rounded,
          onPressed: onLocateMe,
          tooltip: 'Locate Me',
          color: AppColors.secondary,
        ),
        const SizedBox(height: 10),
        // Zoom In
        _buildFab(
          icon: Icons.add_rounded,
          onPressed: onZoomIn,
          tooltip: 'Zoom In',
        ),
        const SizedBox(height: 6),
        // Zoom Out
        _buildFab(
          icon: Icons.remove_rounded,
          onPressed: onZoomOut,
          tooltip: 'Zoom Out',
        ),
      ],
    );
  }

  Widget _buildFab({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? Colors.white, size: 22),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
