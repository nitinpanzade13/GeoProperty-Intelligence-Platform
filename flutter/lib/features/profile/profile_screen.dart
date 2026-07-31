import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/service_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/result.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.getUserProfile();

    if (result is Success<UserModel>) {
      _user = result.data;
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
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading user profile...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Avatar Header
                  GlassCard(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            _user?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(_user?.name ?? 'Analyst User', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(_user?.email ?? '', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _user?.role ?? 'Land Surveyor',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Saved & Preferences Section
                  GlassCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.star_rounded, color: AppColors.warning),
                          title: const Text('Saved Land Parcels'),
                          subtitle: Text('${_user?.savedPropertyIds.length ?? 0} properties bookmarked'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(Routes.favorites),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.map_rounded, color: AppColors.primary),
                          title: const Text('Default Map Mode'),
                          subtitle: Text(_user?.preferredMapType.toUpperCase() ?? 'HYBRID'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(Routes.settings),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // About Application
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About Platform', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text(
                          'Property Radar v1.0.0 (Build 100)\nEnterprise AI-Powered GeoProperty Intelligence Platform for land parcel survey mapping & registry verification.',
                          style: TextStyle(color: Colors.grey, height: 1.4),
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
