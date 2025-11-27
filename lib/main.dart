import 'package:flutter/material.dart';
import 'models.dart';
import 'pages/sign_in.dart';
import 'pages/dashboard.dart';

void main() {
  runApp(const UniTapApp());
}

class UniTapApp extends StatefulWidget {
  const UniTapApp({super.key});
  @override
  State<UniTapApp> createState() => _UniTapAppState();
}

class _UniTapAppState extends State<UniTapApp> {
  bool isDarkMode = true;
  bool isLoggedIn = false;

  late User user;
  late List<Transaction> recentTransactions;
  final Set<String> hiddenBalances = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
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
  void handleLogin() => setState(() => isLoggedIn = true);
  void handleLogout() => setState(() => isLoggedIn = false);

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
      darkTheme: ThemeData(brightness: Brightness.dark, textTheme: textTheme),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: isLoggedIn
          ? Dashboard(
              user: user,
              recentTransactions: recentTransactions,
              isDarkMode: isDarkMode,
              onToggleTheme: toggleTheme,
              hiddenBalances: hiddenBalances,
              onToggleBalance: toggleBalance,
              onLogout: handleLogout,
              onAddTransaction: (txn) {
                setState(() {
                  recentTransactions.insert(0, txn);
                  user.ecoPoints += txn.ecoPoints;
                });
              },
            )
          : SignIn(
              onLogin: handleLogin,
              isDarkMode: isDarkMode,
              onToggleTheme: toggleTheme,
            ),
    );
  }
}
