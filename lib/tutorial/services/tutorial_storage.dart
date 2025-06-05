/*tutorial_storage.dart
**Parte do plano: 3.1 (1) - Serviço de Tutorial (parte de persistência)
**Conteúdo: Gerencia a persistência de dados do tutorial usando SharedPreferences.*/
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar o armazenamento de dados do tutorial
/// Responsável por salvar e recuperar o status e progresso do tutorial
class TutorialStorage {
  // Prefixos para as chaves no SharedPreferences
  static const String _completedKeyPrefix = 'tutorial_completed_';
  static const String _lastStepKeyPrefix = 'tutorial_last_step_';
  static const String _firstLaunchKey = 'app_first_launch';

  /// Verifica se é a primeira vez que o app está sendo executado
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = !(prefs.getBool(_firstLaunchKey) ?? false);

    if (isFirst) {
      // Marca que o app já foi executado
      await prefs.setBool(_firstLaunchKey, true);
    }

    return isFirst;
  }

  /// Verifica se um tutorial específico já foi concluído
  static Future<bool> isTutorialCompleted(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_completedKeyPrefix$tutorialId') ?? false;
  }

  /// Marca um tutorial como concluído
  static Future<void> markTutorialCompleted(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_completedKeyPrefix$tutorialId', true);
  }

  /// Marca um tutorial como não concluído (para forçar exibição novamente)
  static Future<void> resetTutorialStatus(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_completedKeyPrefix$tutorialId');
    await prefs.remove('$_lastStepKeyPrefix$tutorialId');
  }

  /// Salva o último passo visto em um tutorial
  static Future<void> saveLastStep(String tutorialId, int stepIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_lastStepKeyPrefix$tutorialId', stepIndex);
  }

  /// Recupera o último passo visto em um tutorial
  static Future<int> getLastStep(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_lastStepKeyPrefix$tutorialId') ?? 0;
  }

  /// Reseta todos os tutoriais (útil para testes ou configurações)
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_completedKeyPrefix) ||
          key.startsWith(_lastStepKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  /// Marca todos os tutoriais como concluídos (útil para usuários avançados)
  static Future<void> markAllTutorialsCompleted(
      List<String> tutorialIds) async {
    final prefs = await SharedPreferences.getInstance();

    for (final id in tutorialIds) {
      await prefs.setBool('$_completedKeyPrefix$id', true);
    }
  }

  /// Verifica se deve mostrar o tutorial com base em condições customizadas
  static Future<bool> shouldShowTutorial({
    required String tutorialId,
    required bool showOnlyOnce,
    bool forceShow = false,
  }) async {
    if (forceShow) return true;

    if (showOnlyOnce) {
      final completed = await isTutorialCompleted(tutorialId);
      return !completed;
    }

    return true;
  }
}
/*Características do TutorialStorage
O serviço TutorialStorage oferece funcionalidades importantes para o sistema de tutorial:

1. Gestão do Primeiro Lançamento
Detecta se é a primeira vez que o app está sendo executado
Útil para decidir se deve mostrar automaticamente o tutorial inicial
2. Controle por Tutorial
Cada tutorial tem seu próprio espaço de armazenamento identificado por ID
Armazena separadamente o status de conclusão e o último passo visto
3. Funções de Gerenciamento
markTutorialCompleted: Marca um tutorial como concluído
resetTutorialStatus: Limpa o status de um tutorial específico
resetAllTutorials: Limpa todos os dados de tutorial armazenados
4. Controle de Progresso
saveLastStep: Armazena o último passo que o usuário viu
getLastStep: Recupera o último passo para continuar de onde parou
5. Lógica de Decisão
shouldShowTutorial: Centraliza a lógica para decidir se um tutorial deve ser exibido
Suporta opções como exibição única ou forçada
Este serviço complementa o TutorialController, separando a lógica de persistência
da lógica de controle do estado do tutorial. Isso torna o código mais organizado e fácil de manter.*/
