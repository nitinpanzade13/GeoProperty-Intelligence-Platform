import 'package:go_router/go_router.dart';
import 'routes.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/permissions/permission_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/survey/survey_screen.dart';
import '../../features/property/property_detail_screen.dart';
import '../../features/property_search/property_search_screen.dart';
import '../../features/property_search/property_details_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../core/models/property_model.dart';
import '../../core/models/survey_model.dart';
import '../../core/models/location_model.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.permissions,
        builder: (context, state) => const PermissionScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.survey,
        builder: (context, state) => const SurveyScreen(),
      ),
      GoRoute(
        path: Routes.propertyDetail,
        builder: (context, state) {
          final id = state.extra as String? ?? 'SURV-101';
          return PropertyDetailScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: Routes.propertySearch,
        builder: (context, state) => const PropertySearchScreen(),
      ),
      GoRoute(
        path: Routes.propertySearchDetails,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null && extra.containsKey('property')) {
            return PropertySearchDetailsScreen(
              property: extra['property'] as PropertyModel,
              district: extra['district'] as String? ?? 'Pune',
              taluka: extra['taluka'] as String? ?? 'Haveli',
              village: extra['village'] as String? ?? 'Shivajinagar',
              surveyNumber: extra['surveyNumber'] as String? ?? '142',
              gisCode: extra['gisCode'] as String? ?? 'RVM0501270500010046290000',
            );
          }
          return PropertySearchDetailsScreen(
            property: const PropertyModel(
              propertyId: 'PROP-101',
              title: 'Survey No. 142',
              surveyDetails: SurveyModel(
                id: 'SURV-101',
                surveyNumber: '142',
                subdivisionNumber: '3/A',
                district: 'Pune',
                taluka: 'Haveli',
                village: 'Shivajinagar',
                areaSqMeters: 4500.0,
                landType: 'Agricultural',
                location: LocationModel(latitude: 18.5204, longitude: 73.8567),
              ),
              owners: [],
              totalAreaHectares: 0.45,
              boundaryPoints: [],
              status: 'Verified',
            ),
            district: 'Pune',
            taluka: 'Haveli',
            village: 'Shivajinagar',
            surveyNumber: '142',
            gisCode: 'RVM0501270500010046290000',
          );
        },
      ),
      GoRoute(
        path: Routes.map,
        builder: (context, state) {
          if (state.extra is Map<String, dynamic>) {
            final extraMap = state.extra as Map<String, dynamic>;
            return MapScreen(
              initialSurveyNumber: extraMap['surveyNumber'] as String?,
              initialGisCode: extraMap['gisCode'] as String?,
              initialLatitude: extraMap['latitude'] as double?,
              initialLongitude: extraMap['longitude'] as double?,
            );
          }
          final surveyNum = state.extra as String?;
          return MapScreen(initialSurveyNumber: surveyNum);
        },
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: Routes.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
    ],
  );
}
