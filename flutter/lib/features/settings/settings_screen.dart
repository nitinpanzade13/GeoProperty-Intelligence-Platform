import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/service_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/providers/dependency_injection.dart';
import '../../core/services/api_client.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final config = getIt<AppConfig>();
    _urlController = TextEditingController(text: config.apiBaseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveBackendUrl(String newUrl) {
    if (newUrl.trim().isEmpty) return;
    final apiClient = getIt<ApiClient>();
    apiClient.updateBaseUrl(newUrl.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backend Base URL updated to: $newUrl')),
    );
  }

  Future<void> _clearCache() async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearRecentSearches();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local cache & recent search history cleared.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Backend Server URL Settings
            Text('FastAPI Backend Configuration', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Base Server API URL:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _urlController.text = 'http://10.0.2.2:8000/api';
                          _saveBackendUrl(_urlController.text);
                        },
                        child: const Text('Android Emulator'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _urlController.text = 'http://10.193.171.183:8000/api';
                          _saveBackendUrl(_urlController.text);
                        },
                        child: const Text('Wi-Fi LAN IP'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _urlController.text = 'http://localhost:8000/api';
                          _saveBackendUrl(_urlController.text);
                        },
                        child: const Text('Localhost'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Appearance & Theme
            Text('Appearance', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            GlassCard(
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.primary),
                title: const Text('Dark Theme'),
                subtitle: const Text('Enable ultra-sleek dark mode interface'),
                value: isDark,
                onChanged: (_) {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
            ),
            const SizedBox(height: 20),

            // Local Storage Cache Controls
            Text('Storage & Cache Management', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            GlassCard(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.storage_rounded, color: AppColors.secondary),
                    title: Text('Offline Cache Size'),
                    subtitle: Text('1.2 MB (Hive Boxes)'),
                  ),
                  const Divider(),
                  CustomButton(
                    text: 'Clear Cache & Recent History',
                    icon: Icons.delete_outline_rounded,
                    isSecondary: true,
                    onPressed: _clearCache,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
