import 'dart:math';

import 'package:flutter/material.dart';
import 'package:economize/tutorial/controllers/tutorial_controller.dart';
import 'package:economize/tutorial/models/tutorial_step.dart';
import 'package:economize/tutorial/services/tutorial_storage.dart';
import 'package:economize/tutorial/widgets/tutorial_overlay.dart';
import 'package:economize/tutorial/widgets/tutorial_spotlight.dart';
import 'package:economize/tutorial/widgets/tutorial_tooltip.dart';

/// Serviço principal do tutorial interativo
/// Fornece uma interface simplificada para gerenciar tutoriais em diferentes telas
class TutorialService {
  // Singleton
  static final TutorialService _instance = TutorialService._internal();

  factory TutorialService() => _instance;

  TutorialService._internal();

  /// Mapa de tutoriais registrados (por ID)
  final Map<String, List<TutorialStep>> _registeredTutorials = {};

  /// Controlador do tutorial ativo atualmente
  TutorialController? _activeController;

  /// Obtém o controlador ativo (se houver)
  TutorialController? get activeController => _activeController;

  /// ID do tutorial exibido atualmente
  String? activeTutorialId;

  /// Registra um tutorial para uma tela específica
  void registerTutorial(String tutorialId, List<TutorialStep> steps) {
    _registeredTutorials[tutorialId] = steps;
  }

  /// Inicializa o sistema de tutorial e verifica se deve mostrar o tutorial inicial
  Future<bool> initialize({
    String? initialTutorialId,
    BuildContext? contextForInitialTutorial,
  }) async {
    // Verificar se é o primeiro lançamento do app
    final isFirstLaunch = await TutorialStorage.isFirstLaunch();

    // Se for a primeira execução e um tutorial inicial foi especificado
    if (isFirstLaunch &&
        initialTutorialId != null &&
        contextForInitialTutorial != null) {
      // Agendar o tutorial inicial para ser mostrado após a renderização da tela
      WidgetsBinding.instance.addPostFrameCallback((_) {
        startTutorial(
          initialTutorialId,
          contextForInitialTutorial,
          forceShow: true,
        );
      });
    }

    return isFirstLaunch;
  }

  /// Inicia um tutorial específico
  /// Retorna true se o tutorial foi iniciado, false se já foi concluído ou não existe
  Future<bool> startTutorial(
    String tutorialId,
    BuildContext context, {
    bool forceShow = false,
    bool showOnlyOnce = true,
  }) async {
    // Verificar se o tutorial está registrado
    if (!_registeredTutorials.containsKey(tutorialId)) {
      debugPrint('Tutorial não encontrado: $tutorialId');
      return false;
    }

    // Verificar se o tutorial já foi concluído
    final shouldShow = await TutorialStorage.shouldShowTutorial(
      tutorialId: tutorialId,
      showOnlyOnce: showOnlyOnce,
      forceShow: forceShow,
    );

    if (!shouldShow && !forceShow) {
      debugPrint('Tutorial já foi concluído: $tutorialId');
      return false;
    }

    // Obter os passos do tutorial
    final steps = _registeredTutorials[tutorialId]!;

    // Criar um controlador para o tutorial
    final controller = TutorialController(
      tutorialId: tutorialId,
      steps: steps,
      context: context,
      showOnlyOnce: showOnlyOnce,
    );

    // Atualizar o controlador ativo
    _activeController = controller;
    activeTutorialId = tutorialId;

    // Iniciar o tutorial
    controller.start();

    return true;
  }

  /// Exibe um tutorial embutido (overlay) na tela atual
  Widget buildTutorialOverlay(
    BuildContext context, {
    required String tutorialId,
    bool forceShow = false,
    bool showOnlyOnce = true,
    required Widget child,
  }) {
    // Verificar se o tutorial está registrado
    if (!_registeredTutorials.containsKey(tutorialId)) {
      debugPrint('Tutorial não encontrado para overlay: $tutorialId');
      return child;
    }

    // Obter os passos do tutorial
    final steps = _registeredTutorials[tutorialId]!;

    // Criar um controlador para o tutorial
    final controller = TutorialController(
      tutorialId: tutorialId,
      steps: steps,
      context: context,
      showOnlyOnce: showOnlyOnce,
    );

    // Retornar um widget que exibe o tutorial
    return TutorialWidget(
      controller: controller,
      builder: (context) => child,
      overlayBuilder: (context, step, controller) {
        return _buildDefaultOverlay(context, step, controller);
      },
    );
  }

  /// Constrói o overlay padrão para o tutorial
  Widget _buildDefaultOverlay(
      BuildContext context, TutorialStep step, TutorialController controller) {
    // Obter a posição do elemento alvo
    final targetRect = step.getTargetPosition(context);

    if (targetRect == null) {
      // Fallback se não conseguir encontrar o elemento
      return Container(
        color: Colors.black54,
        child: Center(
          child: Text(
            'Não foi possível encontrar o elemento',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Construir o overlay com spotlight e tooltip
    return TutorialOverlay(
      step: step,
      onTargetTap: () {
        // Se houver uma ação personalizada, executá-la
        if (step.onTargetClick != null) {
          step.onTargetClick!();
        } else {
          // Caso contrário, avançar para o próximo passo
          controller.nextStep();
        }
      },
      onBackdropTap: () {
        // Não fazer nada, para evitar cliques acidentais
        // Ou implementar uma lógica específica, se desejado
      },
      tooltip: TutorialTooltip(
        step: step,
        targetRect: targetRect,
        isFirstStep: controller.isFirstStep,
        isLastStep: controller.isLastStep,
        onNext: controller.nextStep,
        onPrevious: controller.isFirstStep ? null : controller.previousStep,
        onSkip: controller.skip,
      ),
    );
  }

  /// Encerra o tutorial ativo (se houver)
  void endActiveTutorial() {
    if (_activeController != null) {
      _activeController!.skip();
      _activeController = null;
      activeTutorialId = null;
    }
  }

  /// Verifica se um tutorial específico já foi concluído
  Future<bool> isTutorialCompleted(String tutorialId) async {
    return await TutorialStorage.isTutorialCompleted(tutorialId);
  }

  /// Reseta o status de um tutorial específico
  Future<void> resetTutorial(String tutorialId) async {
    await TutorialStorage.resetTutorialStatus(tutorialId);
  }

  /// Reseta todos os tutoriais
  Future<void> resetAllTutorials() async {
    await TutorialStorage.resetAllTutorials();
  }

  /// Obtém a lista de IDs de tutoriais registrados
  List<String> getRegisteredTutorialIds() {
    return _registeredTutorials.keys.toList();
  }

  /// Exibe um elemento destacado temporariamente (útil para chamar atenção)
  void showTemporarySpotlight({
    required BuildContext context,
    required GlobalKey targetKey,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onComplete,
  }) {
    // Obter a posição do elemento
    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return;
    }

    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Rect targetRect =
        Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

    // Criar um overlay para exibir o spotlight
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => TutorialSpotlight(
        targetRect: targetRect,
        animate: true,
        glowIntensity: 0.7,
      ),
    );

    // Adicionar o overlay
    overlayState.insert(overlayEntry);

    // Remover após a duração especificada
    Future.delayed(duration, () {
      overlayEntry.remove();
      if (onComplete != null) {
        onComplete();
      }
    });
  }
}

/// Extensão para facilitar o acesso ao serviço de tutorial a partir do contexto
extension TutorialServiceExtension on BuildContext {
  /// Obtém o serviço de tutorial
  TutorialService get tutorialService => TutorialService();

  /// Inicia um tutorial específico
  Future<bool> startTutorial(
    String tutorialId, {
    bool forceShow = false,
    bool showOnlyOnce = true,
  }) {
    return tutorialService.startTutorial(
      tutorialId,
      this,
      forceShow: forceShow,
      showOnlyOnce: showOnlyOnce,
    );
  }

  /// Exibe um spotlight temporário em um elemento
  void showTemporarySpotlight({
    required GlobalKey targetKey,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onComplete,
  }) {
    tutorialService.showTemporarySpotlight(
      context: this,
      targetKey: targetKey,
      duration: duration,
      onComplete: onComplete,
    );
  }

  void updateSteps(String tutorialId, List<TutorialStep> newSteps) {
    final service = TutorialService();

    // Verifica se o tutorial existe
    if (!service._registeredTutorials.containsKey(tutorialId)) {
      debugPrint('Tutorial $tutorialId não encontrado para atualização');
      return;
    }

    // Atualiza os passos no registro
    service._registeredTutorials[tutorialId] = newSteps;

    // Se este for o tutorial ativo atual, reinicie-o para refletir os novos passos
    if (service.activeTutorialId == tutorialId &&
        service._activeController != null) {
      // Salva o índice do passo atual
      final currentStepIndex = service._activeController!.currentStepIndex;

      // Encerra o tutorial atual
      service.endActiveTutorial();

      // Inicia novamente com os novos passos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Reinicia o tutorial
        final controller = TutorialController(
          tutorialId: tutorialId,
          steps: newSteps,
          context: this,
          showOnlyOnce: true,
        );

        // Configura o novo controlador
        service._activeController = controller;
        service.activeTutorialId = tutorialId;

        // Avança para o passo atual
        controller.start();
        for (int i = 0; i < min(currentStepIndex, newSteps.length - 1); i++) {
          controller.nextStep();
        }
      });
    }
  }
}

/*Características e Funcionalidades do TutorialService
O TutorialService atua como o ponto central de nosso sistema de tutorial, com várias características importantes:

1. Arquitetura Singleton
Padrão Singleton: Garante uma única instância do serviço em todo o aplicativo
Acesso Global: Facilmente acessível em qualquer parte do código
2. Registro e Gerenciamento de Tutoriais
Sistema de Registro: Permite definir tutoriais para diferentes telas do app
Armazenamento Centralizado: Mantém uma coleção de todos os tutoriais disponíveis
Controle de Estado: Gerencia qual tutorial está ativo e seu controlador
3. API Amigável
Métodos Intuitivos: Interface clara e simples para iniciar e gerenciar tutoriais
Extensão de BuildContext: Permite acessar o serviço diretamente do contexto
Verificações de Segurança: Trata casos de tutoriais não encontrados ou já completados
4. Integração Visual Fluida
Overlay Automático: Constrói overlays visuais completos com spotlight e tooltip
Efeitos Temporários: Função para destacar elementos momentaneamente (spotlight temporário)
Personalização Flexível: Permite sobrescrever comportamentos padrão
5. Persistência Inteligente
Verificação de Primeiro Uso: Detecta se é a primeira vez que o app é executado
Controle de Exibição: Método para verificar se um tutorial específico deve ser mostrado
Funções de Reset: Métodos para limpar o estado de tutoriais (útil para testes)
Exemplo de Uso
Este serviço facilita muito a integração de tutoriais em seu aplicativo. Por exemplo:

```dart
// Registrar um tutorial na inicialização do app
final tutorialService = TutorialService();
tutorialService.registerTutorial('home_screen', homeScreenTutorialSteps);

// Iniciar o tutorial em uma tela
context.startTutorial('home_screen');

// Ou usar o overlay integrado em um widget
return tutorialService.buildTutorialOverlay(
  context: context,
  tutorialId: 'home_screen',
  child: YourScreenWidget(),
);
```*/
