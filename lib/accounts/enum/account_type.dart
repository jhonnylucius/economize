enum AccountType {
  checking,
  savings,
  creditCard,
  cash,
  investment,
  corrente,
  digital,
  salary,
  criptomoedas,
  actions,
  fundosDeInvestimento,
  previdenciaPrivada,
  tesouroDireto,
  cdb,
  lci,
  lca,
  poupancaDigital,
  other,
}

extension AccountTypeExtension on AccountType {
  String get displayName {
    switch (this) {
      case AccountType.savings:
        return 'Poupança';
      case AccountType.checking:
        return 'Cheque';
      case AccountType.creditCard:
        return 'Cartão de Crédito';
      case AccountType.cash:
        return 'Dinheiro';
      case AccountType.investment:
        return 'Investimento';
      case AccountType.corrente:
        return 'Conta Corrente';
      case AccountType.digital:
        return 'Conta Digital';
      case AccountType.salary:
        return 'Salário';
      case AccountType.criptomoedas:
        return 'Criptomoedas';
      case AccountType.actions:
        return 'Ações';
      case AccountType.fundosDeInvestimento:
        return 'Fundos de Investimento';
      case AccountType.previdenciaPrivada:
        return 'Previdência Privada';
      case AccountType.tesouroDireto:
        return 'Tesouro Direto';
      case AccountType.cdb:
        return 'CDB';
      case AccountType.lci:
        return 'LCI';
      case AccountType.lca:
        return 'LCA';
      case AccountType.poupancaDigital:
        return 'Poupança Digital';
      case AccountType.other:
        return 'Outros';
    }
  }
}

String accountTypeToString(AccountType type) {
  switch (type) {
    case AccountType.checking:
      return 'Cheque';
    case AccountType.savings:
      return 'Poupança';
    case AccountType.creditCard:
      return 'Cartão de Crédito';
    case AccountType.cash:
      return 'Dinheiro';
    case AccountType.investment:
      return 'Investimento';
    case AccountType.corrente:
      return 'Conta Corrente';
    case AccountType.digital:
      return 'Conta Digital';
    case AccountType.salary:
      return 'Salário';
    case AccountType.criptomoedas:
      return 'Criptomoedas';
    case AccountType.actions:
      return 'Ações';
    case AccountType.fundosDeInvestimento:
      return 'Fundos de Investimento';
    case AccountType.previdenciaPrivada:
      return 'Previdência Privada';
    case AccountType.tesouroDireto:
      return 'Tesouro Direto';
    case AccountType.cdb:
      return 'CDB';
    case AccountType.lci:
      return 'LCI';
    case AccountType.lca:
      return 'LCA';
    case AccountType.poupancaDigital:
      return 'Poupança Digital';
    case AccountType.other:
      return 'Outros';
  }
}
