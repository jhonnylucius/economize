import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/report_service.dart';
// Imports não utilizados removidos
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  List<dynamic> _reportData = [];
  String _selectedType = 'receitas';
  String _selectedSpecificType = 'Todas';
  bool _isLoading = false;
  double _total = 0;
  Map<String, double> _totalsByType = {};
  Map<String, List<String>> _availableTypes = {'receitas': [], 'despesas': []};

  @override
  void initState() {
    super.initState();
    _fetchAvailableTypesAndGenerateReport();
  }

  Future<void> _fetchAvailableTypesAndGenerateReport() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      _availableTypes = await _reportService.getAvailableTypes();
      await _generateReport(isInitialLoad: true);
    } catch (e) {
      if (mounted) {
        _showError('Erro ao buscar tipos iniciais: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateReport({bool isInitialLoad = false}) async {
    if (!isInitialLoad && mounted && !_isLoading) {
      setState(() {
        _isLoading = true;
      });
    } else if (!mounted) {
      return;
    }

    try {
      final now = DateTime.now();
      final period = '${now.month.toString().padLeft(2, '0')}/${now.year}';
      _validateSelectedSpecificTypeOnDemand();

      if (!isInitialLoad) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (!mounted) return;

      final result = await _reportService.generateReport(
        type: _selectedType,
        period: period,
        specificType: _selectedSpecificType,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _reportData = result['items'];
            _total = result['total'];
            _totalsByType = Map<String, double>.from(result['totals']);
            if (result['availableTypes'] != null) {
              _availableTypes = result['availableTypes'];
              _validateSelectedSpecificTypeOnDemand();
            }
          });
        } else {
          _showError('Erro ao gerar relatório: ${result['error']}');
          setState(() {
            _reportData = [];
            _total = 0;
            _totalsByType = {};
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao gerar relatório: $e');
        setState(() {
          _reportData = [];
          _total = 0;
          _totalsByType = {};
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _validateSelectedSpecificTypeOnDemand() {
    final currentList = _availableTypes[
            _selectedType == 'receitas' ? 'receitas' : 'despesas'] ??
        [];
    final validItems = ['Todas', ...currentList.where((t) => t != 'Todas')];
    if (!validItems.contains(_selectedSpecificType)) {
      _selectedSpecificType = 'Todas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveScreen(
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            tooltip: 'Ir para Home',
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      child: _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      children: [
        _buildFilters(), // A cor de fundo branca está aqui dentro
        Divider(
          color: theme.colorScheme.onSurface.withAlpha((0.2 * 255).toInt()),
          height: 1,
        ),
        Expanded(
          child: _buildScrollableArea(theme),
        ),
      ],
    );
  }

  Widget _buildScrollableArea(ThemeData theme) {
    if (_isLoading && _reportData.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }
    if (!_isLoading && _reportData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Nenhum dado encontrado para o período selecionado',
            style: TextStyle(color: theme.colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildTotalsByType(),
        _buildReportListItems(),
        _buildTotal(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilters() {
    final theme = Theme.of(context);

    return Container(
      color: Colors.white, // Mantido fundo branco para a área dos filtros
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'receitas',
                  // --- TEXT STYLE REMOVIDO DAQUI ---
                  label: const Text(
                    'Receitas',
                    // style: TextStyle(...) // Removido
                  ),
                  icon: Icon(
                    Icons.attach_money,
                    // Cor do ícone não selecionado será controlada pelo foregroundColor abaixo
                    color: _selectedType == 'receitas'
                        ? Colors.white // Ícone selecionado branco
                        : Colors.black, // Ícone não selecionado preto
                  ),
                ),
                ButtonSegment(
                  value: 'despesas',
                  // --- TEXT STYLE REMOVIDO DAQUI ---
                  label: const Text(
                    'Despesas',
                    // style: TextStyle(...) // Removido
                  ),
                  icon: Icon(
                    Icons.money_off,
                    // Cor do ícone não selecionado será controlada pelo foregroundColor abaixo
                    color: _selectedType == 'despesas'
                        ? Colors.white // Ícone selecionado branco
                        : Colors.black, // Ícone não selecionado preto
                  ),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<String> newSelection) {
                if (_selectedType != newSelection.first) {
                  setState(() {
                    _selectedType = newSelection.first;
                    _selectedSpecificType = 'Todas';
                  });
                  _generateReport();
                }
              },
              style: SegmentedButton.styleFrom(
                // Cores de fundo mantidas
                backgroundColor: theme.colorScheme.surfaceContainerHighest
                    .withAlpha((0.6 * 255).toInt()),
                selectedBackgroundColor: theme.colorScheme.primaryContainer,
                // --- CORES DO TEXTO/ÍCONE AJUSTADAS ---
                selectedForegroundColor:
                    Colors.white, // Texto/Ícone SELECIONADO = Branco
                foregroundColor:
                    Colors.black, // Texto/Ícone NÃO SELECIONADO = Preto
                textStyle:
                    const TextStyle(fontSize: 16), // Tamanho da fonte mantido
                minimumSize: const Size.fromHeight(45),
              ),
            ),
            const SizedBox(height: 30.0), // Mantido espaço aumentado
            SizedBox(
              width: double.infinity, // Mantida largura explícita
              child: FutureBuilder<Map<String, List<String>>>(
                future: Future.value(_availableTypes),
                builder: (context, snapshot) {
                  // ... (lógica do FutureBuilder e Dropdown inalterada) ...
                  if (!snapshot.hasData || snapshot.data == null) {
                    return SizedBox(
                      height: 60,
                      child: (snapshot.hasError)
                          ? const Center(child: Text('Erro tipos'))
                          : null,
                    );
                  }

                  final typesMap = snapshot.data!;
                  final currentTypeList = typesMap[_selectedType == 'receitas'
                          ? 'receitas'
                          : 'despesas'] ??
                      [];
                  final dropdownItems = [
                    'Todas',
                    ...currentTypeList.where((t) => t != 'Todas')
                  ];
                  final validSelectedValue =
                      dropdownItems.contains(_selectedSpecificType)
                          ? _selectedSpecificType
                          : 'Todas';

                  if (_selectedSpecificType != validSelectedValue) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedSpecificType = validSelectedValue;
                        });
                      }
                    });
                  }

                  return DropdownButtonFormField<String>(
                    value: validSelectedValue,
                    decoration: InputDecoration(
                      labelText: 'Filtrar por Tipo Específico',
                      labelStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(180)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: theme.colorScheme.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: theme.colorScheme.onSurface
                                .withAlpha((0.4 * 255).toInt())),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: theme.colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    isExpanded: true,
                    items: dropdownItems.map((tipo) {
                      return DropdownMenuItem<String>(
                        value: tipo,
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: theme.colorScheme.primary, width: 2),
                                borderRadius: BorderRadius.circular(4),
                                color: validSelectedValue == tipo
                                    ? theme.colorScheme.primary
                                        .withAlpha((0.1 * 255).toInt())
                                    : Colors.transparent,
                              ),
                              child: validSelectedValue == tipo
                                  ? Icon(Icons.check,
                                      size: 18,
                                      color: theme.colorScheme.primary)
                                  : null,
                            ),
                            Expanded(
                              child: Text(
                                tipo,
                                style: TextStyle(
                                  color: validSelectedValue == tipo
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                  fontWeight: validSelectedValue == tipo
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null && value != _selectedSpecificType) {
                        setState(() => _selectedSpecificType = value);
                        _generateReport();
                      }
                    },
                    icon: Icon(
                      Icons.arrow_drop_down_circle,
                      color: theme.colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsByType() {
    // ... (código inalterado) ...
    final theme = Theme.of(context);
    if (_totalsByType.isEmpty) {
      return const SizedBox.shrink();
    }
    final sortedEntries = _totalsByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      margin: const EdgeInsets.all(8),
      color: theme.colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Total por Tipo',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Divider(
              color: theme.colorScheme.onSurface.withAlpha((0.2 * 255).toInt()),
              height: 20,
              thickness: 1,
            ),
            Column(
              children: sortedEntries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _currencyFormat.format(entry.value),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportListItems() {
    // ... (código inalterado) ...
    final theme = Theme.of(context);
    if (_reportData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: List.generate(_reportData.length, (index) {
        final item = _reportData[index];
        final titleText = _selectedType == 'receitas'
            ? (item['descricaoDaReceita'] ?? 'Sem descrição')
            : (item['descricaoDaDespesa'] ?? 'Sem descrição');
        final subtitleText = _selectedType == 'receitas'
            ? (item['tipoReceita'] ?? 'Tipo não especificado')
            : (item['tipoDespesa'] ?? 'Tipo não especificado');
        final amount = item['preco'] ?? 0.0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: theme.colorScheme.surface,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: Icon(
              _selectedType == 'receitas'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: _selectedType == 'receitas' ? Colors.green : Colors.red,
              size: 30,
            ),
            title: Text(
              titleText,
              style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              subtitleText,
              style: TextStyle(
                  color: theme.colorScheme.onSurface
                      .withAlpha((0.7 * 255).toInt())),
            ),
            trailing: Text(
              _currencyFormat.format(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _selectedType == 'receitas'
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTotal() {
    // ... (código inalterado) ...
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: theme.colorScheme.primaryContainer,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total ${_selectedType == 'receitas' ? 'Recebido' : 'Gasto'}',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _currencyFormat.format(_total),
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    // ... (código inalterado) ...
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onError),
        ),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
