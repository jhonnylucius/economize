import 'package:economize/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Biblioteca de animações de celebração para o Clube de Benefícios.
///
/// Fornece uma variedade de animações visuais para celebrar conquistas
/// e momentos de sucesso no aplicativo.
class CelebrationAnimations {
  /// Não permite criar instâncias desta classe
  CelebrationAnimations._();
}

/// Animação de confete para momentos de celebração
class ConfettiAnimation extends StatefulWidget {
  /// Duração da animação
  final Duration duration;

  /// Número de partículas
  final int particleCount;

  /// Cores das partículas (usa cores do tema se nulo)
  final List<Color>? colors;

  /// Velocidade da animação
  final double speed;

  /// Se deve repetir a animação
  final bool repeat;

  /// Widget filho exibido junto com os confetes
  final Widget? child;

  /// Altura do container
  final double height;

  /// Largura do container
  final double width;

  /// Direção inicial das partículas
  final ConfettiDirection direction;

  /// Cria uma animação de confete
  const ConfettiAnimation({
    super.key,
    this.duration = const Duration(seconds: 3),
    this.particleCount = 50,
    this.colors,
    this.speed = 1.0,
    this.repeat = false,
    this.child,
    this.height = 300,
    this.width = double.infinity,
    this.direction = ConfettiDirection.down,
    required AnimationController animationController,
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Configure o comportamento baseado na flag de repetição
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }

    _initializeParticles();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    _particles = List<_ConfettiParticle>.generate(
      widget.particleCount,
      (_) => _createParticle(),
    );
  }

  _ConfettiParticle _createParticle() {
    // Cores padrão se não forem fornecidas
    final colors = widget.colors ??
        [
          AppColors.primary,
          AppColors.secondary,
          AppColors.tertiary,
          Colors.pink,
          Colors.purple,
          Colors.orange,
        ];

    // Posição inicial baseada na direção
    late double initialX;
    late double initialY;
    late double velocityX;
    late double velocityY;

    switch (widget.direction) {
      case ConfettiDirection.down:
        initialX = _random.nextDouble() * widget.width;
        initialY = -20;
        velocityX = (_random.nextDouble() - 0.5) * 2 * widget.speed;
        velocityY = 2 + _random.nextDouble() * 2 * widget.speed;
        break;
      case ConfettiDirection.up:
        initialX = _random.nextDouble() * widget.width;
        initialY = widget.height + 20;
        velocityX = (_random.nextDouble() - 0.5) * 2 * widget.speed;
        velocityY = -2 - _random.nextDouble() * 2 * widget.speed;
        break;
      case ConfettiDirection.left:
        initialX = widget.width + 20;
        initialY = _random.nextDouble() * widget.height;
        velocityX = -2 - _random.nextDouble() * 2 * widget.speed;
        velocityY = (_random.nextDouble() - 0.5) * 2 * widget.speed;
        break;
      case ConfettiDirection.right:
        initialX = -20;
        initialY = _random.nextDouble() * widget.height;
        velocityX = 2 + _random.nextDouble() * 2 * widget.speed;
        velocityY = (_random.nextDouble() - 0.5) * 2 * widget.speed;
        break;
      case ConfettiDirection.explosion:
        initialX = widget.width / 2;
        initialY = widget.height / 2;
        final angle = _random.nextDouble() * 2 * math.pi;
        final velocity = 1 + _random.nextDouble() * 3 * widget.speed;
        velocityX = math.cos(angle) * velocity;
        velocityY = math.sin(angle) * velocity;
        break;
    }

    return _ConfettiParticle(
      color: colors[_random.nextInt(colors.length)],
      position: Offset(initialX, initialY),
      velocity: Offset(velocityX, velocityY),
      size: 5 + _random.nextDouble() * 7,
      rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
      type: _ConfettiType.values[_random.nextInt(_ConfettiType.values.length)],
      startLifetime: _random.nextDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: Stack(
        children: [
          if (widget.child != null) widget.child!,
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _controller.value,
                  screenSize: Size(widget.width, widget.height),
                ),
                size: Size(widget.width, widget.height),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Direções possíveis para o confetti
enum ConfettiDirection {
  /// Confetes caindo de cima para baixo
  down,

  /// Confetes subindo de baixo para cima
  up,

  /// Confetes vindo da direita para a esquerda
  left,

  /// Confetes vindo da esquerda para a direita
  right,

  /// Confetes explodindo do centro para fora
  explosion,
}

/// Tipos de partícula de confete
enum _ConfettiType {
  /// Formato circular
  circle,

  /// Formato de quadrado
  square,

  /// Formato triangular
  triangle,

  /// Formato de linha
  line,
}

/// Define uma partícula de confete
class _ConfettiParticle {
  /// Cor da partícula
  Color color;

  /// Posição atual
  Offset position;

  /// Velocidade e direção
  Offset velocity;

  /// Tamanho da partícula
  double size;

  /// Velocidade de rotação
  double rotationSpeed;

  /// Ângulo atual de rotação
  double rotation;

  /// Tipo de partícula
  _ConfettiType type;

  /// Tempo de vida inicial da partícula (0.0 - 1.0)
  double startLifetime;

  _ConfettiParticle({
    required this.color,
    required this.position,
    required this.velocity,
    required this.size,
    required this.rotationSpeed,
    required this.type,
    required this.startLifetime,
    this.rotation = 0,
  });
}

/// Painter para renderizar partículas de confete
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  final Size screenSize;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calcula o progresso efetivo para esta partícula
      final particleProgress = (progress + particle.startLifetime) % 1.0;

      // Atualize a posição da partícula
      particle.position = particle.position + particle.velocity;
      particle.rotation += particle.rotationSpeed;

      // Pinte a partícula
      final paint = Paint()..color = particle.color;

      // Defina a opacidade para desvanecer no final
      if (particleProgress > 0.7) {
        final opacity = 1.0 - ((particleProgress - 0.7) / 0.3);
        paint.color =
            paint.color.withAlpha(((opacity.clamp(0.0, 1.0)) * 255).round());
      }

      // Salve o estado do canvas para aplicar transformações
      canvas.save();

      // Aplique a translação para a posição da partícula
      canvas.translate(particle.position.dx, particle.position.dy);

      // Aplique a rotação
      canvas.rotate(particle.rotation);

      // Desenhe o formato da partícula
      switch (particle.type) {
        case _ConfettiType.circle:
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
          break;

        case _ConfettiType.square:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size,
            ),
            paint,
          );
          break;

        case _ConfettiType.triangle:
          final path = Path();
          path.moveTo(0, -particle.size / 2);
          path.lineTo(particle.size / 2, particle.size / 2);
          path.lineTo(-particle.size / 2, particle.size / 2);
          path.close();
          canvas.drawPath(path, paint);
          break;

        case _ConfettiType.line:
          canvas.drawLine(
            Offset(-particle.size / 2, 0),
            Offset(particle.size / 2, 0),
            paint..strokeWidth = particle.size / 4,
          );
          break;
      }

      // Restaure o canvas ao estado original
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Animação de estrelas em cascata
class StarburstAnimation extends StatefulWidget {
  /// Cores das estrelas
  final List<Color>? colors;

  /// Número de estrelas
  final int starCount;

  /// Tamanho máximo das estrelas
  final double maxStarSize;

  /// Duração da animação
  final Duration duration;

  /// Se a animação deve ser repetida
  final bool repeat;

  /// Widget filho a ser exibido com as estrelas
  final Widget? child;

  /// Ponto de origem das estrelas
  final Alignment origin;

  /// Tamanho do container
  final Size? size;

  /// Cria uma animação de explosão de estrelas
  const StarburstAnimation({
    super.key,
    this.colors,
    this.starCount = 30,
    this.maxStarSize = 20.0,
    this.duration = const Duration(seconds: 2),
    this.repeat = false,
    this.child,
    this.origin = Alignment.center,
    this.size,
  });

  @override
  State<StarburstAnimation> createState() => _StarburstAnimationState();
}

class _StarburstAnimationState extends State<StarburstAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Star> _generateStars(Size size) {
    final defaultColors = widget.colors ??
        [
          Colors.amber,
          Colors.yellow,
          AppColors.tertiary,
          Colors.orange.shade300,
        ];

    // Ponto de origem baseado no alinhamento
    final originX = size.width * ((widget.origin.x + 1) / 2);
    final originY = size.height * ((widget.origin.y + 1) / 2);
    final origin = Offset(originX, originY);

    return List.generate(widget.starCount, (index) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final distance = _random.nextDouble() * size.width * 0.4;
      final velocity = 50 + _random.nextDouble() * 100;

      return _Star(
        color: defaultColors[_random.nextInt(defaultColors.length)],
        size: 5 + _random.nextDouble() * widget.maxStarSize,
        angle: angle,
        distance: distance,
        velocity: velocity,
        origin: origin,
        delay: _random.nextDouble() * 0.5,
        points: _random.nextInt(3) + 4, // 4 a 6 pontas
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size =
          widget.size ?? Size(constraints.maxWidth, constraints.maxHeight);

      _stars = _generateStars(size);

      return Container(
        width: size.width,
        height: size.height,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        child: Stack(
          children: [
            if (widget.child != null) widget.child!,
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _StarPainter(
                    stars: _stars,
                    progress: _controller.value,
                    size: size,
                  ),
                  size: size,
                );
              },
            ),
          ],
        ),
      );
    });
  }
}

/// Define uma estrela para a animação de explosão
class _Star {
  final Color color;
  final double size;
  final double angle;
  final double distance;
  final double velocity;
  final Offset origin;
  final double delay;
  final int points;
  final double rotation;
  final double rotationSpeed;

  _Star({
    required this.color,
    required this.size,
    required this.angle,
    required this.distance,
    required this.velocity,
    required this.origin,
    required this.delay,
    required this.points,
    required this.rotation,
    required this.rotationSpeed,
  });
}

/// Painter para renderizar estrelas
class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress;
  final Size size;

  _StarPainter({
    required this.stars,
    required this.progress,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      // Ajuste o progresso com o atraso da estrela
      final adjustedProgress = math.max(0.0, progress - star.delay);
      if (adjustedProgress <= 0) continue;

      // A estrela só começa a aparecer depois do atraso
      final normalizedProgress =
          math.min(1.0, adjustedProgress / (1.0 - star.delay));

      // Calcule a posição da estrela
      final distance = star.distance + star.velocity * normalizedProgress;
      final x = star.origin.dx + math.cos(star.angle) * distance;
      final y = star.origin.dy + math.sin(star.angle) * distance;

      // Calcule o fator de escala (crescendo e depois encolhendo)
      double scale;
      if (normalizedProgress < 0.3) {
        scale = normalizedProgress / 0.3; // Crescendo
      } else {
        scale = 1.0 - ((normalizedProgress - 0.3) / 0.7); // Diminuindo
      }

      // Calcule a opacidade (desaparece no final)
      final opacity = math.max(0.0, 1.0 - normalizedProgress);

      // Desenhe a estrela
      final paint = Paint()
        ..color = star.color.withAlpha((opacity * 255).round())
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(star.rotation + normalizedProgress * star.rotationSpeed);
      canvas.scale(scale);

      // Desenhe uma estrela
      final path = Path();
      final outerRadius = star.size / 2;
      final innerRadius = star.size / 4;
      final double angleStep = 2 * math.pi / (star.points * 2);

      for (int i = 0; i < star.points * 2; i++) {
        final radius = i % 2 == 0 ? outerRadius : innerRadius;
        final pointAngle = i * angleStep;
        final px = math.cos(pointAngle) * radius;
        final py = math.sin(pointAngle) * radius;

        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }

      path.close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Animação de fogos de artifício
class FireworksAnimation extends StatefulWidget {
  /// Número de fogos
  final int fireworkCount;

  /// Cores dos fogos
  final List<Color>? colors;

  /// Duração da animação
  final Duration duration;

  /// Widget filho
  final Widget? child;

  /// Se a animação deve se repetir
  final bool repeat;

  /// Tamanho de cada explosão
  final double explosionSize;

  /// Cria uma animação de fogos de artifício
  const FireworksAnimation({
    super.key,
    this.fireworkCount = 5,
    this.colors,
    this.duration = const Duration(seconds: 5),
    this.child,
    this.repeat = false,
    this.explosionSize = 100.0,
  });

  @override
  State<FireworksAnimation> createState() => _FireworksAnimationState();
}

class _FireworksAnimationState extends State<FireworksAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<_Firework> _fireworks;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.fireworkCount,
      (_) => AnimationController(
        vsync: this,
        duration: widget.duration,
      ),
    );

    _animations = _controllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      );
    }).toList();

    // Inicia os fogos com atrasos aleatórios
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: _random.nextInt(2000)), () {
        if (mounted) {
          if (widget.repeat) {
            _controllers[i].repeat();
          } else {
            _controllers[i].forward();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<_Firework> _generateFireworks(Size size) {
    final defaultColors = widget.colors ??
        [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.purple,
          Colors.orange,
          Colors.pink,
          AppColors.primary,
          AppColors.tertiary,
        ];

    return List.generate(widget.fireworkCount, (index) {
      return _Firework(
        position: Offset(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height * 0.7,
        ),
        color: defaultColors[_random.nextInt(defaultColors.length)],
        size: widget.explosionSize * (0.5 + _random.nextDouble() * 1.0),
        particleCount: 30 + _random.nextInt(20),
        delayFactor: _random.nextDouble(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _fireworks = _generateFireworks(constraints.biggest);

        return Stack(
          children: [
            if (widget.child != null) widget.child!,
            ...List.generate(widget.fireworkCount, (index) {
              return AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  return CustomPaint(
                    painter: _FireworkPainter(
                      firework: _fireworks[index],
                      progress: _animations[index].value,
                      delayFactor: _fireworks[index].delayFactor,
                    ),
                    size: constraints.biggest,
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }
}

/// Define um fogo de artifício
class _Firework {
  final Offset position;
  final Color color;
  final double size;
  final int particleCount;
  final double delayFactor;

  _Firework({
    required this.position,
    required this.color,
    required this.size,
    required this.particleCount,
    required this.delayFactor,
  });
}

/// Painter para renderizar fogos de artifício
class _FireworkPainter extends CustomPainter {
  final _Firework firework;
  final double progress;
  final double delayFactor;
  final math.Random random = math.Random();

  _FireworkPainter({
    required this.firework,
    required this.progress,
    required this.delayFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Espere o atraso para iniciar este fogo
    final adjustedProgress = progress * (1 + delayFactor) - delayFactor;
    if (adjustedProgress <= 0) {
      return;
    }

    final normalizedProgress = math.min(1.0, adjustedProgress);

    // Traço de subida (rastro)
    if (normalizedProgress < 0.2) {
      final trailProgress = normalizedProgress / 0.2;
      final startY = size.height;
      final endY = firework.position.dy;

      final currentY = startY - (startY - endY) * trailProgress;

      final Paint trailPaint = Paint()
        ..color = firework.color
            .withAlpha(((0.6 * (1 - trailProgress)) * 255).round())
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(firework.position.dx, startY),
        Offset(firework.position.dx, currentY),
        trailPaint,
      );

      // Desenha a "cabeça" do traço
      canvas.drawCircle(
        Offset(firework.position.dx, currentY),
        4,
        Paint()
          ..color = Colors.white.withAlpha(((1 - trailProgress) * 255).round()),
      );

      return;
    }

    // Fase de explosão
    final explosionProgress = (normalizedProgress - 0.2) / 0.8;

    // Gere partículas baseadas em uma semente determinística
    final seed = (firework.position.dx + firework.position.dy).toInt();
    final particleRandom = math.Random(seed);

    for (int i = 0; i < firework.particleCount; i++) {
      final angle = 2 * math.pi * i / firework.particleCount;
      final variance = particleRandom.nextDouble() * 0.2;

      final distance = firework.size * 0.1 +
          firework.size * explosionProgress * (0.8 + variance);

      final decay = 1.0 - explosionProgress;
      final opacity = decay * (0.7 + particleRandom.nextDouble() * 0.3);

      final x = firework.position.dx + math.cos(angle) * distance;
      final y = firework.position.dy + math.sin(angle) * distance;

      // Adicione gravidade às partículas
      final gravityEffect = 20 * math.pow(explosionProgress, 2);
      final adjustedY = y + gravityEffect;

      // Variação de cor
      final colorVariance = particleRandom.nextDouble() * 0.4 - 0.2;
      final hslColor = HSLColor.fromColor(firework.color);
      final adjustedColor = hslColor
          .withLightness((hslColor.lightness + colorVariance).clamp(0.0, 1.0))
          .toColor();

      // Tamanho da partícula diminui com o tempo
      final particleSize = 3 * (1 - explosionProgress * 0.7);

      final paint = Paint()
        ..color = adjustedColor.withAlpha((opacity * 255).round())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, adjustedY), particleSize, paint);

      // Adicione rastro às partículas
      if (explosionProgress > 0.1 && explosionProgress < 0.8) {
        final trailLength = 4 * (1 - explosionProgress);

        final trailPaint = Paint()
          ..color = adjustedColor.withAlpha(((opacity * 0.5) * 255).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = particleSize / 2;

        final trailX = firework.position.dx + math.cos(angle) * distance * 0.85;
        final trailY = firework.position.dy +
            math.sin(angle) * distance * 0.85 +
            gravityEffect * 0.9;

        canvas.drawLine(
          Offset(trailX, trailY),
          Offset(x, adjustedY),
          trailPaint,
        );
      }
    }

    // Adicione brilho central no início da explosão
    if (explosionProgress < 0.2) {
      final glowProgress = 1.0 - explosionProgress / 0.2;
      final glowPaint = Paint()
        ..color = Colors.white.withAlpha((glowProgress * 0.8 * 255).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawCircle(
        firework.position,
        10 * glowProgress,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_FireworkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Animação de brilho dourado para conquistas
class GoldenShineAnimation extends StatefulWidget {
  /// Widget filho que receberá o efeito de brilho
  final Widget child;

  /// Duração de um ciclo completo do brilho
  final Duration duration;

  /// Intensidade do brilho (0.0 - 1.0)
  final double intensity;

  /// Cor do brilho
  final Color? color;

  /// Se deve repetir automaticamente
  final bool repeat;

  /// Cria uma animação de brilho dourado
  const GoldenShineAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.intensity = 0.5,
    this.color,
    this.repeat = true,
  });

  @override
  State<GoldenShineAnimation> createState() => _GoldenShineAnimationState();
}

class _GoldenShineAnimationState extends State<GoldenShineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.transparent,
                widget.color ?? Colors.amber.shade200,
                Colors.white.withAlpha((widget.intensity * 255).round()),
                widget.color ?? Colors.amber.shade200,
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: _SweepingGradientTransform(
                progress: _controller.value,
              ),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Transformação para animar o gradiente do efeito dourado
class _SweepingGradientTransform extends GradientTransform {
  final double progress;

  const _SweepingGradientTransform({required this.progress});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final double width = bounds.width;
    final double height = bounds.height;

    final double diagonal = math.sqrt(width * width + height * height);
    final double offset = 2 * diagonal * progress - diagonal;

    return Matrix4.identity()
      ..translate(offset, offset)
      ..rotateZ(-math.pi / 4);
  }
}

/// Animação de explosão de partículas
class ParticleExplosionAnimation extends StatefulWidget {
  /// Número de partículas
  final int particleCount;

  /// Cores das partículas
  final List<Color>? colors;

  /// Tamanho máximo das partículas
  final double maxParticleSize;

  /// Duração da animação
  final Duration duration;

  /// Ponto de origem da explosão
  final Alignment origin;

  /// Widget filho
  final Widget? child;

  /// Se deve repetir automaticamente
  final bool repeat;

  /// Se deve explodir automaticamente quando construído
  final bool autoPlay;

  /// Modo de emissão das partículas
  final ExplosionMode mode;

  /// Cria uma animação de explosão de partículas
  const ParticleExplosionAnimation({
    super.key,
    this.particleCount = 50,
    this.colors,
    this.maxParticleSize = 15.0,
    this.duration = const Duration(seconds: 1),
    this.origin = Alignment.center,
    this.child,
    this.repeat = false,
    this.autoPlay = true,
    this.mode = ExplosionMode.burst,
  });

  @override
  State<ParticleExplosionAnimation> createState() =>
      _ParticleExplosionAnimationState();
}

class _ParticleExplosionAnimationState extends State<ParticleExplosionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ExplosionParticle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.autoPlay) {
      if (widget.repeat) {
        _controller.repeat();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Inicia manualmente a animação
  void explode() {
    _controller.reset();
    _controller.forward();
  }

  List<_ExplosionParticle> _generateParticles(Size size) {
    final defaultColors = widget.colors ??
        [
          AppColors.primary,
          AppColors.secondary,
          AppColors.tertiary,
          Colors.amber,
          Colors.purple,
        ];

    // Ponto de origem
    final originX = size.width * ((widget.origin.x + 1) / 2);
    final originY = size.height * ((widget.origin.y + 1) / 2);
    final origin = Offset(originX, originY);

    return List.generate(widget.particleCount, (index) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final distance =
          _random.nextDouble() * math.min(size.width, size.height) * 0.5;

      // Velocidades diferentes por modo
      double velocity;
      switch (widget.mode) {
        case ExplosionMode.burst:
          velocity = 100 + _random.nextDouble() * 150;
          break;
        case ExplosionMode.fountain:
          velocity = 80 + _random.nextDouble() * 120;
          break;
        case ExplosionMode.firework:
          velocity = 70 + _random.nextDouble() * 100;
          break;
      }

      return _ExplosionParticle(
        color: defaultColors[_random.nextInt(defaultColors.length)],
        size: 3 + _random.nextDouble() * widget.maxParticleSize,
        angle: angle,
        distance: distance,
        velocity: velocity,
        origin: origin,
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 3,
        delay: widget.mode == ExplosionMode.burst
            ? 0.0
            : _random.nextDouble() * 0.3,
        type:
            _ParticleType.values[_random.nextInt(_ParticleType.values.length)],
        gravity: widget.mode == ExplosionMode.fountain
            ? 100 + _random.nextDouble() * 100
            : 30 + _random.nextDouble() * 50,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _particles = _generateParticles(size);

        return Stack(
          children: [
            if (widget.child != null) widget.child!,
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ExplosionPainter(
                    particles: _particles,
                    progress: _controller.value,
                    size: size,
                    mode: widget.mode,
                  ),
                  size: size,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Modos de explosão para partículas
enum ExplosionMode {
  /// Explosão uniforme em todas as direções
  burst,

  /// Fonte de partículas para cima com gravidade
  fountain,

  /// Semelhante a fogos de artifício
  firework,
}

/// Tipos de partículas na explosão
enum _ParticleType {
  /// Formato circular
  circle,

  /// Formato quadrado
  square,

  /// Formato de estrela
  star,

  /// Formato triangular
  triangle,
}

/// Define uma partícula de explosão
class _ExplosionParticle {
  final Color color;
  final double size;
  final double angle;
  final double distance;
  final double velocity;
  final Offset origin;
  final double rotation;
  final double rotationSpeed;
  final double delay;
  final _ParticleType type;
  final double gravity;

  _ExplosionParticle({
    required this.color,
    required this.size,
    required this.angle,
    required this.distance,
    required this.velocity,
    required this.origin,
    required this.rotation,
    required this.rotationSpeed,
    required this.delay,
    required this.type,
    required this.gravity,
  });
}

/// Painter para renderizar partículas de explosão
class _ExplosionPainter extends CustomPainter {
  final List<_ExplosionParticle> particles;
  final double progress;
  final Size size;
  final ExplosionMode mode;

  _ExplosionPainter({
    required this.particles,
    required this.progress,
    required this.size,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Ajuste o progresso com o delay
      final adjustedProgress = math.max(0.0, progress - particle.delay);
      if (adjustedProgress <= 0) continue;

      // Normalize o progresso considerando o delay
      final normalizedProgress =
          math.min(1.0, adjustedProgress / (1.0 - particle.delay));

      // Cálculo da posição baseada no modo
      double x, y;
      double currentOpacity = 1.0;

      switch (mode) {
        case ExplosionMode.burst:
          final distance = particle.velocity * normalizedProgress;
          x = particle.origin.dx + math.cos(particle.angle) * distance;
          y = particle.origin.dy + math.sin(particle.angle) * distance;

          // A opacidade diminui linearmente
          currentOpacity = 1.0 - normalizedProgress;
          break;

        case ExplosionMode.fountain:
          final horizontalDistance =
              particle.velocity * 0.3 * normalizedProgress;
          final verticalBase = -particle.velocity * normalizedProgress;
          final gravityEffect =
              0.5 * particle.gravity * normalizedProgress * normalizedProgress;

          x = particle.origin.dx +
              math.cos(particle.angle) * horizontalDistance;
          y = particle.origin.dy + verticalBase + gravityEffect;

          // A opacidade diminui mais no final
          currentOpacity = 1.0 - math.pow(normalizedProgress, 2);
          break;

        case ExplosionMode.firework:
          final baseDistance = particle.velocity * normalizedProgress;
          final decay =
              math.pow(normalizedProgress, 0.5).toDouble(); // Desaceleração
          final distance = baseDistance * (1.0 - decay * 0.5);

          x = particle.origin.dx + math.cos(particle.angle) * distance;
          y = particle.origin.dy + math.sin(particle.angle) * distance;

          // Suave efeito de gravidade
          final gravityEffect = 20 * math.pow(normalizedProgress, 2);
          y += gravityEffect;

          // Fade-out mais rápido
          currentOpacity = math.pow(1.0 - normalizedProgress, 1.5).toDouble();
          break;
      }

      // Tamanho diminui com o tempo
      final currentSize = particle.size * (1.0 - normalizedProgress * 0.5);

      // Rotação aumenta com o tempo
      final currentRotation =
          particle.rotation + normalizedProgress * particle.rotationSpeed;

      final paint = Paint()
        ..color = particle.color
            .withAlpha(((currentOpacity.clamp(0.0, 1.0)) * 255).round())
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(currentRotation);

      // Desenhe a forma da partícula
      switch (particle.type) {
        case _ParticleType.circle:
          canvas.drawCircle(Offset.zero, currentSize / 2, paint);
          break;

        case _ParticleType.square:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: currentSize,
              height: currentSize,
            ),
            paint,
          );
          break;

        case _ParticleType.star:
          final path = Path();
          final outerRadius = currentSize / 2;
          final innerRadius = currentSize / 5;

          for (int i = 0; i < 10; i++) {
            final radius = i % 2 == 0 ? outerRadius : innerRadius;
            final angle = i * math.pi / 5;
            final x = math.cos(angle) * radius;
            final y = math.sin(angle) * radius;

            if (i == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          }

          path.close();
          canvas.drawPath(path, paint);
          break;

        case _ParticleType.triangle:
          final path = Path();
          path.moveTo(0, -currentSize / 2);
          path.lineTo(currentSize / 2, currentSize / 2);
          path.lineTo(-currentSize / 2, currentSize / 2);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();

      // Adicione um rastro para partículas em movimento rápido
      if ((mode == ExplosionMode.burst || mode == ExplosionMode.firework) &&
          normalizedProgress > 0.05 &&
          normalizedProgress < 0.7) {
        final trailLength = currentSize * (1.0 - normalizedProgress);

        final trailPaint = Paint()
          ..color =
              particle.color.withAlpha(((currentOpacity * 0.3) * 255).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = currentSize / 4
          ..strokeCap = StrokeCap.round;

        final trailAngle =
            particle.angle + math.pi; // Inverso da direção de movimento
        final trailX = x - math.cos(particle.angle) * trailLength;
        final trailY = y - math.sin(particle.angle) * trailLength;

        canvas.drawLine(
          Offset(x, y),
          Offset(trailX, trailY),
          trailPaint,
        );
      }
    }

    // Adicione brilho na origem no início da animação (para explosões)
    if (progress < 0.2 && mode != ExplosionMode.fountain) {
      final glowOpacity = 1.0 - progress / 0.2;

      final glowPaint = Paint()
        ..color = Colors.white.withAlpha((glowOpacity * 0.7 * 255).round())
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          20 * (1.0 - progress / 0.2),
        );

      if (particles.isNotEmpty) {
        canvas.drawCircle(
          particles.first.origin,
          15 * glowOpacity,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ExplosionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Animação de prêmio ou troféu flutuante
class FloatingPrizeAnimation extends StatefulWidget {
  /// Widget do prêmio/troféu que será animado
  final Widget child;

  /// Altura máxima da flutuação
  final double floatHeight;

  /// Duração de um ciclo completo
  final Duration duration;

  /// Se deve ter um efeito de rotação suave
  final bool enableRotation;

  /// Se deve ter um efeito de brilho
  final bool enableGlow;

  /// Cor do brilho
  final Color? glowColor;

  /// Cria uma animação de prêmio/troféu flutuante
  const FloatingPrizeAnimation({
    super.key,
    required this.child,
    this.floatHeight = 15.0,
    this.duration = const Duration(seconds: 3),
    this.enableRotation = true,
    this.enableGlow = true,
    this.glowColor,
  });

  @override
  State<FloatingPrizeAnimation> createState() => _FloatingPrizeAnimationState();
}

class _FloatingPrizeAnimationState extends State<FloatingPrizeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: -widget.floatHeight / 2,
      end: widget.floatHeight / 2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotateAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Widget result = widget.child;

        // Aplique o efeito de brilho/raios
        if (widget.enableGlow) {
          final effectiveGlowColor = widget.glowColor ??
              Colors.amber.shade200
                  .withAlpha(((_glowAnimation.value * 0.7) * 255).round());

          result = Stack(
            alignment: Alignment.center,
            children: [
              // Raios/brilho
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      effectiveGlowColor,
                      effectiveGlowColor.withAlpha((0.3 * 255).round()),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              ),
              // Widget principal
              result,
            ],
          );
        }

        // Aplique a rotação
        if (widget.enableRotation) {
          result = Transform.rotate(
            angle: _rotateAnimation.value,
            child: result,
          );
        }

        // Aplique a flutuação
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: result,
        );
      },
    );
  }
}

/// Chuva de moedas para celebrar recompensas
class CoinRainAnimation extends StatefulWidget {
  /// Número de moedas
  final int coinCount;

  /// Cores das moedas
  final List<Color>? colors;

  /// Duração da animação
  final Duration duration;

  /// Tamanho máximo das moedas
  final double maxCoinSize;

  /// Widget filho
  final Widget? child;

  /// Cria uma animação de chuva de moedas
  const CoinRainAnimation({
    super.key,
    this.coinCount = 30,
    this.colors,
    this.duration = const Duration(seconds: 4),
    this.maxCoinSize = 30.0,
    this.child,
  });

  @override
  State<CoinRainAnimation> createState() => _CoinRainAnimationState();
}

class _CoinRainAnimationState extends State<CoinRainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Coin> _coins;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Coin> _generateCoins(Size size) {
    final defaultColors = widget.colors ??
        [
          Colors.amber,
          Colors.amber.shade600,
          Colors.orange.shade700,
        ];

    return List.generate(widget.coinCount, (index) {
      return _Coin(
        position: Offset(
          _random.nextDouble() * size.width,
          -widget.maxCoinSize - _random.nextDouble() * size.height * 0.3,
        ),
        size: widget.maxCoinSize * (0.5 + _random.nextDouble() * 0.5),
        velocity: 100 + _random.nextDouble() * 150,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        horizontalMovement: (_random.nextDouble() - 0.5) * 50,
        delay: _random.nextDouble() * 0.5,
        color: defaultColors[_random.nextInt(defaultColors.length)],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _coins = _generateCoins(size);

        return Stack(
          children: [
            if (widget.child != null) widget.child!,
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CoinPainter(
                    coins: _coins,
                    progress: _controller.value,
                    screenSize: size,
                  ),
                  size: size,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Define uma moeda para a animação de chuva
class _Coin {
  final Offset position;
  final double size;
  final double velocity;
  final double rotationSpeed;
  final double horizontalMovement;
  final double delay;
  final Color color;
  double rotation = 0;

  _Coin({
    required this.position,
    required this.size,
    required this.velocity,
    required this.rotationSpeed,
    required this.horizontalMovement,
    required this.delay,
    required this.color,
  });
}

/// Painter para renderizar moedas
class _CoinPainter extends CustomPainter {
  final List<_Coin> coins;
  final double progress;
  final Size screenSize;

  _CoinPainter({
    required this.coins,
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final coin in coins) {
      // Ajuste o progresso com o delay
      final adjustedProgress = math.max(0.0, progress - coin.delay);
      if (adjustedProgress <= 0) continue;

      // A moeda só começa a aparecer depois do delay
      final normalizedProgress =
          math.min(1.0, adjustedProgress / (1.0 - coin.delay));

      // Calcule a posição atual da moeda
      final verticalMovement = coin.velocity * normalizedProgress;
      final horizontalOffset =
          coin.horizontalMovement * math.sin(normalizedProgress * math.pi);

      final x = coin.position.dx + horizontalOffset;
      final y = coin.position.dy + verticalMovement;

      // Atualize a rotação
      coin.rotation += coin.rotationSpeed * 0.01;

      // Desenhe a moeda
      if (x >= -coin.size &&
          x <= size.width + coin.size &&
          y >= -coin.size &&
          y <= size.height + coin.size) {
        _drawCoin(canvas, x, y, coin.size, coin.rotation, coin.color);
      }
    }
  }

  void _drawCoin(Canvas canvas, double x, double y, double size,
      double rotation, Color color) {
    canvas.save();
    canvas.translate(x, y);

    // Rotação para simular moeda girando
    canvas.rotate(rotation);

    // O escalonamento no eixo X simula a moeda se inclinando durante a rotação
    final scaleX = math.cos(math.cos(rotation * 2));
    canvas.scale(scaleX, 1.0);

    // Corpo da moeda
    final coinPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, size / 2, coinPaint);

    // Borda da moeda
    final borderPaint = Paint()
      ..color = color.darken(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.05;

    canvas.drawCircle(Offset.zero, size / 2, borderPaint);

    // Detalhe interior
    final innerPaint = Paint()
      ..color = color.lighten(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.07;

    canvas.drawCircle(Offset.zero, size / 3, innerPaint);

    // Reflexo
    final highlightPaint = Paint()
      ..color = Colors.white.withAlpha((0.3 * 255).round())
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(-size * 0.15, -size * 0.15), size * 0.12, highlightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoinPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Extensão para clarear e escurecer cores
extension ColorUtils on Color {
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color lighten(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
/*Esse componente de Celebration Animations implementa:
1. Animações de Celebração Variadas:
ConfettiAnimation

Partículas multicoloridas para momentos de celebração
Várias direções: chuva para baixo, jato para cima, explosão central, etc.
Partículas em formato variado (quadrados, círculos, triângulos)
Comportamento físico realista com rotação e queda natural
StarburstAnimation

Estrelas que irradiam a partir de um ponto central
Movimento expansivo com desaparecimento gradual
Estrelas com tamanhos e cores variados
Efeito visual de explosão celebratória
FireworksAnimation

Fogos de artifício completos com rastro de subida e explosão
Partículas com efeito de gravidade e brilho
Timing aleatório para simular múltiplos fogos
Efeito de brilho central no momento da explosão
GoldenShineAnimation

Efeito de "varredura" dourada para realçar conquistas
Brilho sutil que percorre um elemento importante
Ideal para medalhas, troféus ou elementos premium
Controle de intensidade e cor para diferentes contextos
ParticleExplosionAnimation

Sistema versátil de explosão de partículas
Três modos: explosão, fonte e fogos
Partículas com formatos, cores e comportamentos variados
Funções para acionar a explosão programaticamente
FloatingPrizeAnimation

Animação suave de flutuação para troféus/prêmios
Movimento vertical suave com rotação opcional
Efeito de brilho radial para destaque
Ideal para telas de conquista e recompensa
CoinRainAnimation

Chuva de moedas para celebrar ganhos financeiros
Moedas detalhadas com reflexo e rotação 3D
Movimento realista com variação de tamanho e velocidade
Perfeita para cashback, pontos ganhos ou economias*/
