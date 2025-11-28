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
