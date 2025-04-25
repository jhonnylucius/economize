import 'package:flutter/material.dart';

class TableCells {
  static Widget buildHeaderCell(
    BuildContext context,
    String text, {
    bool isGreen = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color:
              isGreen ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  static Widget buildCell(
    BuildContext context,
    String text, {
    bool isHighlighted = false,
    bool isGreen = false,
    bool isOrderNumber = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      alignment: isOrderNumber ? Alignment.center : Alignment.centerLeft,
      constraints: const BoxConstraints(),
      child: Text(
        text,
        style: TextStyle(
          color:
              isHighlighted || isGreen
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
          fontWeight:
              isOrderNumber || isHighlighted || isGreen
                  ? FontWeight.bold
                  : null,
        ),
        textAlign: isOrderNumber ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}
