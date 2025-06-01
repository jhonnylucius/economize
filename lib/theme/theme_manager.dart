import 'package:economize/theme/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager with ChangeNotifier {
  static const String _themeKey = 'app_theme';

  // Alteração do tema padrão para roxoEscuro
  ThemeType _currentThemeType = ThemeType.roxoEscuro;
  ThemeData _currentTheme = AppThemes.roxoEscuro;

  ThemeType get currentThemeType => _currentThemeType;
  ThemeData get currentTheme => _currentTheme;

  ThemeManager() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeKey);

      if (savedThemeIndex != null &&
          savedThemeIndex < ThemeType.values.length) {
        _currentThemeType = ThemeType.values[savedThemeIndex];
        _currentTheme = AppThemes.getThemeByType(_currentThemeType);
        notifyListeners();
      }
    } catch (e) {
      // Em caso de erro, permanece com o tema padrão
      debugPrint('Erro ao carregar tema: $e');
    }
  }

  // --- Métodos get...Color() atualizados com ThemeType.dark ---

  Color getHeaderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 255, 255, 255);
      case ThemeType.roxoEscuro:
        return Colors.black; // Baseado no seu DarkTheme surface/scaffold
    }
  }

  Color getCurrentPrimaryColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0); // Cor primária do tema claro
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(
            255, 43, 3, 138); // Roxo como cor primária do tema escuro
    }
  }

// Retorna a cor secundária do tema atual
  Color getCurrentSecondaryColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(
            255, 43, 3, 138); // Cor secundária do tema claro
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 81, 45, 168); // Tom mais claro do roxo
    }
  }

  Color getHeaderTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getHomeButtonIconColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getHomeButtonTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getHomeButtonBorderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        // Corrigido: usar withOpacity
        return Colors.black.withAlpha((0.2 * 255).toInt());
      case ThemeType.roxoEscuro:
        // Corrigido: usar withOpacity
        return Colors.white.withAlpha((0.2 * 255).toInt());
    }
  }

  Color getChartLineColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 43, 3, 138);
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getChartBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        // Nota: No seu código original era 'Branco para tema claro', mas a cor era preta. Mantive a cor.
        return const Color.fromARGB(255, 2, 2, 2);
      case ThemeType.roxoEscuro:
        // Nota: No seu código original era 'Roxo para tema roxo', mas a cor era branca. Mantive a cor.
        return const Color.fromARGB(255, 255, 255, 255);
    }
  }

  Color getChartTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 247, 247, 247);
    }
  }

  Color getTipCardTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getTipCardBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 254, 254, 255);
    }
  }

  Color getTipCardIconColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 43, 3, 138);
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getSummaryCardBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 255, 255, 255);
    }
  }

  Color getSummaryCardTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getSummaryCardTitleColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getSummaryCardChipColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        // Note: Cor original era branca, mas roxo faz mais sentido no tema roxo
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getSummaryCardChipTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        // Note: Cor original era roxa, mas branco faz mais sentido no chip roxo
        return Colors.white;
    }
  }

  Color getDashboardHeaderIconColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        // Note: Cor original era branca, mas preto faz mais sentido no header branco
        return Colors.black;
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getDashboardHeaderTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        // Note: Cor original era branca, mas preto faz mais sentido no header branco
        return Colors.black;
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getDashboardHeaderBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        // Note: Cor original era preta, mas branco faz mais sentido no tema light
        return Colors.white;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getBudgetListHeaderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getBudgetListHeaderTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getBudgetListCardBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 255, 255, 255);
    }
  }

  Color getBudgetListCardTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getBudgetListCardTitleColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getBudgetListSearchBarColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 49, 8, 145);
    }
  }

  Color getBudgetListSearchIconColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getBudgetListChipColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 10, 10, 10);
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getBudgetListChipTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        // Note: Cor original era roxa, mas branco faz mais sentido no chip roxo
        return Colors.white;
    }
  }

  Color getDetailHeaderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getDetailHeaderTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
      case ThemeType.roxoEscuro:
        return Colors.white; // Texto claro no header escuro
    }
  }

  Color getDetailCardColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        // Note: A cor definida era roxa, mas branco pode ser mais usual para card
        return const Color.fromARGB(255, 255, 255, 255);
    }
  }

  Color getDetailCardTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        // Note: A cor definida era roxa, mas preto pode ser mais usual para texto em card branco
        return const Color.fromARGB(255, 43, 3, 138); // Mantendo original
    }
  }

  Color getCompareHeaderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getCompareHeaderTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
      case ThemeType.roxoEscuro:
        return Colors.white; // Texto claro no header escuro
    }
  }

  Color getCompareCardBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        // Note: Cor definida era roxa, mas branco pode ser mais usual para card
        return const Color.fromARGB(255, 255, 255, 255);
    }
  }

  Color getCompareCardTitleColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        // Note: Cor definida era branca, mas roxo pode ser mais usual para título em card branco
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getCompareCardTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        // Note: Cor definida era branca, mas roxo pode ser mais usual para texto em card branco
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getCompareChartBarColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getCompareAvatarBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 230, 230, 230); // Um cinza claro
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getCompareAvatarTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        // Note: Cor original era branca, mas preto faz mais sentido em fundo claro
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getCompareSavingsTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.green;
      case ThemeType.roxoEscuro:
        // Usar um verde claro para contraste no roxo
        return Colors.greenAccent;
    }
  }

  Color getCompareSubtitleTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        // Corrigido: usar withOpacity
        return Colors.black.withAlpha((0.7 * 255).toInt());
      case ThemeType.roxoEscuro:
        // Corrigido: usar withOpacity
        return Colors.white.withAlpha((0.7 * 255).toInt());
    }
  }

  Color getCompareTableHeaderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        return Colors
            .grey.shade800; // Um cinza bem escuro para header da tabela
    }
  }

  Color getCompareTableHeaderTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getCompareTableCellColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 49, 8, 145);
    }
  }

  Color getCompareTableCellTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getCompareBorderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        // Corrigido: usar withOpacity
        return Colors.black.withAlpha((0.2 * 255).toInt());
      case ThemeType.roxoEscuro:
        // Corrigido: usar withOpacity
        return Colors.white.withAlpha((0.2 * 255).toInt());
    }
  }

  Color getDetailHeaderIconColor() {
    // Este método simplesmente retorna a cor do texto do header
    return getDetailHeaderTextColor();
  }

  Color getDetailTabSelectedColor() {
    // Este método simplesmente retorna a cor do texto do header
    return getDetailHeaderTextColor();
  }

  Color getDetailTabUnselectedColor() {
    switch (currentThemeType) {
      case ThemeType.light:
      case ThemeType.roxoEscuro:
        return Colors.white.withAlpha((0.7 * 255).toInt());
    }
  }

  Color getDetailTabIndicatorColor() {
    // Este método simplesmente retorna a cor do texto do header
    return getDetailHeaderTextColor();
  }

  Color getDetailBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.grey.shade200; // Um fundo levemente cinza para light
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getDetailLocationCardColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getDetailLocationCardTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getDetailLocationCardIconColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        // Note: Cor original era quase branca, mantendo
        return const Color.fromARGB(255, 250, 250, 250);
    }
  }

  Color getDetailLocationCardIconBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        // Corrigido: usar withOpacity
        return Colors.black.withAlpha((0.2 * 255).toInt());
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getDetailSearchBarColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        // Note: Cor original era roxa, mas branco pode ser mais usual
        return Colors.white;
    }
  }

  Color getDetailSearchBarTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        // Note: Cor original era branca, mas roxo faz mais sentido com fundo branco
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getDetailSearchBarIconColor() {
    // Este método simplesmente retorna a cor do texto da search bar
    return getDetailSearchBarTextColor();
  }

  Color getDetailFabBackgroundColor() {
    // Este método simplesmente retorna a cor do header
    return getDetailHeaderColor();
  }

  Color getDetailFabIconColor() {
    // Este método simplesmente retorna a cor do texto do header
    return getDetailHeaderTextColor();
  }

  Color getDetailDialogTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getDetailDialogButtonTextColor() {
    // Retorna a cor principal do tema (header) para botões de diálogo
    return getDetailHeaderColor();
  }

  Color getDetailTextFieldTextColor() {
    // Retorna a cor do texto do diálogo
    return getDetailDialogTextColor();
  }

  Color getDetailTextFieldLabelColor() {
    // Retorna a cor do texto do diálogo (ou uma variação)
    return getDetailDialogTextColor();
  }

  Color getDetailTextFieldBorderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        // Corrigido: usar withOpacity
        return Colors.black.withAlpha((0.2 * 255).toInt());
      case ThemeType.roxoEscuro:
        // Corrigido: usar withOpacity
        return Colors.white.withAlpha((0.2 * 255).toInt());
    }
  }

  Color getDetailEmptyStateTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        // Corrigido: usar withOpacity
        return Colors.black.withAlpha((0.7 * 255).toInt());
      case ThemeType.roxoEscuro:
        // Corrigido: usar withOpacity
        return Colors.white.withAlpha((0.7 * 255).toInt());
    }
  }

  Color getDetailLoadingColor() {
    // Retorna a cor principal do tema (header) para o loading
    return getDetailHeaderColor();
  }

  Color getDetailErrorColor() {
    // Mantém a cor de erro padrão
    return Colors.red;
  }

  Color getDetailErrorTextColor() {
    // Mantém branco para texto sobre fundo de erro
    return Colors.white;
  }

  Color getDetailSuccessBackgroundColor() {
    // Usa a cor principal do tema para sucesso
    return getDetailHeaderColor();
  }

  Color getDetailSuccessTextColor() {
    // Usa a cor do texto principal do tema para sucesso
    return getDetailHeaderTextColor();
  }

  Color getDetailCompareButtonBackgroundColor() {
    // Usa a cor principal do tema para o botão de comparar
    return getDetailHeaderColor();
  }

  Color getDetailCompareButtonTextColor() {
    // Usa a cor do texto principal do tema para o botão de comparar
    return getDetailHeaderTextColor();
  }

  Color getDetailBudgetCardTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getDetailBudgetCardTitleColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getDetailDialogBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 243, 243, 245);
    }
  }

  Color getDetailDialogHeaderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 0, 0, 0);
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getDetailDialogContentBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        // Note: Cor original era roxa, mas branco/cinza claro pode ser mais usual
        return const Color.fromARGB(
          255,
          243,
          243,
          245,
        ); // Igual ao dialog background
    }
  }

  Color getDetailDialogContentTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        // Note: Cor original era roxa escura, mas preto pode ser mais usual
        return const Color.fromARGB(255, 43, 3, 138); // Mantendo original
    }
  }

  Color getDetailInputBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        // Note: Cor original era roxa, mas branco/cinza claro pode ser mais usual
        return Colors.grey.shade200;
    }
  }

  Color getDetailInputTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        // Note: Cor original era branca, mas preto é usual para input claro
        return Colors.black;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getDetailInputLabelColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 10, 10, 10);
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getDetailInputBorderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 43, 3, 138);
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getDetailButtonBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(
          255,
          43,
          3,
          138,
        ); // Botão roxo no tema claro
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getDetailButtonTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white; // Texto branco no botão roxo
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getDetailIconColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 43, 3, 138); // Ícone roxo
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getDetailTabBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 43, 3, 138); // TabBar roxa
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 252, 252, 252);
    }
  }

  Color getDetailTabSelectedTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
      case ThemeType.roxoEscuro:
        return Colors
            .white; // Texto selecionado sempre branco (assumindo fundo escuro/roxo)
    }
  }

  Color getDetailTabUnselectedTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
      case ThemeType.roxoEscuro:
        return Colors.white.withAlpha(
          (0.2 * 255).toInt(),
        ); // Texto não selecionado mais suave
    }
  }

  Color getFinanceHeaderColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 3, 3, 3);
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 43, 3, 138);
    }
  }

  Color getFinanceHeaderTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
      case ThemeType.roxoEscuro:
        return Colors.white; // Texto claro no header escuro
    }
  }

  Color getFinanceCardBackgroundColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(255, 49, 8, 145);
    }
  }

  Color getFinanceCardTextColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getFinanceCardIconColor() {
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 43, 3, 138); // Ícone roxo
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  // --- Métodos FAB Finance ---
  // É um pouco confuso como estão definidos, mas seguindo a lógica original:
  Color getFinanceFabTextColor() {
    // Originalmente retornava getFinanceCardIconColor()
    switch (currentThemeType) {
      case ThemeType.light:
        return const Color.fromARGB(255, 43, 3, 138);
      case ThemeType.roxoEscuro:
        return Colors.white;
    }
  }

  Color getFinanceFabIconColor() {
    // Originalmente retornava getFinanceCardBackgroundColor()
    switch (currentThemeType) {
      case ThemeType.light:
        return Colors
            .white; // Ícone branco no FAB (que provavelmente será escuro/roxo)
      case ThemeType.roxoEscuro:
        return const Color.fromARGB(
          255,
          49,
          8,
          145,
        ); // Ícone roxo no FAB (que provavelmente será branco/claro)
    }
  }

  // Define o tema
  Future<void> setTheme(ThemeType themeType) async {
    try {
      _currentThemeType = themeType;
      _currentTheme = AppThemes.getThemeByType(themeType);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeType.index);

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao salvar tema: $e');
    }
  }
}
