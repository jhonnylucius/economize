/*tutorial_tooltip.dart
**Parte do plano: 3.2 (3) - Tooltip (Dica)
**Conteúdo: Card flutuante que exibe explicações e se posiciona relativo ao elemento destacado.*/
import 'package:flutter/material.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/tutorial/models/tutorial_step.dart';
import 'package:economize/tutorial/models/tutorial_position.dart';

/// Widget de tooltip para exibir informações durante o tutorial
/// Exibe título, descrição e botões de navegação
class TutorialTooltip extends StatefulWidget {
  /// Passo atual do tutorial
  final TutorialStep step;

  /// Retângulo do elemento destacado
  final Rect targetRect;

  /// Função chamada quando o usuário clica em "Anterior"
  final VoidCallback? onPrevious;

  /// Função chamada quando o usuário clica em "Próximo"
  final VoidCallback onNext;

  /// Função chamada quando o usuário clica em "Pular"
  final VoidCallback onSkip;

  /// Se é o primeiro passo do tutorial
  final bool isFirstStep;

  /// Se é o último passo do tutorial
  final bool isLastStep;

  /// Cor de fundo da tooltip
  final Color? backgroundColor;

  /// Cor do texto
  final Color? textColor;

  /// Cor dos botões
  final Color? buttonColor;

  /// Largura máxima da tooltip
  final double maxWidth;

  const TutorialTooltip({
    Key? key,
    required this.step,
    required this.targetRect,
    required this.onNext,
    required this.onSkip,
    this.onPrevious,
    this.isFirstStep = false,
    this.isLastStep = false,
    this.backgroundColor,
    this.textColor,
    this.buttonColor,
    this.maxWidth = 300,
  }) : super(key: key);

  @override
  State<TutorialTooltip> createState() => _TutorialTooltipState();
}

class _TutorialTooltipState extends State<TutorialTooltip> {
  /// Posição calculada da tooltip
  late TutorialPosition _tooltipPosition;

  /// Posição (offset) da tooltip na tela
  late Offset _tooltipOffset;

  /// Tamanho do tooltip para cálculos de posicionamento
  Size _tooltipSize = const Size(200, 100);

  /// Chave global para medir o tamanho do tooltip
  final GlobalKey _tooltipKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Definir posição inicial (será recalculada depois que o layout for concluído)
    _tooltipPosition = widget.step.position;
    _tooltipOffset = Offset.zero;

    // Agendar medição de tamanho após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback(_updateTooltipPosition);
  }

  @override
  void didUpdateWidget(TutorialTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Recalcular posição quando o widget ou o alvo mudar
    if (oldWidget.targetRect != widget.targetRect ||
        oldWidget.step != widget.step) {
      WidgetsBinding.instance.addPostFrameCallback(_updateTooltipPosition);
    }
  }

  /// Atualiza a posição da tooltip com base no tamanho e posição do alvo
  void _updateTooltipPosition(_) {
    // Obter o tamanho atual do tooltip
    final RenderBox? renderBox =
        _tooltipKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    setState(() {
      // Salvar o tamanho medido
      _tooltipSize = renderBox.size;

      // Calcular a melhor posição se for "auto"
      final position = widget.step.position == TutorialPosition.auto
          ? TutorialPositionCalculator.calculateOptimalPosition(
              widget.targetRect, _tooltipSize, MediaQuery.of(context).size)
          : widget.step.position;

      _tooltipPosition = position;

      // Calcular o offset da tooltip
      _tooltipOffset = TutorialPositionCalculator.calculateTooltipPosition(
        targetRect: widget.targetRect,
        tooltipSize: _tooltipSize,
        position: position,
        screenSize: MediaQuery.of(context).size,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tooltip posicionada
        Positioned(
          left: _tooltipOffset.dx,
          top: _tooltipOffset.dy,
          child: ScaleAnimation(
            begin: 0.7,
            end: 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: _buildTooltip(context),
          ),
        ),
      ],
    );
  }

  /// Constrói o corpo principal da tooltip
  Widget _buildTooltip(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tooltipBackgroundColor =
        widget.backgroundColor ?? (isDark ? Colors.grey[850]! : Colors.white);
    final textColor =
        widget.textColor ?? (isDark ? Colors.white : Colors.black87);
    final buttonColor =
        widget.buttonColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      key: _tooltipKey,
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
        minWidth: 150,
      ),
      child: Container(
        // Aqui definimos a cor de fundo
        color: tooltipBackgroundColor,
        child: GlassContainer(
          borderRadius: 16,
          opacity: isDark ? 0.15 : 0.1,
          borderColor:
              isDark ? Colors.white.withAlpha((0.2 * 255).round()) : null,
          // Removemos o backgroundColor daqui
          child: Stack(
            children: [
              // Seta apontando para o elemento
              _buildArrow(),

              // Conteúdo principal
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título
                    Text(
                      widget.step.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Descrição
                    Text(
                      widget.step.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Widget customizado (se houver)
                    if (widget.step.customWidget != null) ...[
                      widget.step.customWidget!,
                      const SizedBox(height: 16),
                    ],

                    // Botões de navegação
                    _buildNavigationButtons(context, buttonColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói a seta que aponta para o elemento destacado
  Widget _buildArrow() {
    // Tamanho da seta
    const arrowSize = 12.0;

    // Posicionamento da seta com base na posição da tooltip
    Widget arrow;
    Alignment alignment;

    switch (_tooltipPosition) {
      case TutorialPosition.top:
        arrow = _buildBottomArrow(arrowSize);
        alignment = Alignment.bottomCenter;
        break;
      case TutorialPosition.bottom:
        arrow = _buildTopArrow(arrowSize);
        alignment = Alignment.topCenter;
        break;
      case TutorialPosition.left:
        arrow = _buildRightArrow(arrowSize);
        alignment = Alignment.centerRight;
        break;
      case TutorialPosition.right:
        arrow = _buildLeftArrow(arrowSize);
        alignment = Alignment.centerLeft;
        break;
      case TutorialPosition.auto:
        // Caso improvável, mas vamos usar uma seta para baixo como fallback
        arrow = _buildBottomArrow(arrowSize);
        alignment = Alignment.bottomCenter;
        break;
    }

    return Align(
      alignment: alignment,
      child: arrow,
    );
  }

  // Setas direcionais
  Widget _buildTopArrow(double size) {
    return CustomPaint(
      size: Size(size * 2, size),
      painter: _ArrowPainter(direction: _ArrowDirection.up),
    );
  }

  Widget _buildBottomArrow(double size) {
    return CustomPaint(
      size: Size(size * 2, size),
      painter: _ArrowPainter(direction: _ArrowDirection.down),
    );
  }

  Widget _buildLeftArrow(double size) {
    return CustomPaint(
      size: Size(size, size * 2),
      painter: _ArrowPainter(direction: _ArrowDirection.left),
    );
  }

  Widget _buildRightArrow(double size) {
    return CustomPaint(
      size: Size(size, size * 2),
      painter: _ArrowPainter(direction: _ArrowDirection.right),
    );
  }

  /// Constrói os botões de navegação (Pular, Anterior, Próximo/Concluir)
  Widget _buildNavigationButtons(BuildContext context, Color buttonColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Botão Pular (visível se o passo permitir pular)
        if (widget.step.canSkip)
          TextButton(
            onPressed: widget.onSkip,
            child: Text(
              'Pular',
              style: TextStyle(
                color: buttonColor.withOpacity(0.7),
              ),
            ),
          )
        else
          const SizedBox.shrink(),

        // Botões de navegação (Anterior e Próximo/Concluir)
        Row(
          children: [
            // Botão Anterior (visível exceto no primeiro passo)
            if (!widget.isFirstStep && widget.onPrevious != null)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onPrevious,
                color: buttonColor,
                tooltip: 'Anterior',
              ),

            // Botão Próximo/Concluir
            ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.isLastStep ? 'Concluir' : 'Próximo'),
                  if (!widget.isLastStep) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Direções possíveis para a seta
enum _ArrowDirection {
  up,
  down,
  left,
  right,
}

/// Painter customizado para desenhar a seta
class _ArrowPainter extends CustomPainter {
  final _ArrowDirection direction;

  _ArrowPainter({required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final path = Path();

    switch (direction) {
      case _ArrowDirection.up:
        // Seta apontando para cima
        path.moveTo(0, size.height);
        path.lineTo(size.width / 2, 0);
        path.lineTo(size.width, size.height);
        path.close();
        break;
      case _ArrowDirection.down:
        // Seta apontando para baixo
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width / 2, size.height);
        path.close();
        break;
      case _ArrowDirection.left:
        // Seta apontando para esquerda
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height / 2);
        path.close();
        break;
      case _ArrowDirection.right:
        // Seta apontando para direita
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height / 2);
        path.close();
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) {
    return direction != oldDelegate.direction;
  }
}
/*Características do TutorialTooltip
O componente TutorialTooltip tem diversas características que o tornam poderoso e flexível:

1. Design Visual Sofisticado
Efeito de Vidro (Glass): Utiliza o GlassContainer do seu projeto para um visual moderno
Setas Direcionais: Desenha uma seta que aponta para o elemento destacado
Animação de Entrada: Animação suave de escala ao aparecer
2. Posicionamento Inteligente
Cálculo Automático: Usa o TutorialPositionCalculator para posicionar corretamente
Adaptação à Tela: Garante que a tooltip sempre fique dentro dos limites da tela
Atualização Dinâmica: Recalcula a posição quando o tamanho ou layout muda
3. Conteúdo Rico
Título e Descrição: Exibe o conteúdo explicativo de forma clara
Widgets Customizados: Suporta widgets personalizados para demonstrações específicas
Botões de Navegação: Interface intuitiva para navegar entre os passos
4. Navegação Intuitiva
Botões Contextuais: "Anterior", "Próximo" e "Concluir" conforme o contexto
Opção de Pular: Permite pular o tutorial se configurado no passo
Visual Adaptável: Cores e estilos adaptáveis ao tema do aplicativo
5. Implementação Técnica Robusta
Medição de Layout: Usa GlobalKey para medir o tamanho real do tooltip
Atualização Eficiente: Usa didUpdateWidget para reagir a mudanças
Render Otimizado: Implementação eficiente com CustomPainter para as setas
Este componente completa a parte visual principal do sistema de tutorial, fornecendo uma maneira elegante e informativa de guiar os usuários através das funcionalidades do seu aplicativo.*/
