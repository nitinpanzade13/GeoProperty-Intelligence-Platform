import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DropdownItem<T> {
  final T value;
  final String label;

  const DropdownItem({required this.value, required this.label});
}

class SearchDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isLoading;
  final bool isEnabled;
  final String hintText;

  const SearchDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isLoading = false,
    this.isEnabled = true,
    this.hintText = 'Select Option',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isEnabled ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isEnabled
                    ? (isDark ? Colors.white : Colors.black87)
                    : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isEnabled
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04))
                : (isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.black.withValues(alpha: 0.02)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled
                  ? (value != null
                      ? AppColors.primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.12)))
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Loading records...',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: isEnabled ? value : null,
                    isExpanded: true,
                    hint: Text(
                      hintText,
                      style: TextStyle(
                        color: isEnabled ? Colors.grey : Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isEnabled ? AppColors.primary : Colors.grey,
                    ),
                    items: isEnabled
                        ? items.map((item) {
                            return DropdownMenuItem<T>(
                              value: item.value,
                              child: Text(
                                item.label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList()
                        : [],
                    onChanged: isEnabled ? onChanged : null,
                  ),
                ),
        ),
      ],
    );
  }
}
