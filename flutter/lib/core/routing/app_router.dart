import 'package:go_router/go_router.dart';
import 'routes.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/permissions/permission_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/survey/survey_screen.dart';
import '../../features/property/property_detail_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/favorites/favorites_screen.dart';

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
        path: Routes.map,
        builder: (context, state) => const MapScreen(),
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
