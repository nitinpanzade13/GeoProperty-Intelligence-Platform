import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/search_bar_widget.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/models/survey_model.dart';
import '../../core/providers/service_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/result.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<SurveyModel> _results = [];
  bool _isLoading = false;
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  void _loadRecentSearches() {
    final storage = ref.read(storageServiceProvider);
    _recentSearches = storage.getRecentSearches();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final storage = ref.read(storageServiceProvider);
    await storage.addRecentSearch(query);
    _loadRecentSearches();

    final repo = ref.read(surveyRepositoryProvider);
    final result = await repo.getSurveys(query: query);

    if (result is Success<List<SurveyModel>>) {
      _results = result.data;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Land Parcels'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchBarWidget(
              controller: _controller,
              onSubmitted: _performSearch,
              onClear: () {
                setState(() => _results.clear());
              },
            ),
            const SizedBox(height: 16),
            if (_recentSearches.isNotEmpty && _results.isEmpty && !_isLoading) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () async {
                      await ref.read(storageServiceProvider).clearRecentSearches();
                      setState(() => _recentSearches.clear());
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _recentSearches.map((term) {
                  return ActionChip(
                    label: Text(term),
                    onPressed: () {
                      _controller.text = term;
                      _performSearch(term);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            Expanded(
              child: _isLoading
                  ? const LoadingIndicator(message: 'Searching records...')
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final survey = _results[index];
                        return GlassCard(
                          onTap: () => context.push(Routes.propertyDetail, extra: survey.id),
                          child: ListTile(
                            title: Text('Survey No. ${survey.surveyNumber}/${survey.subdivisionNumber ?? "1"}'),
                            subtitle: Text('${survey.village}, ${survey.district}'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
