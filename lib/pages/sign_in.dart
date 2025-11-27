import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class SignIn extends StatefulWidget {
  final VoidCallback onLogin;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const SignIn({
    super.key,
    required this.onLogin,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> with TickerProviderStateMixin {
  // Local State
  bool isSignUp = false;

  // Text Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // Animation Controllers
  late AnimationController _shapeController;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();

    // Background shapes rotation
    _shapeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Entrance fade/slide
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _shapeController.dispose();
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    // We use the passed isDarkMode widget parameter as the source of truth
    final isDark = widget.isDarkMode;
    final theme = Theme.of(context);

    // --- Dynamic Styles based on Mode --- //

    // Background Gradient
    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Deep Slate
              Color(0xFF082026), // Dark Teal
              Color(0xFF0F172A),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFECFDF5), // Light Mint
              Color(0xFFF0FDFA), // Light Teal
              Color(0xFFFFFFFF), // White
            ],
          );

    // Glass Card Color
    final glassColor = isDark
        ? const Color(0xFF11252E).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.85);

    // Border Color
    final borderColor = isDark
        ? Colors.teal.withValues(alpha: 0.3)
        : Colors.teal.withValues(alpha: 0.15);

    // Text Colors
    final mainTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.teal.shade200 : Colors.teal.shade700;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(decoration: BoxDecoration(gradient: bgGradient)),

          // 2. Animated Background Elements (Stars & Shapes)
          Positioned.fill(child: _StarField(isDarkMode: isDark)),

          // Top Left Rotating Diamond
          _AnimatedShape(
            controller: _shapeController,
            isDarkMode: isDark,
            top: 80,
            left: -40,
            size: 160,
            angleMultiplier: 1,
            color: Colors.teal,
            shape: BoxShape.rectangle,
          ),

          // Bottom Right Rotating Square
          _AnimatedShape(
            controller: _shapeController,
            isDarkMode: isDark,
            bottom: 100,
            right: -20,
            size: 100,
            angleMultiplier: -0.5,
            color: Colors.green, // Emerald
            shape: BoxShape.rectangle,
          ),

          // 3. Theme Toggle (Top Right)
          // Logic: If isDark, show Sun (to switch to light). If Light, show Moon.
          Positioned(
            top: 50,
            right: 24,
            child: _ThemeToggleButton(
              isDarkMode: isDark,
              onToggle: widget.onToggleTheme,
            ),
          ),

          // 4. Main Content Area
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: FadeTransition(
                opacity: _entranceController,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _entranceController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // --- Logo Section ---
                        ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _entranceController,
                            curve: const Interval(
                              0.0,
                              0.8,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00DC82),
                                      Color(0xFF14B8A6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00DC82,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                // LOGO IMAGE HERE
                                child: Image.asset(
                                  'logo.png',
                                  fit: BoxFit.contain,
                                  // Remove 'color: Colors.white' if your logo is full color.
                                  // Keeping it here assuming you want a white silhouette logo like the icon.
                                  color: Colors.white,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.broken_image,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'UniTap',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: mainTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Unified in One Tap',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // --- Glass Card Form ---
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: glassColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.3 : 0.05,
                                    ),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Sign In / Sign Up Switcher
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildToggleBtn(
                                          'Sign In',
                                          !isSignUp,
                                          isDark,
                                        ),
                                        const SizedBox(width: 20),
                                        _buildToggleBtn(
                                          'Sign Up',
                                          isSignUp,
                                          isDark,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Input Fields
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    alignment: Alignment.topCenter,
                                    child: Column(
                                      children: [
                                        if (isSignUp) ...[
                                          _buildInputLabel('Full Name', isDark),
                                          _buildInput(
                                            _nameController,
                                            'Enter your name',
                                            isDark,
                                          ),
                                          const SizedBox(height: 16),
                                        ],

                                        _buildInputLabel('Email', isDark),
                                        _buildInput(
                                          _emailController,
                                          'Enter your email',
                                          isDark,
                                        ),
                                        const SizedBox(height: 16),

                                        _buildInputLabel('Password', isDark),
                                        _buildInput(
                                          _passwordController,
                                          'Enter your password',
                                          isDark,
                                          isPassword: true,
                                        ),
                                        const SizedBox(height: 16),

                                        if (isSignUp) ...[
                                          _buildInputLabel(
                                            'Confirm Password',
                                            isDark,
                                          ),
                                          _buildInput(
                                            _confirmPassController,
                                            'Confirm your password',
                                            isDark,
                                            isPassword: true,
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Gradient Action Button
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: _handleSubmit,
                                      child: Container(
                                        width: double.infinity,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF00DC82),
                                              Color(0xFF0F766E),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF00DC82,
                                              ).withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              isSignUp ? 'Sign Up' : 'Sign In',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  // Features List
                                  _FeatureRow(
                                    icon: Icons.eco_outlined,
                                    title: 'Earn Eco Points',
                                    subtitle:
                                        'Plant real trees with every transaction',
                                    isDark: isDark,
                                    color: const Color(0xFF00DC82),
                                  ),
                                  const SizedBox(height: 16),
                                  _FeatureRow(
                                    icon: Icons.shield_outlined,
                                    title: 'Blockchain Secured',
                                    subtitle:
                                        'Military-grade encryption technology',
                                    isDark: isDark,
                                    color: const Color(0xFF14B8A6),
                                  ),
                                  const SizedBox(height: 16),
                                  _FeatureRow(
                                    icon: Icons.auto_awesome_outlined,
                                    title: 'Unified Payments',
                                    subtitle: 'All transactions in one place',
                                    isDark: isDark,
                                    color: Colors.cyan,
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
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildToggleBtn(String text, bool isActive, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isSignUp = (text == 'Sign Up');
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF00DC82), Color(0xFF14B8A6)],
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF00DC82).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : (isDark ? Colors.teal.shade100 : Colors.teal.shade900),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String placeholder,
    bool isDark, {
    bool isPassword = false,
  }) {
    // Specific colors to match the design images exactly
    final borderColor = isDark ? Colors.teal.shade900 : Colors.teal.shade100;
    final hintColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final fillColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.5)
        : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: hintColor, fontSize: 14),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.teal.withValues(alpha: 0.3)
                : Colors.teal.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00DC82), width: 1.5),
        ),
      ),
    );
  }
}

// --- Internal Components ---

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color color;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.blueGrey.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.teal.shade400 : Colors.teal.shade700,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedShape extends StatelessWidget {
  final AnimationController controller;
  final bool isDarkMode;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final double angleMultiplier;
  final MaterialColor color;
  final BoxShape shape;

  const _AnimatedShape({
    required this.controller,
    required this.isDarkMode,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.angleMultiplier,
    required this.color,
    required this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: controller.value * 2 * math.pi * angleMultiplier,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: shape,
                border: Border.all(
                  color: isDarkMode
                      ? color.shade200.withValues(alpha: 0.05)
                      : color.shade400.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggle;

  const _ThemeToggleButton({required this.isDarkMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.teal.withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              RotationTransition(turns: anim, child: child),
          child: isDarkMode
              ? const Icon(
                  Icons.wb_sunny_rounded,
                  key: ValueKey('sun'),
                  color: Colors.amber,
                  size: 20,
                )
              : const Icon(
                  Icons.nightlight_round_outlined,
                  key: ValueKey('moon'),
                  color: Colors.indigo,
                  size: 20,
                ),
        ),
      ),
    );
  }
}

class _StarField extends StatefulWidget {
  final bool isDarkMode;
  const _StarField({required this.isDarkMode});

  @override
  State<_StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<_StarField> with TickerProviderStateMixin {
  final List<_Star> _stars = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 30; i++) {
      _stars.add(
        _Star(
          left: _rng.nextDouble(),
          top: _rng.nextDouble(),
          size: 2 + _rng.nextDouble() * 3,
          controller: AnimationController(
            vsync: this,
            duration: Duration(milliseconds: 1500 + _rng.nextInt(2000)),
          )..repeat(reverse: true),
          delay: Duration(milliseconds: _rng.nextInt(2000)),
        ),
      );
    }
    for (var star in _stars) {
      Future.delayed(star.delay, () {
        if (mounted) star.controller.forward();
      });
    }
  }

  @override
  void dispose() {
    for (var star in _stars) {
      star.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _stars.map((star) {
        return Positioned(
          left: star.left * MediaQuery.of(context).size.width,
          top: star.top * MediaQuery.of(context).size.height,
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.2,
              end: 0.7,
            ).animate(star.controller),
            child: Container(
              width: star.size,
              height: star.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.5)
                    : const Color(0xFF14B8A6).withValues(alpha: 0.4),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Star {
  final double left;
  final double top;
  final double size;
  final AnimationController controller;
  final Duration delay;
  _Star({
    required this.left,
    required this.top,
    required this.size,
    required this.controller,
    required this.delay,
  });
}
