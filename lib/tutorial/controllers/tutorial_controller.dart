import 'package:economize/tutorial/widgets/tutorial_navigation_buttons.dart';
import 'package:economize/tutorial/widgets/tutorial_overlay.dart';
import 'package:economize/tutorial/widgets/tutorial_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:economize/tutorial/models/tutorial_step.dart';

/// Enum para o estado atual do tutorial
enum TutorialState {
  /// Tutorial não está sendo exibido
  inactive,

  /// Tutorial está sendo exibido
  active,

  /// Tutorial foi concluído
  completed,

  /// Tutorial foi pulado pelo usuário
  skipped,
}

/// Controla a lógica e o estado do tutorial interativo
class TutorialController extends ChangeNotifier {
  /// Identificador único para este tutorial
  final String tutorialId;

  /// Lista de passos do tutorial
  final List<TutorialStep> steps;

  /// Contexto para navegar e obter o tema
  final BuildContext context;

  /// Se deve mostrar o tutorial apenas uma vez
  final bool showOnlyOnce;

  /// Se deve salvar o progresso do tutorial entre sessões
  final bool saveProgress;

  /// Chave para armazenar se o tutorial foi concluído
  late final String _completedKey;

  /// Chave para armazenar o último passo visto
  late final String _lastStepKey;

  /// Estado atual do tutorial
  TutorialState _state = TutorialState.inactive;

  /// Índice do passo atual
  int _currentStepIndex = 0;

  /// Obtém o estado atual do tutorial
  TutorialState get state => _state;

  /// Obtém o passo atual do tutorial
  TutorialStep get currentStep => steps[_currentStepIndex];

  /// Obtém o índice do passo atual
  int get currentStepIndex => _currentStepIndex;

  /// Verifica se está no primeiro passo
  bool get isFirstStep => _currentStepIndex == 0;

  /// Verifica se está no último passo
  bool get isLastStep => _currentStepIndex == steps.length - 1;

  /// Obtém o número total de passos
  int get totalSteps => steps.length;

  /// Verifica se o tutorial está ativo
  bool get isActive => _state == TutorialState.active;

  TutorialController({
    required this.tutorialId,
    required this.steps,
    required this.context,
    this.showOnlyOnce = true,
    this.saveProgress = true,
  }) {
    _completedKey = 'tutorial_completed_$tutorialId';
    _lastStepKey = 'tutorial_last_step_$tutorialId';

    // Validação para garantir que há pelo menos um passo
    if (steps.isEmpty) {
      throw ArgumentError('Tutorial deve ter pelo menos um passo');
    }
  }

  /// Inicia o tutorial, verificando se já foi mostrado antes
  Future<void> initialize() async {
    if (steps.isEmpty) return;

    if (showOnlyOnce) {
      final prefs = await SharedPreferences.getInstance();
      final bool tutorialCompleted = prefs.getBool(_completedKey) ?? false;

      if (tutorialCompleted) {
        _state = TutorialState.completed;
        notifyListeners();
        return;
      }
    }

    if (saveProgress) {
      await _loadProgress();
    }
  }

  /// Inicia o tutorial manualmente (útil para botões de ajuda)
  void start() {
    if (steps.isEmpty) return;

    _state = TutorialState.active;
    notifyListeners();
  }

  /// Avança para o próximo passo
  Future<void> nextStep() async {
    if (!isActive || isLastStep) {
      await _completeTutorial();
      return;
    }

    _currentStepIndex++;

    if (saveProgress) {
      await _saveProgress();
    }

    notifyListeners();
  }

  /// Volta para o passo anterior
  Future<void> previousStep() async {
    if (!isActive || isFirstStep) return;

    _currentStepIndex--;

    if (saveProgress) {
      await _saveProgress();
    }

    notifyListeners();
  }

  /// Pula para um passo específico pelo índice
  Future<void> goToStep(int index) async {
    if (!isActive || index < 0 || index >= steps.length) return;

    _currentStepIndex = index;

    if (saveProgress) {
      await _saveProgress();
    }

    notifyListeners();
  }

  /// Pula o tutorial completamente
  Future<void> skip() async {
    if (!isActive) return;

    _state = TutorialState.skipped;

    if (showOnlyOnce) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedKey, true);
    }

    notifyListeners();
  }

  /// Reinicia o tutorial do primeiro passo
  Future<void> restart() async {
    _currentStepIndex = 0;
    _state = TutorialState.active;

    if (saveProgress) {
      await _saveProgress();
    }

    notifyListeners();
  }

  /// Marca o tutorial como concluído
  Future<void> _completeTutorial() async {
    _state = TutorialState.completed;

    if (showOnlyOnce) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedKey, true);
    }

    notifyListeners();
  }

  /// Salva o progresso atual do tutorial
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastStepKey, _currentStepIndex);
  }

  /// Carrega o progresso salvo anteriormente
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStepIndex = prefs.getInt(_lastStepKey) ?? 0;

    // Garantir que o índice está dentro dos limites
    if (_currentStepIndex >= steps.length) {
      _currentStepIndex = 0;
    }
  }

  /// Reseta o status de concluído (útil para testes)
  Future<void> resetCompletionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
    await prefs.remove(_lastStepKey);
    _currentStepIndex = 0;
    _state = TutorialState.inactive;
    notifyListeners();
  }

  /// Verifica se o tutorial já foi concluído
  Future<bool> hasCompleted() async {
    if (!showOnlyOnce) return false;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }
}

/// Provedor para acessar o controlador do tutorial em qualquer lugar da árvore de widgets
class TutorialControllerProvider extends InheritedNotifier<TutorialController> {
  const TutorialControllerProvider({
    super.key,
    required TutorialController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Obtém o controlador do tutorial a partir do contexto
  static TutorialController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<TutorialControllerProvider>();
    if (provider == null) {
      throw Exception('TutorialControllerProvider não encontrado no contexto');
    }
    return provider.notifier!;
  }
}

/// Widget que exibe o tutorial interativo
class TutorialWidget extends StatefulWidget {
  /// Controlador do tutorial
  final TutorialController controller;

  /// Builder para o conteúdo normal (quando o tutorial não está ativo)
  final Widget Function(BuildContext context) builder;

  /// Builder para o overlay do tutorial (quando o tutorial está ativo)
  final Widget Function(BuildContext context, TutorialStep step,
      TutorialController controller)? overlayBuilder;

  const TutorialWidget({
    super.key,
    required this.controller,
    required this.builder,
    this.overlayBuilder,
  });

  @override
  State<TutorialWidget> createState() => _TutorialWidgetState();
}

class _TutorialWidgetState extends State<TutorialWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return TutorialControllerProvider(
      controller: widget.controller,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final isActive = widget.controller.isActive;

          // Conteúdo normal
          final content = widget.builder(context);

          if (!isActive) return content;

          // Overlay do tutorial
          final overlayBuilder = widget.overlayBuilder;
          if (overlayBuilder != null) {
            return Stack(
              children: [
                content,
                Positioned.fill(
                  child: overlayBuilder(
                    context,
                    widget.controller.currentStep,
                    widget.controller,
                  ),
                ),
              ],
            );
          }

          // Overlay padrão se não houver builder personalizado
          return Stack(
            children: [
              content,
              Positioned.fill(
                child: _buildDefaultOverlay(context),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Constrói o overlay padrão para o tutorial
  /// Constrói o overlay padrão para o tutorial
  Widget _buildDefaultOverlay(BuildContext context) {
    final currentStep = widget.controller.currentStep;
    final isFirstStep = widget.controller.isFirstStep;
    final isLastStep = widget.controller.isLastStep;

    // Obter o retângulo alvo para o elemento que queremos destacar
    final targetKey = currentStep.targetKey;
    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;

    // Se não conseguirmos encontrar o elemento, mostrar um overlay básico
    if (renderBox == null || !renderBox.hasSize) {
      return Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Elemento não encontrado',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TutorialNavigationButtons(
                    onNext: widget.controller.nextStep,
                    onSkip: widget.controller.skip,
                    onPrevious:
                        isFirstStep ? null : widget.controller.previousStep,
                    isFirstStep: isFirstStep,
                    isLastStep: isLastStep,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Calcular o retângulo alvo
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Rect targetRect = Rect.fromLTWH(
      offset.dx - currentStep.spotlightPadding.left,
      offset.dy - currentStep.spotlightPadding.top,
      size.width + currentStep.spotlightPadding.horizontal,
      size.height + currentStep.spotlightPadding.vertical,
    );

    return TutorialOverlay(
      step: currentStep,
      onTargetTap: () {
        // Se houver uma ação personalizada, executá-la
        if (currentStep.onTargetClick != null) {
          currentStep.onTargetClick!();
        } else {
          // Caso contrário, avançar para o próximo passo
          widget.controller.nextStep();
        }
      },
      onBackdropTap: () {
        // Não fazer nada, para evitar cliques acidentais
      },
      tooltip: TutorialTooltip(
        step: currentStep,
        targetRect: targetRect,
        isFirstStep: isFirstStep,
        isLastStep: isLastStep,
        onNext: widget.controller.nextStep,
        onPrevious: isFirstStep ? null : widget.controller.previousStep,
        onSkip: widget.controller.skip,
      ),
    );
  }
}
/*Características do TutorialController
Este controlador é o coração do nosso sistema de tutorial e possui várias características importantes:

1. Gerenciamento de Estado
Estados Definidos: Através do enum TutorialState, temos uma clara representação dos estados possíveis
ChangeNotifier: Integração com o sistema de reatividade do Flutter para atualizar a UI automaticamente
Notificações Apropriadas: Chama notifyListeners() sempre que o estado muda
2. Navegação Robusta
Métodos Intuitivos: nextStep(), previousStep(), goToStep() para navegação
Validação de Limites: Verifica se está no primeiro/último passo para evitar erros
Opções Completas: Permite pular, reiniciar ou completar o tutorial
3. Persistência de Dados
Mostrar Apenas Uma Vez: Opção para exibir o tutorial apenas na primeira execução
Salvamento de Progresso: Permite continuar de onde parou em uma sessão anterior
Reset de Status: Métodos para limpar os dados salvos (útil para testes)
4. Integração com a UI
TutorialControllerProvider: Disponibiliza o controlador em toda a árvore de widgets
TutorialWidget: Componente pronto para uso que gerencia a exibição do tutorial
Builder Patterns: Flexibilidade para personalizar a aparência do tutorial
5. Gerenciamento de Múltiplos Tutoriais
IDs Únicos: Permite ter diferentes tutoriais para diferentes partes do app
Isolamento de Dados: Cada tutorial tem seu próprio espaço de armazenamento. 
Este controlador completa nossa infraestrutura básica de tutorial, conectando os componentes visuais que já criamos com a lógica de estado e navegação.*/
