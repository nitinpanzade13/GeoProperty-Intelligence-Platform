import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/providers/service_providers.dart';
import '../../core/routing/routes.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _isGranting = false;

  Future<void> _requestLocationPermission() async {
    setState(() => _isGranting = true);
    final locationService = ref.read(locationServiceProvider);
    await locationService.requestPermission();
    setState(() => _isGranting = false);
    if (mounted) {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Location & GPS Access',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Property Radar requires high-precision location services to overlay survey boundary polygons, detect plot coordinates, and perform accurate land intelligence analysis.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              CustomButton(
                text: 'Enable GPS Location',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isGranting,
                onPressed: _requestLocationPermission,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Skip for Now',
                isSecondary: true,
                onPressed: () => context.go(Routes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
