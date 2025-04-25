import 'package:flutter/material.dart';

enum TipCategory {
  savingMoney, // Economia de dinheiro
  smartShopping, // Compras inteligentes
  budgeting, // Orçamento
  negotiation, // Negociação
  investment, // Investimento básico
  financeiro,
}

extension TipCategoryExtension on TipCategory {
  String get displayName {
    switch (this) {
      case TipCategory.savingMoney:
        return 'Economia';
      case TipCategory.smartShopping:
        return 'Compras Inteligentes';
      case TipCategory.budgeting:
        return 'Orçamento';
      case TipCategory.negotiation:
        return 'Negociação';
      case TipCategory.investment:
        return 'Investimento';
      case TipCategory.financeiro:
        return 'Financeiro';
    }
  }

  IconData get icon {
    switch (this) {
      case TipCategory.savingMoney:
        return Icons.savings;
      case TipCategory.smartShopping:
        return Icons.shopping_cart;
      case TipCategory.budgeting:
        return Icons.account_balance_wallet;
      case TipCategory.negotiation:
        return Icons.handshake;
      case TipCategory.investment:
        return Icons.trending_up;
      case TipCategory.financeiro:
        return Icons.monetization_on;
    }
  }
}

class FinancialTip {
  final String title; // Título da dica
  final String description; // Descrição detalhada
  final TipCategory category; // Categoria
  final String? shortSummary; // Resumo curto (opcional)
  final List<String> steps; // Passos práticos
  final List<String>? examples; // Exemplos (opcional)

  const FinancialTip({
    required this.title,
    required this.description,
    required this.category,
    this.shortSummary,
    required this.steps,
    this.examples,
  });

  // Converte para Map (útil para persistência)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.toString(),
      'shortSummary': shortSummary,
      'steps': steps,
      'examples': examples,
    };
  }

  // Cria objeto a partir de um Map
  factory FinancialTip.fromMap(Map<String, dynamic> map) {
    return FinancialTip(
      title: map['title'],
      description: map['description'],
      category: TipCategory.values.firstWhere(
        (e) => e.toString() == map['category'],
      ),
      shortSummary: map['shortSummary'],
      steps: List<String>.from(map['steps']),
      examples:
          map['examples'] != null ? List<String>.from(map['examples']) : null,
    );
  }
}
