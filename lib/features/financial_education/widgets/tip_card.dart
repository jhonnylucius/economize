import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/interactive_animations.dart';
import 'package:economize/features/financial_education/models/financial_tip.dart';
import 'package:flutter/material.dart';

class TipCard extends StatefulWidget {
  final FinancialTip tip;

  const TipCard({
    super.key,
    required this.tip,
  });

  @override
  State<TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<TipCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tip = widget.tip;

    return PressableCard(
      onPress: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: GlassContainer(
        borderRadius: 16,
        blur: 5,
        opacity: 0.05,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withAlpha((0.8 * 255).toInt()),
              ],
            ),
            border: Border.all(
              color: theme.colorScheme.primary.withAlpha((0.3 * 255).toInt()),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withAlpha((0.1 * 255).toInt()),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do card com ícone e título
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withAlpha((0.2 * 255).toInt()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        tip.category.icon,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip.title,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo do card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.shortSummary ?? '',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(height: 12),
                      Text(
                        tip.description,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withAlpha((0.8 * 255).toInt()),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Exemplo da dica
                      if (tip.examples!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withAlpha((0.5 * 255).toInt()),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary
                                  .withAlpha((0.2 * 255).toInt()),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Exemplo:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tip.examples!.first,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              // Rodapé do card
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer
                      .withAlpha((0.5 * 255).toInt()),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: theme.colorScheme.primary
                          .withAlpha((0.7 * 255).toInt()),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Toque para detalhes',
                      style: TextStyle(
                        color: theme.colorScheme.primary
                            .withAlpha((0.8 * 255).toInt()),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        foregroundColor: theme.colorScheme.primary,
                      ),
                      child: Row(
                        children: [
                          Text(
                            _isExpanded ? 'Mostrar menos' : 'Mostrar mais',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
