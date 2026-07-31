import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/environment.dart';
import 'core/providers/dependency_injection.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment config defaulting to local Wi-Fi IP for physical mobile devices
  Environment.init();

  // Initialize GetIt dependency injection and Hive storage
  await setupDependencyInjection();

  runApp(
    const ProviderScope(
      child: GeoPropertyApp(),
    ),
  );
}

class GeoPropertyApp extends ConsumerWidget {
  const GeoPropertyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'GeoProperty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}

// Backward compatibility alias for widget tests
typedef PropertyRadarApp = GeoPropertyApp;
