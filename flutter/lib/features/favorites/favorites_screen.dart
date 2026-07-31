import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/models/survey_model.dart';
import '../../core/providers/service_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/result.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<SurveyModel> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final repo = ref.read(surveyRepositoryProvider);
    final result = await repo.getSurveys();

    if (result is Success<List<SurveyModel>>) {
      _favorites = result.data.where((s) => s.isFavorite).toList();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Starred Properties'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading saved land parcels...')
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_border_rounded, size: 64, color: AppColors.warning),
                      const SizedBox(height: 16),
                      Text(
                        'No bookmarked land parcels yet',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the star icon on any survey parcel to save it here.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final survey = _favorites[index];
                    return GlassCard(
                      onTap: () => context.push(Routes.propertyDetail, extra: survey.id),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.warning,
                          child: Icon(Icons.star_rounded, color: Colors.white),
                        ),
                        title: Text('Survey No. ${survey.surveyNumber}/${survey.subdivisionNumber ?? "1"}'),
                        subtitle: Text('${survey.village}, ${survey.district} • ${survey.areaSqMeters} sq.m'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    );
                  },
                ),
    );
  }
}
