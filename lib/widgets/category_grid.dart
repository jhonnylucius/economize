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
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.textColor,
    required this.selectedColor,
    required Color unselectedColor,
  }) : super(key: key);

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
        childAspectRatio: 0.9,
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

        return InkWell(
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
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? (isDark
                            ? const Color.fromARGB(255, 43, 3, 138)
                            : selectedColor)
                        : textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
