import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/accounts/service/account_service.dart';
import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/features/financial_education/utils/currency_input_formatter.dart';
import 'package:economize/icons/my_flutter_app_icons.dart';
import 'package:economize/model/revenues.dart';
import 'package:economize/model/gamification/achievement.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/gamification/achievement_service.dart';
import 'package:economize/service/moedas/currency_service.dart';
import 'package:economize/service/revenues_service.dart';
import 'package:economize/theme/app_themes.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:economize/widgets/category_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

class RevenuesScreen extends StatefulWidget {
  const RevenuesScreen({super.key});

  @override
  State<RevenuesScreen> createState() => _RevenuesScreenState();
}

class _RevenuesScreenState extends State<RevenuesScreen>
    with SingleTickerProviderStateMixin {
  List<Revenues> listRevenues = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RevenuesService _revenuesService = RevenuesService();
  final AccountService _accountService = AccountService(); // Adicionado
  late CurrencyService _currencyService;
  bool _isLoading = false;
  bool _isFiltering = false;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  late AnimationController _animationController;
  final GlobalKey _helpKey = GlobalKey();

  // ... (sua lista de categorias de receita permanece a mesma) ...
  static const List<Map<String, dynamic>> _categoriasReceita = [
    {'icon': Icons.credit_card, 'name': 'Salário'},
    {'icon': Icons.attach_money, 'name': '13º Salário'},
    {'icon': Icons.money, 'name': 'Rendimentos'},
    {'icon': Icons.account_balance_wallet, 'name': 'Carteira'},
    {'icon': Icons.receipt, 'name': 'Reembolsos'},
    {'icon': Icons.business_center, 'name': 'Emprego'},
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
    _currencyService = context.read<CurrencyService>();
    _loadRevenues();
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

  Future<void> _loadRevenues() async {
    setState(() => _isLoading = true);
    try {
      final revenues = await _revenuesService.getAllRevenues();
      // Ordenar por data, mais recente primeiro
      revenues.sort((a, b) => b.data.compareTo(a.data));
      if (mounted) {
        setState(() => listRevenues = revenues);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erro ao carregar receitas: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Revenues> _getFilteredRevenues() {
    return listRevenues.where((revenue) {
      // Filtro por texto
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final descLower = revenue.descricaoDaReceita.toLowerCase();
        final tipoLower = revenue.tipoReceita.toLowerCase();
        final dataFormatada =
            DateFormat('dd/MM/yyyy').format(revenue.data).toLowerCase();
        final valorFormatado = revenue.preco.toString().toLowerCase();

        if (!descLower.contains(searchLower) &&
            !tipoLower.contains(searchLower) &&
            !dataFormatada.contains(searchLower) &&
            !valorFormatado.contains(searchLower)) {
          return false;
        }
      }

      // Filtro por intervalo de data
      if (_startDate != null && revenue.data.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null &&
          revenue.data.isAfter(DateTime(
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
          'Receitas',
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
            tooltip: "Filtrar receitas",
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
            onPressed: _loadRevenues,
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
            onPressed: () =>
                _showRevenuesScreenHelp(context), // Chama o método de ajuda
          ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: _isFiltering ? _buildFilterBar(themeManager) : null,
    );
  }

  // Adicione este método na classe _RevenuesScreenState
  void _showRevenuesScreenHelp(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final isDark = themeManager.currentThemeType != ThemeType.light;

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
                                themeManager.getCurrentPrimaryColor(),
                            child: Icon(
                              Icons.attach_money,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Tela de Receitas",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color.fromARGB(255, 0, 0, 0)
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Como gerenciar suas entradas financeiras",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
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

                    // Seção 1: Barra Superior
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        title: "1. Barra de Ferramentas",
                        icon: Icons.search,
                        iconColor: Colors.blue,
                        content:
                            "A barra superior oferece acesso a ferramentas importantes:\n\n"
                            "• Título 'Receitas': Identifica a tela atual\n\n"
                            "• Filtrar: Permite buscar receitas por texto ou datas\n\n"
                            "• Atualizar: Recarrega a lista de receitas\n\n"
                            "• Ajuda: Abre este guia de informações",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 2: Card Resumo
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        title: "2. Resumo Financeiro",
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: Colors.green,
                        content:
                            "O card de resumo mostra uma visão geral de suas receitas:\n\n"
                            "• Valor Total: Soma de todas as suas receitas listadas\n\n"
                            "• Contador: Quantidade de receitas registradas\n\n"
                            "• Filtros Aplicados: Indica quando há filtros ativos\n\n"
                            "• Botão Limpar: Remove todos os filtros aplicados",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 3: Lista de Receitas
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        title: "3. Lista de Receitas",
                        icon: Icons.list_alt,
                        iconColor: Colors.amber,
                        content:
                            "Cada card na lista apresenta detalhes de uma receita:\n\n"
                            "• Tipo e Ícone: Identifica a categoria da receita (Salário, Investimentos, etc)\n\n"
                            "• Data: Mostra quando a receita foi recebida\n\n"
                            "• Valor: Exibe o montante da receita com destaque\n\n"
                            "• Opções rápidas: Botões para editar ou excluir a receita",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 4: Ações de Deslize
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 400),
                      child: _buildHelpSection(
                        title: "4. Gestos e Interações",
                        icon: Icons.swipe,
                        iconColor: Colors.purple,
                        content:
                            "Existem várias formas de interagir com suas receitas:\n\n"
                            "• Toque no Card: Abre o formulário para edição da receita\n\n"
                            "• Deslize para Esquerda: Exclui rapidamente uma receita\n\n"
                            "• Botões de Ação: Atalhos para editar ou excluir cada item\n\n"
                            "• Arraste para Baixo: Atualiza a lista de receitas",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 5: Botões Inferiores
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 500),
                      child: _buildHelpSection(
                        title: "5. Botões de Ação",
                        icon: Icons.add_circle_outline,
                        iconColor: const Color(0xFF4CAF50),
                        content:
                            "Os botões na parte inferior permitem ações rápidas:\n\n"
                            "• Adicionar Receita: Abre o formulário para cadastrar uma nova receita\n\n"
                            "• Ir para Despesas: Navega diretamente para a tela de despesas\n\n"
                            "• Os botões flutuam sobre a lista para fácil acesso",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 6: Formulário de Receitas
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 600),
                      child: _buildHelpSection(
                        title: "6. Cadastro de Receitas",
                        icon: Icons.edit_note,
                        iconColor: Colors.orange,
                        content:
                            "O formulário permite cadastrar ou editar receitas:\n\n"
                            "• Data: Selecione a data em que recebeu a receita\n\n"
                            "• Valor: Digite o valor recebido (use ponto como separador decimal)\n\n"
                            "• Tipo: Escolha a categoria que melhor descreve a receita\n\n"
                            "• Salvar: Confirma o cadastro ou atualização da receita",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 7: Mensagens e Notificações
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 700),
                      child: _buildHelpSection(
                        title: "7. Mensagens \ne Notificações",
                        icon: Icons.notifications_none,
                        iconColor: Colors.teal,
                        content:
                            "O app comunica o resultado das suas ações:\n\n"
                            "• Mensagens de Sucesso: Confirmam quando uma ação foi realizada\n\n"
                            "• Alertas de Erro: Informam quando algo não funcionou como esperado\n\n"
                            "• Confirmações: Pedem sua confirmação antes de ações irreversíveis\n\n"
                            "• Indicadores Visuais: Mostram quando uma operação está em andamento",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dicas
                    FadeAnimation(
                      delay: const Duration(milliseconds: 800),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeManager
                              .getCurrentPrimaryColor()
                              .withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeManager
                                .getCurrentPrimaryColor()
                                .withAlpha((0.3 * 255).round()),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tips_and_updates,
                                  color: themeManager.getCurrentPrimaryColor(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Dica profissional",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        themeManager.getCurrentPrimaryColor(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Registre todas as suas fontes de renda, mesmo as ocasionais ou de pequeno valor. Isso dará uma visão mais precisa das suas finanças e ajudará no planejamento do seu orçamento.",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.5,
                              ),
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
                                themeManager.getCurrentPrimaryColor(),
                            foregroundColor: theme.colorScheme.onPrimary,
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
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  color: isDark ? Colors.white : Colors.black87,
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
                color: isDark ? Colors.white : Colors.black87,
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
                          locale: const Locale('pt', 'BR'),
                          // TEMA CLARO PARA startDate:
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                primaryColor: const Color(0xFF4CAF50),
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF4CAF50),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black87,
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
                          locale: const Locale('pt', 'BR'),
                          // TEMA CLARO PARA endDate:
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                primaryColor: const Color(0xFF4CAF50),
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF4CAF50),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black87,
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
              heroTag: 'add_revenue',
              onPressed: () => _showFormModal(),
              icon: const Icon(
                Icons.add,
                color: Colors.white, // Garante que o ícone seja branco
              ),
              label: const Text(
                'Add Receitas',
                style: TextStyle(
                    color: Colors.white), // Garante que o texto seja branco
              ),
              backgroundColor: const Color(0xFF4CAF50), // Verde para Receitas
            ),
          ),
          ScaleAnimation.bounceIn(
            delay: const Duration(milliseconds: 400),
            child: FloatingActionButton.extended(
              heroTag: 'goto_costs',
              onPressed: () => Navigator.pushNamed(context, '/costs'),
              icon: const Icon(
                Icons.arrow_forward,
                color: Colors.white, // Garante que o ícone seja branco
              ),
              label: const Text(
                'Ir p/ Despesas',
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
                  color: Color(0xFF4CAF50), // Verde para Receitas
                ),
                const SizedBox(height: 16),
                Text(
                  'Carregando suas receitas...',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Lista de receitas
        if (!_isLoading) _buildRevenuesListWithHeader(themeManager),
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

  Widget _buildRevenuesListWithHeader(ThemeManager themeManager) {
    if (listRevenues.isEmpty) {
      return _buildEmptyState(themeManager);
    }

    return Column(
      children: [
        // Resumo de valor total
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _buildTotalValueCard(themeManager),
        ),
        // Lista de receitas
        Expanded(
          child: _buildRevenuesList(themeManager),
        ),
      ],
    );
  }

  Widget _buildTotalValueCard(ThemeManager themeManager) {
    final filteredRevenues = _getFilteredRevenues();
    final totalValue =
        filteredRevenues.fold<double>(0, (sum, revenue) => sum + revenue.preco);
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
                    color: Color(0xFF4CAF50), // Verde para Receitas
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total em Receitas',
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
                      color: const Color(0xFF4CAF50)
                          .withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filteredRevenues.length} ${filteredRevenues.length == 1 ? 'receita' : 'receitas'}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _currencyService.formatCurrency(totalValue), // ✅ DEPOIS
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
                            color: Color(0xFF4CAF50), // Verde para Receitas
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

  Widget _buildRevenuesList(ThemeManager themeManager) {
    final filteredRevenues = _getFilteredRevenues();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 140), // Espaço para os FABs
      itemCount: filteredRevenues.length,
      itemBuilder: (context, index) {
        final revenue = filteredRevenues[index];
        return _buildRevenueCard(revenue, themeManager, index);
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
              hasFilters ? 'Nenhuma receita encontrada' : 'Vamos começar?',
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
                    ? 'Não encontramos receitas com os filtros atuais. Tente outros critérios de busca.'
                    : 'Registre suas receitas para acompanhar seu orçamento',
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
                  backgroundColor:
                      const Color(0xFF4CAF50), // Verde para Receitas
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _showFormModal(),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Receita'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF4CAF50), // Verde para Receitas
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

  Widget _buildRevenueCard(
      Revenues revenue, ThemeManager themeManager, int index) {
    // Sempre usar cores do tema claro
    final textColor = Colors.black;

    final categoryData = _categoriasReceita.firstWhere(
      (cat) => cat['name'] == revenue.tipoReceita,
      orElse: () => _categoriasReceita.last, // "Outros" como fallback
    );

    final categoryIcon = categoryData['icon'] as IconData;

    return SlideAnimation.fromRight(
      delay: Duration(milliseconds: 50 * index),
      child: Dismissible(
        key: ValueKey(revenue.id),
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
        onDismissed: (_) => _removeRevenue(revenue),
        child: Card(
          elevation: 0,
          color: Colors.white, // Sempre branco
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.black
                  .withAlpha((0.15 * 255).toInt()), // Sempre borda sutil
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showFormModal(model: revenue),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Ícone da categoria
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50)
                              .withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: const Color(0xFF4CAF50), // Verde para Receitas
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Data e categoria
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              revenue.tipoReceita,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color:
                                      textColor.withAlpha((0.6 * 255).toInt()),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(revenue.data),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textColor
                                        .withAlpha((0.6 * 255).toInt()),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Valor
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50)
                              .withAlpha((0.15 * 255).toInt()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currencyService
                              .formatCurrency(revenue.preco), // ✅ DEPOIS
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF4CAF50), // Verde para Receitas
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Barra dividindo o card sutilmente
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF4CAF50)
                                .withAlpha((0.2 * 255).toInt()),
                            const Color(0xFF4CAF50)
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
                      const SizedBox(width: 4),
                      Text(
                        'Toque para editar',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withAlpha((0.6 * 255).toInt()),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _showFormModal(model: revenue),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Color(0xFF4CAF50), // Verde para Receitas
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Editar',
                                style: TextStyle(
                                  color:
                                      Color(0xFF4CAF50), // Verde para Receitas
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _removeRevenue(revenue),
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
                              const SizedBox(width: 4),
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

  void _showAchievementSnackbar(List<Achievement> achievements) {
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

  Future<void> _showFormModal({Revenues? model}) async {
    context.read<ThemeManager>();

    // Sempre usar o tema claro no modal
    final modalColor = Colors.white;
    final textColor = Colors.black87;
    final borderColor = const Color(0xFF4CAF50).withAlpha((0.3 * 255).toInt());
    final fieldBackgroundColor = Colors.grey.shade50;

    final dataController = TextEditingController(
      text: model != null
          ? DateFormat('dd/MM/yyyy').format(model.data)
          : DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );
    final precoController = TextEditingController(
      text: model?.preco.toString() ?? '', // ✅ AQUI É ONDE DEVE FICAR
    );
    String selectedTipo = model?.tipoReceita ?? _categoriasReceita[0]['name'];

    int? selectedAccountId = model?.accountId;

    final dateFormatter = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {"#": RegExp(r'[0-9]')},
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300, // Sempre cinza claro
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cabeçalho
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50)
                                  .withAlpha((0.25 * 255).toInt()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.attach_money,
                              color: Color(0xFF4CAF50), // Verde para Receitas
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              model == null ? 'Nova Receita' : 'Editar Receita',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: textColor.withAlpha((0.7 * 255).toInt()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Campo de data
                      Text(
                        'Data da Receita',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: dataController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: '01/01/2025',
                          hintStyle: TextStyle(
                              color: textColor.withAlpha((0.5 * 255).toInt())),
                          suffixIcon: IconButton(
                            icon: const Icon(MyFlutterApp.calendar_check,
                                color: Color(0xFF4CAF50)),
                            onPressed: () async {
                              // NOVO: Forçar tema claro para o DatePicker
                              final date = await showDatePicker(
                                context: context,
                                initialDate: model?.data ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                locale: const Locale('pt', 'BR'),
                                // ADICIONAR ESTAS LINHAS PARA FORÇAR TEMA CLARO:
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      primaryColor: const Color(0xFF4CAF50),
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF4CAF50),
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black87,
                                      ),
                                      dialogBackgroundColor: Colors.white,
                                      textTheme: const TextTheme(
                                        bodyLarge:
                                            TextStyle(color: Colors.black87),
                                        bodyMedium:
                                            TextStyle(color: Colors.black87),
                                        titleLarge:
                                            TextStyle(color: Colors.black87),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setState(() {
                                  dataController.text =
                                      DateFormat('dd/MM/yyyy').format(date);
                                });
                              }
                            },
                          ),
                          filled: true,
                          fillColor: fieldBackgroundColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: borderColor, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4CAF50), // Verde para Receitas
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.red.shade700,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.red.shade700,
                              width: 2,
                            ),
                          ),
                          errorStyle: TextStyle(
                            color: Colors.red.shade700,
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
                      const SizedBox(height: 20),
// --- NOVO WIDGET: SELETOR DE CONTA ---
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
                      // Campo de valor
                      Text(
                        'Valor da Receita',
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
                          // ✅ ADICIONAR formatação automática
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(), // Se tiver o formatter das metas
                        ],
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          prefixText: 'R\$ ',
                          prefixStyle: TextStyle(color: textColor),
                          hintText: '0.00',
                          hintStyle: TextStyle(
                              color: textColor.withAlpha((0.5 * 255).toInt())),
                          helperText: '',
                          helperStyle: TextStyle(
                            color: textColor.withAlpha((0.6 * 255).toInt()),
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: fieldBackgroundColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: borderColor, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4CAF50), // Verde para Receitas
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.red.shade700,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.red.shade700,
                              width: 2,
                            ),
                          ),
                          errorStyle: TextStyle(
                            color: Colors.red.shade700,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o valor';
                          }

                          // ✅ NOVA VALIDAÇÃO que aceita formato brasileiro
                          try {
                            String valorLimpo = value
                                .replaceAll('R\$', '')
                                .replaceAll(' ', '')
                                .trim();

                            // Se tem ponto e vírgula (formato completo: 1.234,56)
                            if (valorLimpo.contains('.') &&
                                valorLimpo.contains(',')) {
                              valorLimpo = valorLimpo
                                  .replaceAll('.', '')
                                  .replaceAll(',', '.');
                            }
                            // Se só tem vírgula (formato: 1234,56)
                            else if (valorLimpo.contains(',')) {
                              valorLimpo = valorLimpo.replaceAll(',', '.');
                            }

                            final valorNumerico = double.parse(valorLimpo);

                            if (valorNumerico <= 0) {
                              return 'O valor deve ser maior que zero';
                            }

                            return null; // ✅ Valor válido!
                          } catch (e) {
                            return 'Por favor, insira um valor válido';
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Seleção de categoria
                      Text(
                        'Tipo de Receita',
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
                          categories: _categoriasReceita,
                          selectedCategory: selectedTipo,
                          onCategorySelected: (categoria) {
                            setState(() {
                              selectedTipo = categoria;
                            });
                          },
                          textColor: textColor,
                          selectedColor:
                              const Color(0xFF4CAF50), // Verde para Receitas
                          unselectedColor: const Color(0xFF4CAF50)
                              .withAlpha((0.8 * 255).toInt()),
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
                              // No método _showFormModal, onde salva a receita:
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  // ❌ PROBLEMA: Esta linha está causando o erro
                                  // preco: double.parse(precoController.text),

                                  // ✅ CORREÇÃO: Conversão segura do valor formatado
                                  double valorNumerico = 0.0;
                                  try {
                                    String valorTexto = precoController.text
                                        .replaceAll('R\$', '')
                                        .replaceAll(' ', '')
                                        .trim();

                                    // Detectar formato brasileiro: 1.234,56
                                    if (valorTexto.contains('.') &&
                                        valorTexto.contains(',')) {
                                      // Formato completo: 1.234,56
                                      valorTexto = valorTexto
                                          .replaceAll('.', '')
                                          .replaceAll(',', '.');
                                    } else if (valorTexto.contains(',')) {
                                      // Apenas vírgula: 1234,56
                                      valorTexto =
                                          valorTexto.replaceAll(',', '.');
                                    }

                                    valorNumerico = double.parse(valorTexto);
                                  } catch (e) {
                                    Logger().e('❌ Erro ao converter valor: $e');
                                    return; // Não salva se der erro
                                  }

                                  final revenue = Revenues(
                                    id: model?.id ?? const Uuid().v4(),
                                    data: DateFormat('dd/MM/yyyy')
                                        .parse(dataController.text),
                                    preco: valorNumerico, // ✅ VALOR CORRETO
                                    descricaoDaReceita: selectedTipo,
                                    tipoReceita: selectedTipo,
                                    accountId:
                                        selectedAccountId, // <-- PASSANDO O ID DA CONTA
                                  );

                                  try {
                                    await _revenuesService.saveRevenue(
                                        revenue, _accountService);

                                    final newAchievements =
                                        await AchievementService
                                            .checkAndUnlockAchievements();
                                    if (newAchievements.isNotEmpty) {
                                      _showAchievementSnackbar(newAchievements);
                                    }

                                    // Atualização local
                                    await _loadRevenues();

                                    // NOVO: Notificar a Home para atualizar
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString('last_finance_update',
                                        DateTime.now().toIso8601String());

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
                                backgroundColor: const Color(
                                    0xFF4CAF50), // Verde para Receitas
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

  Future<void> _removeRevenue(Revenues revenue) async {
    try {
      await _revenuesService.deleteRevenue(revenue.id, _accountService);
      await Future.delayed(const Duration(milliseconds: 300));
      final updatedRevenues = await _revenuesService.getAllRevenues();
      updatedRevenues.sort((a, b) => b.data.compareTo(a.data));

      if (mounted) {
        setState(() {
          listRevenues = updatedRevenues;
        });

        _showSuccessSnackBar('Receita excluída com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erro ao remover receita: $e');
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
              foregroundColor: const Color(0xFF4CAF50), // Verde para Receitas
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
