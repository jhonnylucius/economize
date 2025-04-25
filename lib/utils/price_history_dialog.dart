import 'package:economize/model/budget/price_history.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PriceHistoryDialog extends StatelessWidget {
  final List<PriceHistory> history;
  final String itemName;
  final String locationName;
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  PriceHistoryDialog({
    super.key,
    required this.history,
    required this.itemName,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final record = history[index];
        final isPositive = record.variation > 0;

        return ListTile(
          leading: Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            // Substituindo cores fixas por cores do tema
            color:
                isPositive
                    ? theme.colorScheme.error
                    : theme.colorScheme.tertiary,
          ),
          title: Text(
            currencyFormat.format(record.price),
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          subtitle: Text(
            DateFormat('dd/MM/yyyy HH:mm').format(record.date),
            style: TextStyle(
              color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
            ),
          ),
          trailing: Text(
            '${record.variation.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              // Substituindo cores fixas por cores do tema
              color:
                  isPositive
                      ? theme.colorScheme.error
                      : theme.colorScheme.tertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
