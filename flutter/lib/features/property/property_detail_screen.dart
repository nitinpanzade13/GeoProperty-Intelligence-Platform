import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/models/property_model.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import '../../core/widgets/custom_error_widget.dart';
import '../../core/providers/service_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/result.dart';
import 'widgets/expandable_owner_card.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  PropertyModel? _property;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPropertyDetails();
  }

  Future<void> _loadPropertyDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(propertyRepositoryProvider);
    final sNum = widget.propertyId.contains('-')
        ? widget.propertyId.split('-').last
        : widget.propertyId;
    final result =
        await repo.getPropertyDetails(widget.propertyId, surveyNumber: sNum);

    if (result is Success<PropertyModel>) {
      _property = result.data;
    } else if (result is Failure<PropertyModel>) {
      _errorMessage = result.message;
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
        title: const Text('Property Intelligence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing property details...')),
              );
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: const [
                  ShimmerSkeleton(width: double.infinity, height: 120),
                  SizedBox(height: 16),
                  ShimmerSkeleton(width: double.infinity, height: 200),
                  SizedBox(height: 16),
                  ShimmerSkeleton(width: double.infinity, height: 160),
                ],
              ),
            );
          }

          if (_errorMessage != null) {
            return CustomErrorWidget(
              message: _errorMessage!,
              onRetry: _loadPropertyDetails,
            );
          }

          final prop = _property!;
          final survey = prop.surveyDetails;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              prop.status.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            'GIS Code: ${prop.surveyDetails.id.contains("MH-") ? prop.surveyDetails.id : "MH-2701-270101-52001"}',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(prop.title, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${survey.village}, ${survey.taluka}, ${survey.district}, Maharashtra',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Survey Information Card
                Text('Survey Information', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    children: [
                      _buildInfoRow('Survey Number', survey.surveyNumber),
                      _buildInfoRow('Subdivision (Hissa)',
                          survey.subdivisionNumber ?? '1'),
                      _buildInfoRow('Land Classification', survey.landType),
                      _buildInfoRow('District', survey.district),
                      _buildInfoRow('Taluka', survey.taluka),
                      _buildInfoRow('Village', survey.village),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Area & Pot Kharaba Information Card
                Text('Area & Land Metrics', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    children: [
                      _buildInfoRow(
                          'Total Sq. Meters', '${survey.areaSqMeters} m²'),
                      _buildInfoRow(
                          'Area in Hectares', '${prop.totalAreaHectares} Ha'),
                      _buildInfoRow('Pot Kharaba (Uncultivable)', '150.0 m²'),
                      if (prop.valuationEstimateInr != null)
                        _buildInfoRow(
                          'Estimated Market Valuation',
                          '₹ ${prop.valuationEstimateInr!.toStringAsFixed(2)}',
                          valueColor: AppColors.secondary,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Multi-Owner Expandable Cards
                Text('Registered Property Owners (${prop.owners.length})',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prop.owners.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final owner = prop.owners[index];
                    return ExpandableOwnerCard(
                      owner: owner,
                      totalAreaSqMeters: survey.areaSqMeters,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Polygon Geometry Vertices
                Text(
                    'GIS Polygon Vertices (${prop.boundaryPoints.length} points)',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coordinates Boundary Points:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...prop.boundaryPoints.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final pt = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            'P${idx + 1}: Lat ${pt.latitude.toStringAsFixed(5)}, Lng ${pt.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 13),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                CustomButton(
                  text: 'Inspect on GIS Interactive Map',
                  icon: Icons.map_rounded,
                  onPressed: () {
                    context.push(
                      Routes.map,
                      extra: {
                        'surveyNumber': survey.surveyNumber,
                        'gisCode': _property!.gisCode,
                        // 'latitude': _property!.boundaryPoints.first.latitude,
                        // 'longitude': _property!.boundaryPoints.first.longitude,
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Download Official Land Intelligence Report',
                  icon: Icons.download_rounded,
                  isSecondary: true,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Land Intelligence PDF report generated.')),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
