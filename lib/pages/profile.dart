import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:unitap/models.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  final bool isDarkMode;
  final Set<String> hiddenBalances;
  final VoidCallback onBack;
  final void Function(String id) onToggleBalance;
  // Future enhancement: onEdit callbacks for accounts/cards/wallets.
  const ProfilePage({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.hiddenBalances,
    required this.onBack,
    required this.onToggleBalance,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _activeTab = 'info'; // info | banks | cards | wallets

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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 24),
                  _buildTabs(isDark),
                  const SizedBox(height: 16),
                  _buildContent(isDark),
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
          onTap: widget.onBack,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2F3F) : Colors.white,
              borderRadius: BorderRadius.circular(20),
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
        const SizedBox(width: 16),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF34D399), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.name,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.blueGrey.shade900,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.user.email,
                style: TextStyle(
                  color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(bool isDark) {
    final tabs = [
      ('info', 'Info'),
      ('banks', 'Banks (${widget.user.bankAccounts.length})'),
      ('cards', 'Cards (${widget.user.cards.length})'),
      ('wallets', 'Wallets (${widget.user.mobileWallets.length})'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final t in tabs) ...[
            GestureDetector(
              onTap: () => setState(() => _activeTab = t.$1),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: _activeTab == t.$1
                      ? const LinearGradient(
                          colors: [Color(0xFF34D399), Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _activeTab == t.$1
                      ? null
                      : (isDark ? const Color(0xFF0F2F3F) : Colors.white),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _activeTab == t.$1
                        ? Colors.transparent
                        : (isDark
                              ? Colors.teal.withValues(alpha: 0.3)
                              : Colors.green.withValues(alpha: 0.2)),
                  ),
                  boxShadow: _activeTab == t.$1
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF34D399,
                            ).withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  t.$2,
                  style: TextStyle(
                    color: _activeTab == t.$1
                        ? Colors.white
                        : (isDark
                              ? Colors.teal.shade300
                              : Colors.teal.shade600),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    switch (_activeTab) {
      case 'info':
        return Column(
          children: [
            _InfoCard(
              label: 'Full Name',
              value: widget.user.name,
              isDark: isDark,
            ),
            _InfoCard(label: 'Email', value: widget.user.email, isDark: isDark),
            _InfoCard(
              label: 'Eco Points',
              value: widget.user.ecoPoints.toString(),
              isDark: isDark,
            ),
            _InfoCard(
              label: 'Trees Planted',
              value: widget.user.treesPlanted.toString(),
              isDark: isDark,
            ),
            _InfoCard(
              label: 'Blockchain Address',
              value: widget.user.blockchainAddress,
              isDark: isDark,
              monospace: true,
            ),
          ],
        );
      case 'banks':
        return Column(
          children: [
            for (final account in widget.user.bankAccounts)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: Colors.blue,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account.bankName,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.blueGrey.shade900,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    account.accountNumber,
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
                          GestureDetector(
                            onTap: () => widget.onToggleBalance(account.id),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0A1F2F)
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.hiddenBalances.contains(account.id)
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: isDark
                                    ? Colors.teal.shade400
                                    : Colors.teal.shade600,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.type == 'checking'
                                    ? 'Checking Account'
                                    : 'Savings Account',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.teal.shade300
                                      : Colors.teal.shade700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.hiddenBalances.contains(account.id)
                                    ? '••••••'
                                    : '\$${account.balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.blueGrey.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          // Placeholder action buttons (edit/delete)
                          Row(
                            children: [
                              _iconSquare(
                                isDark,
                                Icons.edit_rounded,
                                Colors.teal,
                              ),
                              const SizedBox(width: 8),
                              _iconSquare(
                                isDark,
                                Icons.delete_rounded,
                                Colors.redAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            _dashedAddButton(isDark, text: 'Add Bank Account'),
          ],
        );
      case 'cards':
        return Column(
          children: [
            for (final card in widget.user.cards)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.credit_card_rounded,
                                  color: Colors.purple,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.bankName,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.blueGrey.shade900,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    card.cardNumber,
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
                          Row(
                            children: [
                              _iconSquare(
                                isDark,
                                Icons.edit_rounded,
                                Colors.teal,
                              ),
                              const SizedBox(width: 8),
                              _iconSquare(
                                isDark,
                                Icons.delete_rounded,
                                Colors.redAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 3.2,
                            ),
                        children: [
                          _miniInfo(isDark, 'Holder', card.cardHolder),
                          _miniInfo(isDark, 'Expiry', card.expiryDate),
                          _miniInfo(isDark, 'Type', card.type),
                          _miniInfo(isDark, 'CVV', card.cvv),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            _dashedAddButton(isDark, text: 'Add Card'),
          ],
        );
      case 'wallets':
        return Column(
          children: [
            for (final wallet in widget.user.mobileWallets)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.smartphone_rounded,
                                  color: Colors.green,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wallet.provider,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.blueGrey.shade900,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    wallet.phoneNumber,
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
                          GestureDetector(
                            onTap: () => widget.onToggleBalance(wallet.id),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0A1F2F)
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.hiddenBalances.contains(wallet.id)
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: isDark
                                    ? Colors.teal.shade400
                                    : Colors.teal.shade600,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Balance',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.teal.shade300
                                      : Colors.teal.shade700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.hiddenBalances.contains(wallet.id)
                                    ? '••••••'
                                    : '\$${wallet.balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.blueGrey.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _iconSquare(
                                isDark,
                                Icons.edit_rounded,
                                Colors.teal,
                              ),
                              const SizedBox(width: 8),
                              _iconSquare(
                                isDark,
                                Icons.delete_rounded,
                                Colors.redAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            _dashedAddButton(isDark, text: 'Add Mobile Wallet'),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _dashedAddButton(bool isDark, {required String text}) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F2F3F).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.teal.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
          style: BorderStyle
              .solid, // dashed not directly supported; choose solid subtle
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.teal.shade300 : Colors.teal.shade600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _miniInfo(bool isDark, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0A1F2F).withValues(alpha: 0.5)
            : Colors.green.shade50.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
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
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.blueGrey.shade900,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _iconSquare(bool isDark, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0A1F2F).withValues(alpha: 0.5)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.teal.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.3),
        ),
      ),
      child: Icon(icon, color: isDark ? Colors.teal.shade300 : color, size: 18),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool monospace;
  const _InfoCard({
    required this.label,
    required this.value,
    required this.isDark,
    this.monospace = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassContainer(
        isDark: isDark,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.teal.shade300 : Colors.teal.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.blueGrey.shade900,
                fontSize: 15,
                fontFamily: monospace ? 'monospace' : null,
                fontWeight: FontWeight.w600,
              ),
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
