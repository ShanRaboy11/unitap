import 'dart:ui';
import 'package:flutter/material.dart';

class NetworkSecurity extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onBack;
  const NetworkSecurity({
    super.key,
    required this.isDarkMode,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    // Matching the gradient from previous screens
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

    final mockNetworkStats = const _Stats(
      totalTransactions: 1247,
      averageSpeed: '2.3s',
      networkStatus: 'Optimal',
      uptime: '99.9%',
      nodesActive: 847,
      lastBlock: '18,234,567',
    );

    final recentBlocks = const [
      _BlockInfo(
        block: 18234567,
        txns: 12,
        time: 'Just now',
        hash: '0x9f8a7b6c',
      ),
      _BlockInfo(
        block: 18234566,
        txns: 8,
        time: '3 mins ago',
        hash: '0x1a2b3c4d',
      ),
      _BlockInfo(
        block: 18234565,
        txns: 15,
        time: '6 mins ago',
        hash: '0xa1b2c3d4',
      ),
      _BlockInfo(
        block: 18234564,
        txns: 10,
        time: '9 mins ago',
        hash: '0x5e6f7a8b',
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: bgGradient)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
              child: Column(
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 16),
                  _buildStatusCard(isDark, mockNetworkStats),
                  const SizedBox(height: 16),
                  _buildNetworkStats(isDark, mockNetworkStats),
                  const SizedBox(height: 16),
                  _buildSecurityFeatures(isDark),
                  const SizedBox(height: 16),
                  _buildRecentBlocks(isDark, recentBlocks),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
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
              color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Security',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.blueGrey.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Blockchain Technology',
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

  Widget _buildStatusCard(bool isDark, _Stats stats) {
    return _GradientCard(
      colors: const [Color(0xFF7C3AED), Color(0xFF4338CA)], // Purple Gradient
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Icon + Text
              Row(
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: Colors.purple.shade100,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Network Status',
                    style: TextStyle(
                      color: Color(0xFFE9D5FF),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Right: Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Optimal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Main Title
          const Text(
            'UniTap Blockchain',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 24),

          // Bottom Stats Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Network Uptime',
                        style: TextStyle(
                          color: Color(0xFFD8B4FE),
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '99.9%',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Active Nodes',
                        style: TextStyle(
                          color: Color(0xFFD8B4FE),
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '847',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStats(bool isDark, _Stats stats) {
    return _GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Network Statistics',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.blueGrey.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 1
          Row(
            children: [
              Expanded(
                child: _NetworkStatCard(
                  isDark: isDark,
                  icon: Icons.storage_rounded,
                  label: 'Total\nTransactions',
                  value: _comma(stats.totalTransactions),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NetworkStatCard(
                  isDark: isDark,
                  icon: Icons.flash_on_rounded,
                  label: 'Avg Speed',
                  value: stats.averageSpeed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2
          Row(
            children: [
              Expanded(
                child: _NetworkStatCard(
                  isDark: isDark,
                  icon: Icons.trending_up_rounded,
                  label: 'Network\nUptime',
                  value: stats.uptime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NetworkStatCard(
                  isDark: isDark,
                  icon: Icons.lock_outline_rounded,
                  label: 'Active Nodes',
                  value: stats.nodesActive.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeatures(bool isDark) {
    return _GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_rounded,
                color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Security Features',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.blueGrey.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FeatureItem(
            isDark: isDark,
            icon: Icons.lock_rounded,
            title: 'End-to-End Encryption',
            subtitle:
                'All transactions are encrypted using military-grade AES-256 encryption',
          ),
          _FeatureItem(
            isDark: isDark,
            icon: Icons.history_edu_rounded,
            title: 'Immutable Ledger',
            subtitle:
                'Transaction history cannot be altered or deleted once recorded on the blockchain',
          ),
          _FeatureItem(
            isDark: isDark,
            icon: Icons.verified_user_rounded,
            title: 'Distributed Verification',
            subtitle:
                'Multiple nodes verify each transaction ensuring maximum security and reliability',
          ),
          _FeatureItem(
            isDark: isDark,
            icon: Icons.remove_red_eye_rounded,
            title: 'Real-Time Monitoring',
            subtitle:
                '24/7 network monitoring detects and prevents suspicious activities instantly',
          ),
          _FeatureItem(
            isDark: isDark,
            icon: Icons.vpn_key_rounded,
            title: 'Multi-Signature Authorization',
            subtitle:
                'High-value transactions require multiple confirmations for added security',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBlocks(bool isDark, List<_BlockInfo> blocks) {
    return _GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage_rounded,
                color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Blocks',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.blueGrey.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...blocks.asMap().entries.map((e) {
            final b = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Block #${_comma(b.block)}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : Colors.blueGrey.shade900,
                        ),
                      ),
                      Text(
                        b.time,
                        style: TextStyle(
                          color: isDark
                              ? Colors.teal.shade500
                              : Colors.teal.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('txns', style: TextStyle(color: Colors.green)),
                      Text(
                        '${b.txns} • ${b.hash}...',
                        style: TextStyle(
                          color: isDark
                              ? Colors.teal.shade500
                              : Colors.teal.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _comma(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      buf.write(s[i]);
      final pos = i + 1;
      if (idx > 1 && (s.length - pos) % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }
}

// --- UPDATED GRADIENT CARD (Smaller Circles) ---
class _GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final double borderRadius;
  const _GradientCard({
    required this.colors,
    required this.child,
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // 1. Top-Right Circle (Reduced Size)
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 240, // Reduced from 300
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // 2. Bottom-Left Circle (Reduced Size)
              Positioned(
                bottom: -40,
                left: -40,
                child: Container(
                  width: 120, // Reduced from 150
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // 3. Content
              Padding(padding: const EdgeInsets.all(24), child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkStatCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;

  const _NetworkStatCard({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0A1F2F).withValues(alpha: 0.6)
            : Colors.green.shade50.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.teal.withValues(alpha: 0.2)
              : Colors.green.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isDark ? Colors.tealAccent : Colors.teal,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.tealAccent : Colors.teal.shade700,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.blueGrey.shade900,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureItem({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.teal.withValues(alpha: 0.2)
                  : Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.tealAccent : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.blueGrey.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.teal.shade300 : Colors.teal.shade700,
                    fontSize: 13,
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

class _Stats {
  final int totalTransactions;
  final String averageSpeed;
  final String networkStatus;
  final String uptime;
  final int nodesActive;
  final String lastBlock;
  const _Stats({
    required this.totalTransactions,
    required this.averageSpeed,
    required this.networkStatus,
    required this.uptime,
    required this.nodesActive,
    required this.lastBlock,
  });
}

class _BlockInfo {
  final int block;
  final int txns;
  final String time;
  final String hash;
  const _BlockInfo({
    required this.block,
    required this.txns,
    required this.time,
    required this.hash,
  });
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _GlassContainer({required this.child, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F2F3F).withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
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
