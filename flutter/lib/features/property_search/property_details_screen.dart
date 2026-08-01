import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/models/property_model.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/routing/routes.dart';
import '../property/widgets/expandable_owner_card.dart';

class PropertySearchDetailsScreen extends StatelessWidget {
  final PropertyModel property;
  final String district;
  final String taluka;
  final String village;
  final String surveyNumber;
  final String gisCode;

  const PropertySearchDetailsScreen({
    super.key,
    required this.property,
    required this.district,
    required this.taluka,
    required this.village,
    required this.surveyNumber,
    required this.gisCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final survey = property.surveyDetails;
    final primaryOwner = property.owners.isNotEmpty ? property.owners.first.fullName : 'Registered Owner';
    final primaryKhata = property.owners.isNotEmpty ? property.owners.first.khataNumber : 'KH-1001';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Land Record Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Summary Card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.status.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        'GIS: $gisCode',
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Survey No. $surveyNumber',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$village, $taluka, $district, Maharashtra',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Administrative & Location Card
            Text('Administrative Hierarchy', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            GlassCard(
              child: Column(
                children: [
                  _buildDetailRow('District', district),
                  _buildDetailRow('Taluka', taluka),
                  _buildDetailRow('Village', village),
                  _buildDetailRow('Unified GIS Code', gisCode),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Land & Measurement Metrics Card
            Text('Land & Measurement Metrics', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            GlassCard(
              child: Column(
                children: [
                  _buildDetailRow('Survey Number', surveyNumber),
                  _buildDetailRow('Subdivision (Hissa)', survey.subdivisionNumber ?? '1'),
                  _buildDetailRow('Total Area (Sq. Meters)', '${survey.areaSqMeters} m²'),
                  _buildDetailRow('Total Area (Hectares)', '${property.totalAreaHectares} Ha'),
                  _buildDetailRow('Pot Kharaba (Uncultivable)', '150.0 m²'),
                  if (property.valuationEstimateInr != null)
                    _buildDetailRow(
                      'Estimated Valuation',
                      '₹ ${property.valuationEstimateInr!.toStringAsFixed(2)}',
                      valueColor: AppColors.secondary,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Primary Owner Information Summary
            Text('Primary Khata Summary', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            GlassCard(
              child: Column(
                children: [
                  _buildDetailRow('Primary Registered Owner', primaryOwner),
                  _buildDetailRow('Khata Register No.', primaryKhata ?? 'N/A'),
                  _buildDetailRow('Total Owner Count', '${property.owners.length} Registered Owners'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Multi-Owner Cards List
            if (property.owners.isNotEmpty) ...[
              Text('All Registered Owners (${property.owners.length})', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: property.owners.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final owner = property.owners[index];
                  return ExpandableOwnerCard(
                    owner: owner,
                    totalAreaSqMeters: survey.areaSqMeters,
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Bottom Action Button: View on Map
            CustomButton(
              text: 'View on Map',
              icon: Icons.map_rounded,
              onPressed: () {
                context.push(
                  Routes.map,
                  extra: {
                    'surveyNumber': surveyNumber,
                    'gisCode': gisCode,
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
