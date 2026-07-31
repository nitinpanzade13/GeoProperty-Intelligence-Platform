import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/location_model.dart';

class LocationCard extends StatelessWidget {
  final LocationModel? location;
  final bool isLoading;

  const LocationCard({
    super.key,
    this.location,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.secondary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT LOCATION',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        location?.village ?? location?.address ?? 'Detecting GPS position...',
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                if (location != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${location!.district}, ${location!.state} (${location!.latitude.toStringAsFixed(4)}, ${location!.longitude.toStringAsFixed(4)})',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
