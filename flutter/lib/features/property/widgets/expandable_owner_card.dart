import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/owner_model.dart';
import '../../../core/widgets/glass_card.dart';

class ExpandableOwnerCard extends StatefulWidget {
  final OwnerModel owner;
  final double totalAreaSqMeters;

  const ExpandableOwnerCard({
    super.key,
    required this.owner,
    required this.totalAreaSqMeters,
  });

  @override
  State<ExpandableOwnerCard> createState() => _ExpandableOwnerCardState();
}

class _ExpandableOwnerCardState extends State<ExpandableOwnerCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calculatedArea = (widget.totalAreaSqMeters * widget.owner.ownershipPercentage) / 100.0;
    final areaHectares = calculatedArea / 10000.0;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: const Icon(Icons.person_rounded, color: AppColors.primary),
        ),
        title: Text(
          widget.owner.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Khata No: ${widget.owner.khataNumber ?? "N/A"} • ${widget.owner.ownershipPercentage}% Share',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        trailing: Icon(
          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
          color: AppColors.primary,
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildOwnerDetailRow('Full Owner Name', widget.owner.fullName),
                _buildOwnerDetailRow('Khata Register No.', widget.owner.khataNumber ?? 'N/A'),
                _buildOwnerDetailRow('Ownership Percentage', '${widget.owner.ownershipPercentage}%'),
                _buildOwnerDetailRow('Land Share Area', '${calculatedArea.toStringAsFixed(2)} m² (${areaHectares.toStringAsFixed(4)} Ha)'),
                if (widget.owner.contactPhone != null)
                  _buildOwnerDetailRow('Contact Phone', widget.owner.contactPhone!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
