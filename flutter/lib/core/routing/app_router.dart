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
import '../../core/constants/defaults.dart';
import '../../features/admin/admin_login_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';

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
          final id = state.extra as String? ?? '${Defaults.surveyIdPrefix}101';
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
              district: extra['district'] as String? ?? Defaults.district,
              taluka: extra['taluka'] as String? ?? Defaults.taluka,
              village: extra['village'] as String? ?? Defaults.village,
              surveyNumber:
                  extra['surveyNumber'] as String? ?? Defaults.surveyNumber,
              gisCode: extra['gisCode'] as String? ?? Defaults.gisCode,
            );
          }
          return PropertySearchDetailsScreen(
            property: const PropertyModel(
              propertyId: 'PROP-101',
              gisCode: Defaults.gisCode,
              title: 'Survey No. 142',
              surveyDetails: SurveyModel(
                id: '${Defaults.surveyIdPrefix}101',
                surveyNumber: Defaults.surveyNumber,
                subdivisionNumber: '3/A',
                district: Defaults.district,
                taluka: Defaults.taluka,
                village: Defaults.village,
                areaSqMeters: Defaults.defaultAreaSqMeters,
                landType: Defaults.landType,
                location: LocationModel(
                    latitude: Defaults.latitude, longitude: Defaults.longitude),
              ),
              owners: [],
              totalAreaHectares: 0.45,
              boundaryPoints: [],
              status: Defaults.propertyStatus,
            ),
            district: Defaults.district,
            taluka: Defaults.taluka,
            village: Defaults.village,
            surveyNumber: Defaults.surveyNumber,
            gisCode: Defaults.gisCode,
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
              district: extraMap['district'] as String?,
              taluka: extraMap['taluka'] as String?,
              village: extraMap['village'] as String?,
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
      GoRoute(
        path: Routes.adminLogin,
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: Routes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
}
