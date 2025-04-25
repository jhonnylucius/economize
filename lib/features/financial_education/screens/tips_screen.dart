import 'package:economize/features/financial_education/data/tips_repository.dart';
import 'package:economize/features/financial_education/models/financial_tip.dart';
import 'package:economize/features/financial_education/widgets/tip_card.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<FinancialTip> _tips = TipsRepository.tips;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TipCategory.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<FinancialTip> _getFilteredTips(TipCategory category) {
    return _tips.where((tip) => tip.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    context.watch<ThemeManager>(); // Adicione esta linha

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dicas Financeiras',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            tooltip: 'Ir para Home',
            color: theme.colorScheme.onPrimary,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: theme.colorScheme.onPrimary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withAlpha(
            (0.7 * 255).toInt(),
          ),
          tabs:
              TipCategory.values.map((category) {
                return Tab(
                  icon: Icon(category.icon),
                  text: category.displayName,
                );
              }).toList(),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor, // Usando a cor do tema
      body: TabBarView(
        controller: _tabController,
        children:
            TipCategory.values.map((category) {
              final categoryTips = _getFilteredTips(category);

              return categoryTips.isEmpty
                  ? _buildEmptyState(theme)
                  : Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: categoryTips.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return TipCard(tip: categoryTips[index]);
                      },
                    ),
                  );
            }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/calculator'),
        icon: Icon(
          Icons.calculate_outlined,
          color: theme.colorScheme.onPrimary,
        ),
        label: Text(
          'Calculadora de Metas',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            size: 64,
            color: theme.colorScheme.primary.withAlpha((0.5 * 255).toInt()),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma dica disponível\nnesta categoria ainda',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
