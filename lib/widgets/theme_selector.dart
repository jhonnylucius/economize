import 'package:economize/theme/app_themes.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    // Obtém o tema ATUAL (seja ele Light ou Pastel)
    final currentTheme = Theme.of(context);

    return Card(
      color: currentTheme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Escolha um tema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: currentTheme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            // *** INÍCIO DA MODIFICAÇÃO LOCAL DO TEMA ***
            // Envolve a coluna de RadioListTiles com um widget Theme
            Theme(
              // Cria uma CÓPIA do tema atual e sobrescreve APENAS o radioTheme
              data: currentTheme.copyWith(
                radioTheme: RadioThemeData(
                  // Define a cor de preenchimento (a bolinha) baseado no estado
                  fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                    // Se estiver SELECIONADO, usa a cor primária do tema atual
                    if (states.contains(WidgetState.selected)) {
                      return currentTheme.colorScheme.primary;
                    }
                    // Se NÃO estiver selecionado:
                    // *** AQUI ESTÁ A LÓGICA PARA A COR NÃO SELECIONADA ***
                    // Força o uso da cor primária do tema atual (roxo no Pastel, preto no Light)
                    // Isso garante que a bolinha não selecionada não fique branca no tema Pastel.
                    return currentTheme.colorScheme.primary;
                  }),
                ),
                // Opcional: Se quiser garantir que unselectedWidgetColor não interfira
                // unselectedWidgetColor: currentTheme.colorScheme.primary,
              ),
              // O filho do Theme é a coluna com os RadioListTiles
              child: Column(
                children: ThemeType.values.map((themeType) {
                  return RadioListTile<ThemeType>(
                    title: Text(
                      themeType.displayName,
                      style: TextStyle(
                        color: currentTheme.colorScheme.onSurface,
                      ),
                    ),
                    value: themeType,
                    groupValue: themeManager.currentThemeType,
                    // activeColor: currentTheme.colorScheme.primary, // Removido: Agora controlado pelo fillColor no Theme override
                    onChanged: (ThemeType? value) async {
                      if (value != null &&
                          value != themeManager.currentThemeType) {
                        await themeManager.setTheme(value);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    secondary: _buildThemePreview(themeType, currentTheme),
                  );
                }).toList(),
              ),
            ),
            // *** FIM DA MODIFICAÇÃO LOCAL DO TEMA ***
          ],
        ),
      ),
    );
  }

  // Método _buildThemePreview (sem alterações nesta correção)
  Widget _buildThemePreview(ThemeType themeType, ThemeData currentTheme) {
    Color previewColor = _getPreviewColor(themeType);
    Color borderColor;
    final isPreviewSimilarToSurface = (previewColor.computeLuminance() -
                currentTheme.colorScheme.surface.computeLuminance())
            .abs() <
        0.2;

    if (isPreviewSimilarToSurface) {
      borderColor =
          currentTheme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt());
    } else {
      borderColor = previewColor.computeLuminance() > 0.5
          ? Colors.grey[600]!
          : Colors.grey[300]!;
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: previewColor,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  // Método _getPreviewColor (sem alterações nesta correção)
  Color _getPreviewColor(ThemeType theme) {
    switch (theme) {
      case ThemeType.light:
        return Colors.grey[200]!;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }
}

// Função showThemeSelector (sem alterações nesta correção)
void showThemeSelector(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    clipBehavior: Clip.antiAliasWithSaveLayer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          8.0,
          8.0,
          8.0,
          8.0 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: const ThemeSelector(),
      );
    },
  );
}

/*
// Exemplo de como o enum ThemeType deve ser definido (ajuste conforme sua estrutura)
enum ThemeType {
  light(displayName: 'Claro'),
  roxoEscuro(displayName: 'Roxo Escuro');
  // dark(displayName: 'Escuro'); // Adicione se tiver um tema escuro

  final String displayName;
  const ThemeType({required this.displayName});
}
*/
