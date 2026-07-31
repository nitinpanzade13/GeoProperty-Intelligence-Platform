import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/routing/routes.dart';
import '../../core/models/location_model.dart';
import '../../core/models/survey_model.dart';
import '../../core/providers/service_providers.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import '../../core/utils/result.dart';
import 'widgets/location_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/map_preview_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  LocationModel? _location;
  List<SurveyModel> _surveys = [];
  bool _isLoading = true;
  bool _isBackendConnected = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final locationRepo = ref.read(locationRepositoryProvider);
    final surveyRepo = ref.read(surveyRepositoryProvider);

    // Fetch Current Location
    final locResult = await locationRepo.getCurrentLocation();
    if (locResult is Success<LocationModel>) {
      _location = locResult.data;
    }

    // Fetch Survey Intelligence list from Backend
    final surveyResult = await surveyRepo.getSurveys();
    if (surveyResult is Success<List<SurveyModel>>) {
      _surveys = surveyResult.data;
      _isBackendConnected = true;
    } else {
      _isBackendConnected = false;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favorites = _surveys.where((s) => s.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.radar_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Text(
              'GeoProperty',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Intelligence',
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(Routes.search),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Backend Service Health Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (_isBackendConnected ? AppColors.secondary : AppColors.warning).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isBackendConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      color: _isBackendConnected ? AppColors.secondary : AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isBackendConnected
                          ? 'FastAPI Backend: Connected (v2.0)'
                          : 'Offline Cache Mode',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isBackendConnected ? AppColors.secondary : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Current Location Card
              LocationCard(location: _location, isLoading: _isLoading),
              const SizedBox(height: 20),

              // Quick Actions
              Text('Quick Actions', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              QuickActionsGrid(
                items: [
                  QuickActionItem(
                    title: 'Surveys',
                    icon: Icons.assignment_rounded,
                    color: AppColors.primary,
                    onTap: () => context.push(Routes.survey),
                  ),
                  QuickActionItem(
                    title: 'Live Map',
                    icon: Icons.map_rounded,
                    color: AppColors.secondary,
                    onTap: () => context.push(Routes.map),
                  ),
                  QuickActionItem(
                    title: 'Favorites',
                    icon: Icons.star_rounded,
                    color: AppColors.warning,
                    onTap: () => context.push(Routes.favorites),
                  ),
                  QuickActionItem(
                    title: 'Profile',
                    icon: Icons.person_rounded,
                    color: AppColors.tertiary,
                    onTap: () => context.push(Routes.profile),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Map Interactive Preview
              Text('GIS Map Preview', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              MapPreviewCard(onTap: () => context.push(Routes.map)),
              const SizedBox(height: 24),

              // Survey Information Feed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Survey Intelligence', style: theme.textTheme.titleLarge),
                  TextButton(
                    onPressed: () => context.push(Routes.survey),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _isLoading
                  ? const ShimmerSkeleton(width: double.infinity, height: 120)
                  : _surveys.isEmpty
                      ? const GlassCard(
                          child: Text('No survey records available.'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _surveys.take(2).length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final survey = _surveys[index];
                            return GlassCard(
                              onTap: () => context.push(
                                Routes.propertyDetail,
                                extra: survey.id,
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Icon(Icons.landscape_rounded, color: Colors.white, size: 20),
                                ),
                                title: Text('Survey No. ${survey.surveyNumber}/${survey.subdivisionNumber ?? "1"}'),
                                subtitle: Text('${survey.village}, ${survey.district} • ${survey.areaSqMeters} sq.m'),
                                trailing: const Icon(Icons.chevron_right_rounded),
                              ),
                            );
                          },
                        ),
              const SizedBox(height: 24),

              // Starred Parcels
              if (favorites.isNotEmpty) ...[
                Text('Starred Land Parcels', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: favorites.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final fav = favorites[index];
                      return GlassCard(
                        onTap: () => context.push(Routes.propertyDetail, extra: fav.id),
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Survey ${fav.surveyNumber}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                fav.village,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                fav.landType,
                                style: const TextStyle(fontSize: 11, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
