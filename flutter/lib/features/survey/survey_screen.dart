import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/custom_error_widget.dart';
import '../../core/routing/routes.dart';
import 'survey_provider.dart';

class SurveyScreen extends ConsumerWidget {
  const SurveyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(surveyNotifierProvider);
    final notifier = ref.read(surveyNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Land Survey Directory'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SearchBarWidget(
                  onChanged: notifier.updateSearch,
                  onClear: () => notifier.updateSearch(''),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Survey No.'),
                      selected: state.sortMode == SurveySortMode.number,
                      onSelected: (_) => notifier.setSortMode(SurveySortMode.number),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Area'),
                      selected: state.sortMode == SurveySortMode.area,
                      onSelected: (_) => notifier.setSortMode(SurveySortMode.area),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Village'),
                      selected: state.sortMode == SurveySortMode.village,
                      onSelected: (_) => notifier.setSortMode(SurveySortMode.village),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading) {
                  return const LoadingIndicator(message: 'Searching land survey records...');
                }

                if (state.errorMessage != null) {
                  return CustomErrorWidget(
                    message: state.errorMessage!,
                    onRetry: notifier.loadSurveys,
                  );
                }

                if (state.surveys.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No survey records match your search',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.surveys.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final survey = state.surveys[index];
                    return GlassCard(
                      onTap: () => context.push(Routes.propertyDetail, extra: survey.id),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.landscape_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Survey No. ${survey.surveyNumber}/${survey.subdivisionNumber ?? "1"}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${survey.village}, ${survey.taluka}, ${survey.district}',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Area: ${survey.areaSqMeters} sq.m • ${survey.landType}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                survey.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                                color: survey.isFavorite ? AppColors.warning : Colors.grey,
                              ),
                              onPressed: () => notifier.toggleFavorite(survey.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
