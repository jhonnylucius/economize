/// Define os tokens primitivos de espaçamento do sistema de design
///
/// Estabelece uma escala consistente de espaçamentos que devem ser usados
/// em toda a aplicação para margens, paddings e distâncias entre elementos.
class SpacingTokens {
  // Escala de espaçamento principal (múltiplos de 4)

  /// Espaçamento mínimo (2px) - usado para separações muito pequenas
  static const double xxxs = 2.0;

  /// Espaçamento extra-extra-pequeno (4px)
  /// Útil para espaçamento interno mínimo ou entre elementos muito próximos
  static const double xxs = 4.0;

  /// Espaçamento extra-pequeno (8px)
  /// Comumente usado para padding interno em elementos compactos
  static const double xs = 8.0;

  /// Espaçamento pequeno (12px)
  /// Bom para espaçamentos internos em cards ou entre elementos relacionados
  static const double s = 12.0;

  /// Espaçamento médio (16px) - valor padrão para a maioria dos espaçamentos
  /// Usado como padrão para padding de containers e margens entre componentes
  static const double m = 16.0;

  /// Espaçamento grande (24px)
  /// Para separação mais expressiva entre grupos de conteúdo relacionados
  static const double l = 24.0;

  /// Espaçamento extra-grande (32px)
  /// Para separar seções distintas de conteúdo
  static const double xl = 32.0;

  /// Espaçamento extra-extra-grande (48px)
  /// Para grandes separações visuais entre blocos importantes de conteúdo
  static const double xxl = 48.0;

  /// Espaçamento máximo (64px)
  /// Para separações muito grandes ou margens de página
  static const double xxxl = 64.0;

  // Valores específicos contextuais

  /// Margem padrão para o conteúdo da página
  static const double pageMargin = m;

  /// Espaçamento entre itens em listas
  static const double listItemSpacing = s;

  /// Espaçamento entre seções
  static const double sectionSpacing = xl;

  /// Espaçamento padrão para inputs
  static const double inputPadding = s;

  /// Margem interna de cards
  static const double cardPadding = m;

  /// Espaço entre elementos relacionados em um grupo
  static const double relatedElementSpacing = xs;

  /// Espaço entre grupos de elementos
  static const double groupSpacing = l;

  /// Espaçamento para indentação (ex: listas hierárquicas)
  static const double indentationSpacing = m;

  /// Espaçamento interno em botões
  static const double buttonPadding = s;

  /// Espaçamento vertical entre linhas de texto
  static const double lineSpacing = xs;

  /// Retorna um espaçamento na escala com base em um multiplicador
  /// Útil para criar espaçamentos proporcionais dinamicamente
  static double scale(double factor) {
    // Baseado na unidade de 4.0
    return 4.0 * factor;
  }
}
