import 'package:economize/model/budget/budget.dart';
import 'package:economize/model/budget/budget_item.dart';
import 'package:economize/model/budget/price_history.dart';
import 'package:economize/service/budget_service.dart';
import 'package:economize/service/price_history_service.dart';
import 'package:economize/theme/app_themes.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:economize/utils/budget_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BudgetItemCard extends StatefulWidget {
  final BudgetItem item;
  final Map<String, String> locationNames;
  final VoidCallback? onDelete;
  final Function(String, double)? onPriceUpdate;
  final String budgetId;
  final Budget budget;
  final Function(bool)? onEditingStateChange;
  final BudgetService budgetService;
  final PriceHistoryService priceHistoryService;

  const BudgetItemCard({
    super.key,
    required this.item,
    required this.locationNames,
    this.onDelete,
    this.onPriceUpdate,
    required this.budgetId,
    required this.budget,
    this.onEditingStateChange,
    required this.budgetService,
    required this.priceHistoryService,
  });

  @override
  State<BudgetItemCard> createState() => _BudgetItemCardState();
}

class _BudgetItemCardState extends State<BudgetItemCard> {
  bool _isEditing = false;
  final Map<String, TextEditingController> _priceControllers = {};
  bool _hasChanges = false;
  late TextEditingController _quantityController;
  late String _selectedUnit;
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var entry in widget.locationNames.entries) {
      _priceControllers[entry.key] = TextEditingController(
        text: widget.item.prices[entry.key]?.toString() ?? '',
      )..addListener(() => _checkChanges());
    }

    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    )..addListener(() => _checkChanges());

    _selectedUnit = widget.item.unit;
  }

  void _checkChanges() {
    if (!mounted) return;
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    try {
      // Primeiro salva as alterações
      final newQuantity =
          double.tryParse(_quantityController.text) ?? widget.item.quantity;
      final oldUnit = widget.item.unit;
      final newUnit = _selectedUnit;

      final Map<String, double> newPrices = {};

      for (var entry in _priceControllers.entries) {
        final price = double.tryParse(_priceControllers[entry.key]!.text);
        if (price != null) {
          if (oldUnit != newUnit) {
            newPrices[entry.key] = BudgetUtils.convertUnit(
              price,
              oldUnit,
              newUnit,
            );
          } else {
            newPrices[entry.key] = price;
          }
        }
      }

      // Atualiza o item no banco
      await widget.budgetService.updateItemPrice(
        widget.budgetId,
        widget.item.id,
        newPrices,
        newQuantity,
        newUnit,
      );

      // Registra histórico de preços
      for (var entry in newPrices.entries) {
        if (widget.item.prices[entry.key] != entry.value) {
          await widget.priceHistoryService.registerPrice(
            PriceHistory(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              itemId: widget.item.id,
              locationId: entry.key,
              price: entry.value,
              date: DateTime.now(),
            ),
          );
        }
      }

      // Pequeno delay antes de atualizar
      await Future.delayed(const Duration(milliseconds: 300));

      // Força atualização completa do orçamento
      final updatedBudget = await widget.budgetService.getBudget(
        widget.budgetId,
      );
      if (updatedBudget != null && mounted) {
        setState(() {
          widget.budget.items = updatedBudget.items;
          widget.budget.locations = updatedBudget.locations;
          widget.budget.summary = updatedBudget.summary;
        });
      }

      setState(() {
        _isEditing = false;
        _hasChanges = false;
      });

      widget.onEditingStateChange?.call(false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar alterações: $e')));
    }
  }

  Widget _buildUnitSelector() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                enabled: _isEditing,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  isDense: true,
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _selectedUnit,
              dropdownColor: theme.colorScheme.surface,
              style: TextStyle(color: theme.colorScheme.onSurface),
              onChanged: _isEditing
                  ? (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedUnit = newValue;
                          _hasChanges = true;
                        });
                      }
                    }
                  : null,
              items: const [
                DropdownMenuItem(value: 'un', child: Text('Unidade')),
                DropdownMenuItem(value: 'kg', child: Text('Quilograma')),
                DropdownMenuItem(value: 'g', child: Text('Grama')),
                DropdownMenuItem(value: 'L', child: Text('Litro')),
                DropdownMenuItem(value: 'ml', child: Text('Mililitro')),
                DropdownMenuItem(value: 'par', child: Text('Par')),
                DropdownMenuItem(value: 'cx', child: Text('Caixa')),
                DropdownMenuItem(value: 'pct', child: Text('Pacote')),
                DropdownMenuItem(value: 'band', child: Text('Bandeja')),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceInput(String locationId, double? currentPrice) {
    context.watch<ThemeManager>();
    final appThemes = AppThemes();

    if (_isEditing) {
      // Modo edição - campo de entrada com borda e fundo consistente
      return TextFormField(
        controller: _priceControllers[locationId],
        enabled: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixText: 'R\$ ',
          prefixStyle: TextStyle(color: appThemes.getInputTextColor()),
          isDense: true,
          filled: true,
          fillColor: appThemes.getInputBackgroundColor(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: appThemes.getCardBorderColor(),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: appThemes.getCardBorderColor(),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: appThemes.getInputFocusBorderColor(),
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        style: TextStyle(color: appThemes.getInputTextColor()),
        cursorColor: appThemes.getInputCursorColor(),
      );
    } else {
      // Modo visualização - apenas mostra o preço com borda consistente
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: appThemes.getCardBorderColor(),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
          color: appThemes.getCardBackgroundColor(),
        ),
        child: Text(
          currentPrice != null
              ? currencyFormat.format(currentPrice)
              : 'R\$ 0,00',
          style: TextStyle(
            color: appThemes.getCardTextColor(),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Cancelar edição - restaurar valores originais
        _initializeControllers();
        _hasChanges = false;
      }
      _isEditing = !_isEditing;
      widget.onEditingStateChange?.call(_isEditing);
    });
  }

  void _showHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height:
              MediaQuery.of(context).size.height * 0.8, // Aumentado para 80%
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Comparativo de Preços',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Table(
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      columnWidths: {
                        0: const FixedColumnWidth(100), // Item
                        for (var i = 0; i < widget.locationNames.length; i++)
                          i + 1: const FixedColumnWidth(85), // Locais
                        widget.locationNames.length + 1:
                            const FixedColumnWidth(85), // Melhor Local
                        widget.locationNames.length + 2:
                            const FixedColumnWidth(85), // Melhor Preço
                      },
                      children: [
                        // Cabeçalho
                        TableRow(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          children: [
                            _buildTableCell('Item', isHeader: true),
                            ...widget.locationNames.entries.map(
                              (entry) => _buildTableCell(
                                entry.value,
                                isHeader: true,
                              ),
                            ),
                            _buildTableCell(
                              'Melhor Local',
                              isHeader: true,
                              isGreen: true,
                            ),
                            _buildTableCell(
                              'Melhor Preço',
                              isHeader: true,
                              isGreen: true,
                            ),
                          ],
                        ),
                        // Linhas para todos os itens do orçamento
                        ...widget.budget.items.map(
                          (budgetItem) => TableRow(
                            children: [
                              _buildTableCell(budgetItem.name),
                              ...widget.locationNames.entries.map((entry) {
                                final price = budgetItem.prices[entry.key] ?? 0;
                                return _buildTableCell(
                                  currencyFormat.format(price),
                                  isGreen: price == budgetItem.bestPrice,
                                );
                              }),
                              _buildTableCell(
                                widget.locationNames[
                                        budgetItem.bestPriceLocation] ??
                                    'N/A',
                                isGreen: true,
                              ),
                              _buildTableCell(
                                currencyFormat.format(budgetItem.bestPrice),
                                isGreen: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isGreen = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : null,
          color:
              isGreen ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final theme = themeManager.currentTheme;

    if (_priceControllers.isEmpty) {
      _initializeControllers();
    }

    return Card(
      // Adicione esta linha para cortar o conteúdo interno:
      clipBehavior: Clip.antiAlias,
      // A cor e a forma já vêm do cardTheme, não precisa mexer aqui.
      child: ExpansionPanelList(
        elevation: 0,
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            _isExpanded = isExpanded;
          });
        },
        materialGapSize: 0,
        children: [
          ExpansionPanel(
            // Adicione esta linha para garantir o fundo branco do painel:
            backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
            canTapOnHeader: true,
            headerBuilder: (BuildContext context, bool isExpanded) {
              // Seu método _buildHeader existente
              return _buildHeader(context, isExpanded);
            },
            body: _buildBody(), // <<< USA O SEU MÉTODO _buildBody() EXISTENTE
            isExpanded: _isExpanded,
          ),
        ],
      ),
    );
  }

  // Construir o cabeçalho do card
  Widget _buildHeader(BuildContext context, bool isExpanded) {
    return Padding(
      // Trocado ListTile por Padding
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(),
          _buildPriceInfo(),
          _buildStatusInfo(),
          _buildPriceAlerts(),
        ],
      ),
    );
  }

  // Construir linha do título com botões
  Widget _buildTitleRow() {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.item.name,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.history, color: theme.colorScheme.primary),
              onPressed: () => _showHistory(context),
            ),
            if (widget.onDelete != null)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                onPressed: widget.onDelete,
              ),
          ],
        ),
      ],
    );
  }

  // Construir informações de preço
  Widget _buildPriceInfo() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Melhor preço: ${currencyFormat.format(widget.item.bestPrice)}',
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        if (widget.item.unit != 'un')
          Text(
            'Preço por unidade: ${currencyFormat.format(BudgetUtils.calculatePricePerUnit(widget.item.bestPrice, widget.item.quantity, widget.item.unit))} / ${widget.item.unit}',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(
                alpha: (0.7 * 255).toDouble(),
              ),
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  // Construir informações de status
  Widget _buildStatusInfo() {
    final theme = Theme.of(context);
    final completedLocations =
        widget.item.prices.values.where((price) => price > 0).length;
    final isComplete = completedLocations == widget.locationNames.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Locais orçados: $completedLocations/${widget.locationNames.length}',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(
              alpha: (0.7 * 255).toDouble(),
            ),
            fontSize: 12,
          ),
        ),
        if (isComplete) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                'Concluído',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Construir alertas de preço
  Widget _buildPriceAlerts() {
    final theme = Theme.of(context);
    return StreamBuilder<List<PriceHistory>>(
      stream: Stream.fromFuture(
        widget.priceHistoryService.getSignificantVariations(
          threshold: 5.0,
          days: 30,
        ),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final variations =
            snapshot.data!.where((h) => h.itemId == widget.item.id).toList();

        if (variations.isEmpty) return const SizedBox.shrink();

        return Text(
          'Variação significativa detectada!',
          style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
        );
      },
    );
  }

  // Construir corpo do card
  Widget _buildBody() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUnitSelector(),
          const SizedBox(height: 16),
          Text(
            'Preços por Local:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildPriceInputs(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  // Construir inputs de preço
  List<Widget> _buildPriceInputs() {
    final theme = Theme.of(context);
    return widget.locationNames.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              flex: 2, // Define proporção para o nome do local
              child: Text(
                entry.value,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
            SizedBox(
              width: 180, // Aumentado de 100 para 200
              child: _buildPriceInput(entry.key, widget.item.prices[entry.key]),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Construir botões de ação
  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    context
        .read<ThemeManager>(); // Use read se não precisar ouvir mudanças aqui

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botão Editar/Cancelar
        ElevatedButton.icon(
          onPressed: _toggleEdit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary, // Mantém para o texto
          ),
          icon: Icon(
            _isEditing ? Icons.cancel : Icons.edit,
            color: theme
                .colorScheme.onPrimary, // <<< ADICIONE A COR AQUI DIRETAMENTE
          ),
          label: Text(
            _isEditing ? 'Cancelar' : 'Editar',
          ), // O texto já deve pegar a foregroundColor
        ),

        // Botão Salvar (se estiver editando)
        if (_isEditing) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _hasChanges
                ? _saveChanges
                : null, // Desabilita se não houver mudanças
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  Colors.grey[400], // Cor quando desabilitado
            ),
            icon: const Icon(
              Icons.save,
              color: Colors.white, // <<< Defina a cor aqui também se necessário
            ),
            label: const Text('Salvar'),
          ),
        ],
      ],
    );
  }
}
