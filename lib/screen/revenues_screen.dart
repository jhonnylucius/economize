import 'package:economize/icons/my_flutter_app_icons.dart';
import 'package:economize/model/revenues.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/revenues_service.dart';
import 'package:economize/widgets/category_grid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:uuid/uuid.dart';

class RevenuesScreen extends StatefulWidget {
  const RevenuesScreen({super.key});

  @override
  State<RevenuesScreen> createState() => _RevenuesScreenState();
}

class _RevenuesScreenState extends State<RevenuesScreen> {
  List<Revenues> listRevenues = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RevenuesService _revenuesService = RevenuesService();
  bool _isLoading = false;

  static const List<Map<String, dynamic>> _categoriasReceita = [
    {'icon': Icons.credit_card, 'name': 'Salário'},
    {'icon': Icons.savings, 'name': 'Investimentos'},
    {'icon': Icons.schedule, 'name': 'Meio Período'},
    {'icon': Icons.card_giftcard, 'name': 'Prêmios'},
    {'icon': Icons.business, 'name': 'Empreendimentos'},
    {'icon': Icons.attach_money, 'name': 'Vendas'},
    {'icon': Icons.monetization_on, 'name': 'Comissões'},
    {'icon': Icons.paid, 'name': 'Pagamentos'},
    {'icon': Icons.gif, 'name': 'Doações'},
    {'icon': Icons.work, 'name': 'Freelancer'},
    {'icon': Icons.business_center, 'name': 'Consultoria'},
    {'icon': Icons.emoji_events, 'name': 'Bônus'},
    {'icon': Icons.local_offer, 'name': 'Promoções'},
    {'icon': Icons.local_activity, 'name': 'Eventos'},
    {'icon': Icons.more_horiz, 'name': 'Outros'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRevenues();
  }

  Future<void> _loadRevenues() async {
    setState(() => _isLoading = true);
    try {
      final revenues = await _revenuesService.getAllRevenues();
      setState(() => listRevenues = revenues);
    } catch (e) {
      _showErrorDialog('Erro ao carregar receitas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveScreen(
      appBar: AppBar(
        title: const Text('Receitas'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRevenues),
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
              heroTag: 'add_revenue',
              onPressed: () => _showFormModal(),
              icon: const Icon(Icons.add),
              label: const Text('Add Receitas'),
              backgroundColor: theme.colorScheme.onPrimary,
              foregroundColor: theme.colorScheme.primary,
            ),
            FloatingActionButton.extended(
              heroTag: 'goto_costs',
              onPressed: () => Navigator.pushNamed(context, '/costs'),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Ir p/ Despesas'),
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

    if (listRevenues.isEmpty) {
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
              'Registre suas Receitas',
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
      itemCount: listRevenues.length,
      itemBuilder: (context, index) {
        final revenue = listRevenues[index];
        return _buildRevenueCard(revenue);
      },
    );
  }

  Widget _buildRevenueCard(Revenues revenue) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(revenue.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      onDismissed: (_) => _removeRevenue(revenue),
      child: Card(
        elevation: 2,
        color: theme.colorScheme.surface,
        child: ListTile(
          onLongPress: () => _showFormModal(model: revenue),
          leading: Icon(
            Icons.attach_money,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            DateFormat('dd/MM/yyyy').format(revenue.data),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'R\$ ${revenue.preco.toStringAsFixed(2)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Mostrar apenas a descrição, removendo duplicação
              Text(
                revenue.descricaoDaReceita, // Manter apenas a descrição
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

  Future<void> _showFormModal({Revenues? model}) async {
    final theme = Theme.of(context);
    final dataController = TextEditingController(
      text: model != null
          ? DateFormat('dd/MM/yyyy').format(model.data)
          : DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );
    final precoController = TextEditingController(
      text: model?.preco.toString() ?? '',
    );
    final descricaoController = TextEditingController(
      text: model?.descricaoDaReceita ?? '',
    );
    String selectedTipo = model?.tipoReceita ?? _categoriasReceita[0]['name'];

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
                      CategoryGrid(
                        categories: _categoriasReceita,
                        selectedCategory: selectedTipo,
                        onCategorySelected: (categoria) {
                          setState(() {
                            selectedTipo = categoria;
                            descricaoController.text =
                                categoria; // Atualiza descrição automaticamente
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
                                final revenue = Revenues(
                                  id: model?.id ?? const Uuid().v4(),
                                  data: DateFormat('dd/MM/yyyy')
                                      .parse(dataController.text),
                                  preco: double.parse(precoController.text),
                                  descricaoDaReceita: descricaoController.text,
                                  tipoReceita: selectedTipo,
                                );

                                try {
                                  await _revenuesService.saveRevenue(revenue);
                                  await _loadRevenues();
                                  if (mounted) {
                                    Navigator.pop(context);
                                    _showSuccessSnackBar(
                                        'Receita salva com sucesso!');
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    _showErrorDialog(
                                        'Erro ao salvar receita: $e');
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

  Future<void> _removeRevenue(Revenues revenue) async {
    try {
      await _revenuesService.deleteRevenue(revenue.id);
      await Future.delayed(const Duration(milliseconds: 300));
      final updatedRevenues = await _revenuesService.getAllRevenues();

      if (mounted) {
        setState(() {
          listRevenues = updatedRevenues;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Receita excluída com sucesso!',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erro ao remover receita: $e');
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
