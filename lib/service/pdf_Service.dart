import 'dart:io';

import 'package:economize/model/budget/budget.dart';
import 'package:economize/model/budget/budget_item.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<BudgetItem> _getSortedItems(Budget budget) {
    final groupedItems = <String, List<BudgetItem>>{};

    for (var item in budget.items) {
      if (!groupedItems.containsKey(item.bestPriceLocation)) {
        groupedItems[item.bestPriceLocation] = [];
      }
      groupedItems[item.bestPriceLocation]!.add(item);
    }

    groupedItems.forEach((_, items) {
      items.sort((a, b) => a.name.compareTo(b.name));
    });

    final sortedItems = <BudgetItem>[];
    for (var location in budget.locations) {
      if (groupedItems.containsKey(location.id)) {
        sortedItems.addAll(groupedItems[location.id]!);
      }
    }

    return sortedItems;
  }

  Future<File> generatePriceComparisonPdf(Budget budget) async {
    final pdf = pw.Document();

    // Preparar dados
    final headers = [
      'Nº',
      'Item',
      ...budget.locations.map((loc) => loc.name),
      'Melhor Local',
      'Melhor Preço',
    ];

    final sortedItems = _getSortedItems(budget);

    // Gerar linhas
    final rows =
        sortedItems.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          final bestLocation = budget.locations.firstWhere(
            (loc) => loc.id == item.bestPriceLocation,
          );

          return [
            index.toString(),
            item.name,
            ...budget.locations.map(
              (loc) => currencyFormat.format(item.prices[loc.id] ?? 0),
            ),
            bestLocation.name,
            currencyFormat.format(item.bestPrice),
          ];
        }).toList();

    // Adicionar linha de totais
    final locationTotals = <String, double>{};
    final bestPriceTotal = budget.items.fold<double>(
      0,
      (sum, item) => sum + item.bestPrice,
    );

    for (var location in budget.locations) {
      locationTotals[location.id] = budget.items.fold<double>(
        0,
        (sum, item) => sum + (item.prices[location.id] ?? 0),
      );
    }

    rows.add([
      '-',
      'Totais',
      ...budget.locations.map(
        (loc) => currencyFormat.format(locationTotals[loc.id] ?? 0),
      ),
      '-',
      currencyFormat.format(bestPriceTotal),
    ]);

    // Gerar PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build:
            (context) => [
              _buildHeader(budget),
              pw.SizedBox(height: 10),
              _buildSummaryCard(budget),
              pw.SizedBox(height: 16),
              _buildTable(headers, rows),
            ],
      ),
    );

    // Salvar arquivo
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/resumo_orcamento.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildHeader(Budget budget) {
    return pw.Center(
      child: pw.Text(
        'Relatório de Preços - ${budget.title}',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildSummaryCard(Budget budget) {
    return pw.Center(
      child: pw.Container(
        width: 400,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'Resumo Geral',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryItem(
                  'Total Original',
                  currencyFormat.format(budget.summary.totalOriginal),
                  PdfColors.grey700,
                ),
                _buildSummaryItem(
                  'Melhor Preço',
                  currencyFormat.format(budget.summary.totalOptimized),
                  PdfColors.green700,
                ),
                _buildSummaryItem(
                  'Economia',
                  currencyFormat.format(budget.summary.savings),
                  PdfColors.blue700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTable(List<String> headers, List<List<dynamic>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children:
              headers
                  .map(
                    (header) => pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        header,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
        ),
        // Linhas de dados
        ...rows.asMap().entries.map((entry) {
          final isLastRow = entry.key == rows.length - 1;
          return pw.TableRow(
            decoration:
                isLastRow
                    ? const pw.BoxDecoration(color: PdfColors.grey200)
                    : null,
            children:
                entry.value
                    .map(
                      (cell) => pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          cell.toString(),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    )
                    .toList(),
          );
        }),
      ],
    );
  }
}
