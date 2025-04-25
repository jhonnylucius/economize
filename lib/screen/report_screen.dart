import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/report_service.dart';
import 'package:economize/theme/app_themes.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final period = '${now.month.toString().padLeft(2, '0')}/${now.year}';

      // Adiciona um pequeno delay para garantir que a UI atualize
      await Future.delayed(const Duration(milliseconds: 300));

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
          });
        } else {
          _showError('Erro ao gerar relatório: ${result['error']}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao gerar relatório: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Usa o ResponsiveScreen como widget raiz
    return ResponsiveScreen(
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            // Corrigido para /home
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            tooltip: 'Ir para Home',
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      // Adiciona a localização do FAB, mesmo que não haja um FAB
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // O corpo da tela é passado para o child do ResponsiveScreen
      child: _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    // O conteúdo permanece o mesmo, agora dentro do child do ResponsiveScreen
    return Column(
      children: [
        _buildFilters(),
        Divider(
          color: theme.colorScheme.onSurface.withAlpha((0.2 * 255).toInt()),
        ),
        if (_isLoading)
          Expanded(
            // Adiciona Expanded para centralizar o indicador
            child: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          )
        else if (_reportData.isEmpty)
          Expanded(
            // Adiciona Expanded para centralizar o texto
            child: Center(
              child: Text(
                'Nenhum dado encontrado para o período selecionado',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                _buildTotalsByType(),
                Expanded(child: _buildReportList()),
                _buildTotal(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilters() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'receitas',
                      label: Text(
                        'Receitas',
                        style: TextStyle(
                          color:
                              context.watch<ThemeManager>().currentThemeType ==
                                      ThemeType.light
                                  ? const Color.fromARGB(255, 0, 0, 0)
                                  : const Color.fromARGB(255, 255, 255, 255),
                          fontSize: 16,
                        ),
                      ),
                      icon: Icon(
                        Icons.attach_money,
                        // Cor do ícone ajustada para contraste
                        color:
                            _selectedType == 'receitas'
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withAlpha(
                                  (0.6 * 255).toInt(),
                                ),
                      ),
                    ),
                    ButtonSegment(
                      value: 'despesas',
                      label: Text(
                        'Despesas',
                        style: TextStyle(
                          color:
                              context.watch<ThemeManager>().currentThemeType ==
                                      ThemeType.light
                                  ? const Color.fromARGB(255, 0, 0, 0)
                                  : const Color.fromARGB(255, 255, 255, 255),
                          fontSize: 16,
                        ),
                      ),
                      icon: Icon(
                        Icons.money_off,
                        // Cor do ícone ajustada para contraste
                        color:
                            _selectedType == 'despesas'
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withAlpha(
                                  (0.6 * 255).toInt(),
                                ),
                      ),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                      _selectedSpecificType = 'Todas';
                    });
                    _generateReport();
                  },
                  style: SegmentedButton.styleFrom(
                    // Cor de fundo dos segmentos não selecionados
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withAlpha((0.6 * 255).toInt()),
                    // Cor de fundo do segmento selecionado
                    selectedBackgroundColor: theme.colorScheme.primaryContainer,
                    // Cor do texto/ícone do segmento selecionado
                    selectedForegroundColor:
                        theme.colorScheme.onPrimaryContainer,
                    // Cor do texto/ícone dos segmentos não selecionados
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<Map<String, List<String>>>(
            future: _reportService.getAvailableTypes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final types =
                  snapshot.data![_selectedType == 'receitas'
                      ? 'receitas'
                      : 'despesas'] ??
                  [];
              // Garante que 'Todas' esteja sempre presente e seja a primeira opção
              final dropdownItems = [
                'Todas',
                ...types.where((t) => t != 'Todas'),
              ];

              return DropdownButtonFormField<String>(
                value: _selectedSpecificType,
                decoration: InputDecoration(
                  labelText: 'Filtrar por Tipo Específico', // Adiciona um label
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      8,
                    ), // Bordas arredondadas
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    // Borda quando não focado
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.onSurface.withAlpha(
                        (0.4 * 255).toInt(),
                      ),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    // Borda quando focado
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                ),
                dropdownColor: theme.colorScheme.surface,
                isExpanded: true,
                items:
                    dropdownItems.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Row(
                          children: [
                            // Checkbox visual
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                // Cor de fundo se selecionado
                                color:
                                    _selectedSpecificType == tipo
                                        ? theme.colorScheme.primary.withAlpha(
                                          (0.1 * 255).toInt(),
                                        )
                                        : Colors.transparent,
                              ),
                              child:
                                  _selectedSpecificType == tipo
                                      ? Icon(
                                        Icons.check,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      )
                                      : null,
                            ),
                            // Texto do item
                            Text(
                              tipo,
                              style: TextStyle(
                                color:
                                    _selectedSpecificType == tipo
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                fontWeight:
                                    _selectedSpecificType == tipo
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
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
        ],
      ),
    );
  }

  Widget _buildTotalsByType() {
    final theme = Theme.of(context);

    // Retorna um SizedBox se não houver totais por tipo para exibir
    if (_totalsByType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8),
      color: theme.colorScheme.surface,
      elevation: 2, // Adiciona uma leve sombra
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Bordas arredondadas
      child: Padding(
        padding: const EdgeInsets.all(12), // Aumenta o padding interno
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Total por Tipo',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold, // Deixa o título em negrito
              ),
              textAlign: TextAlign.center,
            ),
            Divider(
              color: theme.colorScheme.onSurface.withAlpha((0.2 * 255).toInt()),
              height: 20, // Aumenta a altura (espaçamento) do divisor
              thickness: 1, // Espessura do divisor
            ),
            // Usa ListView.builder para melhor performance se houver muitos tipos
            ListView.separated(
              shrinkWrap: true, // Para usar dentro de um Column
              physics:
                  const NeverScrollableScrollPhysics(), // Desabilita scroll interno
              itemCount: _totalsByType.length,
              itemBuilder: (context, index) {
                final entry =
                    (_totalsByType.entries.toList()..sort(
                      (a, b) => b.value.compareTo(a.value),
                    ))[index]; // Ordena por valor decrescente
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                  ), // Ajusta padding vertical
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        // Permite que o nome do tipo quebre a linha se necessário
                        child: Text(
                          entry.key,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          overflow:
                              TextOverflow
                                  .ellipsis, // Adiciona "..." se for muito longo
                        ),
                      ),
                      const SizedBox(width: 16), // Espaço entre nome e valor
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
              },
              separatorBuilder:
                  (context, index) => Divider(
                    // Divisor entre os itens
                    color: theme.colorScheme.onSurface.withAlpha(
                      (0.1 * 255).toInt(),
                    ),
                    height: 1,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList() {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8), // Adiciona padding inferior
      itemCount: _reportData.length,
      itemBuilder: (context, index) {
        final item = _reportData[index];
        // Determina os textos com base no tipo (receita/despesa)
        final titleText =
            _selectedType == 'receitas'
                ? item.descricaoDaReceita
                : item.descricaoDaDespesa ?? 'Sem descrição';
        final subtitleText =
            _selectedType == 'receitas' ? item.tipoReceita : item.tipoDespesa;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: theme.colorScheme.surface,
          elevation: 1, // Sombra sutil
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ), // Bordas arredondadas
          child: ListTile(
            // Ícone principal baseado no tipo
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
                fontWeight: FontWeight.w500, // Peso médio
              ),
              maxLines: 2, // Limita a 2 linhas
              overflow: TextOverflow.ellipsis, // Adiciona "..." se exceder
            ),
            subtitle: Text(
              subtitleText,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.7 * 255).toInt(),
                ),
              ),
            ),
            trailing: Text(
              _currencyFormat.format(item.preco),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                // Cor baseada no tipo
                color:
                    _selectedType == 'receitas'
                        ? theme
                            .colorScheme
                            .primary // Roxo para receita
                        : theme.colorScheme.error, // Vermelho para despesa
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotal() {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8),
      // Cor de destaque para o total
      color: theme.colorScheme.primaryContainer,
      elevation: 4, // Sombra mais pronunciada
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Bordas arredondadas
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ), // Ajusta padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total ${_selectedType == 'receitas' ? 'Recebido' : 'Gasto'}',
              style: TextStyle(
                // Cor de texto que contrasta com primaryContainer
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _currencyFormat.format(_total),
              style: TextStyle(
                // Cor de texto que contrasta com primaryContainer
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
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onError),
        ),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating, // SnackBar flutuante
        margin: const EdgeInsets.all(8), // Margem para SnackBar flutuante
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ), // Bordas arredondadas
      ),
    );
  }
}
