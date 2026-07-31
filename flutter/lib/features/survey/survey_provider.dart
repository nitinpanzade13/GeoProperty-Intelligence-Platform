import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/survey_model.dart';
import '../../core/repositories/survey_repository.dart';
import '../../core/providers/service_providers.dart';
import '../../core/utils/result.dart';

enum SurveySortMode { number, area, village }

class SurveyState {
  final List<SurveyModel> surveys;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final SurveySortMode sortMode;

  const SurveyState({
    this.surveys = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.sortMode = SurveySortMode.number,
  });

  SurveyState copyWith({
    List<SurveyModel>? surveys,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    SurveySortMode? sortMode,
  }) {
    return SurveyState(
      surveys: surveys ?? this.surveys,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      sortMode: sortMode ?? this.sortMode,
    );
  }
}

final surveyNotifierProvider = StateNotifierProvider<SurveyNotifier, SurveyState>((ref) {
  final repository = ref.watch(surveyRepositoryProvider);
  return SurveyNotifier(repository);
});

class SurveyNotifier extends StateNotifier<SurveyState> {
  final ISurveyRepository _repository;

  SurveyNotifier(this._repository) : super(const SurveyState()) {
    loadSurveys();
  }

  Future<void> loadSurveys({String? query}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.getSurveys(query: query ?? state.searchQuery);

    if (result is Success<List<SurveyModel>>) {
      List<SurveyModel> list = List.from(result.data);
      _applySorting(list, state.sortMode);
      state = state.copyWith(
        surveys: list,
        isLoading: false,
        searchQuery: query ?? state.searchQuery,
      );
    } else if (result is Failure<List<SurveyModel>>) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.message,
      );
    }
  }

  void updateSearch(String query) {
    loadSurveys(query: query);
  }

  void setSortMode(SurveySortMode sortMode) {
    List<SurveyModel> sorted = List.from(state.surveys);
    _applySorting(sorted, sortMode);
    state = state.copyWith(sortMode: sortMode, surveys: sorted);
  }

  Future<void> toggleFavorite(String surveyId) async {
    await _repository.toggleFavorite(surveyId);
    final updated = state.surveys.map((s) {
      if (s.id == surveyId) {
        return s.copyWith(isFavorite: !s.isFavorite);
      }
      return s;
    }).toList();
    state = state.copyWith(surveys: updated);
  }

  void _applySorting(List<SurveyModel> list, SurveySortMode mode) {
    switch (mode) {
      case SurveySortMode.number:
        list.sort((a, b) => a.surveyNumber.compareTo(b.surveyNumber));
        break;
      case SurveySortMode.area:
        list.sort((a, b) => b.areaSqMeters.compareTo(a.areaSqMeters));
        break;
      case SurveySortMode.village:
        list.sort((a, b) => a.village.compareTo(b.village));
        break;
    }
  }
}
