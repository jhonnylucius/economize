import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Biblioteca de animações de transição para o Clube de Benefícios.
///
/// Fornece um conjunto de transições personalizadas para navegação entre telas
/// e componentes, criando uma experiência de usuário fluida e consistente.
class TransitionAnimations {
  /// Não permite criar instâncias desta classe
  TransitionAnimations._();

  /// Duração padrão para transições entre telas
  static const Duration defaultPageDuration = Duration(milliseconds: 300);

  /// Duração padrão para transições entre componentes
  static const Duration defaultComponentDuration = Duration(milliseconds: 250);

  /// Curva de animação padrão para transições
  static const Curve defaultCurve = Curves.easeInOut;
}

/// Rota com transição de fade entre telas
class FadePageRoute<T> extends PageRouteBuilder<T> {
  /// Widget da página de destino
  final Widget page;

  /// Duração da animação
  final Duration duration;

  /// Curva da animação
  final Curve curve;

  /// Cria uma rota com transição de fade
  FadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: child,
            );
          },
          transitionDuration: duration,
        );
}

/// Rota com transição de slide horizontal
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  /// Widget da página de destino
  final Widget page;

  /// Duração da animação
  final Duration duration;

  /// Curva da animação
  final Curve curve;

  /// Direção do slide
  final AxisDirection direction;

  /// Quantidade de offset inicial (1.0 = 100% da tela)
  final double offset;

  /// Cria uma rota com transição de slide horizontal
  SlidePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.direction = AxisDirection.right,
    this.offset = 1.0,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            // Determina a posição inicial baseada na direção
            Offset begin;
            switch (direction) {
              case AxisDirection.up:
                begin = Offset(0, offset);
                break;
              case AxisDirection.right:
                begin = Offset(-offset, 0);
                break;
              case AxisDirection.down:
                begin = Offset(0, -offset);
                break;
              case AxisDirection.left:
                begin = Offset(offset, 0);
                break;
            }

            return SlideTransition(
              position: Tween<Offset>(
                begin: begin,
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );
          },
          transitionDuration: duration,
        );
}

/// Rota com transição de escala
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  /// Widget da página de destino
  final Widget page;

  /// Duração da animação
  final Duration duration;

  /// Curva da animação
  final Curve curve;

  /// Escala inicial (0.0 - 1.0)
  final double beginScale;

  /// Alinhamento da origem da escala
  final Alignment alignment;

  /// Se deve aplicar fade junto com a escala
  final bool withFade;

  /// Cria uma rota com transição de escala
  ScalePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.beginScale = 0.8,
    this.alignment = Alignment.center,
    this.withFade = true,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            Widget result = ScaleTransition(
              scale: Tween<double>(
                begin: beginScale,
                end: 1.0,
              ).animate(curvedAnimation),
              alignment: alignment,
              child: child,
            );

            if (withFade) {
              result = FadeTransition(
                opacity: curvedAnimation,
                child: result,
              );
            }

            return result;
          },
          transitionDuration: duration,
        );
}

/// Rota com transição de Hero compartilhado
class HeroPageRoute<T> extends PageRouteBuilder<T> {
  /// Widget da página de destino
  final Widget page;

  /// Duração da animação
  final Duration duration;

  /// Curva da animação
  final Curve curve;

  /// Se deve aplicar fade para elementos não-hero
  final bool withFade;

  /// Cria uma rota com transição de Hero
  HeroPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.fastOutSlowIn,
    this.withFade = true,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            if (withFade) {
              return FadeTransition(
                opacity: curvedAnimation,
                child: child,
              );
            }

            return child;
          },
          transitionDuration: duration,
        );
}

/// Rota com transição de elementos em escalonamento
class StaggeredPageRoute<T> extends PageRouteBuilder<T> {
  /// Widget da página de destino
  final Widget page;

  /// Duração da animação
  final Duration duration;

  /// Offset para início da animação
  final Offset beginOffset;

  /// Cria uma rota com transição escalonada de elementos
  StaggeredPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 600),
    this.beginOffset = const Offset(0, 0.05),
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          // A animação escalonada é implementada pela página de destino
          transitionDuration: duration,
        );
}

/// Rota com transição de paralaxe
class ParallaxPageRoute<T> extends PageRouteBuilder<T> {
  /// Widget da página de destino
  final Widget page;

  /// Duração da animação
  final Duration duration;

  /// Curva da animação
  final Curve curve;

  /// Fator de paralaxe (quanto maior, mais diferença entre camadas)
  final double parallaxFactor;

  /// Cria uma rota com efeito de paralaxe
  ParallaxPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOut,
    this.parallaxFactor = 0.2,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            return Stack(
              children: [
                // Camada de fundo (mais lenta)
                SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(-parallaxFactor, 0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                ),

                // A camada de frente é implementada pela página de destino
                // com um efeito mais rápido usando o ParallaxContainer
              ],
            );
          },
          transitionDuration: duration,
        );
}

/// Container para criar efeito de paralaxe em elementos
class ParallaxContainer extends StatelessWidget {
  /// Widget filho que terá o efeito aplicado
  final Widget child;

  /// Controlador da animação
  final AnimationController controller;

  /// Fator de multiplicação do efeito (1.0 = movimento padrão)
  final double factor;

  /// Direção do movimento de paralaxe
  final AxisDirection direction;

  /// Cria um container com efeito de paralaxe
  const ParallaxContainer({
    super.key,
    required this.child,
    required this.controller,
    this.factor = 1.0,
    this.direction = AxisDirection.right,
  });

  @override
  Widget build(BuildContext context) {
    // Determina o offset baseado na direção
    Offset getOffset() {
      switch (direction) {
        case AxisDirection.up:
          return Offset(0, -0.1 * factor);
        case AxisDirection.right:
          return Offset(0.1 * factor, 0);
        case AxisDirection.down:
          return Offset(0, 0.1 * factor);
        case AxisDirection.left:
          return Offset(-0.1 * factor, 0);
      }
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.translate(
          offset: getOffset() * (1 - controller.value) * 100,
          child: child,
        );
      },
    );
  }
}

/// Transição customizada de rotação 3D
class Rotate3DPageRoute<T> extends PageRouteBuilder<T> {
  /// Widget da página de destino
  final Widget page;

  /// Duração da animação
  final Duration duration;

  /// Curva da animação
  final Curve curve;

  /// Eixo de rotação
  final bool flipX;

  /// Cria uma transição com rotação 3D
  Rotate3DPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutBack,
    this.flipX = true,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            return Rotate3DTransition(
              animation: curvedAnimation,
              flipX: flipX,
              child: child,
            );
          },
          transitionDuration: duration,
        );
}

/// Widget para criar efeito de rotação 3D
class Rotate3DTransition extends AnimatedWidget {
  /// Filho que será animado
  final Widget child;

  /// Se rotaciona no eixo X (se falso, rotaciona no Y)
  final bool flipX;

  /// Cria uma transição de rotação 3D
  const Rotate3DTransition({
    super.key,
    required Animation<double> animation,
    required this.child,
    this.flipX = true,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final value = animation.value;

    // Cria perspectiva e rotação
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Perspectiva
      ..rotateX(flipX ? (1 - value) * math.pi / 2 : 0)
      ..rotateY(!flipX ? (1 - value) * math.pi / 2 : 0);

    return Transform(
      alignment: Alignment.center,
      transform: transform,
      child: child,
    );
  }
}

/// Transição circular que revela/oculta conteúdo
class CircularRevealRoute<T> extends PageRouteBuilder<T> {
  /// Widget da página de destino
  final Widget page;

  /// Duração da animação
  final Duration duration;

  /// Curva da animação
  final Curve curve;

  /// Ponto de origem da revelação
  final Alignment alignment;

  /// Reverso (true = fecha o círculo ao invés de abrir)
  final bool reverse;

  /// Cria uma transição de revelação circular
  CircularRevealRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOut,
    this.alignment = Alignment.center,
    this.reverse = false,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            return CircularRevealTransition(
              animation: animation,
              curve: curve,
              alignment: alignment,
              reverse: reverse,
              child: child,
            );
          },
          transitionDuration: duration,
        );
}

/// Widget de transição com revelação circular
class CircularRevealTransition extends StatelessWidget {
  /// Animação controladora
  final Animation<double> animation;

  /// Curva da animação
  final Curve curve;

  /// Alinhamento da origem
  final Alignment alignment;

  /// Se é reverso (fechando ao invés de abrindo)
  final bool reverse;

  /// Widget filho que será revelado
  final Widget child;

  /// Cria uma transição de revelação circular
  const CircularRevealTransition({
    super.key,
    required this.animation,
    required this.child,
    this.curve = Curves.easeInOut,
    this.alignment = Alignment.center,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
      builder: (context, child) {
        return ClipPath(
          clipper: CircularRevealClipper(
            value: reverse ? 1 - animation.value : animation.value,
            alignment: alignment,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Clipper para criar efeito de revelação circular
class CircularRevealClipper extends CustomClipper<Path> {
  /// Valor da animação (0-1)
  final double value;

  /// Alinhamento da origem
  final Alignment alignment;

  /// Cria um clipper para revelação circular
  CircularRevealClipper({
    required this.value,
    required this.alignment,
  });

  @override
  Path getClip(Size size) {
    final center = alignment.alongSize(size);

    // Calcula o raio máximo para cobrir toda a tela
    final maxRadius =
        math.sqrt(math.pow(size.width, 2) + math.pow(size.height, 2));

    // Raio atual baseado no progresso da animação
    final radius = value * maxRadius;

    return Path()
      ..addOval(
        Rect.fromCircle(center: center, radius: radius),
      );
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

/// Transição baseada em clipe compartilhado
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  /// Widget da página de destino
  final Widget page;

  /// Duração da animação
  final Duration duration;

  /// Curva da animação
  final Curve curve;

  /// Eixo de movimento (X = horizontal, Y = vertical, Z = profundidade)
  final SharedAxisTransitionType type;

  /// Fator da transição (intensidade do movimento)
  final double transitionFactor;

  /// Cria uma rota com transição de eixo compartilhado
  SharedAxisPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.fastOutSlowIn,
    this.type = SharedAxisTransitionType.horizontal,
    this.transitionFactor = 60.0,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            return SharedAxisTransition(
              animation: curvedAnimation,
              secondaryAnimation: secondaryAnimation,
              type: type,
              transitionFactor: transitionFactor,
              child: child,
            );
          },
          transitionDuration: duration,
        );
}

/// Tipos de transição de eixo compartilhado
enum SharedAxisTransitionType {
  /// Transição horizontal
  horizontal,

  /// Transição vertical
  vertical,

  /// Transição de profundidade (escala)
  scaled,
}

/// Transição com eixo compartilhado (Material Motion style)
class SharedAxisTransition extends StatelessWidget {
  /// Animação primária
  final Animation<double> animation;

  /// Animação secundária
  final Animation<double> secondaryAnimation;

  /// Widget filho
  final Widget child;

  /// Tipo da transição
  final SharedAxisTransitionType type;

  /// Fator de intensidade da transição
  final double transitionFactor;

  /// Cria uma transição de eixo compartilhado
  const SharedAxisTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    required this.type,
    this.transitionFactor = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    // Como estamos lidando com duas animações (entrada e saída),
    // precisamos combinar seus efeitos
    final inAnimation = animation;
    final outAnimation = ReverseAnimation(secondaryAnimation);

    // Efeito de fade comum para todas as variações
    Widget result = FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1.0),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: outAnimation,
          curve: const Interval(0.3, 1.0),
        ),
        child: child,
      ),
    );

    // Aplique o movimento baseado no tipo de transição
    switch (type) {
      case SharedAxisTransitionType.horizontal:
        result = SlideTransition(
          position: Tween<Offset>(
            begin: Offset(transitionFactor / 100, 0),
            end: Offset.zero,
          ).animate(inAnimation),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.3, 0),
              end: Offset.zero,
            ).animate(outAnimation),
            child: result,
          ),
        );
        break;

      case SharedAxisTransitionType.vertical:
        result = SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, transitionFactor / 100),
            end: Offset.zero,
          ).animate(inAnimation),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.3),
              end: Offset.zero,
            ).animate(outAnimation),
            child: result,
          ),
        );
        break;

      case SharedAxisTransitionType.scaled:
        result = ScaleTransition(
          scale: Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).animate(inAnimation),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 1.1,
              end: 1.0,
            ).animate(outAnimation),
            child: result,
          ),
        );
        break;
    }

    return result;
  }
}

/// Transição com efeito de página virando
class PageTurnRoute<T> extends PageRouteBuilder<T> {
  /// Widget da página de destino
  final Widget page;

  /// Duração da animação
  final Duration duration;

  /// Curva da animação
  final Curve curve;

  /// Se vira da direita para esquerda (se falso, vira da esquerda para direita)
  final bool rightToLeft;

  /// Cria uma transição com efeito de virar página
  // ignore: use_super_parameters
  PageTurnRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeInOut,
    this.rightToLeft = true,
    RouteSettings? settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: duration,
          settings: settings,
          transitionsBuilder: (_, animation, __, child) {
            return PageTurnTransition(
              animation: animation,
              rightToLeft: rightToLeft,
              curve: curve,
              child: child,
            );
          },
        );
}

/// Widget de transição com efeito de virar página
class PageTurnTransition extends AnimatedWidget {
  /// Widget filho
  final Widget child;

  /// Se vira da direita para esquerda
  final bool rightToLeft;

  /// Curva da animação
  final Curve curve;

  /// Cria uma transição de virar página
  PageTurnTransition({
    super.key,
    required Animation<double> animation,
    required this.child,
    this.rightToLeft = true,
    this.curve = Curves.easeInOut,
  }) : super(
            listenable: CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final value = animation.value;

    final perspective = 0.003;
    final depth = 0.5;

    // Cálculo do ângulo de rotação
    final rotation = rightToLeft ? (math.pi * value) : -(math.pi * value);

    // Ponto em torno do qual girar a página
    final pivot = rightToLeft ? 0.0 : 1.0;

    return Transform(
      alignment: rightToLeft ? Alignment.centerLeft : Alignment.centerRight,
      transform: Matrix4.identity()
        ..setEntry(3, 2, perspective)
        ..rotateY(rotation),
      child: child,
    );
  }
}

/// Factory de navegação que facilita o uso das transições
class NavigationTransitions {
  /// Não permite criar instâncias desta classe
  NavigationTransitions._();

  /// Navega para nova tela com transição de fade
  static Future<T?> fade<T>({
    required BuildContext context,
    required Widget page,
    Duration? duration,
    Curve curve = Curves.easeInOut,
    bool replace = false,
  }) {
    final route = FadePageRoute<T>(
      page: page,
      duration: duration ?? TransitionAnimations.defaultPageDuration,
      curve: curve,
    );

    if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }

  /// Navega para nova tela com transição de slide
  static Future<T?> slide<T>({
    required BuildContext context,
    required Widget page,
    AxisDirection direction = AxisDirection.right,
    Duration? duration,
    Curve curve = Curves.easeInOut,
    bool replace = false,
  }) {
    final route = SlidePageRoute<T>(
      page: page,
      direction: direction,
      duration: duration ?? TransitionAnimations.defaultPageDuration,
      curve: curve,
    );

    if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }

  /// Navega para nova tela com transição de escala
  static Future<T?> scale<T>({
    required BuildContext context,
    required Widget page,
    double beginScale = 0.8,
    Duration? duration,
    Curve curve = Curves.easeOut,
    bool replace = false,
  }) {
    final route = ScalePageRoute<T>(
      page: page,
      beginScale: beginScale,
      duration: duration ?? TransitionAnimations.defaultPageDuration,
      curve: curve,
    );

    if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }

  /// Navega para nova tela com transição de hero
  static Future<T?> hero<T>({
    required BuildContext context,
    required Widget page,
    Duration? duration,
    bool replace = false,
  }) {
    final route = HeroPageRoute<T>(
      page: page,
      duration: duration ?? TransitionAnimations.defaultPageDuration,
    );

    if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }

  /// Navega para nova tela com transição circular
  static Future<T?> circularReveal<T>({
    required BuildContext context,
    required Widget page,
    Alignment alignment = Alignment.center,
    Duration? duration,
    Curve curve = Curves.easeInOut,
    bool replace = false,
  }) {
    final route = CircularRevealRoute<T>(
      page: page,
      alignment: alignment,
      duration: duration ?? TransitionAnimations.defaultPageDuration,
      curve: curve,
    );

    if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }

  /// Navega para nova tela com transição 3D
  static Future<T?> rotate3D<T>({
    required BuildContext context,
    required Widget page,
    bool flipX = true,
    Duration? duration,
    Curve curve = Curves.easeOutBack,
    bool replace = false,
  }) {
    final route = Rotate3DPageRoute<T>(
      page: page,
      flipX: flipX,
      duration: duration ?? TransitionAnimations.defaultPageDuration,
      curve: curve,
    );

    if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }

  /// Navega com transição de eixo compartilhado
  static Future<T?> sharedAxis<T>({
    required BuildContext context,
    required Widget page,
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
    Duration? duration,
    bool replace = false,
  }) {
    final route = SharedAxisPageRoute<T>(
      page: page,
      type: type,
      duration: duration ?? TransitionAnimations.defaultPageDuration,
    );

    if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }

  /// Navega com efeito de virar página
  static Future<T?> pageTurn<T>({
    required BuildContext context,
    required Widget page,
    bool rightToLeft = true,
    Duration? duration,
    bool replace = false,
  }) {
    final route = PageTurnRoute<T>(
      page: page,
      rightToLeft: rightToLeft,
      duration: duration ?? TransitionAnimations.defaultPageDuration,
    );

    if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }
}

/// Transição de deslize para componentes internos da UI
class SlideComponentTransition extends StatelessWidget {
  /// Widget filho
  final Widget child;

  /// Controlador da animação
  final AnimationController controller;

  /// Direção do slide
  final AxisDirection direction;

  /// Offset inicial (1.0 = 100% do tamanho)
  final double offset;

  /// Curva da animação
  final Curve curve;

  /// Cria uma transição de slide para componentes de UI
  const SlideComponentTransition({
    super.key,
    required this.child,
    required this.controller,
    this.direction = AxisDirection.right,
    this.offset = 1.0,
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    // Determina a posição inicial baseada na direção
    Offset getBeginOffset() {
      switch (direction) {
        case AxisDirection.up:
          return Offset(0, offset);
        case AxisDirection.right:
          return Offset(-offset, 0);
        case AxisDirection.down:
          return Offset(0, -offset);
        case AxisDirection.left:
          return Offset(offset, 0);
      }
    }

    return AnimatedBuilder(
      animation: CurvedAnimation(
        parent: controller,
        curve: curve,
      ),
      builder: (context, _) {
        final value = controller.value;

        return SlideTransition(
          position: Tween<Offset>(
            begin: getBeginOffset(),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: controller,
              curve: curve,
            ),
          ),
          child: child,
        );
      },
    );
  }
}

/// Transição de sobreposição para componentes de UI
class OverlayComponentTransition extends StatelessWidget {
  /// Widget filho
  final Widget child;

  /// Controlador da animação
  final AnimationController controller;

  /// Curva de entrada
  final Curve enterCurve;

  /// Curva de saída
  final Curve exitCurve;

  /// Duração relativa da entrada (0.0-1.0)
  final double enterDuration;

  /// Duração relativa da saída (0.0-1.0)
  final double exitDuration;

  /// Cria uma transição para componentes sobrepostos
  const OverlayComponentTransition({
    super.key,
    required this.child,
    required this.controller,
    this.enterCurve = Curves.easeOut,
    this.exitCurve = Curves.easeIn,
    this.enterDuration = 0.35,
    this.exitDuration = 0.65,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Determina se está entrando ou saindo
        final value = controller.value;

        if (value < enterDuration) {
          // Fase de entrada
          final enterValue = value / enterDuration;
          final curvedValue = enterCurve.transform(enterValue);

          return Opacity(
            opacity: curvedValue,
            child: Transform.scale(
              scale: 0.8 + (0.2 * curvedValue),
              child: child,
            ),
          );
        } else {
          // Fase de saída ou exibição completa
          final exitProgress = value > 1.0 - exitDuration
              ? (value - (1.0 - exitDuration)) / exitDuration
              : 0.0;

          final curvedExitValue =
              exitProgress > 0.0 ? exitCurve.transform(exitProgress) : 0.0;

          return Opacity(
            opacity: 1.0 - curvedExitValue,
            child: Transform.scale(
              scale: 1.0 - (0.2 * curvedExitValue),
              child: child,
            ),
          );
        }
      },
      child: child,
    );
  }
}

/// Transição sequencial para listas de itens
class StaggeredListTransition extends StatelessWidget {
  /// Widgets filhos a serem animados
  final List<Widget> children;

  /// Controlador da animação
  final AnimationController controller;

  /// Atraso entre cada item (em fração da animação total)
  final double staggerDelay;

  /// Curva da animação
  final Curve curve;

  /// Duração por item (em fração da animação total)
  final double itemDuration;

  /// Tipo de animação para cada item
  final StaggeredAnimationType type;

  /// Direção da animação (para slide)
  final AxisDirection direction;

  /// Cria uma transição sequencial para listas
  const StaggeredListTransition({
    super.key,
    required this.children,
    required this.controller,
    this.staggerDelay = 0.05,
    this.itemDuration = 0.3,
    this.curve = Curves.easeOut,
    this.type = StaggeredAnimationType.fade,
    this.direction = AxisDirection.up,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: _buildStaggeredChildren(),
        );
      },
    );
  }

  List<Widget> _buildStaggeredChildren() {
    return List.generate(children.length, (index) {
      // Calcula o início e fim da animação para este item
      final startPercent = index * staggerDelay;
      final endPercent = startPercent + itemDuration;

      // Normaliza o valor da animação para este item específico
      double itemProgress;
      if (controller.value < startPercent) {
        itemProgress = 0.0;
      } else if (controller.value > endPercent) {
        itemProgress = 1.0;
      } else {
        itemProgress =
            (controller.value - startPercent) / (endPercent - startPercent);
      }

      final curvedProgress = curve.transform(itemProgress);

      // Aplica a animação adequada baseada no tipo
      Widget animatedChild = children[index];

      switch (type) {
        case StaggeredAnimationType.fade:
          animatedChild = Opacity(
            opacity: curvedProgress,
            child: animatedChild,
          );
          break;

        case StaggeredAnimationType.scale:
          animatedChild = Transform.scale(
            scale: curvedProgress,
            alignment: Alignment.center,
            child: animatedChild,
          );
          break;

        case StaggeredAnimationType.slide:
          // Determina o offset com base na direção
          Offset getOffset() {
            final distance = 1.0 - curvedProgress;
            switch (direction) {
              case AxisDirection.up:
                return Offset(0, distance * 20);
              case AxisDirection.right:
                return Offset(-distance * 20, 0);
              case AxisDirection.down:
                return Offset(0, -distance * 20);
              case AxisDirection.left:
                return Offset(distance * 20, 0);
            }
          }

          animatedChild = Transform.translate(
            offset: getOffset(),
            child: animatedChild,
          );
          break;

        case StaggeredAnimationType.fadeSlide:
          // Combina fade com slide
          Offset getOffset() {
            final distance = 1.0 - curvedProgress;
            switch (direction) {
              case AxisDirection.up:
                return Offset(0, distance * 20);
              case AxisDirection.right:
                return Offset(-distance * 20, 0);
              case AxisDirection.down:
                return Offset(0, -distance * 20);
              case AxisDirection.left:
                return Offset(distance * 20, 0);
            }
          }

          animatedChild = Opacity(
            opacity: curvedProgress,
            child: Transform.translate(
              offset: getOffset(),
              child: animatedChild,
            ),
          );
          break;
      }

      return animatedChild;
    });
  }
}

/// Tipos de animação para transições escalonadas
enum StaggeredAnimationType {
  /// Animação de fade (aparece gradualmente)
  fade,

  /// Animação de escala (cresce do centro)
  scale,

  /// Animação de deslize
  slide,

  /// Combinação de fade e deslize
  fadeSlide,
}

/// Transição que imita folha de papel erguendo-se (Material Design)
class MaterialElevationTransition extends StatelessWidget {
  /// Widget filho
  final Widget child;

  /// Controlador de animação
  final AnimationController controller;

  /// Elevação máxima
  final double maxElevation;

  /// Curva de animação
  final Curve curve;

  /// Cria uma transição com elevação estilo Material Design
  const MaterialElevationTransition({
    super.key,
    required this.child,
    required this.controller,
    this.maxElevation = 8.0,
    this.curve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(
        parent: controller,
        curve: curve,
      ),
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withAlpha((0.2 * controller.value * 255).round()),
                blurRadius: maxElevation * controller.value,
                spreadRadius: (maxElevation / 4) * controller.value,
                offset: Offset(0, (maxElevation / 3) * controller.value),
              ),
            ],
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Widget que cria uma navegação interna com transições
class InAppPageTransitionSwitcher extends StatelessWidget {
  /// Widget filho atual
  final Widget child;

  /// ID único para o widget atual (usado para determinar transições)
  final Object childKey;

  /// Tipo de transição a usar
  final InAppTransitionType transitionType;

  /// Duração da transição
  final Duration duration;

  /// Layout do container (deve ser stack para alguns efeitos)
  final StackSwitcherLayoutMode layoutMode;

  /// Cria um switcher de páginas com transição interna
  const InAppPageTransitionSwitcher({
    super.key,
    required this.child,
    required this.childKey,
    this.transitionType = InAppTransitionType.fadeScale,
    this.duration = const Duration(milliseconds: 300),
    this.layoutMode = StackSwitcherLayoutMode.stack,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (currentChild, previousChildren) {
        switch (layoutMode) {
          case StackSwitcherLayoutMode.stack:
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          case StackSwitcherLayoutMode.inside:
            return currentChild ?? const SizedBox.shrink();
        }
      },
      transitionBuilder: (child, animation) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );

        switch (transitionType) {
          case InAppTransitionType.fade:
            return FadeTransition(
              opacity: curvedAnimation,
              child: child,
            );

          case InAppTransitionType.fadeScale:
            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0)
                    .animate(curvedAnimation),
                child: child,
              ),
            );

          case InAppTransitionType.slideUp:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            );

          case InAppTransitionType.slideHorizontal:
            // Determina a direção do slide com base no valor da chave
            final goingForward = childKey.hashCode > child.key.hashCode;
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(goingForward ? 1.0 : -1.0, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            );
        }
      },
      child: Container(
        key: ValueKey(childKey),
        child: child,
      ),
    );
  }
}

/// Tipos de transição para navegação interna
enum InAppTransitionType {
  /// Transição com fade
  fade,

  /// Transição com fade e escala
  fadeScale,

  /// Transição deslizando para cima
  slideUp,

  /// Transição deslizando horizontalmente
  slideHorizontal,
}

/// Modos de layout para o switcher de páginas
enum StackSwitcherLayoutMode {
  /// Empilha widgets (permite sobreposição)
  stack,

  /// Substitui completamente o widget atual
  inside,
}
/*Esse componente de Transition Animations implementa:
1. Transições entre Páginas Completas:
FadePageRoute

Transição suave de fade entre telas
Ideal para transições não direcionais
SlidePageRoute

Movimento lateral, vertical ou diagonal entre telas
Suporte a todas as direções (cima, baixo, esquerda, direita)
ScalePageRoute

Efeito de zoom ao navegar entre telas
Controle sobre alinhamento e escala inicial
HeroPageRoute

Facilita animações hero compartilhadas entre telas
Implementada com a API de Hero do Flutter
ParallaxPageRoute & ParallaxContainer

Efeito de profundidade com elementos se movendo em velocidades diferentes
Cria sensação de 3D sutil entre páginas
CircularRevealRoute

Revelação circular que cresce a partir de um ponto
Excelente para transições de botões para páginas relacionadas
Rotate3DPageRoute

Efeito 3D de rotação ao navegar
Controle sobre eixo de rotação (X ou Y)
SharedAxisPageRoute

Implementação do sistema de transições "shared axis" do Material Motion
Três variantes: horizontal, vertical e escala
PageTurnRoute

Efeito de página sendo virada como um livro
Direção configurável (esquerda para direita ou vice-versa)
2. Transições para Componentes de Interface:
SlideComponentTransition

Anima a entrada de componentes com efeito deslizante
Configurável para qualquer direção
OverlayComponentTransition

Especializada para componentes sobrepostos como dialogs
Combina fade e escala com curvas personalizadas
StaggeredListTransition

Anima itens de uma lista em sequência
Múltiplos efeitos: fade, scale, slide ou combinações
Controle sobre timing e atrasos entre itens
MaterialElevationTransition

Efeito de elevação gradual com sombra
Simula papel sendo erguido (conceito do Material Design)
3. Utilitários e Ferramentas:
NavigationTransitions

Métodos estáticos para usar transições facilmente
API simplificada para navegação com efeitos
InAppPageTransitionSwitcher

Mecanismo para criar transições entre "páginas" dentro do mesmo fluxo
Alternativa a navegação completa para mudanças de estado na UI
4. Recursos Avançados:
Suporte a navegação bidirecional inteligente
Combinação de múltiplos efeitos (ex: fade + slide)
Consistência com padrões de Material Design
Customização completa de curvas de animação
Controle preciso sobre timing e duração
Estas transições elevam significativamente a qualidad*/
