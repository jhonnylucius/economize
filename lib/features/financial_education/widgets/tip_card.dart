import 'package:economize/features/financial_education/models/financial_tip.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TipCard extends StatefulWidget {
  final FinancialTip tip;

  const TipCard({super.key, required this.tip});

  @override
  State<TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<TipCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Get ThemeManager instance using Provider
    final themeManager = context.watch<ThemeManager>();

    return Card(
      elevation: 4,
      // Use ThemeManager for card background color
      color: themeManager.getTipCardBackgroundColor(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(16), // Match Card's border radius
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.tip.category.icon,
                    // Use ThemeManager for icon color
                    color: themeManager.getTipCardIconColor(),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tip.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            // Use ThemeManager for text color
                            color: themeManager.getTipCardTextColor(),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.tip.category.displayName,
                          style: TextStyle(
                            // Use ThemeManager for text color with opacity
                            color: themeManager.getTipCardTextColor().withAlpha(
                              (0.6 * 255).toInt(),
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    // Use ThemeManager for icon color
                    color: themeManager.getTipCardIconColor(),
                  ),
                ],
              ),
              if (widget.tip.shortSummary != null) ...[
                const SizedBox(height: 12),
                Text(
                  widget.tip.shortSummary!,
                  style: TextStyle(
                    // Use ThemeManager for text color (adjust opacity if needed, e.g., .withOpacity(0.9))
                    color: themeManager.getTipCardTextColor(),
                    fontSize: 14,
                  ),
                ),
              ],
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                // Consider using themeManager for Divider color if desired
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  widget.tip.description,
                  style: TextStyle(
                    // Use ThemeManager for text color
                    color: themeManager.getTipCardTextColor(),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Como fazer:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    // Use ThemeManager for "primary-like" text/icon color
                    color: themeManager.getTipCardIconColor(),
                    fontSize: 14, // Approximating titleSmall size
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.tip.steps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            // Use ThemeManager for "primary-like" background color with opacity
                            color: themeManager.getTipCardIconColor().withAlpha(
                              (0.1 * 255).toInt(),
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              // Use ThemeManager for "primary-like" text/icon color
                              color: themeManager.getTipCardIconColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              // Use ThemeManager for text color
                              color: themeManager.getTipCardTextColor(),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (widget.tip.examples != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Exemplos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      // Use ThemeManager for "primary-like" text/icon color
                      color: themeManager.getTipCardIconColor(),
                      fontSize: 14, // Approximating titleSmall size
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.tip.examples!.map((example) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_right,
                            // Use ThemeManager for icon color
                            color: themeManager.getTipCardIconColor(),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              example,
                              style: TextStyle(
                                // Use ThemeManager for text color
                                color: themeManager.getTipCardTextColor(),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
