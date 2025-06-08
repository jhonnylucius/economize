import 'package:economize/service/gamification/achievement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:economize/animations/celebration_animations.dart';
import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/model/gamification/achievement.dart';
import 'package:economize/theme/theme_manager.dart';
import 'dart:math' as math;
import 'package:logger/logger.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  // Controllers para animações
  late AnimationController _headerAnimationController;
  late AnimationController _confettiController;
  late AnimationController _floatingController;
  late AnimationController _murphyDanceController;

  // Animations
  late Animation<double> _headerRotation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _murphyDance;

  List<Achievement> _achievements = [];
  List<Achievement> _filteredAchievements = [];
  AchievementRarity? _selectedRarity;
  bool _showOnlyUnlocked = false;
  bool _isLoading = true;
  Map<String, int> _stats = {};

  // Easter egg do Murphy
  int _murphyClickCount = 0;
  bool _murphyModeActive = false;
  final List<String> _murphyQuotes = [
    "👻 Vou quebrar esse app!",
    "😈 Nunca vão me pegar!",
    "🤡 Bugs são arte!",
    "💀 Sou imortal!",
    "🥜 3 paçocas? Jamais!",
    "👻 Danço melhor que vocês!",
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAchievements();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _headerRotation = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(_headerAnimationController);
    _headerAnimationController.repeat();

    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _floatingAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
    _floatingController.repeat(reverse: true);

    _murphyDanceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _murphyDance = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(
          parent: _murphyDanceController, curve: Curves.elasticInOut),
    );
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);

    try {
      final achievements = await AchievementService.getAllAchievements();
      final stats = await AchievementService.getAchievementStats();

      setState(() {
        _achievements = achievements;
        _filteredAchievements = achievements;
        _stats = stats;
        _isLoading = false;
      });

      if (stats['unlocked']! > 0) {
        _confettiController.forward();
      }
    } catch (e) {
      Logger().e('❌ Erro ao carregar conquistas: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterAchievements() {
    setState(() {
      _filteredAchievements = _achievements.where((achievement) {
        if (_selectedRarity != null && achievement.rarity != _selectedRarity) {
          return false;
        }
        if (_showOnlyUnlocked && !achievement.isUnlocked) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  void _activateMurphyMode() {
    _murphyClickCount++;
    if (_murphyClickCount == 3) {
      setState(() => _murphyModeActive = true);
      _murphyDanceController.repeat(reverse: true);
      HapticFeedback.heavyImpact();
      _showMurphyQuote();
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() => _murphyModeActive = false);
          _murphyDanceController.stop();
          _murphyClickCount = 0;
        }
      });
    }
  }

  void _showMurphyQuote() {
    final quote = _murphyQuotes[math.Random().nextInt(_murphyQuotes.length)];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(quote),
        backgroundColor: Colors.purple.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '💃 DANÇA!',
          textColor: Colors.white,
          onPressed: () {
            _murphyDanceController
                .forward()
                .then((_) => _murphyDanceController.reverse());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = ThemeManager();

    // ✅ CORES LIMPAS E MODERNAS
    final bool isDarkTheme = theme.brightness == Brightness.dark;
    final headerColor = isDarkTheme ? Colors.purple : theme.primaryColor;
    final headerTextColor = Colors.white;
    final backgroundColor = Colors.white;
    final surfaceColor = Colors.grey.shade50;
    final textColor = Colors.grey.shade800;
    final subtitleColor = Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,

      // 🎭 APP BAR LIMPO E ELEGANTE
      appBar: AppBar(
        elevation: 0,
        backgroundColor: headerColor,
        title: SlideAnimation.fromLeft(
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _headerRotation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _headerRotation.value,
                    child: Icon(
                      Icons.emoji_events,
                      color: headerTextColor,
                      size: 28,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _activateMurphyMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conquistas',
                      style: TextStyle(
                        color: headerTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_stats.isNotEmpty)
                      Text(
                        '${_stats['unlocked']}/${_stats['total']} desbloqueadas',
                        style: TextStyle(
                          color: headerTextColor.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (_murphyModeActive)
                AnimatedBuilder(
                  animation: _murphyDance,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_murphyDance.value, 0),
                      child: const Text('👻💃', style: TextStyle(fontSize: 20)),
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          SlideAnimation.fromRight(
            child: PopupMenuButton<String>(
              icon: Icon(Icons.filter_list, color: headerTextColor),
              onSelected: (value) {
                if (value == 'unlocked') {
                  setState(() {
                    _showOnlyUnlocked = !_showOnlyUnlocked;
                    _filterAchievements();
                  });
                } else if (value.startsWith('rarity_')) {
                  final rarityName = value.split('_')[1];
                  setState(() {
                    _selectedRarity = _selectedRarity?.toString() == rarityName
                        ? null
                        : AchievementRarity.values
                            .firstWhere((r) => r.toString() == rarityName);
                    _filterAchievements();
                  });
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'unlocked',
                  child: Row(
                    children: [
                      Icon(_showOnlyUnlocked
                          ? Icons.check_box
                          : Icons.check_box_outline_blank),
                      const SizedBox(width: 8),
                      const Text('Apenas desbloqueadas'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                ...AchievementRarity.values.map((rarity) => PopupMenuItem(
                      value: 'rarity_${rarity.toString()}',
                      child: Row(
                        children: [
                          Icon(_getAchievementIcon(rarity),
                              color: _getCleanRarityColor(rarity)),
                          const SizedBox(width: 8),
                          Text(_getRarityName(rarity)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          _isLoading
              ? _buildLoadingState()
              : _buildAchievementsList(textColor, subtitleColor, surfaceColor),

          // 🎊 Confetti sutil
          if (_stats['unlocked'] != null && _stats['unlocked']! > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: ConfettiAnimation(
                  particleCount: 30,
                  direction: ConfettiDirection.down,
                  colors: [Colors.amber, Colors.orange, headerColor],
                  animationController: _confettiController,
                  duration: const Duration(seconds: 3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando conquistas...'),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(
      Color textColor, Color subtitleColor, Color surfaceColor) {
    if (_filteredAchievements.isEmpty) {
      return _buildEmptyState(textColor, subtitleColor);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
            child: _buildStatsHeader(textColor, subtitleColor, surfaceColor)),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7, // ✅ AJUSTADO PARA NÃO DAR OVERFLOW
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final achievement = _filteredAchievements[index];
                return _buildCleanAchievementCard(
                    achievement, index, textColor, subtitleColor);
              },
              childCount: _filteredAchievements.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildMurphyEasterEgg()),
      ],
    );
  }

  // ✨ CARD LIMPO E MODERNO SEM OVERFLOW
  Widget _buildCleanAchievementCard(Achievement achievement, int index,
      Color textColor, Color subtitleColor) {
    final isUnlocked = achievement.isUnlocked;
    final rarityColor = _getCleanRarityColor(achievement.rarity);

    return SlideAnimation.fromBottom(
      delay: Duration(milliseconds: 50 * index),
      child: AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatingAnimation.value),
            child: GestureDetector(
              onTap: () => _showAchievementDetails(achievement),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isUnlocked
                          ? rarityColor.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isUnlocked
                        ? rarityColor.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12), // ✅ REDUZIDO
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // ✅ IMPORTANTE!
                    children: [
                      // 🏆 Ícone da conquista
                      Container(
                        width: 50, // ✅ MENOR
                        height: 50,
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? rarityColor.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isUnlocked ? rarityColor : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isUnlocked ? achievement.rarityIcon : Icons.lock,
                          color: isUnlocked ? rarityColor : Colors.grey,
                          size: 24, // ✅ MENOR
                        ),
                      ),

                      const SizedBox(height: 8), // ✅ REDUZIDO

                      // 🏷️ Título
                      Text(
                        isUnlocked ? achievement.title : '???',
                        style: TextStyle(
                          fontSize: 12, // ✅ MENOR
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? textColor : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4), // ✅ REDUZIDO

                      // 📝 Descrição
                      Expanded(
                        // ✅ USAR EXPANDED
                        child: Text(
                          isUnlocked
                              ? achievement.description
                              : achievement.secretDescription,
                          style: TextStyle(
                            fontSize: 10, // ✅ MENOR
                            color: subtitleColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 🎖️ Badge de raridade
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2), // ✅ MENOR
                        decoration: BoxDecoration(
                          color: rarityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: rarityColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(achievement.rarityIcon,
                                size: 10, color: rarityColor), // ✅ MENOR
                            const SizedBox(width: 2),
                            Text(
                              _getRarityName(achievement.rarity),
                              style: TextStyle(
                                fontSize: 8, // ✅ MENOR
                                fontWeight: FontWeight.bold,
                                color: rarityColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 📊 Progresso (se não desbloqueada)
                      if (!isUnlocked && achievement.progress > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            children: [
                              Text(
                                '${(achievement.progress * 100).toInt()}%',
                                style: TextStyle(
                                    fontSize: 8,
                                    color: subtitleColor), // ✅ MENOR
                              ),
                              const SizedBox(height: 2),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: achievement.progress,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      rarityColor),
                                  minHeight: 3, // ✅ MENOR
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(
      Color textColor, Color subtitleColor, Color surfaceColor) {
    final unlockedCount = _stats['unlocked'] ?? 0;
    final totalCount = _stats['total'] ?? 0;
    final percentage = _stats['percentage'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCleanStatItem(
                  title: 'Desbloqueadas',
                  value: unlockedCount.toString(),
                  icon: Icons.emoji_events,
                  color: Colors.amber.shade600,
                ),
                _buildCleanStatItem(
                  title: 'Total',
                  value: totalCount.toString(),
                  icon: Icons.stars,
                  color: Colors.blue.shade600,
                ),
                _buildCleanStatItem(
                  title: 'Progresso',
                  value: '$percentage%',
                  icon: Icons.trending_up,
                  color: Colors.green.shade600,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barra de progresso limpa
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progresso Geral',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalCount > 0 ? unlockedCount / totalCount : 0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.amber.shade600),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textColor, Color subtitleColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Nenhuma conquista encontrada',
            style: TextStyle(fontSize: 18, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajuste os filtros ou comece a usar o app!',
            style: TextStyle(fontSize: 14, color: subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMurphyEasterEgg() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: GestureDetector(
        onTap: _activateMurphyMode,
        child: AnimatedBuilder(
          animation: _murphyDance,
          builder: (context, child) {
            return Transform.rotate(
              angle: _murphyModeActive ? _murphyDance.value * 0.1 : 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      _murphyModeActive ? '👻💃🕺👻' : '👻',
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _murphyModeActive
                          ? 'MURPHY ESTÁ DANÇANDO!'
                          : 'Toque aqui 3 vezes...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_murphyClickCount > 0 && _murphyClickCount < 3)
                      Text(
                        'Faltam ${3 - _murphyClickCount} toques',
                        style: TextStyle(
                            fontSize: 10, color: Colors.purple.shade400),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) =>
          _CleanAchievementDetailDialog(achievement: achievement),
    );
  }

  // ✨ CORES LIMPAS PARA RARIDADES
  Color _getCleanRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.bronze:
        return Colors.brown.shade600;
      case AchievementRarity.silver:
        return Colors.grey.shade600;
      case AchievementRarity.gold:
        return Colors.amber.shade600;
      case AchievementRarity.diamond:
        return Colors.cyan.shade600;
      case AchievementRarity.legendary:
        return Colors.purple.shade600;
    }
  }

  String _getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.bronze:
        return 'Bronze';
      case AchievementRarity.silver:
        return 'Prata';
      case AchievementRarity.gold:
        return 'Ouro';
      case AchievementRarity.diamond:
        return 'Diamante';
      case AchievementRarity.legendary:
        return 'Lendária';
    }
  }

  IconData _getAchievementIcon(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.bronze:
        return Icons.emoji_events;
      case AchievementRarity.silver:
        return Icons.military_tech;
      case AchievementRarity.gold:
        return Icons.stars;
      case AchievementRarity.diamond:
        return Icons.diamond;
      case AchievementRarity.legendary:
        return Icons.auto_awesome;
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _confettiController.dispose();
    _floatingController.dispose();
    _murphyDanceController.dispose();
    super.dispose();
  }
}

// 🎭 DIÁLOGO LIMPO E MODERNO
class _CleanAchievementDetailDialog extends StatefulWidget {
  final Achievement achievement;

  const _CleanAchievementDetailDialog({required this.achievement});

  @override
  State<_CleanAchievementDetailDialog> createState() =>
      _CleanAchievementDetailDialogState();
}

class _CleanAchievementDetailDialogState
    extends State<_CleanAchievementDetailDialog> with TickerProviderStateMixin {
  late AnimationController _dialogController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dialogController, curve: Curves.easeOut),
    );
    _dialogController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final isUnlocked = achievement.isUnlocked;
    final rarityColor = _getCleanRarityColor(achievement.rarity);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header com ícone
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: rarityColor, width: 3),
                    ),
                    child: Icon(
                      isUnlocked ? achievement.rarityIcon : Icons.lock,
                      size: 40,
                      color: isUnlocked ? rarityColor : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Título
                  Text(
                    isUnlocked
                        ? achievement.title
                        : '??? Conquista Secreta ???',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: rarityColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Data de desbloqueio
                  if (isUnlocked && achievement.unlockedAt != null)
                    Text(
                      'Desbloqueada em ${_formatDate(achievement.unlockedAt!)}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),

                  const SizedBox(height: 16),

                  // Descrição
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUnlocked
                          ? achievement.description
                          : achievement.secretDescription,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Raridade
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(achievement.rarityIcon, color: rarityColor),
                        const SizedBox(width: 8),
                        Text(
                          _getRarityName(achievement.rarity),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: rarityColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fechar'),
                        ),
                      ),
                      if (isUnlocked)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _shareAchievement,
                            icon: const Icon(Icons.share),
                            label: const Text('Compartilhar'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: rarityColor),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _shareAchievement() {
    final achievementText = '''
🏆 Nova Conquista Desbloqueada!

${widget.achievement.title}
${widget.achievement.description}

Raridade: ${_getRarityName(widget.achievement.rarity)}
Desbloqueada no app Economize! 💰

#Economize #Conquistas #${_getRarityName(widget.achievement.rarity)}
''';

    Clipboard.setData(ClipboardData(text: achievementText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🏆 Conquista "${widget.achievement.title}" copiada!'),
        backgroundColor: _getCleanRarityColor(widget.achievement.rarity),
      ),
    );
  }

  Color _getCleanRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.bronze:
        return Colors.brown.shade600;
      case AchievementRarity.silver:
        return Colors.grey.shade600;
      case AchievementRarity.gold:
        return Colors.amber.shade600;
      case AchievementRarity.diamond:
        return Colors.cyan.shade600;
      case AchievementRarity.legendary:
        return Colors.purple.shade600;
    }
  }

  String _getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.bronze:
        return 'Bronze';
      case AchievementRarity.silver:
        return 'Prata';
      case AchievementRarity.gold:
        return 'Ouro';
      case AchievementRarity.diamond:
        return 'Diamante';
      case AchievementRarity.legendary:
        return 'Lendária';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _dialogController.dispose();
    super.dispose();
  }
}
