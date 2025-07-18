import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/accounts/service/account_service.dart';
import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/features/financial_education/utils/currency_input_formatter.dart';
import 'package:economize/model/costs.dart';
import 'package:economize/model/gamification/achievement.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/costs_service.dart';
import 'package:economize/service/gamification/achievement_service.dart';
import 'package:economize/service/moedas/currency_service.dart';
import 'package:economize/service/notification_service.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:economize/widgets/category_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

class CostsScreen extends StatefulWidget {
  const CostsScreen({super.key});

  @override
  State<CostsScreen> createState() => _CostsScreenState();
}

class _CostsScreenState extends State<CostsScreen>
    with SingleTickerProviderStateMixin {
  List<Costs> listCosts = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CostsService _costsService = CostsService();
  final AccountService _accountService = AccountService(); // <-- Adicionado
  bool _isLoading = false;
  bool _isFiltering = false;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  late AnimationController _animationController;
  final GlobalKey _helpKey = GlobalKey();
  late CurrencyService _currencyService;

  // Categorias (sem alteração)
  static const List<Map<String, dynamic>> _categoriasDespesa = [
    {'icon': Icons.house, 'name': 'Aluguel'},
    {'icon': Icons.shopping_cart, 'name': 'Compras Mensal'},
    {'icon': Icons.wallet_rounded, 'name': 'Energia'},
    {'icon': Icons.wifi, 'name': 'Internet'},
    {'icon': Icons.water_drop, 'name': 'Água'},
    {'icon': Icons.local_fire_department, 'name': 'Gás de Cozinha'},
    {'icon': Icons.local_phone, 'name': 'Telefone Fixo'},
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
    {
      'icon': Icons.transfer_within_a_station,
      'name': 'Transferências entre contas'
    },
    {'icon': Icons.movie, 'name': 'Cinema'},
    {'icon': Icons.card_giftcard, 'name': 'Presentes'},
    {'icon': Icons.card_membership, 'name': 'Assinaturas'},
    {'icon': Icons.shopping_bag, 'name': 'Compras Online'},
    {'icon': Icons.credit_card, 'name': 'Cartão de Crédito'},
    {'icon': Icons.attach_money, 'name': 'Empréstimos'},
    {'icon': Icons.money_off, 'name': 'Dívidas'},
    {'icon': Icons.account_balance, 'name': 'Banco'},
    {'icon': Icons.receipt_long, 'name': 'Recibos'},
    {'icon': Icons.receipt, 'name': 'Notas Fiscais'},
    {'icon': Icons.payment, 'name': 'Pagamento Boleto'},
    {'icon': Icons.payments, 'name': 'Pagamento Pix'},
    {'icon': Icons.credit_card, 'name': 'Pagamento Cartão de Débito'},
    {'icon': Icons.cloud, 'name': 'Serviços em Nuvem'},
    {'icon': Icons.security, 'name': 'Seguro de Vida'},
    {'icon': Icons.home_work, 'name': 'Seguro Residencial'},
    {'icon': Icons.directions_car, 'name': 'Seguro de Carro'},
    {'icon': Icons.computer, 'name': 'Computador/Notebook'},
    {'icon': Icons.desktop_windows, 'name': 'Desktop'},
    {'icon': Icons.keyboard, 'name': 'Teclado'},
    {'icon': Icons.mouse, 'name': 'Mouse'},
    {'icon': Icons.usb, 'name': 'Hub USB'},
    {'icon': Icons.fitness_center, 'name': 'Academia'},
    {'icon': Icons.spa, 'name': 'Depilação'},
    {'icon': Icons.brush, 'name': 'Manicure'},
    {'icon': Icons.content_cut, 'name': 'Cabeleireiro'},
    {'icon': Icons.school, 'name': 'Educação/Cursos'},
    {'icon': Icons.emoji_transportation, 'name': 'Transporte'},
    {'icon': Icons.flight, 'name': 'Viagens'},
    {'icon': Icons.sports_soccer, 'name': 'Esportes'},
    {'icon': Icons.child_friendly, 'name': 'Despesas com Filhos'},
    {'icon': Icons.local_bar, 'name': 'Lazer/Bar'},
    {'icon': Icons.fastfood, 'name': 'Lanches'},
    {'icon': Icons.videogame_asset, 'name': 'Jogos'},
    {'icon': Icons.subscriptions, 'name': 'Assinaturas'},
    {'icon': Icons.tv, 'name': 'Streaming TV'},
    {'icon': Icons.library_books, 'name': 'Livros'},
    {'icon': Icons.music_note, 'name': 'Música'},
    {'icon': Icons.healing, 'name': 'Psicólogo/Terapia'},
    {'icon': Icons.payments, 'name': 'Pagamentos Diversos'},
    {'icon': Icons.more_horiz, 'name': 'Outros'},
  ];
  static const List<String> _categoriasRecorrentes = [
    'Aluguel',
    'Energia',
    'Internet',
    'Água',
    'Gás de Cozinha',
    'Telefone',
    'Alarme',
    'Compras Mensal',
    'Farmácia',
    'IPVA',
    'IRPF',
    'IPTU',
    'Impostos',
    'Supermercado',
    'Animais de Estimação',
    'Saúde',
    'Hospital',
    'Serviços em Nuvem',
    'Seguro de Vida',
    'Seguro Residencial',
    'Seguro de Carro',
    'Cartão de Crédito',
    'Empréstimos',
    'Dívidas',
    'Banco',
    'Pagamento Boleto',
    'Pagamento Pix',
    'Pagamento Cartão de Débito',
    'Academia',
    'Depilação',
    'Manicure',
    'Cabeleireiro',
    'Educação/Cursos',
    'Transporte',
    'Streaming TV',
    'Assinaturas',
  ];

  bool _isRecurrentCategory(String category) {
    return _categoriasRecorrentes.contains(category);
  }

  @override
  void initState() {
    super.initState();
    _currencyService = context.read<CurrencyService>();
    _loadCosts();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCosts() async {
    setState(() => _isLoading = true);
    try {
      final costs = await _costsService.getAllCosts();

      // ✅ NOVA ORDENAÇÃO: Não pagas por vencimento + Pagas por data
      costs.sort((a, b) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Categorizar as despesas
        bool aVencida = !a.pago && a.data.isBefore(today);
        bool bVencida = !b.pago && b.data.isBefore(today);
        bool aProxima =
            !a.pago && !aVencida && a.data.difference(today).inDays <= 5;
        bool bProxima =
            !b.pago && !bVencida && b.data.difference(today).inDays <= 5;

        // 1. Vencidas primeiro (ordenadas por vencimento - mais atrasadas primeiro)
        if (aVencida && bVencida) return a.data.compareTo(b.data);
        if (aVencida && !bVencida) return -1;
        if (!aVencida && bVencida) return 1;

        // 2. Próximas ao vencimento (ordenadas por vencimento)
        if (aProxima && bProxima) return a.data.compareTo(b.data);
        if (aProxima && !bProxima) return -1;
        if (!aProxima && bProxima) return 1;

        // 3. Outras não pagas (ordenadas por vencimento)
        if (!a.pago && !b.pago) return a.data.compareTo(b.data);
        if (!a.pago && b.pago) return -1;
        if (a.pago && !b.pago) return 1;

        // 4. Pagas por último (mais recentes primeiro)
        return b.data.compareTo(a.data);
      });

      if (mounted) {
        setState(() => listCosts = costs);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erro ao carregar despesas: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Costs> _getFilteredCosts() {
    return listCosts.where((cost) {
      // Filtro por texto
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final descLower = cost.descricaoDaDespesa.toLowerCase();
        final tipoLower = cost.tipoDespesa.toLowerCase();
        final dataFormatada =
            DateFormat('dd/MM/yyyy').format(cost.data).toLowerCase();
        final valorFormatado = cost.preco.toString().toLowerCase();

        if (!descLower.contains(searchLower) &&
            !tipoLower.contains(searchLower) &&
            !dataFormatada.contains(searchLower) &&
            !valorFormatado.contains(searchLower)) {
          return false;
        }
      }

      // Filtro por intervalo de data
      if (_startDate != null && cost.data.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null &&
          cost.data.isAfter(DateTime(
              _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59))) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final theme = Theme.of(context);
    // Sempre considerar tema claro, independente da configuração do app
    final isDarkTheme = false;

    return ResponsiveScreen(
      appBar: _buildAppBar(theme, themeManager, isDarkTheme),
      backgroundColor: Colors.white, // Sempre branco, independente do tema
      floatingActionButton: _buildFloatingActionButtons(themeManager),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      resizeToAvoidBottomInset: true,
      child: _buildBody(themeManager),
    );
  }

  AppBar _buildAppBar(
      ThemeData theme, ThemeManager themeManager, bool isDarkTheme) {
    return AppBar(
      title: SlideAnimation.fromTop(
        child: const Text(
          'Despesas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white, // Sempre branco
          ),
        ),
      ),
      backgroundColor: themeManager.getCurrentPrimaryColor(),
      foregroundColor: Colors.white, // Garante que os ícones sejam brancos
      elevation: 0,
      actions: [
        SlideAnimation.fromTop(
          delay: const Duration(milliseconds: 100),
          child: IconButton(
            tooltip: "Filtrar despesas",
            icon: AnimatedIcon(
              icon: AnimatedIcons.search_ellipsis,
              progress: _animationController,
              color: Colors.white, // Garante que o ícone seja branco
            ),
            onPressed: () {
              setState(() {
                _isFiltering = !_isFiltering;
                if (_isFiltering) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                  // Limpar filtros
                  _searchQuery = '';
                  _startDate = null;
                  _endDate = null;
                }
              });
            },
          ),
        ),
        SlideAnimation.fromTop(
          delay: const Duration(milliseconds: 150),
          child: IconButton(
            tooltip: "Atualizar lista",
            icon: const Icon(
              Icons.refresh,
              color: Colors.white, // Garante que o ícone seja branco
            ),
            onPressed: _loadCosts,
          ),
        ),
        SlideAnimation.fromTop(
          delay: const Duration(milliseconds: 200),
          child: IconButton(
            key: _helpKey, // Chave para tutorial
            tooltip: 'Ajuda', // Texto do tooltip
            icon: const Icon(
              Icons.help_outline, // Ícone de ajuda
              color: Colors.white,
            ),
            onPressed: () => _showCostsScreenHelp(context),
          ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: _isFiltering ? _buildFilterBar(themeManager) : null,
    );
  }

  // Adicione este método na classe _CostsScreenState
  void _showCostsScreenHelp(BuildContext context) {
    context.read<ThemeManager>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GlassContainer(
            frostedEffect: true,
            blur: 10,
            opacity: 0.2,
            borderRadius: 24,
            borderColor: Colors.white.withAlpha((0.3 * 255).round()),
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho
                    SlideAnimation.fromTop(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                const Color.fromARGB(255, 216, 78, 196),
                            child: Icon(
                              Icons.payments_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Gerenciamento de Despesas",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Como controlar seus gastos",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Seção 1: Filtros e Pesquisa
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        context: context,
                        title: "1. Filtros e Pesquisa",
                        icon: Icons.search,
                        iconColor: const Color.fromARGB(255, 216, 78, 196),
                        content:
                            "Use os filtros para encontrar despesas específicas:\n\n"
                            "• Clique no ícone de pesquisa no topo para abrir os filtros\n\n"
                            "• Digite termos de busca para filtrar por descrição, tipo ou valor\n\n"
                            "• Selecione datas específicas para filtrar por período\n\n"
                            "• As despesas são atualizadas automaticamente conforme você filtra",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 2: Resumo de Despesas
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        context: context,
                        title: "2. Resumo de Despesas",
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: Colors.blue,
                        content:
                            "O card de resumo mostra uma visão geral de suas despesas:\n\n"
                            "• Valor total de todas as despesas listadas\n\n"
                            "• Quantidade de despesas no período\n\n"
                            "• Indicador de filtros aplicados\n\n"
                            "• Opção para limpar filtros quando necessário",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 3: Cards de Despesas
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        context: context,
                        title: "3. Cards de Despesas",
                        icon: Icons.credit_card,
                        iconColor: Colors.green,
                        content:
                            "Cada card contém informações detalhadas sobre uma despesa:\n\n"
                            "• Categoria com ícone representativo\n\n"
                            "• Data de vencimento ou pagamento\n\n"
                            "• Valor da despesa em destaque\n\n"
                            "• Indicador de status: pago, pendente ou vencimento próximo\n\n"
                            "• Ícone de despesa recorrente (quando aplicável)",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 4: Indicadores de Status
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 400),
                      child: _buildHelpSection(
                        context: context,
                        title: "4. Indicadores \nde Status",
                        icon: Icons.info_outline,
                        iconColor: Colors.orange,
                        content:
                            "Os status ajudam a identificar rapidamente a situação da despesa:\n\n"
                            "• Símbolo Amarelo: Despesas com vencimento próximo (até 5 dias)\n\n"
                            "• Símbolo Vermelho: Despesas não pagas\n\n"
                            "• Símbolo Azul: Despesas recorrentes (mensais)\n\n"
                            "• Sem símbolo: Despesas já pagas e regulares",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 5: Gerenciamento de Despesas
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 500),
                      child: _buildHelpSection(
                        context: context,
                        title: "5. Gerenciando \nDespesas",
                        icon: Icons.edit_outlined,
                        iconColor: Colors.purple,
                        content:
                            "Você pode gerenciar suas despesas de várias formas:\n\n"
                            "• Toque em um card para editar os detalhes da despesa\n\n"
                            "• Use o botão 'Editar' para modificar rapidamente\n\n"
                            "• Use o botão 'Excluir' para remover a despesa\n\n"
                            "• Arraste um card para a esquerda para excluí-lo rapidamente",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 6: Adicionando Despesas
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 600),
                      child: _buildHelpSection(
                        context: context,
                        title: "6. Adicionando \nNovas Despesas",
                        icon: Icons.add_circle_outline,
                        iconColor: const Color.fromARGB(255, 216, 78, 196),
                        content: "Para adicionar uma nova despesa:\n\n"
                            "• Toque no botão 'Add Despesas' na parte inferior da tela\n\n"
                            "• Preencha os campos: data, valor, descrição e categoria\n\n"
                            "• Cadastre despesas que ainda vão vencer e receba notificações\n avisando 5 dias antes de seu vencimento\n\n"
                            "• Algumas categorias são automaticamente marcadas como recorrentes",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 7: Navegação
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 700),
                      child: _buildHelpSection(
                        context: context,
                        title: "7. Navegação para\n Receitas",
                        icon: Icons.arrow_forward,
                        iconColor: Colors.teal,
                        content: "Para equilibrar seu orçamento, você pode:\n\n"
                            "• Clicar no botão 'Ir p/ Receitas' para acessar a tela de receitas\n\n"
                            "• Comparar suas despesas com suas receitas\n\n"
                            "• Visualizar seu saldo geral na tela de Saldo",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dicas
                    FadeAnimation(
                      delay: const Duration(milliseconds: 800),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 216, 78, 196)
                              .withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromARGB(255, 216, 78, 196)
                                .withAlpha((0.3 * 255).round()),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color:
                                      const Color.fromARGB(255, 216, 78, 196),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Dica útil",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        const Color.fromARGB(255, 216, 78, 196),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Marque suas despesas recorrentes para ter maior previsibilidade no seu orçamento mensal. Isso ajuda a planejar seus gastos fixos e evitar surpresas.",
                              style: TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botão para fechar
                    Center(
                      child: ScaleAnimation.bounceIn(
                        delay: const Duration(milliseconds: 900),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 216, 78, 196),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline),
                              const SizedBox(width: 8),
                              const Text(
                                "Entendi!",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// Método auxiliar para construir seções de ajuda
  Widget _buildHelpSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: iconColor.withAlpha((0.2 * 255).round()),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ...existing code...

  PreferredSize _buildFilterBar(ThemeManager themeManager) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(112),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        color: themeManager.getCurrentPrimaryColor(),
        child: Column(
          children: [
            // Campo de pesquisa (sem alteração)
            SlideAnimation.fromRight(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.15 * 255).toInt()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withAlpha((0.3 * 255).toInt()),
                    width: 1,
                  ),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Digite para buscar',
                    hintStyle: TextStyle(
                      color: Colors.white.withAlpha((0.7 * 255).toInt()),
                    ),
                    icon: const Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filtro de data
            SlideAnimation.fromLeft(
              delay: const Duration(milliseconds: 100),
              child: Row(
                children: [
                  // PRIMEIRO InkWell - Data inicial (_startDate)
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          locale: Locale(
                              _currencyService.selectedCountry.locale
                                  .split('_')[0],
                              _currencyService.selectedCountry.locale
                                  .split('_')[1]),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                primaryColor:
                                    themeManager.getCurrentPrimaryColor(),
                                colorScheme: ColorScheme.light(
                                  primary: themeManager
                                      .getCurrentPrimaryColor(), // Cor principal
                                  onPrimary: Colors
                                      .white, // Texto sobre a cor principal
                                  surface: Colors.white, // Fundo do calendário
                                  onSurface: Colors.black87, // Texto dos dias
                                  // NOVO: Cor do cabeçalho e seleção de ano
                                  onSurfaceVariant:
                                      themeManager.getCurrentPrimaryColor(),
                                  // NOVO: Cor dos ícones no cabeçalho
                                  onSecondaryContainer:
                                      themeManager.getCurrentPrimaryColor(),
                                ),
                                // NOVO: Definir cores específicas do DatePicker
                                datePickerTheme: DatePickerThemeData(
                                  headerBackgroundColor:
                                      themeManager.getCurrentPrimaryColor(),
                                  headerForegroundColor:
                                      Colors.white, // Texto do cabeçalho
                                  backgroundColor: Colors.white,
                                  // NOVO: Cor dos anos na seleção
                                  yearForegroundColor:
                                      WidgetStateColor.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.white; // Ano selecionado
                                    }
                                    return themeManager
                                        .getCurrentPrimaryColor(); // Anos não selecionados
                                  }),
                                  yearBackgroundColor:
                                      WidgetStateColor.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return themeManager
                                          .getCurrentPrimaryColor(); // Fundo do ano selecionado
                                    }
                                    return Colors
                                        .transparent; // Fundo dos anos não selecionados
                                  }),
                                ),
                                dialogBackgroundColor: Colors.white,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.15 * 255).toInt()),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withAlpha((0.3 * 255).toInt()),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _startDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(_startDate!)
                                    : 'Data inicial',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_startDate != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _startDate = null;
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // SEGUNDO InkWell - Data final (_endDate)
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          locale: Locale(
                              _currencyService.selectedCountry.locale
                                  .split('_')[0],
                              _currencyService.selectedCountry.locale
                                  .split('_')[1]),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                primaryColor:
                                    themeManager.getCurrentPrimaryColor(),
                                colorScheme: ColorScheme.light(
                                  primary: themeManager
                                      .getCurrentPrimaryColor(), // Cor principal
                                  onPrimary: Colors
                                      .white, // Texto sobre a cor principal
                                  surface: Colors.white, // Fundo do calendário
                                  onSurface: Colors.black87, // Texto dos dias
                                  // NOVO: Cor do cabeçalho e seleção de ano
                                  onSurfaceVariant:
                                      themeManager.getCurrentPrimaryColor(),
                                  // NOVO: Cor dos ícones no cabeçalho
                                  onSecondaryContainer:
                                      themeManager.getCurrentPrimaryColor(),
                                ),
                                // NOVO: Definir cores específicas do DatePicker
                                datePickerTheme: DatePickerThemeData(
                                  headerBackgroundColor:
                                      themeManager.getCurrentPrimaryColor(),
                                  headerForegroundColor:
                                      Colors.white, // Texto do cabeçalho
                                  backgroundColor: Colors.white,
                                  // NOVO: Cor dos anos na seleção
                                  yearForegroundColor:
                                      WidgetStateColor.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.white; // Ano selecionado
                                    }
                                    return themeManager
                                        .getCurrentPrimaryColor(); // Anos não selecionados
                                  }),
                                  yearBackgroundColor:
                                      WidgetStateColor.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return themeManager
                                          .getCurrentPrimaryColor(); // Fundo do ano selecionado
                                    }
                                    return Colors
                                        .transparent; // Fundo dos anos não selecionados
                                  }),
                                ),
                                dialogBackgroundColor: Colors.white,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            _endDate = date;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.15 * 255).toInt()),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withAlpha((0.3 * 255).toInt()),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _endDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                    : 'Data final',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_endDate != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _endDate = null;
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(ThemeManager themeManager) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ScaleAnimation.bounceIn(
            delay: const Duration(milliseconds: 300),
            child: FloatingActionButton.extended(
              heroTag: 'add_cost',
              onPressed: () => _showFormModal(),
              icon: const Icon(
                Icons.add,
                color: Colors.white, // Garante que o ícone seja branco
              ),
              label: const Text(
                'Add Despesas',
                style: TextStyle(
                    color: Colors.white), // Garante que o texto seja branco
              ),
              backgroundColor: const Color.fromARGB(255, 216, 78, 196),
            ),
          ),
          ScaleAnimation.bounceIn(
            delay: const Duration(milliseconds: 400),
            child: FloatingActionButton.extended(
              heroTag: 'goto_revenues',
              onPressed: () => Navigator.pushNamed(context, '/revenues'),
              icon: const Icon(
                Icons.arrow_forward,
                color: Colors.white, // Garante que o ícone seja branco
              ),
              label: const Text(
                'Ir p/ Receitas',
                style: TextStyle(
                    color: Colors.white), // Garante que o texto seja branco
              ),
              backgroundColor: themeManager.getCurrentPrimaryColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeManager themeManager) {
    // Forçar tema claro mesmo que o app esteja no tema escuro
    final textColor = Colors.black; // Sempre preto

    return Stack(
      children: [
        // Fundo decorativo com padrão sutil
        _buildBackgroundPattern(themeManager),

        if (_isLoading)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Color.fromARGB(255, 216, 78, 196),
                ),
                const SizedBox(height: 16),
                Text(
                  'Carregando suas despesas...',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Lista de despesas
        if (!_isLoading) _buildCostsListWithHeader(themeManager),
      ],
    );
  }

  Widget _buildBackgroundPattern(ThemeManager themeManager) {
    // Sempre usar o padrão do tema claro
    return Positioned.fill(
      child: CustomPaint(
        painter: _PatternPainter(
          color:
              Colors.black.withAlpha((0.03 * 255).toInt()), // Sempre tema claro
        ),
      ),
    );
  }

  Widget _buildCostsListWithHeader(ThemeManager themeManager) {
    if (listCosts.isEmpty) {
      return _buildEmptyState(themeManager);
    }

    return Column(
      children: [
        // Resumo de valor total
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _buildTotalValueCard(themeManager),
        ),
        // Lista de despesas
        Expanded(
          child: _buildCostsList(themeManager),
        ),
      ],
    );
  }

  Widget _buildTotalValueCard(ThemeManager themeManager) {
    final filteredCosts = _getFilteredCosts();
    final totalValue =
        filteredCosts.fold<double>(0, (sum, cost) => sum + cost.preco);
    // Sempre usar cores do tema claro
    final textColor = Colors.black;

    return SlideAnimation.fromTop(
      child: GlassContainer(
        frostedEffect: true,
        borderRadius: 16,
        opacity: 0.1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color.fromARGB(255, 216, 78, 196),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total em Despesas',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 216, 78, 196)
                          .withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filteredCosts.length} ${filteredCosts.length == 1 ? 'despesa' : 'despesas'}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _currencyService.formatCurrency(totalValue),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              if (_isFiltering &&
                  (_searchQuery.isNotEmpty ||
                      _startDate != null ||
                      _endDate != null))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 14,
                        color: textColor.withAlpha((0.7 * 255).toInt()),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Filtros aplicados',
                        style: TextStyle(
                          color: textColor.withAlpha((0.7 * 255).toInt()),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Limpar filtros',
                          style: TextStyle(
                            color: Color.fromARGB(255, 216, 78, 196),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostsList(ThemeManager themeManager) {
    final filteredCosts = _getFilteredCosts();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 140), // Espaço para os FABs
      itemCount: filteredCosts.length,
      itemBuilder: (context, index) {
        final cost = filteredCosts[index];
        return _buildCostCard(cost, themeManager, index);
      },
    );
  }

  Widget _buildEmptyState(ThemeManager themeManager) {
    // Sempre usar cores do tema claro
    final textColor = Colors.black;
    bool hasFilters =
        _searchQuery.isNotEmpty || _startDate != null || _endDate != null;

    return Center(
      child: SlideAnimation.fromBottom(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            hasFilters
                ? Icon(
                    Icons.search_off,
                    size: 80,
                    color: textColor.withAlpha((0.6 * 255).toInt()),
                  )
                : Image.asset(
                    'assets/icon_removedbg.png',
                    width: 180,
                    height: 180,
                  ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'Nenhuma despesa encontrada' : 'Vamos começar?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                hasFilters
                    ? 'Não encontramos despesas com os filtros atuais. Tente outros critérios de busca.'
                    : 'Registre suas despesas para acompanhar seu orçamento',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withAlpha((0.7 * 255).toInt()),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            if (hasFilters)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _startDate = null;
                    _endDate = null;
                  });
                },
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Limpar filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 216, 78, 196),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _showFormModal(),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Despesa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 216, 78, 196),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostCard(Costs cost, ThemeManager themeManager, int index) {
    // Sempre usar cores do tema claro
    final textColor = Colors.black;
    final totalValue = cost.preco;

    final categoryData = _categoriasDespesa.firstWhere(
      (cat) => cat['name'] == cost.tipoDespesa,
      orElse: () => _categoriasDespesa.last, // "Outros" como fallback
    );

    final categoryIcon = categoryData['icon'] as IconData;

    // Determinar se está próximo do vencimento (dentro de 5 dias)
    final isNearDue = !cost.pago &&
        cost.data.isAfter(DateTime.now()) &&
        cost.data.difference(DateTime.now()).inDays <= 5;

    return SlideAnimation.fromRight(
      delay: Duration(milliseconds: 50 * index),
      child: Dismissible(
        key: ValueKey(cost.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => _removeCost(cost),
        child: Card(
          elevation: 0,
          color: Colors.white, // Sempre branco
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              // Destaque visual para despesas não pagas com vencimento próximo
              color: isNearDue
                  ? Colors.orange.withAlpha((0.7 * 255).toInt())
                  : Colors.black.withAlpha((0.15 * 255).toInt()),
              width: isNearDue ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showFormModal(model: cost),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20), // Padding geral do card
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Alinhamento no topo
                    children: [
                      // Ícone da categoria
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 216, 78, 196)
                              .withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: const Color.fromARGB(255, 216, 78, 196),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Coluna com informações da despesa
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // PRIMEIRA LINHA: Descrição + Ícones + Preço (ALINHADOS)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment
                                  .center, // Alinhamento central
                              children: [
                                // Descrição da despesa
                                Expanded(
                                  child: Text(
                                    (cost.descricaoDaDespesa.isNotEmpty)
                                        ? cost.descricaoDaDespesa
                                        : cost.tipoDespesa,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                ),

                                // Indicadores de status (recorrente e pagamento)
                                if (cost.recorrente)
                                  Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue
                                          .withAlpha((0.1 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Tooltip(
                                      message: 'Despesa Recorrente',
                                      child: const Icon(
                                        Icons.repeat,
                                        size: 14,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),

                                if (!cost.pago)
                                  Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: isNearDue
                                          ? Colors.orange
                                              .withAlpha((0.1 * 255).toInt())
                                          : Colors.red
                                              .withAlpha((0.1 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Tooltip(
                                      message: isNearDue
                                          ? 'Vencimento Próximo'
                                          : 'Pagamento Pendente',
                                      child: Icon(
                                        isNearDue
                                            ? Icons.warning_amber_rounded
                                            : Icons.pending_actions,
                                        size: 14,
                                        color: isNearDue
                                            ? Colors.orange
                                            : Colors.red,
                                      ),
                                    ),
                                  ),

                                // Container do valor (ALINHADO COM A DESCRIÇÃO)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 216, 78, 196)
                                            .withAlpha((0.15 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _currencyService.formatCurrency(totalValue),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color.fromARGB(255, 216, 78, 196),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 12), // Espaçamento entre as duas linhas

                            // SEGUNDA LINHA: Data + Status "Vence em breve" (ALINHADOS)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment
                                  .center, // Alinhamento central
                              children: [
                                // Data
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 12,
                                      color: textColor
                                          .withAlpha((0.6 * 255).toInt()),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(cost.data),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textColor
                                            .withAlpha((0.6 * 255).toInt()),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                    width:
                                        16), // Espaçamento entre data e status

                                // Status de pagamento como texto (ALINHADO COM A DATA)
                                if (!cost.pago)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isNearDue
                                          ? Colors.orange
                                              .withAlpha((0.1 * 255).toInt())
                                          : Colors.red
                                              .withAlpha((0.1 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isNearDue ? 'Vence em breve' : 'Não pago',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isNearDue
                                            ? Colors.orange
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
// ✅ NOVO: INDICADOR DE PAGO (O VERDINHO DA FELICIDADE!)
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green
                                          .withAlpha((0.15 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.green
                                            .withAlpha((0.3 * 255).toInt()),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 12,
                                          color: Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'PAGO! 🎊💚',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Barra dividindo o card sutilmente
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color.fromARGB(255, 216, 78, 196)
                                .withAlpha((0.2 * 255).toInt()),
                            const Color.fromARGB(255, 216, 78, 196)
                                .withAlpha((0.2 * 255).toInt()),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Opções rápidas
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: textColor.withAlpha((0.6 * 255).toInt()),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Toque para editar',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withAlpha((0.6 * 255).toInt()),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _showFormModal(model: cost),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Color.fromARGB(255, 216, 78, 196),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Editar',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 216, 78, 196),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _removeCost(cost),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Excluir',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Future<void> _showFormModal({Costs? model}) async {
    context.read<ThemeManager>();
    final precoController = TextEditingController(
      text: model != null
          ? _currencyService
              .formatCurrency(model.preco) // ✅ FORMATAÇÃO DINÂMICA
          : '',
    );

    // Sempre usar o tema claro no modal
    final modalColor = Colors.white;
    final textColor = Colors.black87;
    final borderColor =
        const Color.fromARGB(255, 216, 78, 196).withAlpha((0.3 * 255).toInt());
    final fieldBackgroundColor = Colors.grey.shade50;

    final dataController = TextEditingController(
      text: model != null
          ? DateFormat('dd/MM/yyyy').format(model.data)
          : DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );

    final descricaoController = TextEditingController(
      text: model?.descricaoDaDespesa ?? '',
    );

    // Inicializar as variáveis
    String selectedTipo = model?.tipoDespesa ?? _categoriasDespesa[0]['name'];

    // Usar a função _isRecurrentCategory para verificar se a categoria é recorrente
    bool recorrente = model?.recorrente ?? _isRecurrentCategory(selectedTipo);

    // Data da despesa
    final dataEscolhida = model?.data ?? DateTime.now();

    // ✅ NOVA VARIÁVEL PARA QUANTIDADE DE MESES
    int quantidadeMesesRecorrentes = model?.quantidadeMesesRecorrentes ?? 6;

    // Se a data for no passado ou o modelo já tem um valor, use-o; caso contrário, assuma falso
    bool pago = model?.pago ?? dataEscolhida.isBefore(DateTime.now());
    int? selectedAccountId = model?.accountId;

    void showAchievementSnackbar(List<Achievement> achievements) {
      if (achievements.length == 1) {
        final achievement = achievements.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nova Conquista: ${achievement.title}!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.amber.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/achievements');
              },
            ),
          ),
        );
      } else if (achievements.length > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${achievements.length} Novas Conquistas Desbloqueadas!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.amber.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Ver Todas',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/achievements');
              },
            ),
          ),
        );
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Função para atualizar o status "recorrente" quando a categoria é alterada
            void updateCategory(String categoria) {
              setState(() {
                selectedTipo = categoria;
                // Só atualiza automaticamente se for uma nova despesa ou se não estava marcado ainda
                if (model == null || !recorrente) {
                  recorrente = _isRecurrentCategory(categoria);
                }
              });
            }

            return Container(
              decoration: BoxDecoration(
                color: modalColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.25 * 255).toInt()),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                math.max(MediaQuery.of(context).viewInsets.bottom, 48),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título do modal
                      Text(
                        model != null ? 'Editar Despesa' : 'Nova Despesa',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo de Data
                      Text(
                        'Data',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: model?.data ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            locale: Locale(
                                _currencyService.selectedCountry.locale
                                    .split('_')[0],
                                _currencyService.selectedCountry.locale
                                    .split('_')[1]),
                            builder: (context, child) {
                              final themeManager = Provider.of<ThemeManager>(
                                  context,
                                  listen: false);
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  primaryColor:
                                      themeManager.getCurrentPrimaryColor(),
                                  colorScheme: ColorScheme.light(
                                    primary:
                                        themeManager.getCurrentPrimaryColor(),
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black87,
                                    onSurfaceVariant:
                                        themeManager.getCurrentPrimaryColor(),
                                    onSecondaryContainer:
                                        themeManager.getCurrentPrimaryColor(),
                                  ),
                                  datePickerTheme: DatePickerThemeData(
                                    headerBackgroundColor:
                                        themeManager.getCurrentPrimaryColor(),
                                    headerForegroundColor: Colors.white,
                                    backgroundColor: Colors.white,
                                    yearForegroundColor:
                                        WidgetStateColor.resolveWith((states) {
                                      if (states
                                          .contains(WidgetState.selected)) {
                                        return Colors.white;
                                      }
                                      return themeManager
                                          .getCurrentPrimaryColor();
                                    }),
                                    yearBackgroundColor:
                                        WidgetStateColor.resolveWith((states) {
                                      if (states
                                          .contains(WidgetState.selected)) {
                                        return themeManager
                                            .getCurrentPrimaryColor();
                                      }
                                      return Colors.transparent;
                                    }),
                                  ),
                                  dialogBackgroundColor: Colors.white,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setState(() {
                              dataController.text =
                                  DateFormat('dd/MM/yyyy').format(date);
                              if (model == null) {
                                pago = date.isBefore(DateTime.now());
                              }
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: fieldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: textColor.withAlpha((0.6 * 255).toInt()),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                dataController.text,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Conta',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      FutureBuilder<List<Account>>(
                        future: _accountService.getAllAccounts(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text(
                                'Nenhuma conta encontrada. Crie uma primeiro.');
                          }
                          final accounts = snapshot.data!;
                          // Garante que o valor selecionado seja válido
                          if (selectedAccountId != null &&
                              !accounts
                                  .any((acc) => acc.id == selectedAccountId)) {
                            selectedAccountId = null;
                          }

                          return DropdownButtonFormField<int>(
                            value: selectedAccountId,
                            isExpanded: true,
                            hint: const Text('Selecione uma conta'),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.account_balance),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300)),
                            ),
                            items: accounts.map((account) {
                              return DropdownMenuItem<int>(
                                value: account.id,
                                child: Row(
                                  children: [
                                    Icon(
                                        IconData(account.icon,
                                            fontFamily: 'MaterialIcons'),
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(account.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedAccountId = value;
                              });
                            },
                            validator: (value) => value == null
                                ? 'Por favor, selecione uma conta.'
                                : null,
                          );
                        },
                      ),
                      // --- FIM DO NOVO WIDGET ---

                      const SizedBox(height: 20),

                      // Campo de Valor
                      Text(
                        'Valor',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: precoController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(), // Usando o mesmo das metas
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, informe um valor';
                          }
                          final cleanValue =
                              value.replaceAll(RegExp(r'[^\d]'), '');
                          if (cleanValue.isEmpty ||
                              double.tryParse(cleanValue) == null) {
                            return 'Por favor, informe um valor válido';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 12),
                              Text(
                                _currencyService
                                    .countryFlag, // ✅ BANDEIRA DINÂMICA
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _currencyService
                                    .currencySymbol, // ✅ SÍMBOLO DINÂMICO
                                style: TextStyle(
                                  color:
                                      textColor.withAlpha((0.6 * 255).toInt()),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          hintText:
                              '${_currencyService.currencySymbol} 0,00', // ✅ HINT DINÂMICO
                          hintStyle: TextStyle(
                            color: textColor.withAlpha((0.4 * 255).toInt()),
                          ),
                          filled: true,
                          fillColor: fieldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo opcional de Descrição
                      Text(
                        'Descrição (opcional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descricaoController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.description,
                            color: textColor.withAlpha((0.6 * 255).toInt()),
                          ),
                          hintText: 'Descreva sua despesa',
                          hintStyle: TextStyle(
                            color: textColor.withAlpha((0.4 * 255).toInt()),
                          ),
                          filled: true,
                          fillColor: fieldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Seleção de categoria
                      Text(
                        'Tipo de Despesa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: fieldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: CategoryGrid(
                          categories: _categoriasDespesa,
                          selectedCategory: selectedTipo,
                          onCategorySelected:
                              updateCategory, // Usa nossa nova função
                          textColor: textColor,
                          selectedColor: const Color.fromARGB(255, 214, 6, 180),
                          unselectedColor:
                              const Color.fromARGB(255, 214, 6, 180)
                                  .withAlpha((0.8 * 255).toInt()),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // NOVOS CAMPOS - Opções de recorrente e pago
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: fieldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Opções adicionais',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Campo recorrente
                            Row(
                              children: [
                                Checkbox(
                                  value: recorrente,
                                  onChanged: (value) {
                                    setState(() {
                                      recorrente = value ?? false;
                                    });
                                  },
                                  activeColor:
                                      const Color.fromARGB(255, 216, 78, 196),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Despesa recorrente',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                Tooltip(
                                  message:
                                      'Cria automaticamente esta despesa para os próximos meses',
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: textColor
                                        .withAlpha((0.5 * 255).toInt()),
                                  ),
                                ),
                              ],
                            ),

                            // ✅ NOVO: CONTADOR DE MESES (SÓ APARECE QUANDO RECORRENTE)
                            if (recorrente) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 216, 78, 196)
                                      .withAlpha((0.1 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        const Color.fromARGB(255, 216, 78, 196)
                                            .withAlpha((0.3 * 255).toInt()),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lançar para quantos meses?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Botão diminuir
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                                    255, 216, 78, 196)
                                                .withAlpha((0.2 * 255).toInt()),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.remove,
                                                size: 18),
                                            color: const Color.fromARGB(
                                                255, 216, 78, 196),
                                            onPressed: () {
                                              if (quantidadeMesesRecorrentes >
                                                  1) {
                                                setState(() {
                                                  quantidadeMesesRecorrentes--;
                                                });
                                              }
                                            },
                                          ),
                                        ),

                                        // Display do número
                                        Container(
                                          width: 80,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color.fromARGB(
                                                      255, 216, 78, 196)
                                                  .withAlpha(
                                                      (0.3 * 255).toInt()),
                                            ),
                                          ),
                                          child: Text(
                                            '$quantidadeMesesRecorrentes',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                        ),

                                        // Botão aumentar
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                                    255, 216, 78, 196)
                                                .withAlpha((0.2 * 255).toInt()),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            icon:
                                                const Icon(Icons.add, size: 18),
                                            color: const Color.fromARGB(
                                                255, 216, 78, 196),
                                            onPressed: () {
                                              if (quantidadeMesesRecorrentes <
                                                  24) {
                                                setState(() {
                                                  quantidadeMesesRecorrentes++;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      quantidadeMesesRecorrentes == 1
                                          ? 'Apenas 1 mês adicional'
                                          : '$quantidadeMesesRecorrentes meses adicionais',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textColor
                                            .withAlpha((0.7 * 255).toInt()),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 4),

                            // Campo pago (sem alteração)
                            Row(
                              children: [
                                Checkbox(
                                  value: pago,
                                  onChanged: (value) {
                                    setState(() {
                                      pago = value ?? false;
                                    });
                                  },
                                  activeColor:
                                      const Color.fromARGB(255, 216, 78, 196),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Já foi pago',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Marque se a despesa já foi paga',
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: textColor
                                        .withAlpha((0.5 * 255).toInt()),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botões de ação
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  final dataFormatada = DateFormat('dd/MM/yyyy')
                                      .parse(dataController.text);

                                  // ✅ CONVERSÃO MAIS ROBUSTA
                                  double valorNumerico = 0.0;
                                  try {
                                    String valorTexto = precoController.text
                                        .replaceAll('R\$', '')
                                        .replaceAll(' ', '')
                                        .trim();

                                    // Se está vazio, valor é 0
                                    if (valorTexto.isEmpty) {
                                      valorNumerico = 0.0;
                                    } else {
                                      // Detectar formato brasileiro: 1.234,56
                                      if (valorTexto.contains('.') &&
                                          valorTexto.contains(',')) {
                                        // Formato completo: 1.234,56
                                        // Remove pontos (separadores de milhares) e substitui vírgula por ponto
                                        valorTexto = valorTexto
                                            .replaceAll('.', '')
                                            .replaceAll(',', '.');
                                      } else if (valorTexto.contains(',')) {
                                        // Apenas vírgula: 1234,56
                                        valorTexto =
                                            valorTexto.replaceAll(',', '.');
                                      }
                                      // Se apenas ponto, assume que já está correto

                                      valorNumerico = double.parse(valorTexto);
                                    }
                                  } catch (e) {
                                    Logger().e('❌ Erro ao converter valor: $e');
                                    valorNumerico = 0.0;
                                  }

                                  final cost = Costs(
                                    id: model?.id ?? const Uuid().v4(),
                                    data: dataFormatada,
                                    preco:
                                        valorNumerico, // ✅ VALOR CORRETO GARANTIDO
                                    descricaoDaDespesa:
                                        descricaoController.text.isEmpty
                                            ? selectedTipo
                                            : descricaoController.text,
                                    tipoDespesa: selectedTipo,
                                    recorrente: recorrente,
                                    pago: pago,
                                    category: selectedTipo,
                                    accountId:
                                        selectedAccountId, // <-- PASSANDO O ID DA CONTA
                                    isLancamentoFuturo:
                                        model?.isLancamentoFuturo ??
                                            false, // ✅ ADICIONAR ESTA LINHA
                                    recorrenciaOrigemId: model
                                        ?.recorrenciaOrigemId, // ✅ ADICIONAR ESTA LINHA
                                    quantidadeMesesRecorrentes:
                                        quantidadeMesesRecorrentes, // ✅ ADICIONAR ESTA LINHA
                                  );
                                  try {
                                    await _costsService.saveCost(
                                        cost, _accountService);

                                    final newAchievements =
                                        await AchievementService
                                            .checkAndUnlockAchievements();
                                    if (newAchievements.isNotEmpty) {
                                      showAchievementSnackbar(newAchievements);
                                    }

                                    // Atualização local
                                    await _loadCosts();
                                    // ADICIONAR ESTAS LINHAS LOGO APÓS O saveCost():
                                    // Agendar notificação IMEDIATAMENTE para despesas futuras não pagas
                                    if (!cost.pago &&
                                        cost.data.isAfter(DateTime.now())) {
                                      final notificationService =
                                          NotificationService();
                                      await notificationService
                                          .schedulePaymentNotification(
                                        paymentId: cost.id,
                                        paymentName: cost.tipoDespesa,
                                        amount: cost.preco,
                                        dueDate: cost.data,
                                        isRecurrent: cost.recorrente,
                                      );

                                      debugPrint(
                                          '🔔 Notificação agendada para: ${cost.tipoDespesa}');
                                    }

                                    // NOVO: Notificar a Home para atualizar
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString('last_finance_update',
                                        DateTime.now().toIso8601String());

                                    if (context.mounted) {
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
                                backgroundColor:
                                    const Color.fromARGB(255, 216, 78, 196),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  Text(model == null ? 'Salvar' : 'Atualizar'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                          height: 44), // <-- Adicione esta linha aqui!
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
      await _costsService.deleteCost(cost.id, _accountService);
      await Future.delayed(const Duration(milliseconds: 300));
      final updatedCosts = await _costsService.getAllCosts();
      updatedCosts.sort((a, b) => b.data.compareTo(a.data));

      if (mounted) {
        setState(() {
          listCosts = updatedCosts;
        });

        _showSuccessSnackBar('Despesa excluída com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erro ao remover despesa: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog(String message) {
    // Sempre usar tema claro para o diálogo de erro
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Sempre branco
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(
          Icons.error_outline,
          color: Colors.red.shade700,
          size: 32,
        ),
        title: Text(
          'Erro',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.black87, // Sempre preto
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 216, 78, 196),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;
  final math.Random random = math.Random(42); // Seed fixo para padrão estático

  _PatternPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Criar padrão de formas geométricas não piscantes
    // Grade de formas de fundo fixa
    final cellSize = size.width / 8; // Ajustado para mais densidade

    for (int i = -1; i < 15; i++) {
      for (int j = -1; j < 30; j++) {
        final x = i * cellSize + random.nextDouble() * (cellSize * 0.5);
        final y = j * cellSize + random.nextDouble() * (cellSize * 0.5);

        final shapeType = (i + j) % 4;

        switch (shapeType) {
          case 0:
            // Cifrão
            _drawDollarSign(canvas, paint, x, y, cellSize * 0.4);
            break;
          case 1:
            // Círculos para moedas
            final radius = cellSize * (0.1 + random.nextDouble() * 0.1);
            canvas.drawCircle(Offset(x, y), radius, paint);
            break;
          case 2:
            // Símbolo +
            _drawPlusSign(canvas, paint, x, y, cellSize * 0.3);
            break;
          case 3:
            // Ícone de gráfico simplificado
            _drawChart(canvas, paint, x, y, cellSize * 0.4);
            break;
        }
      }
    }
  }

  void _drawDollarSign(
      Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();
    final halfSize = size / 2;
    // Linha vertical do cifrão
    path.moveTo(x, y - halfSize);
    path.lineTo(x, y + halfSize);

    // Curva S do cifrão
    path.moveTo(x - halfSize * 0.6, y - halfSize * 0.3);
    path.quadraticBezierTo(
        x + halfSize * 0.8, y - halfSize * 0.8, x + halfSize * 0.4, y);
    path.quadraticBezierTo(x - halfSize * 0.8, y + halfSize * 0.8,
        x - halfSize * 0.6, y + halfSize * 0.3);

    canvas.drawPath(path, paint);
  }

  void _drawPlusSign(
      Canvas canvas, Paint paint, double x, double y, double size) {
    // Linha horizontal
    canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: size, height: size * 0.2),
        paint);

    // Linha vertical
    canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: size * 0.2, height: size),
        paint);
  }

  void _drawChart(Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();
    final halfSize = size / 2;

    // Linha base
    path.moveTo(x - halfSize, y + halfSize * 0.8);
    path.lineTo(x + halfSize, y + halfSize * 0.8);

    // Barras do gráfico
    final barWidth = size / 5;

    // Barra 1
    path.moveTo(x - halfSize + barWidth * 0.5, y + halfSize * 0.8);
    path.lineTo(x - halfSize + barWidth * 0.5, y);

    // Barra 2
    path.moveTo(x - halfSize + barWidth * 1.8, y + halfSize * 0.8);
    path.lineTo(x - halfSize + barWidth * 1.8, y - halfSize * 0.3);

    // Barra 3
    path.moveTo(x - halfSize + barWidth * 3.1, y + halfSize * 0.8);
    path.lineTo(x - halfSize + barWidth * 3.1, y + halfSize * 0.4);

    // Barra 4
    path.moveTo(x - halfSize + barWidth * 4.4, y + halfSize * 0.8);
    path.lineTo(x - halfSize + barWidth * 4.4, y - halfSize * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) => oldDelegate.color != color;
}
