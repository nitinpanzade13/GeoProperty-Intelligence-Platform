import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onLocateMe;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapControls({
    super.key,
    required this.onLocateMe,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 📍 Locate Me
        _buildFab(
          icon: Icons.my_location_rounded,
          onPressed: onLocateMe,
          tooltip: 'Locate Me',
          iconColor: AppColors.secondary,
        ),
        const SizedBox(height: 12),

        // ➕ Zoom In
        _buildFab(
          icon: Icons.add_rounded,
          onPressed: onZoomIn,
          tooltip: 'Zoom In',
        ),
        const SizedBox(height: 8),

        // ➖ Zoom Out
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
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      elevation: 6,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            icon,
            size: 22,
            color: iconColor ?? Colors.white,
          ),
          tooltip: tooltip,
          splashRadius: 24,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
