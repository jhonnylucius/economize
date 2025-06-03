import 'package:economize/theme/app_themes.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final Color textColor;
  final Color selectedColor;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.textColor,
    required this.selectedColor,
    required Color unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final isDark = themeManager.currentThemeType != ThemeType.light;
    themeManager.getCurrentPrimaryColor();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8, // Diminuído para acomodar duas linhas de texto
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = category['name'] == selectedCategory;

        // Determinar a cor dos ícones baseado no tema
        final iconColor = isSelected
            ? selectedColor
            : isDark
                ? const Color.fromARGB(255, 43, 3, 138) // Roxo para tema escuro
                : textColor.withAlpha((0.6 * 255).toInt());

        // Cor do texto da categoria
        final categoryTextColor = isSelected
            ? (isDark ? const Color.fromARGB(255, 43, 3, 138) : selectedColor)
            : textColor;

        return Tooltip(
          message: category['name'], // Tooltip mostra o nome completo
          waitDuration: const Duration(
              milliseconds: 500), // Mostrar após segurar por meio segundo
          preferBelow: true, // Tooltip abaixo do item
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (isDark
                      ? const Color.fromARGB(255, 43, 3, 138)
                      : selectedColor)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          textStyle: TextStyle(
            color: categoryTextColor,
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
          child: InkWell(
            onTap: () => onCategorySelected(category['name']),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? const Color.fromARGB(255, 43, 3, 138)
                            .withAlpha((0.2 * 255).toInt())
                        : selectedColor.withAlpha((0.2 * 255).toInt()))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? (isDark
                          ? const Color.fromARGB(255, 43, 3, 138)
                          : selectedColor)
                      : textColor.withAlpha((0.3 * 255).toInt()),
                  width: isSelected ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category['icon'],
                    color: iconColor,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category['name'],
                    style: TextStyle(
                      fontSize: 11, // Mantém o tamanho de fonte pequeno
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: categoryTextColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2, // Permite duas linhas de texto
                    overflow:
                        TextOverflow.ellipsis, // "..." se ainda não couber
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
