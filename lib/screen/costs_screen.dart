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
    {'icon': Icons.house, 'name': 'Aluguel'},
    {'icon': Icons.shopping_cart, 'name': 'Compras Mensal'},
    {'icon': Icons.wallet_rounded, 'name': 'Energia'},
    {'icon': Icons.wifi, 'name': 'Internet'},
    {'icon': Icons.water_drop, 'name': 'Água'},
    {'icon': Icons.phone_android, 'name': 'Telefone'},
    {'icon': Icons.local_pharmacy, 'name': 'Farmácia'},
    {'icon': Icons.home, 'name': 'Reparos na Moradia'},
    {'icon': Icons.access_alarm_outlined, 'name': 'Alarme'},
    {'icon': Icons.admin_panel_settings, 'name': 'IPVA'},
    {'icon': Icons.compost, 'name': 'IRPF'},
    {'icon': Icons.local_parking, 'name': 'IPTU'},
    {'icon': Icons.monetization_on, 'name': 'Impostos'},
    {'icon': Icons.restaurant, 'name': 'Restaurante'},
    {'icon': Icons.local_grocery_store, 'name': 'Supermercado'},
    {'icon': Icons.pets, 'name': 'Animais de Estimação'},
    {'icon': Icons.medical_services, 'name': 'Saúde'},
    {'icon': Icons.local_hospital, 'name': 'Hospital'},
    {'icon': Icons.local_cafe, 'name': 'Café'},
    {'icon': Icons.movie, 'name': 'Cinema'},
    {'icon': Icons.music_note, 'name': 'Shows'},
    {'icon': Icons.sports_baseball, 'name': 'Esportes'},
    {'icon': Icons.movie, 'name': 'Entretenimento'},
    {'icon': Icons.school, 'name': 'Educação'},
    {'icon': Icons.face, 'name': 'Beleza'},
    {'icon': Icons.sports_soccer, 'name': 'Esportes'},
    {'icon': Icons.people, 'name': 'Social'},
    {'icon': Icons.directions_bus, 'name': 'Transporte'},
    {'icon': Icons.checkroom, 'name': 'Roupas'},
    {'icon': Icons.directions_car, 'name': 'Carro'},
    {'icon': Icons.local_bar, 'name': 'Bebidas Alcoólicas'},
    {'icon': Icons.local_laundry_service, 'name': 'Lavanderia'},
    {'icon': Icons.local_parking, 'name': 'Estacionamento'},
    {'icon': Icons.local_post_office, 'name': 'Correios'},
    {'icon': Icons.local_shipping, 'name': 'Frete'},
    {'icon': Icons.local_activity, 'name': 'Atividades'},
    {'icon': Icons.local_drink, 'name': 'Bebidas não alcoólicas'},
    {'icon': Icons.local_fire_department, 'name': 'Combustível'},
    {'icon': Icons.local_hotel, 'name': 'Hotel'},
    {'icon': Icons.local_mall, 'name': 'Shopping'},
    {'icon': Icons.local_movies, 'name': 'Cinema'},
    {'icon': Icons.local_offer, 'name': 'Promoções'},
    {'icon': Icons.local_parking, 'name': 'Estacionamento'},
    {'icon': Icons.local_post_office, 'name': 'Correios'},
    {'icon': Icons.local_printshop, 'name': 'Impressão'},
    {'icon': Icons.local_play, 'name': 'Jogos'},
    {'icon': Icons.local_printshop, 'name': 'Impressão'},
    {'icon': Icons.local_see, 'name': 'Passeios'},
    {'icon': Icons.local_taxi, 'name': 'Taxi'},
    {'icon': Icons.local_florist, 'name': 'Flores'},
    {'icon': Icons.local_gas_station, 'name': 'Posto de Gasolina'},
    {'icon': Icons.local_hospital, 'name': 'Saúde'},
    {'icon': Icons.local_library, 'name': 'Biblioteca'},
    {'icon': Icons.lock, 'name': 'Segurança'},
    {'icon': Icons.smoking_rooms, 'name': 'Cigarros'},
    {'icon': Icons.devices, 'name': 'Eletrônicos'},
    {'icon': Icons.flight, 'name': 'Viagem'},
    {'icon': Icons.calculate, 'name': 'Estimativa'},
    {'icon': Icons.build, 'name': 'Reparos'},
    {'icon': Icons.house_siding, 'name': 'Manutenção'},
    {'icon': Icons.holiday_village, 'name': 'Férias'},
    {'icon': Icons.hotel, 'name': 'Hotel'},
    {'icon': Icons.local_activity, 'name': 'Atividades'},
    {'icon': Icons.local_airport, 'name': 'Aeroporto'},
    {'icon': Icons.local_atm, 'name': 'Caixa eletrônico'},
    {'icon': Icons.local_bar, 'name': 'Bar'},
    {'icon': Icons.local_cafe, 'name': 'Café da manhã'},
    {'icon': Icons.local_car_wash, 'name': 'Lavagem de carro'},
    {'icon': Icons.local_florist, 'name': 'presentes'},
    {'icon': Icons.favorite, 'name': 'Doações'},
    {'icon': Icons.money, 'name': 'Loteria'},
    {'icon': Icons.fastfood, 'name': 'Lanches'},
    {'icon': Icons.child_care, 'name': 'Filhos'},
    {'icon': Icons.eco, 'name': 'Vegetais'},
    {'icon': Icons.food_bank, 'name': 'Frutas'},
    {'icon': Icons.local_offer, 'name': 'Promoções'},
    {'icon': Icons.account_circle, 'name': 'Assinaturas'},
    {'icon': Icons.account_box, 'name': 'Caixa eletrônico'},
    {'icon': Icons.accessibility_new, 'name': 'Acessórios'},
    {'icon': Icons.security_update_warning, 'name': 'Seguros'},
    {'icon': Icons.airplanemode_active, 'name': 'Passagens aéreas'},
    {'icon': Icons.food_bank, 'name': 'Alimentação'},
    {'icon': Icons.local_offer, 'name': 'Ofertas'},
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Mostrar apenas a descrição, removendo a duplicação
              Text(
                cost.descricaoDaDespesa, // Mantendo apenas a descrição
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
