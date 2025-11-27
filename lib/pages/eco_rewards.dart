import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:unitap/models.dart';

class EcoRewards extends StatefulWidget {
  final User user;
  final bool isDarkMode;
  final VoidCallback onBack;
  final void Function(int trees, int pointsUsed) onPlantTrees;
  const EcoRewards({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.onBack,
    required this.onPlantTrees,
  });

  @override
  State<EcoRewards> createState() => _EcoRewardsState();
}

class _EcoRewardsState extends State<EcoRewards> with TickerProviderStateMixin {
  int? selectedIndex;
  bool showSuccess = false;
  late List<_FloatingLeaf> _leaves;

  final List<_TreePackage> treePackages = const [
    _TreePackage(trees: 1, points: 100, impact: '20kg CO₂ offset/year'),
    _TreePackage(trees: 5, points: 450, impact: '100kg CO₂ offset/year'),
    _TreePackage(trees: 10, points: 850, impact: '200kg CO₂ offset/year'),
    _TreePackage(trees: 25, points: 2000, impact: '500kg CO₂ offset/year'),
  ];

  @override
  void initState() {
    super.initState();
    _leaves = List.generate(20, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2500 + math.Random().nextInt(2000)),
      )..repeat(reverse: true);
      return _FloatingLeaf(
        left: math.Random().nextDouble(),
        top: math.Random().nextDouble(),
        controller: controller,
      );
    });
  }

  @override
  void dispose() {
    for (var leaf in _leaves) {
      leaf.controller.dispose();
    }
    super.dispose();
  }

  void _handlePlantTrees() {
    if (selectedIndex == null) return;
    final pkg = treePackages[selectedIndex!];
    if (widget.user.ecoPoints >= pkg.points) {
      widget.onPlantTrees(pkg.trees, pkg.points);
      setState(() => showSuccess = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          showSuccess = false;
          selectedIndex = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF082026), Color(0xFF0F172A)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFECFDF5), Color(0xFFF0FDFA), Colors.white],
          );

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: bgGradient)),
          Positioned.fill(
            child: _LeafField(leaves: _leaves, isDark: isDark),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 24),
                  _buildStats(isDark),
                  const SizedBox(height: 24),
                  _buildImpactDashboard(isDark),
                  const SizedBox(height: 24),
                  _buildPackages(isDark),
                  const SizedBox(height: 24),
                  if (selectedIndex != null &&
                      widget.user.ecoPoints >=
                          treePackages[selectedIndex!].points)
                    _PrimaryButton(
                      text:
                          'Plant ${treePackages[selectedIndex!].trees} Tree${treePackages[selectedIndex!].trees > 1 ? 's' : ''}',
                      icon: Icons.eco_rounded,
                      onTap: _handlePlantTrees,
                    ),
                ],
              ),
            ),
          ),
          if (showSuccess) _buildSuccessOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onBack,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2F3F) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.teal.withValues(alpha: 0.3)
                    : Colors.green.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.teal.shade300 : Colors.teal.shade600,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eco Rewards',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.blueGrey.shade900,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              'Plant trees & save the planet',
              style: TextStyle(
                color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _GradientCard(
            colors: const [Color(0xFF059669), Color(0xFF0D9488)],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.green.shade100,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'Available Points',
                  style: TextStyle(color: Colors.green.shade100, fontSize: 12),
                ),
                Text(
                  widget.user.ecoPoints.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _GradientCard(
            colors: const [Color(0xFF16A34A), Color(0xFF059669)],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.forest_rounded,
                  color: Colors.green.shade100,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'Trees Planted',
                  style: TextStyle(color: Colors.green.shade100, fontSize: 12),
                ),
                Text(
                  widget.user.treesPlanted.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImpactDashboard(bool isDark) {
    return _GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.public_rounded,
                color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Environmental Impact',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.blueGrey.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: [
              _ImpactItem(
                label: 'CO₂ Offset',
                value:
                    '${(widget.user.treesPlanted * 20).toStringAsFixed(0)}kg/year',
                isDark: isDark,
              ),
              _ImpactItem(
                label: 'Oxygen Produced',
                value:
                    '${(widget.user.treesPlanted * 118).toStringAsFixed(0)}kg/year',
                isDark: isDark,
              ),
              _ImpactItem(
                label: 'Eco Rank',
                value: 'Level ${((widget.user.treesPlanted / 5).floor() + 1)}',
                isDark: isDark,
                highlight: true,
              ),
              _ImpactItem(
                label: 'Total Impact',
                value: '${widget.user.treesPlanted * 3} plants',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackages(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_events_rounded,
              color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Plant Trees',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.blueGrey.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(treePackages.length, (index) {
          final pkg = treePackages[index];
          final affordable = widget.user.ecoPoints >= pkg.points;
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => setState(() => selectedIndex = index),
            child: _GlassContainer(
              isDark: isDark,
              padding: const EdgeInsets.all(20),
              borderHighlight: isSelected ? Colors.green : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: affordable
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.forest_rounded,
                              color: affordable ? Colors.green : Colors.grey,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pkg.trees} Tree${pkg.trees > 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.blueGrey.shade900,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                pkg.impact,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.teal.shade300
                                      : Colors.teal.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${pkg.points} pts',
                            style: TextStyle(
                              color: affordable
                                  ? Colors.green
                                  : Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!affordable)
                            const Text(
                              'Insufficient',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            color: isDark
                                ? Colors.teal.shade300
                                : Colors.teal.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Selected - Ready to plant',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.teal.shade300
                                  : Colors.teal.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSuccessOverlay(bool isDark) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: _GradientCard(
            colors: const [Color(0xFF059669), Color(0xFF0D9488)],
            padding: const EdgeInsets.all(32),
            borderRadius: 36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Icon(
                    Icons.forest_rounded,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Trees Planted! 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thank you for contributing to a greener planet!',
                  style: TextStyle(color: Colors.green.shade100, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TreePackage {
  final int trees;
  final int points;
  final String impact;
  const _TreePackage({
    required this.trees,
    required this.points,
    required this.impact,
  });
}

class _FloatingLeaf {
  final double left;
  final double top;
  final AnimationController controller;
  _FloatingLeaf({
    required this.left,
    required this.top,
    required this.controller,
  });
}

class _LeafField extends StatelessWidget {
  final List<_FloatingLeaf> leaves;
  final bool isDark;
  const _LeafField({required this.leaves, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: leaves.map((leaf) {
        return Positioned(
          left: leaf.left * MediaQuery.of(context).size.width,
          top: leaf.top * MediaQuery.of(context).size.height,
          child: AnimatedBuilder(
            animation: leaf.controller,
            builder: (context, child) {
              final value = leaf.controller.value; // 0..1
              final dy = (math.sin(value * math.pi * 2) * 15);
              final opacity = 0.3 + (math.sin(value * math.pi * 2) * 0.3 + 0.3);
              return Opacity(
                opacity: opacity.clamp(0.0, 0.6),
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Icon(
                    Icons.eco_rounded,
                    color: isDark
                        ? Colors.greenAccent.withValues(alpha: 0.3)
                        : Colors.greenAccent.withValues(alpha: 0.4),
                    size: 28,
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

class _GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  const _GradientCard({
    required this.colors,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 28,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: padding,
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;
  final Color? borderHighlight;
  const _GlassContainer({
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(24),
    this.borderHighlight,
  });
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F2F3F).withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  borderHighlight ??
                  (isDark
                      ? Colors.teal.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.2)),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ImpactItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;
  const _ImpactItem({
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0A1F2F).withValues(alpha: 0.5)
            : Colors.green.shade50.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.teal.withValues(alpha: 0.25)
              : Colors.green.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.teal.shade300 : Colors.teal.shade700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: highlight
                  ? Colors.green
                  : (isDark ? Colors.white : Colors.blueGrey.shade900),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  const _PrimaryButton({required this.text, this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00DC82), Color(0xFF14B8A6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00DC82).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
