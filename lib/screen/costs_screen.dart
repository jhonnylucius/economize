import 'package:economize/icons/my_flutter_app_icons.dart';
import 'package:economize/model/costs.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/costs_service.dart';
import 'package:economize/widgets/category_grid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:uuid/uuid.dart';

class CostsScreen extends StatefulWidget {
  const CostsScreen({super.key});

  @override
  State<CostsScreen> createState() => _CostsScreenState();
}

class _CostsScreenState extends State<CostsScreen> {
  List<Costs> listCosts = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CostsService _costsService = CostsService();
  bool _isLoading = false;

  static const List<Map<String, dynamic>> _categoriasDespesa = [
    {'icon': Icons.shopping_cart, 'name': 'Compras'},
    {'icon': Icons.restaurant, 'name': 'Comida'},
    {'icon': Icons.phone_android, 'name': 'Telefone'},
    {'icon': Icons.movie, 'name': 'Entretenimento'},
    {'icon': Icons.school, 'name': 'Educação'},
    {'icon': Icons.face, 'name': 'Beleza'},
    {'icon': Icons.sports_soccer, 'name': 'Esportes'},
    {'icon': Icons.people, 'name': 'Social'},
    {'icon': Icons.directions_bus, 'name': 'Transporte'},
    {'icon': Icons.checkroom, 'name': 'Roupas'},
    {'icon': Icons.directions_car, 'name': 'Carro'},
    {'icon': Icons.local_bar, 'name': 'Licor'},
    {'icon': Icons.smoking_rooms, 'name': 'Cigarros'},
    {'icon': Icons.devices, 'name': 'Eletrônicos'},
    {'icon': Icons.flight, 'name': 'Viagem'},
    {'icon': Icons.local_hospital, 'name': 'Saúde'},
    {'icon': Icons.calculate, 'name': 'Estimativa'},
    {'icon': Icons.build, 'name': 'Reparos'},
    {'icon': Icons.home, 'name': 'Moradia'},
    {'icon': Icons.house, 'name': 'Lar'},
    {'icon': Icons.card_giftcard, 'name': 'Presentes'},
    {'icon': Icons.favorite, 'name': 'Doações'},
    {'icon': Icons.money, 'name': 'Loteria'},
    {'icon': Icons.fastfood, 'name': 'Lanches'},
    {'icon': Icons.child_care, 'name': 'Filhos'},
    {'icon': Icons.eco, 'name': 'Vegetais'},
    {'icon': Icons.food_bank, 'name': 'Frutas'},
    {'icon': Icons.local_grocery_store, 'name': 'Mercado'},
    {'icon': Icons.pets, 'name': 'Animais'},
    {'icon': Icons.local_offer, 'name': 'Promoções'},
    {'icon': Icons.account_circle, 'name': 'Assinaturas'},
    {'icon': Icons.account_box, 'name': 'Caixa eletrônico'},
    {'icon': Icons.ac_unit_outlined, 'name': 'Ar condicionado'},
    {'icon': Icons.accessibility_new, 'name': 'Acessórios'},
    {'icon': Icons.account_balance_wallet, 'name': 'Carteira'},
    {'icon': Icons.account_tree_outlined, 'name': 'Árvore de natal'},
    {'icon': Icons.access_alarm_outlined, 'name': 'Alarme'},
    {'icon': Icons.admin_panel_settings, 'name': 'IPVA'},
    {'icon': Icons.compost, 'name': 'IRPF'},
    {'icon': Icons.security_update_warning, 'name': 'Seguros'},
    {'icon': Icons.airplanemode_active, 'name': 'Passagens aéreas'},
    {'icon': Icons.add, 'name': 'Outros'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCosts();
  }

  Future<void> _loadCosts() async {
    setState(() => _isLoading = true);
    try {
      final costs = await _costsService.getAllCosts();
      setState(() => listCosts = costs);
    } catch (e) {
      _showErrorDialog('Erro ao carregar despesas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
// Continuação do arquivo costs_screen.dart

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveScreen(
      appBar: AppBar(
        title: const Text('Despesas'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCosts),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/home'),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.extended(
              heroTag: 'add_cost',
              onPressed: () => _showFormModal(),
              icon: const Icon(Icons.add),
              label: const Text('Add Despesas'),
              backgroundColor: theme.colorScheme.onPrimary,
              foregroundColor: theme.colorScheme.primary,
            ),
            FloatingActionButton.extended(
              heroTag: 'goto_revenues',
              onPressed: () => Navigator.pushNamed(context, '/revenues'),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Ir p/ Receitas'),
              backgroundColor: theme.colorScheme.onPrimary,
              foregroundColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      resizeToAvoidBottomInset: true,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (listCosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon_removedbg.png', width: 180, height: 180),
            const SizedBox(height: 16),
            Text(
              'Vamos começar?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registre suas Despesas',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: listCosts.length,
      itemBuilder: (context, index) {
        final cost = listCosts[index];
        return _buildCostCard(cost);
      },
    );
  }

  Widget _buildCostCard(Costs cost) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(cost.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      onDismissed: (_) => _removeCost(cost),
      child: Card(
        elevation: 2,
        color: theme.colorScheme.surface,
        child: ListTile(
          onLongPress: () => _showFormModal(model: cost),
          leading: Icon(
            Icons.money_off,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            DateFormat('dd/MM/yyyy').format(cost.data),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'R\$ ${cost.preco.toStringAsFixed(2)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                cost.tipoDespesa,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withAlpha((0.7 * 255).toInt()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFormModal({Costs? model}) async {
    final theme = Theme.of(context);
    final dataController = TextEditingController(
      text: model != null
          ? DateFormat('dd/MM/yyyy').format(model.data) // Remover o as DateTime
          : DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );
    final precoController = TextEditingController(
      text: model?.preco.toString() ?? '',
    );
    final descricaoController = TextEditingController(
      text: model?.descricaoDaDespesa ?? '',
    );
    String selectedTipo = model?.tipoDespesa ?? _categoriasDespesa[0]['name'];

    final dateFormatter = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {"#": RegExp(r'[0-9]')},
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: dataController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Data',
                          labelStyle:
                              TextStyle(color: theme.colorScheme.onSurface),
                          hintText: '01/01/2025',
                          suffixIcon: IconButton(
                            icon: Icon(MyFlutterApp.calendar_check,
                                color: theme.colorScheme.primary),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                locale: const Locale('pt', 'BR'),
                              );
                              if (date != null) {
                                dataController.text =
                                    "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                              }
                            },
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        inputFormatters: [dateFormatter],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira a data';
                          }
                          try {
                            DateFormat('dd/MM/yyyy').parseStrict(value);
                          } catch (e) {
                            return 'Formato de data inválido (DD/MM/AAAA)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: precoController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Valor',
                          labelStyle:
                              TextStyle(color: theme.colorScheme.onSurface),
                          hintText: '100.00',
                          helperText: 'Use ponto ao invés de vírgula',
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o valor';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor, insira um valor válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      // Remover todo o TextFormField da descrição que estava aqui
                      CategoryGrid(
                        categories: _categoriasDespesa,
                        selectedCategory: selectedTipo,
                        onCategorySelected: (categoria) {
                          setState(() {
                            selectedTipo = categoria;
                            descricaoController.text =
                                categoria; // Adicionar esta linha
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancelar',
                              style:
                                  TextStyle(color: theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(width: 16),
                          FilledButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final cost = Costs(
                                  id: model?.id ?? const Uuid().v4(),
                                  data: DateFormat('dd/MM/yyyy').parse(
                                      dataController
                                          .text), // Usando mesmo formato da receita
                                  preco: double.parse(precoController.text),
                                  descricaoDaDespesa: selectedTipo,
                                  tipoDespesa: selectedTipo,
                                );

                                try {
                                  await _costsService.saveCost(cost);
                                  await _loadCosts();
                                  if (mounted) {
                                    Navigator.pop(context);
                                    _showSuccessSnackBar(
                                        'Despesa salva com sucesso!');
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    _showErrorDialog(
                                        'Erro ao salvar despesa: $e');
                                  }
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                            child: Text(model == null ? 'Salvar' : 'Atualizar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeCost(Costs cost) async {
    try {
      await _costsService.deleteCost(cost.id);
      await Future.delayed(const Duration(milliseconds: 300));
      final updatedCosts = await _costsService.getAllCosts();

      if (mounted) {
        setState(() {
          listCosts = updatedCosts;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Despesa excluída com sucesso!',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erro ao remover despesa: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  void _showErrorDialog(String message) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Erro',
          style: TextStyle(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
