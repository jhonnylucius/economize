import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/theme/app_themes.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:economize/widgets/theme_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../icons/my_flutter_app_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAnimating = false;
  int? _selectedIndex;
  // Removido 'isLight' pois não é mais necessário para o AppBar
  // bool get isLight =>
  //     context.watch<ThemeManager>().currentThemeType == ThemeType.roxoEscuro;

  @override
  Widget build(BuildContext context) {
    // Obtém o tema atual (seja Light ou Pastel)
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;
    // Obtém o ThemeManager apenas para a lógica do texto "O que quer fazer?"
    final themeManager = context.watch<ThemeManager>();

    return ResponsiveScreen(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false, // Mantido como estava
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Mantido como estava
          mainAxisSize: MainAxisSize.min, // Mantido como estava
          children: [
            Image.asset('assets/icon_removedbg.png', height: 80, width: 80),
            const SizedBox(width: 8),
            Text(
              'Economize\$',
              style: TextStyle(
                // *** CORREÇÃO: Usa a cor ON PRIMARY do tema atual ***
                // Isso será branco tanto no tema Light (sobre preto) quanto no Pastel (sobre roxo)
                color: theme.colorScheme.onPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // *** CORREÇÃO: Usa a cor PRIMARY do tema atual ***
        // Isso será preto no tema Light e roxo no tema Pastel
        backgroundColor: theme.colorScheme.primary,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: padding.bottom),
        child: BottomNavigationBar(
          backgroundColor: theme.colorScheme.surface,
          // Ajuste para usar cores do tema para ícones selecionados/não selecionados
          selectedItemColor:
              theme.colorScheme.primary, // Cor primária quando selecionado
          unselectedItemColor: theme.colorScheme.onSurface.withValues(
            alpha: (0.6 * 255).toDouble(),
          ), // Cor onSurface com opacidade quando não selecionado
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.palette), label: 'Temas'),
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate),
              label: 'Calcular Meta',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_objects),
              label: 'Metas',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                showThemeSelector(context);
                break;
              case 1:
                Navigator.pushNamed(context, '/calculator');
                break;
              case 2:
                Navigator.pushNamed(context, '/goals');
                break;
            }
          },
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked, // Mantido
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              'O que quer fazer?',
              style: TextStyle(
                // Mantém a lógica original para esta cor específica (preto ou branco)
                color:
                    themeManager.currentThemeType == ThemeType.light
                        ? Colors.black
                        : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              width: screenSize.width,
              child: Stack(
                fit: StackFit.expand,
                children: List.generate(8, (index) {
                  double x = (index % 2) * (screenSize.width / 2);
                  double y = (index ~/ 2) * ((screenSize.width / 2) / 1.3);

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOut,
                    left:
                        _isAnimating
                            ? (_selectedIndex == index
                                ? x
                                : _getExitPosition(index, screenSize.width).dx)
                            : x,
                    top:
                        _isAnimating
                            ? (_selectedIndex == index
                                ? y
                                : _getExitPosition(index, screenSize.height).dy)
                            : y,
                    width: screenSize.width / 2,
                    height: (screenSize.width / 2) / 1.3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildGridItemWithAnimation(
                        index: index,
                        icon: _getIconForIndex(index),
                        label: _getLabelForIndex(index),
                        route: _getRouteForIndex(index),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItemWithAnimation({
    required int index,
    required IconData icon,
    required String label,
    required String route,
  }) {
    return _buildGridItem(
      icon: icon,
      label: label,
      onTap: () => _handleItemTap(index, route),
    );
  }

  // *** MÉTODO _buildGridItem CORRIGIDO para usar cores do tema ***
  Widget _buildGridItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    // Removido themeManager pois usaremos cores padrão do tema

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 2,
        // Usa a cor do card definida no tema (branco em ambos os casos)
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // Usa a cor primária para a borda (preto no Light, roxo no Pastel)
          side: BorderSide(color: theme.colorScheme.primary, width: 1),
        ),
        padding: const EdgeInsets.all(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Usa a cor primária para o ícone (preto no Light, roxo no Pastel)
          Icon(icon, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              // Usa a cor primária para o texto (preto no Light, roxo no Pastel)
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Métodos _getExitPosition, _handleItemTap, _getIconForIndex, _getLabelForIndex, _getRouteForIndex (sem alterações)
  Offset _getExitPosition(int index, double size) {
    switch (index % 4) {
      case 0:
        return Offset(-size, 0);
      case 1:
        return Offset(size, 0);
      case 2:
        return Offset(-size, size);
      case 3:
        return Offset(size, size);
      default:
        return Offset.zero;
    }
  }

  void _handleItemTap(int index, String route) {
    setState(() {
      _selectedIndex = index;
      _isAnimating = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      Navigator.pushNamed(context, route);
      // Reset animation state after navigation (important for back navigation)
      if (mounted) {
        // Check if the widget is still in the tree
        setState(() {
          _isAnimating = false;
          _selectedIndex = null;
        });
      }
    });
  }

  IconData _getIconForIndex(int index) {
    final icons = [
      MyFlutterApp.calculator,
      MyFlutterApp.file_download,
      MyFlutterApp.comments_dollar,
      Icons.pie_chart,
      Icons.integration_instructions_outlined,
      Icons.control_point_rounded,
      Icons.import_contacts,
      Icons.graphic_eq,
    ];
    return icons[index];
  }

  String _getLabelForIndex(int index) {
    final labels = [
      'Orçamentos',
      'Despesas',
      'Receitas',
      'Dashboard',
      'Relatórios',
      'Gerenciar Produtos',
      'Dicas Importantes',
      'Tendência das Despesa',
    ];
    return labels[index];
  }

  String _getRouteForIndex(int index) {
    final routes = [
      '/budget/list',
      '/costs',
      '/revenues',
      '/dashboard',
      '/report',
      '/items/manage',
      '/tips',
      '/trend',
    ];
    return routes[index];
  }
}
