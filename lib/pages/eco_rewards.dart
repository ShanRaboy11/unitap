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
        duration: Duration(milliseconds: 3000 + math.Random().nextInt(3000)),
      )..repeat(reverse: true);
      return _FloatingLeaf(
        left: math.Random().nextDouble(),
        top: math.Random().nextDouble(),
        rotation: math.Random().nextDouble() * 2 * math.pi,
        size: 20 + math.Random().nextDouble() * 15,
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 24),
                  _buildStatsRow(isDark),
                  const SizedBox(height: 24),
                  _buildImpactDashboard(isDark),
                  const SizedBox(height: 24),
                  _buildPackagesList(isDark),
                ],
              ),
            ),
          ),
          if (selectedIndex != null && !showSuccess)
            Positioned(
              bottom: 30,
              left: 24,
              right: 24,
              child: _PrimaryButton(
                text:
                    'Plant ${treePackages[selectedIndex!].trees} Tree${treePackages[selectedIndex!].trees > 1 ? 's' : ''}',
                icon: Icons.eco_rounded,
                onTap: _handlePlantTrees,
                isEnabled:
                    widget.user.ecoPoints >=
                    treePackages[selectedIndex!].points,
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
                fontSize: 18,
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

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _GradientCard(
            colors: const [Color(0xFF059669), Color(0xFF0D9488)],
            icon: Icons.auto_awesome_rounded,
            label: 'Available Points',
            value: widget.user.ecoPoints.toString(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _GradientCard(
            colors: const [Color(0xFF16A34A), Color(0xFF059669)],
            icon: Icons.forest_rounded,
            label: 'Trees Planted',
            value: widget.user.treesPlanted.toString(),
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
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Changed layout logic to match image exactly (2x2 grid)
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _ImpactItem(
                      label: 'CO2 Offset',
                      value: '${(widget.user.treesPlanted * 20)}kg/year',
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _ImpactItem(
                      label: 'Oxygen Produced',
                      value: '${(widget.user.treesPlanted * 118)}kg/year',
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _ImpactItem(
                      label: 'Eco Rank',
                      value:
                          'Level ${((widget.user.treesPlanted / 5).floor() + 1)}',
                      isDark: isDark,
                      highlight: true,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _ImpactItem(
                      label: 'Total Impact',
                      value: '${widget.user.treesPlanted * 3} plants',
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesList(bool isDark) {
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
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(treePackages.length, (index) {
          final pkg = treePackages[index];
          final affordable = widget.user.ecoPoints >= pkg.points;
          final isSelected = selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(
              bottom: 10,
            ), // Reduced gap from 16 to 10
            child: GestureDetector(
              onTap: () => setState(() => selectedIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: isSelected
                      ? Border.all(color: Colors.green, width: 2)
                      : Border.all(color: Colors.transparent, width: 2),
                ),
                child: _GlassContainer(
                  isDark: isDark,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: affordable
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.forest_rounded,
                                  color: affordable
                                      ? Colors.green
                                      : Colors.grey,
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
                                      fontSize: 16,
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
                                  fontSize: 14,
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
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Selected',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
        }),
      ],
    );
  }

  Widget _buildSuccessOverlay(bool isDark) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.forest_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Trees Planted!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thank you for making the world greener.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.green.shade100,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Helper Widgets ---

// 1. Fixed Stats Card (Full Box BG)
class _GradientCard extends StatelessWidget {
  final List<Color> colors;
  final IconData icon;
  final String label;
  final String value;

  const _GradientCard({
    required this.colors,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Allow the container to define height based on padding, but ensure width fills parent
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge, // Hide overflow of decorative circles
      child: Stack(
        children: [
          // Single decorative circle (top-right) with clipped overflow
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Foreground padded content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 24),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.green.shade100,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Fixed Impact Item (Matches image style)
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0A1F2F).withValues(alpha: 0.6) // Darker card bg
            : Colors.green.shade50.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.teal.withValues(alpha: 0.2)
              : Colors.green.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Left aligned
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight
                  ? Colors.greenAccent
                  : (isDark ? Colors.tealAccent : Colors.teal),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: highlight
                  ? Colors.green
                  : (isDark ? Colors.white : Colors.blueGrey.shade900),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.visible, // Allow text to show fully
          ),
        ],
      ),
    );
  }
}

// Standard Glass Container
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  const _GlassContainer({
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(24),
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
            border: Border.all(
              color: isDark
                  ? Colors.teal.withValues(alpha: 0.3)
                  : Colors.green.withValues(alpha: 0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Button Component
class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isEnabled;

  const _PrimaryButton({
    required this.text,
    this.icon,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00DC82), Color(0xFF14B8A6)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (isEnabled)
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
      ),
    );
  }
}

// Models
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
  final double left, top, rotation, size;
  final AnimationController controller;
  _FloatingLeaf({
    required this.left,
    required this.top,
    required this.rotation,
    required this.size,
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
              final val = leaf.controller.value;
              final dy = math.sin(val * math.pi * 2) * 20;
              final dx = math.cos(val * math.pi * 2) * 10;
              return Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: leaf.rotation + (val * 0.5),
                  child: Icon(
                    Icons.eco_rounded,
                    color: isDark
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.25),
                    size: leaf.size,
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
