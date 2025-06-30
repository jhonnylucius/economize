import 'package:economize/model/budget/budget.dart';
import 'package:economize/model/budget/budget_item.dart';
import 'package:economize/service/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class PriceComparisonTable extends StatefulWidget {
  final Budget budget;

  const PriceComparisonTable({super.key, required this.budget});

  @override
  State<PriceComparisonTable> createState() => _PriceComparisonTableState();
}

class _PriceComparisonTableState extends State<PriceComparisonTable> {
  final GlobalKey _screenShotKey = GlobalKey();
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final PdfService _pdfService = PdfService();

  List<BudgetItem> _getSortedItems() {
    final groupedItems = <String, List<BudgetItem>>{};

    for (var item in widget.budget.items) {
      if (!groupedItems.containsKey(item.bestPriceLocation)) {
        groupedItems[item.bestPriceLocation] = [];
      }
      groupedItems[item.bestPriceLocation]!.add(item);
    }

    groupedItems.forEach((_, items) {
      items.sort((a, b) => a.name.compareTo(b.name));
    });

    final sortedItems = <BudgetItem>[];
    for (var location in widget.budget.locations) {
      if (groupedItems.containsKey(location.id)) {
        sortedItems.addAll(groupedItems[location.id]!);
      }
    }

    return sortedItems;
  }

  Future<void> _shareTable(BuildContext context) async {
    try {
      _showLoadingDialog(context);

      final pdfFile = await _pdfService.generatePriceComparisonPdf(
        widget.budget,
      );

      if (context.mounted) {
        Navigator.pop(context);
        await Share.shareXFiles(
          [XFile(pdfFile.path)],
          text: 'Tabela Comparativa de Preços',
        );
      }
    } catch (e) {
      _handleError(context, e);
    }
  }

  void _showLoadingDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        );
      },
    );
  }

  void _handleError(BuildContext context, dynamic error) {
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao compartilhar: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedItems = _getSortedItems();

    final locationTotals = <String, double>{};
    final bestPriceTotal = widget.budget.items.fold<double>(
      0,
      (sum, item) => sum + item.bestPrice,
    );

    for (var location in widget.budget.locations) {
      locationTotals[location.id] = widget.budget.items.fold<double>(
        0,
        (sum, item) => sum + (item.prices[location.id] ?? 0),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surface,
      child: RepaintBoundary(
        key: _screenShotKey,
        child: SingleChildScrollView(
          controller: _verticalController,
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Comparativo de Preços',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.share,
                          color: theme.colorScheme.primary,
                        ),
                        tooltip: 'Compartilhar tabela',
                        onPressed: () => _shareTable(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Table(
                    border: TableBorder.all(
                      color: theme.colorScheme.outline.withAlpha(
                        (0.2 * 255).toInt(),
                      ),
                      width: 1,
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                    columnWidths: {
                      0: const FixedColumnWidth(50),
                      1: const FixedColumnWidth(120),
                      for (var i = 0; i < widget.budget.locations.length; i++)
                        i + 2: const FixedColumnWidth(100),
                      widget.budget.locations.length + 2:
                          const FixedColumnWidth(120),
                      widget.budget.locations.length + 3:
                          const FixedColumnWidth(120),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        children: [
                          _buildHeaderCell('Nº'),
                          _buildHeaderCell('Item'),
                          ...widget.budget.locations.map(
                            (loc) => _buildHeaderCell(loc.name),
                          ),
                          _buildHeaderCell('Melhor Local', isGreen: true),
                          _buildHeaderCell('Melhor Preço', isGreen: true),
                        ],
                      ),
                      ...sortedItems.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final item = entry.value;
                        final bestLocation = widget.budget.locations.firstWhere(
                          (loc) => loc.id == item.bestPriceLocation,
                        );

                        return TableRow(
                          children: [
                            _buildCell('$index', isOrderNumber: true),
                            _buildCell(item.name),
                            ...widget.budget.locations.map(
                              (loc) => _buildCell(
                                currencyFormat.format(item.prices[loc.id] ?? 0),
                                isHighlighted:
                                    item.prices[loc.id] == item.bestPrice,
                              ),
                            ),
                            _buildCell(bestLocation.name, isGreen: true),
                            _buildCell(
                              currencyFormat.format(item.bestPrice),
                              isGreen: true,
                            ),
                          ],
                        );
                      }),
                      TableRow(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        children: [
                          _buildCell('-', isOrderNumber: true),
                          _buildCell(
                            'Totais',
                            isHighlighted: true,
                            isTotalRow: true,
                          ),
                          ...widget.budget.locations.map(
                            (loc) => _buildCell(
                              currencyFormat.format(
                                locationTotals[loc.id] ?? 0,
                              ),
                              isHighlighted: true,
                              isTotalRow: true,
                            ),
                          ),
                          _buildCell('-', isHighlighted: true),
                          _buildCell(
                            currencyFormat.format(bestPriceTotal),
                            isGreen: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool isGreen = false}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      alignment: Alignment.center,
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color:
              isGreen ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCell(
    String text, {
    bool isHighlighted = false,
    bool isGreen = false,
    bool isOrderNumber = false,
    bool isTotalRow = false,
  }) {
    final theme = Theme.of(context);

    Color getTextColor() {
      if (isGreen) return theme.colorScheme.primary;
      if (isTotalRow) return theme.colorScheme.secondary;
      if (isHighlighted) return theme.colorScheme.primary;
      return theme.colorScheme.onSurface;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      alignment: isOrderNumber ? Alignment.center : Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: getTextColor(),
          fontWeight: isOrderNumber || isHighlighted || isGreen || isTotalRow
              ? FontWeight.bold
              : null,
        ),
        textAlign: isOrderNumber ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}
