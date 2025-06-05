/*tutorial_welcome_screen.dart
**Parte do plano: 3.3 (3) - Verificação de Primeira Execução
**Conteúdo: Tela de boas-vindas opcional antes de iniciar o tutorial principal.*/
import 'package:flutter/material.dart';
import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/tutorial/services/tutorial_storage.dart';
import 'package:economize/tutorial/tutorial_service.dart';

/// Tela de boas-vindas para o tutorial
/// Exibida na primeira vez que o usuário abre o aplicativo
class TutorialWelcomeScreen extends StatefulWidget {
  /// ID do tutorial que será iniciado após esta tela
  final String tutorialId;

  /// Função chamada quando o usuário pula o tutorial
  final VoidCallback? onSkip;

  /// Função chamada quando o usuário inicia o tutorial
  final VoidCallback? onStart;

  /// Título da tela
  final String title;

  /// Descrição do app e do tutorial
  final String description;

  /// Caminho da imagem de boas-vindas
  final String? imagePath;

  /// Se deve mostrar um indicador de progresso nos botões
  final bool showProgress;

  /// Tela para onde navegar após fechar esta tela
  final Widget? nextScreen;

  const TutorialWelcomeScreen({
    super.key,
    required this.tutorialId,
    this.onSkip,
    this.onStart,
    this.title = 'Bem-vindo ao Economize!',
    this.description =
        'Vamos fazer um tour rápido pelas principais funcionalidades para você aproveitar ao máximo seu controle financeiro.',
    this.imagePath,
    this.showProgress = false,
    this.nextScreen, // ADICIONE ESTE PARÂMETRO
  });

  @override
  State<TutorialWelcomeScreen> createState() => _TutorialWelcomeScreenState();

  /// Exibe esta tela como um modal
  static Future<bool> show({
    required BuildContext context,
    required String tutorialId,
    VoidCallback? onSkip,
    VoidCallback? onStart,
    String? title,
    String? description,
    String? imagePath,
    Widget? nextScreen, // ADICIONE ESTE PARÂMETRO
  }) async {
    // Verificar se o tutorial já foi concluído
    final completed = await TutorialStorage.isTutorialCompleted(tutorialId);
    if (completed) return false;

    // Mostrar a tela de boas-vindas
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialWelcomeScreen(
        tutorialId: tutorialId,
        onSkip: onSkip,
        onStart: onStart,
        title: title ?? 'Bem-vindo ao Economize!',
        description: description ??
            'Vamos fazer um tour rápido pelas principais funcionalidades para você aproveitar ao máximo seu controle financeiro.',
        imagePath: imagePath,
        showProgress: true,
        nextScreen: nextScreen, // PASSAR A TELA AQUI
      ),
    );

    return result ?? false;
  }
}

class _TutorialWelcomeScreenState extends State<TutorialWelcomeScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark
                  ? theme.colorScheme.primary.withAlpha((0.8 * 255).round())
                  : theme.colorScheme.primary.withAlpha((0.6 * 255).round()),
              isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo ou Ilustração
                  SlideAnimation.fromTop(
                    delay: const Duration(milliseconds: 100),
                    child: _buildImage(size),
                  ),

                  const SizedBox(height: 30),

                  // Card de conteúdo
                  ScaleAnimation(
                    delay: const Duration(milliseconds: 300),
                    child: GlassContainer(
                      borderRadius: 24,
                      opacity: 0.1,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            // Título
                            FadeAnimation.fadeIn(
                              delay: const Duration(milliseconds: 500),
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : theme.colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Descrição
                            FadeAnimation.fadeIn(
                              delay: const Duration(milliseconds: 700),
                              child: Text(
                                widget.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Botões
                            FadeAnimation.fadeIn(
                              delay: const Duration(milliseconds: 900),
                              child: _buildButtons(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói a imagem ou ilustração
  Widget _buildImage(Size size) {
    if (widget.imagePath != null) {
      return Image.asset(
        widget.imagePath!,
        height: size.height * 0.25,
        width: size.width * 0.8,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage(context);
        },
      );
    } else {
      return _buildFallbackImage(context);
    }
  }

  /// Constrói uma imagem alternativa caso a principal não seja encontrada
  Widget _buildFallbackImage(BuildContext context) {
    final theme = Theme.of(context);
    return Icon(
      Icons.account_balance_wallet,
      size: 120,
      color: theme.colorScheme.onPrimary..withAlpha((0.9 * 255).round()),
    );
  }

  /// Constrói os botões de navegação
  Widget _buildButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botão Pular
        Expanded(
          child: TextButton(
            onPressed: _isLoading ? null : _handleSkip,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Pular',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha((0.8 * 255).round()),
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Botão Iniciar Tutorial
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleStart,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : const Text(
                    'Iniciar Tour',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  /// Trata a ação de pular o tutorial
  void _handleSkip() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Marcar o tutorial como concluído
    await TutorialStorage.markTutorialCompleted(widget.tutorialId);

    if (widget.onSkip != null) {
      widget.onSkip!();
    } else if (widget.nextScreen != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => widget.nextScreen!),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

// Modifique o método _handleStart para incluir navegação para nextScreen
  void _handleStart() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    if (widget.onStart != null) {
      widget.onStart!();
    } else {
      // Iniciar o tutorial
      await context.startTutorial(widget.tutorialId);

      if (widget.nextScreen != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => widget.nextScreen!),
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }
}

/// Extensão para facilitar a exibição da tela de boas-vindas
extension TutorialWelcomeExtension on BuildContext {
  /// Exibe a tela de boas-vindas do tutorial
  Future<bool> showTutorialWelcome({
    required String tutorialId,
    VoidCallback? onSkip,
    VoidCallback? onStart,
    String? title,
    String? description,
    String? imagePath,
    Widget? nextScreen, // ADICIONE ESTE PARÂMETRO
  }) {
    return TutorialWelcomeScreen.show(
      context: this,
      tutorialId: tutorialId,
      onSkip: onSkip,
      onStart: onStart,
      title: title,
      description: description,
      imagePath: imagePath,
      nextScreen: nextScreen, // PASSAR A TELA AQUI
    );
  }
}
/*Características da Tela de Boas-vindas do Tutorial
A tela de boas-vindas é um componente importante para introduzir o usuário ao tutorial interativo, destacando-se pelas seguintes características:

1. Design Atrativo e Moderno
Fundo com Gradiente: Cria uma atmosfera visual atraente usando as cores do tema
Efeito Glass: Utiliza o componente GlassContainer para um visual moderno e elegante
Animações Sequenciadas: Entradas animadas de elementos para criar uma experiência dinâmica
2. Flexibilidade de Conteúdo
Textos Personalizáveis: Título e descrição podem ser facilmente alterados
Suporte a Imagens: Permite incluir uma imagem ou ilustração personalizada
Fallback Inteligente: Exibe um ícone caso a imagem não seja encontrada
3. Opções de Navegação Claras
Botão de Iniciar Tour: Destaque visual para incentivar o usuário a iniciar o tutorial
Opção de Pular: Permite que usuários avançados pulem o tutorial
Indicador de Progresso: Opção para mostrar feedback visual durante o carregamento
4. Integração com o Sistema de Tutorial
Gerenciamento de Estado: Marca o tutorial como concluído quando pulado
Inicialização Automática: Inicia o tutorial específico quando solicitado
Verificação de Status: Evita mostrar a tela se o tutorial já foi concluído
5. Flexibilidade de Uso
Método Estático: Facilita a exibição como diálogo modal
Extensão de BuildContext: Permite chamar diretamente do contexto com context.showTutorialWelcome()
Callbacks Personalizáveis: Permite ações customizadas ao pular ou iniciar
Esta tela complementa perfeitamente o sistema de tutorial, oferecendo uma introdução amigável antes de iniciar o tour guiado pelas funcionalidades do aplicativo.

Como Utilizar
Para mostrar a tela de boas-vindas na inicialização do aplicativo ou quando um usuário acessa uma área importante pela primeira vez:

```
// Na função main ou após a tela de splash
void checkFirstRun() async {
  final isFirstLaunch = await TutorialStorage.isFirstLaunch();
  
  if (isFirstLaunch) {
    context.showTutorialWelcome(
      tutorialId: 'home_tutorial',
      title: 'Bem-vindo ao Economize!',
      description: 'Vamos aprender como controlar suas finanças de forma simples e eficiente.',
      imagePath: 'assets/images/welcome.png',
    );
  }
}
```
Com esta tela, completamos a estrutura básica do sistema de tutorial interativo! 🎉*/
