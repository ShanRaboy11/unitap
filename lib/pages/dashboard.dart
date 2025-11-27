import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:unitap/models.dart';

class Dashboard extends StatefulWidget {
  final User user;
  final List<Transaction> recentTransactions;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;
  final Set<String> hiddenBalances;
  final Function(String) onToggleBalance;

  const Dashboard({
    super.key,
    required this.user,
    required this.recentTransactions,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
    required this.hiddenBalances,
    required this.onToggleBalance,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
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
          Positioned.fill(child: StarField(isDarkMode: isDark)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _entranceController,
                    child: _buildHeader(context),
                  ),
                  const SizedBox(height: 24),
                  SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entranceController,
                            curve: const Interval(
                              0.0,
                              0.6,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                        ),
                    child: FadeTransition(
                      opacity: _entranceController,
                      child: _buildBalanceCard(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entranceController,
                            curve: const Interval(
                              0.1,
                              0.7,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                        ),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _entranceController,
                        curve: const Interval(0.2, 1.0),
                      ),
                      child: _buildQuickActions(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.16),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entranceController,
                            curve: const Interval(
                              0.2,
                              0.8,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                        ),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _entranceController,
                        curve: const Interval(0.4, 1.0),
                      ),
                      child: _buildRecentActivity(context),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = widget.isDarkMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00DC82), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00DC82).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: isDark ? Colors.teal.shade200 : Colors.teal.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.user.name,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.blueGrey.shade900,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _SquareIconButton(
              icon: isDark
                  ? Icons.wb_sunny_rounded
                  : Icons.nightlight_round_rounded,
              color: isDark ? Colors.amber : Colors.indigo,
              isDark: isDark,
              onTap: widget.onToggleTheme,
            ),
            const SizedBox(width: 8),
            _SquareIconButton(
              icon: Icons.logout_rounded,
              color: Colors.redAccent,
              isDark: isDark,
              isDestructive: true,
              onTap: widget.onLogout,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00DC82), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00DC82).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Accounts',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.user.ecoPoints} pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...widget.user.bankAccounts.map(
                  (acc) => _buildAccountItem(
                    icon: Icons.account_balance_rounded,
                    name: acc.bankName,
                    number: acc.accountNumber,
                    balance: acc.balance,
                    id: acc.id,
                  ),
                ),
                ...widget.user.mobileWallets.map(
                  (wallet) => _buildAccountItem(
                    icon: Icons.smartphone_rounded,
                    name: wallet.provider,
                    number: wallet.phoneNumber,
                    balance: wallet.balance,
                    id: wallet.id,
                  ),
                ),
                ...widget.user.cards.map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.credit_card_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.bankName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                card.cardNumber,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.white24, height: 1),
                ),
                Row(
                  children: [
                    _buildPill(
                      Icons.eco_rounded,
                      '${widget.user.ecoPoints} points',
                    ),
                    const SizedBox(width: 12),
                    _buildPill(
                      Icons.forest_rounded,
                      '${widget.user.treesPlanted} trees',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem({
    required IconData icon,
    required String name,
    required String number,
    required double balance,
    required String id,
  }) {
    final isHidden = widget.hiddenBalances.contains(id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green.shade200, size: 18),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      number,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  isHidden ? '••••••' : '\$${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => widget.onToggleBalance(id),
                  child: Icon(
                    isHidden
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.green.shade200,
                    size: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade100, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _ActionCard(
          icon: Icons.arrow_outward_rounded,
          color: Colors.green,
          title: 'New Transaction',
          subtitle: 'Transfer, Deposit',
          isDark: widget.isDarkMode,
          onTap: () {},
        ),
        _ActionCard(
          icon: Icons.energy_savings_leaf_rounded,
          color: Colors.green,
          title: 'Eco Rewards',
          subtitle: 'Plant Trees',
          isDark: widget.isDarkMode,
          onTap: () {},
        ),
        _ActionCard(
          icon: Icons.security_rounded,
          color: Colors.purple,
          title: 'Network Security',
          subtitle: 'Blockchain Info',
          isDark: widget.isDarkMode,
          onTap: () {},
        ),
        _ActionCard(
          icon: Icons.history_rounded,
          color: Colors.blue,
          title: 'History',
          subtitle: 'All Transactions',
          isDark: widget.isDarkMode,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final isDark = widget.isDarkMode;
    return _GlassContainer(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.history_edu_rounded,
                color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.blueGrey.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.recentTransactions.map(
            (txn) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0A1F2F).withValues(alpha: 0.5)
                      : Colors.green.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.teal.withValues(alpha: 0.3)
                        : Colors.green.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                (txn.type == 'deposit'
                                        ? Colors.green
                                        : txn.type == 'withdraw'
                                        ? Colors.red
                                        : Colors.blue)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            txn.type == 'deposit'
                                ? Icons.arrow_downward_rounded
                                : txn.type == 'withdraw'
                                ? Icons.arrow_upward_rounded
                                : Icons.compare_arrows_rounded,
                            color: txn.type == 'deposit'
                                ? Colors.green
                                : txn.type == 'withdraw'
                                ? Colors.red
                                : Colors.blue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txn.type == 'deposit'
                                  ? 'Deposit'
                                  : txn.type == 'withdraw'
                                  ? 'Withdrawal'
                                  : 'Transfer',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : Colors.blueGrey.shade900,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              txn.recipient != null
                                  ? 'To ${txn.recipient}'
                                  : txn.paymentMethod,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.teal.shade200
                                    : Colors.teal.shade700,
                                fontSize: 11,
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
                          '\$${txn.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.blueGrey.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          txn.status.toUpperCase(),
                          style: TextStyle(
                            color: txn.status == 'completed'
                                ? Colors.green
                                : Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;
  const _SquareIconButton({
    required this.icon,
    required this.color,
    required this.isDark,
    this.isDestructive = false,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDestructive
              ? (isDark
                    ? Colors.red.withValues(alpha: 0.2)
                    : Colors.red.shade50)
              : (isDark ? const Color(0xFF0F2F3F) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? (isDark
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.red.shade200)
                : (isDark
                      ? Colors.teal.withValues(alpha: 0.3)
                      : Colors.green.shade200),
          ),
          boxShadow: isDestructive
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final MaterialColor color;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _GlassContainer(
        isDark: isDark,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color.shade400, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.blueGrey.shade900,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

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
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.teal.withValues(alpha: 0.3)
                  : Colors.green.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class StarField extends StatefulWidget {
  final bool isDarkMode;
  const StarField({super.key, required this.isDarkMode});
  @override
  State<StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<StarField> with TickerProviderStateMixin {
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
  final double left, top, size;
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
