import 'package:flutter/material.dart';

/// Define os tokens primitivos de raios para cantos arredondados no sistema de design
///
/// Estabelece valores consistentes para bordas arredondadas em toda a aplicação,
/// criando uma hierarquia visual e garantindo consistência entre componentes.
class RadiusTokens {
  // Valores básicos para cantos arredondados

  /// Raio não arredondado (0px) - para elementos quadrados/retangulares
  static const double none = 0.0;

  /// Raio mínimo (2px) - arredondamento sutil quase imperceptível
  static const double xxs = 2.0;

  /// Raio extra-pequeno (4px) - para elementos com arredondamento sutil
  static const double xs = 4.0;

  /// Raio pequeno (8px) - para cards e containers com arredondamento suave
  static const double s = 8.0;

  /// Raio médio (12px) - para elementos que precisam ser claramente arredondados
  static const double m = 12.0;

  /// Raio grande (16px) - para elementos que destacam seu arredondamento
  static const double l = 16.0;

  /// Raio extra-grande (24px) - para elementos com forte arredondamento
  static const double xl = 24.0;

  /// Raio circular (9999px) - para criar elementos completamente arredondados/circulares
  static const double full = 9999.0;

  // Valores para usos específicos

  /// Raio padrão para botões - arredondamento consistente em todos os botões
  static const double button = s;

  /// Raio padrão para cards - arredondamento suave para todos os cards
  static const double card = s;

  /// Raio para botões de ação flutuante
  static const double floatingActionButton = full;

  /// Raio para botões de ícone - normalmente circulares
  static const double iconButton = full;

  /// Raio para chips e tags - pequenos elementos com leve arredondamento
  static const double chip = l;

  /// Raio para inputs - campos de entrada com cantos sutilmente arredondados
  static const double input = xs;

  /// Raio para bottom sheets - folhas de baixo com cantos superiores arredondados
  static const double bottomSheet = l;

  /// Raio para modais - diálogos com cantos arredondados
  static const double modal = m;

  /// Raio para imagens - padrão para imagens contidas em cards
  static const double image = s;

  /// Raio para badges e indicadores
  static const double badge = s;

  /// Raio para avatares - imagens de perfil circular
  static const double avatar = full;

  /// Obtém um raio de borda circular
  /// Útil para criar elementos perfeitamente circulares
  static BorderRadius circular(double radius) {
    return BorderRadius.circular(radius);
  }

  /// Obtém um raio de borda apenas para os cantos superiores
  /// Útil para bottom sheets e cards especiais
  static BorderRadius onlyTop(double radius) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
  }

  /// Obtém um raio de borda apenas para os cantos inferiores
  /// Útil para headers de cards especiais
  static BorderRadius onlyBottom(double radius) {
    return BorderRadius.only(
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
  }

  /// Obtém um raio de borda personalizado para cada canto
  /// Permite criar formas personalizadas com diferentes raios em cada canto
  static BorderRadius custom({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomLeft: Radius.circular(bottomLeft),
      bottomRight: Radius.circular(bottomRight),
    );
  }
}
