import 'dart:ui';
import 'package:flutter/material.dart';

class CustomNavbar extends StatelessWidget {
  final String currentScreen;
  final Function(String) onNavigate;
  final bool isDarkMode;

  const CustomNavbar({
    super.key,
    required this.currentScreen,
    required this.onNavigate,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'id': 'dashboard', 'icon': Icons.home_rounded, 'label': 'Home'},
      {
        'id': 'transaction',
        'icon': Icons.arrow_outward_rounded,
        'label': 'Pay',
      },
      {'id': 'eco', 'icon': Icons.eco_rounded, 'label': 'Eco'},
      {'id': 'network', 'icon': Icons.shield_rounded, 'label': 'Network'},
      {'id': 'profile', 'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    final bgColor = isDarkMode
        ? const Color(0xFF0A2F2F).withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.95);

    final borderColor = isDarkMode
        ? Colors.teal.withValues(alpha: 0.2)
        : Colors.green.withValues(alpha: 0.2);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: navItems.map((item) {
                    final id = item['id'] as String;
                    final isActive = currentScreen == id;
                    final icon = item['icon'] as IconData;
                    final label = item['label'] as String;

                    final activeColor = isDarkMode
                        ? Colors.white
                        : Colors.teal.shade700;
                    final inactiveColor = isDarkMode
                        ? Colors.teal.shade400.withValues(alpha: 0.6)
                        : Colors.teal.shade600.withValues(alpha: 0.6);

                    return GestureDetector(
                      onTap: () => onNavigate(id),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Active Indicator (Subtle background glow or gradient text logic)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? (isDarkMode
                                          ? Colors.teal.withValues(alpha: 0.2)
                                          : Colors.green.withValues(alpha: 0.1))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icon,
                                color: isActive
                                    ? (isDarkMode
                                          ? Colors.tealAccent
                                          : Colors.green)
                                    : inactiveColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: TextStyle(
                                color: isActive ? activeColor : inactiveColor,
                                fontSize: 10,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
