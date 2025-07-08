import 'package:economize/animations/celebration_animations.dart';
import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/service/moedas/currency_service.dart';
import 'package:economize/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  bool _showSecondPhase = false;
  bool _showFinalPhase = false;
  bool _animationFinished = false;
  final List<_CoinParticle> _coinParticles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _logoScaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 10,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5),
      ),
    );

    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: math.pi * 2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // Iniciar a animação e sequenciar as fases
    _controller.forward();

    // Fase 2: Mostrar texto e partículas
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _showSecondPhase = true;
          _generateCoinParticles();
        });
      }
    });

    // Fase 3: Mostrar tagline e botão
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() {
          _showFinalPhase = true;
        });
      }
    });

    // Inicia navegação quando a animação completa
    Future.delayed(const Duration(milliseconds: 4000), () {
      _initializeApp();
      setState(() {
        _animationFinished = true;
      });
    });
  }

  void _generateCoinParticles() {
    // Gerar partículas de moedas para o efeito de dinheiro
    for (int i = 0; i < 30; i++) {
      _coinParticles.add(_CoinParticle(
        position: Offset(
          _random.nextDouble() * MediaQuery.of(context).size.width,
          -50 - _random.nextDouble() * 100,
        ),
        size: 10 + _random.nextDouble() * 20,
        speed: 3 + _random.nextDouble() * 5,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
        horizontalSpeed: (_random.nextDouble() - 0.5) * 2,
        delay: _random.nextDouble() * 2,
        color: _getRandomCoinColor(),
      ));
    }
  }

  Color _getRandomCoinColor() {
    final colors = [
      Colors.amber.shade300,
      Colors.amber.shade400,
      Colors.amber.shade500,
      Colors.yellow.shade600,
      Colors.orange.shade300,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  // SUBSTITUIR O MÉTODO _initializeApp:
  Future<void> _initializeApp() async {
    try {
      // Simula carregamento
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      // ✅ VERIFICAR SE PRECISA CONFIGURAR MOEDA
      final needsCurrencySelection = await CurrencyService.isFirstRun();

      if (!mounted) return;
      if (needsCurrencySelection) {
        // Primeira execução - vai para seleção de país
        Navigator.pushReplacementNamed(context, '/country-selection');
      } else {
        // Já configurado - vai direto para home
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      debugPrint('Erro na inicialização: $e');
      // Em caso de erro, vai para home mesmo assim
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Fundo com círculos decorativos
          Positioned.fill(
            child: CustomPaint(
              painter: _CirclesBackgroundPainter(
                color: AppColors.primaryLight,
                circlesCount: 12,
                maxRadius: 100,
              ),
            ),
          ),

          // Partículas de moedas caindo
          if (_showSecondPhase && !_animationFinished)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _CoinsPainter(
                      coins: _coinParticles,
                      time: DateTime.now().millisecondsSinceEpoch / 2000,
                      screenSize: Size(size.width, size.height),
                    ),
                    size: Size(size.width, size.height),
                  );
                },
              ),
            ),

          // Confetes quando aparece a fase final
          if (_showFinalPhase && !_animationFinished)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: size.height * 0.7,
              child: CustomPaint(
                painter: _ConfettiPainter(
                  colors: [
                    Colors.green.shade300,
                    Colors.green.shade500,
                    Colors.green.shade700,
                    Colors.yellow,
                    Colors.amber,
                    Colors.white,
                  ],
                  particleCount: 30,
                ),
              ),
            ),

          // Conteúdo principal centralizado
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animado
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: Transform.rotate(
                        angle:
                            _logoRotationAnimation.value * 0.1, // Rotação sutil
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Hero(
                            tag: 'app_logo',
                            child: Image.asset(
                              'assets/icon_removedbg.png',
                              width: 120,
                              height: 120,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Nome do app com animação
                if (_showSecondPhase)
                  FadeAnimation.fadeIn(
                    child: GoldenShineAnimation(
                      intensity: 0.8,
                      child: Text(
                        "ECONOMIZE\$",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Tagline com animação
                if (_showFinalPhase)
                  SlideAnimation.fromBottom(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        "Seu dinheiro sob controle",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 60),

                if (_showFinalPhase) const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pintor para desenhar o fundo com círculos decorativos
class _CirclesBackgroundPainter extends CustomPainter {
  final Color color;
  final int circlesCount;
  final double maxRadius;
  final math.Random random = math.Random(42); // Seed fixo para repetibilidade

  _CirclesBackgroundPainter({
    required this.color,
    required this.circlesCount,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha((0.2 * 255).toInt())
      ..style = PaintingStyle.fill;

    for (int i = 0; i < circlesCount; i++) {
      final radius = 20 + random.nextDouble() * maxRadius;
      final x = random.nextDouble() * (size.width + radius * 2) - radius;
      final y = random.nextDouble() * (size.height + radius * 2) - radius;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_CirclesBackgroundPainter oldDelegate) => false;
}

// Classe para definir uma partícula de moeda
class _CoinParticle {
  Offset position;
  final double size;
  final double speed;
  final double rotationSpeed;
  final double horizontalSpeed;
  final double delay;
  final Color color;
  double rotation = 0;
  bool active = false;

  _CoinParticle({
    required this.position,
    required this.size,
    required this.speed,
    required this.rotationSpeed,
    required this.horizontalSpeed,
    required this.delay,
    required this.color,
  });
}

// Pintor para desenhar as moedas caindo
class _CoinsPainter extends CustomPainter {
  final List<_CoinParticle> coins;
  final double time;
  final Size screenSize;

  _CoinsPainter({
    required this.coins,
    required this.time,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final coin in coins) {
      // Ativar moeda após delay
      if (!coin.active && time > coin.delay) {
        coin.active = true;
      }

      if (coin.active) {
        // Atualizar posição
        coin.position = Offset(
          coin.position.dx + coin.horizontalSpeed,
          coin.position.dy + coin.speed,
        );

        // Resetar posição quando sair da tela
        if (coin.position.dy > screenSize.height + coin.size) {
          coin.position = Offset(
            math.Random().nextDouble() * screenSize.width,
            -coin.size,
          );
        }

        // Atualizar rotação
        coin.rotation += coin.rotationSpeed;

        // Desenhar moeda
        _drawCoin(canvas, coin);
      }
    }
  }

  void _drawCoin(Canvas canvas, _CoinParticle coin) {
    canvas.save();
    canvas.translate(coin.position.dx, coin.position.dy);

    // Rotação para simular moeda girando
    canvas.rotate(coin.rotation);

    // O escalonamento no eixo X simula a moeda se inclinando durante a rotação
    final scaleX = math.cos(math.cos(coin.rotation * 2));
    canvas.scale(scaleX, 1.0);

    // Corpo da moeda
    final coinPaint = Paint()
      ..color = coin.color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, coin.size / 2, coinPaint);

    // Borda da moeda
    final borderPaint = Paint()
      ..color = coin.color.withRed((coin.color.r * 0.8).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = coin.size * 0.05;

    canvas.drawCircle(Offset.zero, coin.size / 2, borderPaint);

    // Detalhe interior - cifrão ou símbolo
    final textPainter = TextPainter(
      text: TextSpan(
        text: '\$',
        style: TextStyle(
          color: coin.color.withRed((coin.color.r * 0.7).toInt()),
          fontSize: coin.size * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    // Reflexo
    final highlightPaint = Paint()
      ..color = Colors.white.withAlpha((0.3 * 255).toInt())
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(-coin.size * 0.15, -coin.size * 0.15),
      coin.size * 0.12,
      highlightPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoinsPainter oldDelegate) => true;
}

// Extensão para converter radiano para grau
extension NumExtension on num {
  double get toRad => this * math.pi / 180.0;
  double get toDeg => this * 180.0 / math.pi;
}

// Pintor para desenhar confetes animados
class _ConfettiPainter extends CustomPainter {
  final List<Color> colors;
  final int particleCount;
  final List<_ConfettiParticle> particles = [];
  final math.Random random = math.Random();

  _ConfettiPainter({
    required this.colors,
    this.particleCount = 30,
  }) {
    _initializeParticles();
  }

  void _initializeParticles() {
    if (particles.isEmpty) {
      for (int i = 0; i < particleCount; i++) {
        particles.add(_ConfettiParticle(
          color: colors[random.nextInt(colors.length)],
          size: 5 + random.nextDouble() * 10,
          position: Offset(-100 + random.nextDouble() * 500,
              400 + random.nextDouble() * 100),
          velocity: Offset(
              (random.nextDouble() - 0.5) * 5, -(2 + random.nextDouble() * 4)),
          rotationSpeed: (random.nextDouble() - 0.5) * 0.1,
        ));
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final now = DateTime.now().millisecondsSinceEpoch / 1000;

    for (final particle in particles) {
      // Atualizar posição com base no tempo
      final x = particle.position.dx + particle.velocity.dx * 2;
      final y = particle.position.dy +
          particle.velocity.dy * 2 +
          now * 0.2; // Gravidade

      particle.position = Offset(x, y % (size.height + 50) - 50);
      particle.rotation += particle.rotationSpeed;

      // Desenhar partícula
      paint.color = particle.color;
      canvas.save();
      canvas.translate(particle.position.dx, particle.position.dy);
      canvas.rotate(particle.rotation);

      // Forma da partícula (retângulo ou círculo)
      if (random.nextBool()) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ConfettiParticle {
  Offset position;
  Offset velocity;
  double rotation;
  final double rotationSpeed;
  final double size;
  final Color color;

  _ConfettiParticle({
    required this.position,
    required this.velocity,
    this.rotation = 0.0,
    required this.rotationSpeed,
    required this.size,
    required this.color,
  });
}
