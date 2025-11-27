import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
// import removed: services are not used beyond dart:ui

// --- Entry Point ---
void main() {
  runApp(const UniTapApp());
}

// --- Data Models ---
class Transaction {
  final String id;
  final String type; // 'transfer', 'deposit', 'withdraw'
  final double amount;
  final DateTime date;
  final String status;
  final String? recipient;
  final String paymentMethod;
  final int ecoPoints;
  final String? blockchainHash;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.status,
    this.recipient,
    required this.paymentMethod,
    required this.ecoPoints,
    this.blockchainHash,
  });
}

class BankAccount {
  final String id;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final double balance;
  final String type;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.balance,
    required this.type,
  });
}

class CardModel {
  final String id;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cvv;
  final String type; // 'credit', 'debit'
  final String bankName;

  CardModel({
    required this.id,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cvv,
    required this.type,
    required this.bankName,
  });
}

class MobileWallet {
  final String id;
  final String provider;
  final String phoneNumber;
  final double balance;

  MobileWallet({
    required this.id,
    required this.provider,
    required this.phoneNumber,
    required this.balance,
  });
}

class User {
  String name;
  String email;
  int ecoPoints;
  int treesPlanted;
  String blockchainAddress;
  List<BankAccount> bankAccounts;
  List<CardModel> cards;
  List<MobileWallet> mobileWallets;

  User({
    required this.name,
    required this.email,
    required this.ecoPoints,
    required this.treesPlanted,
    required this.blockchainAddress,
    required this.bankAccounts,
    required this.cards,
    required this.mobileWallets,
  });
}

// --- Main App Controller ---
class UniTapApp extends StatefulWidget {
  const UniTapApp({super.key});

  @override
  State<UniTapApp> createState() => _UniTapAppState();
}

class _UniTapAppState extends State<UniTapApp> {
  bool isDarkMode = true;

  // Initialize State similar to React useState
  late User user;
  late List<Transaction> recentTransactions;
  Set<String> hiddenBalances = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Initially hide all balances
    hiddenBalances.addAll(user.bankAccounts.map((e) => e.id));
    hiddenBalances.addAll(user.mobileWallets.map((e) => e.id));
  }

  void _initializeData() {
    user = User(
      name: 'Alex Johnson',
      email: 'alex.johnson@example.com',
      ecoPoints: 2847,
      treesPlanted: 12,
      blockchainAddress: '0x742d...Bed',
      bankAccounts: [
        BankAccount(
          id: 'bank-1',
          bankName: 'Chase Bank',
          accountNumber: '****1234',
          accountName: 'Alex Johnson',
          balance: 8420.50,
          type: 'checking',
        ),
        BankAccount(
          id: 'bank-2',
          bankName: 'Bank of America',
          accountNumber: '****5678',
          accountName: 'Alex Johnson',
          balance: 5200.00,
          type: 'savings',
        ),
      ],
      cards: [
        CardModel(
          id: 'card-1',
          cardNumber: '**** **** **** 4532',
          cardHolder: 'Alex Johnson',
          expiryDate: '12/26',
          cvv: '***',
          type: 'credit',
          bankName: 'Chase Visa',
        ),
      ],
      mobileWallets: [
        MobileWallet(
          id: 'wallet-1',
          provider: 'GCash',
          phoneNumber: '+1 (555) 123-4567',
          balance: 450.00,
        ),
      ],
    );

    recentTransactions = [
      Transaction(
        id: 'TXN-1',
        type: 'transfer',
        amount: 250.00,
        date: DateTime.now(),
        status: 'completed',
        recipient: 'Sarah Mitchell',
        paymentMethod: 'Blockchain Wallet',
        ecoPoints: 25,
      ),
      Transaction(
        id: 'TXN-2',
        type: 'deposit',
        amount: 1000.00,
        date: DateTime.now(),
        status: 'completed',
        paymentMethod: 'Bank Transfer',
        ecoPoints: 100,
      ),
      Transaction(
        id: 'TXN-3',
        type: 'withdraw',
        amount: 500.00,
        date: DateTime.now(),
        status: 'completed',
        paymentMethod: 'ATM',
        ecoPoints: 50,
      ),
    ];
  }

  void toggleTheme() => setState(() => isDarkMode = !isDarkMode);

  void toggleBalance(String id) {
    setState(() {
      if (hiddenBalances.contains(id)) {
        hiddenBalances.remove(id);
      } else {
        hiddenBalances.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define Theme Data
    final textTheme = TextTheme(
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: isDarkMode ? Colors.teal.shade200 : Colors.teal.shade700,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light, textTheme: textTheme),
      home: Dashboard(
        user: user,
        recentTransactions: recentTransactions,
        isDarkMode: isDarkMode,
        onToggleTheme: toggleTheme,
        hiddenBalances: hiddenBalances,
        onToggleBalance: toggleBalance,
        onLogout: () {}, // Handle logout
      ),
    );
  }
}

// --- Dashboard Screen ---
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

    // Background Gradient logic (matching Sign In)
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
          // 1. Background
          Container(decoration: BoxDecoration(gradient: bgGradient)),

          // 2. Stars
          Positioned.fill(child: StarField(isDarkMode: isDark)),

          // 3. Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // --- Header ---
                  FadeTransition(
                    opacity: _entranceController,
                    child: _buildHeader(context),
                  ),
                  const SizedBox(height: 24),

                  // --- Balance Card ---
                  SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entranceController,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: FadeTransition(
                      opacity: _entranceController,
                      child: _buildBalanceCard(context),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Quick Actions Grid ---
                  SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entranceController,
                            curve: const Interval(
                              0.2,
                              1.0,
                              curve: Curves.easeOut,
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

                  // --- Recent Transactions ---
                  SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entranceController,
                            curve: const Interval(
                              0.4,
                              1.0,
                              curve: Curves.easeOut,
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
                  const SizedBox(height: 40), // Padding bottom
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
          colors: [
            Color(0xFF00DC82),
            Color(0xFF0F766E),
          ], // Emerald to Dark Teal
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
          // Decorative Circles
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
                        Icon(
                          Icons.shield_outlined,
                          color: Colors.green.shade100,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'My Accounts',
                          style: TextStyle(
                            color: Colors.green.shade100,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Blockchain Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Account List
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.credit_card_rounded,
                              color: Colors.green.shade200,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.bankName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  card.cardNumber,
                                  style: TextStyle(
                                    color: Colors.green.shade200,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          card.type.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
                      Icons.trending_up_rounded,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      number,
                      style: TextStyle(
                        color: Colors.green.shade200,
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
                        ? Colors.teal.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: txn.type == 'deposit'
                                ? Colors.green.withValues(alpha: 0.2)
                                : txn.type == 'withdraw'
                                ? Colors.red.withValues(alpha: 0.2)
                                : Colors.blue.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            txn.type == 'deposit'
                                ? Icons.south_west_rounded
                                : txn.type == 'withdraw'
                                ? Icons.north_east_rounded
                                : Icons.swap_horiz_rounded,
                            size: 20,
                            color: txn.type == 'deposit'
                                ? Colors.green.shade400
                                : txn.type == 'withdraw'
                                ? Colors.red.shade400
                                : Colors.blue.shade400,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txn.type[0].toUpperCase() + txn.type.substring(1),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : Colors.blueGrey.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              txn.recipient ?? txn.paymentMethod,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${txn.type == 'deposit' ? '+' : '-'}\$${txn.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: txn.type == 'deposit'
                                ? Colors.green.shade400
                                : Colors.red.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '+${txn.ecoPoints} pts',
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helper Widgets ---

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

// --- Reused Animated Background Components ---

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
