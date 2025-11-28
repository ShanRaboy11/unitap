import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // REQUIRED PACKAGE
import 'package:unitap/models.dart'; // Models (User, Transaction)

// Steps Enum
enum TransactionStep { type, method, details, confirm, qr, receipt }

class TransactionFlow extends StatefulWidget {
  final User user;
  final Function(Transaction) onComplete;
  final VoidCallback onBack;
  final bool isDarkMode;

  const TransactionFlow({
    super.key,
    required this.user,
    required this.onComplete,
    required this.onBack,
    required this.isDarkMode,
  });

  @override
  State<TransactionFlow> createState() => _TransactionFlowState();
}

class _TransactionFlowState extends State<TransactionFlow> {
  TransactionStep currentStep = TransactionStep.type;

  // Form Data
  String? transactionType; // 'transfer', 'deposit', 'withdraw'
  String? paymentMethod; // 'blockchain', 'card', 'bank', 'mobile'

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _recipientCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  // QR Logic
  String qrToken = '';
  String qrDataString = ''; // The actual data to encode
  int timeLeft = 30;
  Timer? _timer;
  bool isExpired = false; // Keep QR data even after expiry

  Transaction? completedTransaction;

  @override
  void dispose() {
    _timer?.cancel();
    _amountCtrl.dispose();
    _recipientCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // --- Logic ---

  void _generateQR() {
    // Build QR payload for any transaction type/method
    final now = DateTime.now().toUtc();
    final expires = now.add(const Duration(minutes: 15));
    final amt = double.tryParse(_amountCtrl.text) ?? 0.0;
    final toAccount = _recipientCtrl.text.isNotEmpty ? _recipientCtrl.text : '';
    final txType = transactionType ?? 'transfer';

    final String payload =
        '{"token_id":"2e89202b-8e85-4383-9864-0ab64a632d8e","UserId":"44444444-4444-4444-4444-444444444444","TokenSignature":"qr_expired_111111","TransactionType":"$txType","ToAccount":"$toAccount","Amount":${amt.toStringAsFixed(2)},"is_scanned":"false","created_at":"${now.toIso8601String()}","expires_at":"${expires.toIso8601String()}"}';

    setState(() {
      qrToken = 'qr_expired_111111';
      qrDataString = payload;
      timeLeft = 900; // 15 minutes
      isExpired = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        setState(() => isExpired = true); // Keep QR & data unchanged
        _timer?.cancel();
      }
    });
  }

  void _handleQRConfirm() {
    _timer?.cancel();
    final double amount = double.tryParse(_amountCtrl.text) ?? 0.0;

    final newTxn = Transaction(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      type: transactionType!,
      amount: amount,
      date: DateTime.now(),
      status: 'completed',
      recipient: _recipientCtrl.text.isNotEmpty ? _recipientCtrl.text : null,
      paymentMethod: _formatPaymentMethod(paymentMethod!),
      ecoPoints: (amount / 10).floor(),
      blockchainHash:
          '0x${List.generate(40, (_) => math.Random().nextInt(16).toRadixString(16)).join()}',
    );

    setState(() {
      completedTransaction = newTxn;
      currentStep = TransactionStep.receipt;
    });
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'blockchain':
        return 'Blockchain Wallet';
      case 'card':
        return 'Credit Card';
      case 'bank':
        return 'Bank Transfer';
      case 'mobile':
        return 'Mobile Wallet';
      default:
        return method;
    }
  }

  void _handleBack() {
    if (currentStep == TransactionStep.type) {
      widget.onBack();
    } else if (currentStep == TransactionStep.receipt) {
      if (completedTransaction != null) {
        widget.onComplete(completedTransaction!);
      }
    } else {
      setState(() {
        // Go back one step
        final index = TransactionStep.values.indexOf(currentStep);
        currentStep = TransactionStep.values[index - 1];
      });
    }
  }

  // --- UI Building Blocks ---

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
          Positioned.fill(child: _StarField(isDarkMode: isDark)),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _handleBack,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F2F3F)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.teal.withValues(alpha: 0.3)
                                  : Colors.green.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: isDark
                                ? Colors.teal.shade200
                                : Colors.teal.shade600,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStepTitle(),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : Colors.blueGrey.shade900,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Step ${TransactionStep.values.indexOf(currentStep) + 1} of 6',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.teal.shade400
                                  : Colors.teal.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Animated Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: SingleChildScrollView(
                      key: ValueKey(currentStep),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildCurrentStep(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (currentStep) {
      case TransactionStep.type:
        return 'Select Transaction Type';
      case TransactionStep.method:
        return 'Select Payment Method';
      case TransactionStep.details:
        return 'Transaction Details';
      case TransactionStep.confirm:
        return 'Confirm Transaction';
      case TransactionStep.qr:
        return 'Scan QR Code';
      case TransactionStep.receipt:
        return 'Transaction Complete';
    }
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case TransactionStep.type:
        return Column(
          children: [
            _OptionCard(
              icon: Icons.arrow_outward_rounded,
              color: Colors.blue,
              title: 'Money Transfer',
              subtitle: 'Send money to anyone instantly',
              isDark: widget.isDarkMode,
              onTap: () => setState(() {
                transactionType = 'transfer';
                currentStep = TransactionStep.method;
              }),
            ),
            _OptionCard(
              icon: Icons.south_west_rounded,
              color: Colors.green,
              title: 'Deposit / Cash In',
              subtitle: 'Add funds to your account',
              isDark: widget.isDarkMode,
              onTap: () => setState(() {
                transactionType = 'deposit';
                currentStep = TransactionStep.method;
              }),
            ),
            _OptionCard(
              icon: Icons.north_east_rounded,
              color: Colors.red,
              title: 'Withdraw / Cash Out',
              subtitle: 'Withdraw cash from ATM',
              isDark: widget.isDarkMode,
              onTap: () => setState(() {
                transactionType = 'withdraw';
                currentStep = TransactionStep.method;
              }),
            ),
          ],
        );

      case TransactionStep.method:
        return Column(
          children: [
            _OptionCard(
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.teal,
              title: 'Blockchain Wallet',
              subtitle: 'Secure and instant blockchain transfer',
              isDark: widget.isDarkMode,
              onTap: () => setState(() {
                paymentMethod = 'blockchain';
                currentStep = TransactionStep.details;
              }),
            ),
            _OptionCard(
              icon: Icons.credit_card_rounded,
              color: Colors.teal,
              title: 'Credit/Debit Card',
              subtitle: 'Use your card for this transaction',
              isDark: widget.isDarkMode,
              onTap: () => setState(() {
                paymentMethod = 'card';
                currentStep = TransactionStep.details;
              }),
            ),
            _OptionCard(
              icon: Icons.account_balance_rounded,
              color: Colors.teal,
              title: 'Bank Transfer',
              subtitle: 'Direct bank account transfer',
              isDark: widget.isDarkMode,
              onTap: () => setState(() {
                paymentMethod = 'bank';
                currentStep = TransactionStep.details;
              }),
            ),
            _OptionCard(
              icon: Icons.smartphone_rounded,
              color: Colors.teal,
              title: 'Mobile Wallet',
              subtitle: 'Pay using mobile wallet',
              isDark: widget.isDarkMode,
              onTap: () => setState(() {
                paymentMethod = 'mobile';
                currentStep = TransactionStep.details;
              }),
            ),
          ],
        );

      case TransactionStep.details:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputGroup(
              label: 'Amount',
              child: _buildTextField(
                controller: _amountCtrl,
                hint: '0.00',
                prefix: '\$',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              footer:
                  '+${(double.tryParse(_amountCtrl.text) ?? 0) ~/ 10} eco points will be earned',
            ),
            if (transactionType == 'transfer')
              _buildInputGroup(
                label: 'Recipient',
                child: _buildTextField(
                  controller: _recipientCtrl,
                  hint: 'Enter recipient name or address',
                ),
              ),
            // Example Fields for Card/Bank (Simplified for UI)
            if (paymentMethod == 'card') ...[
              _buildInputGroup(
                label: 'Card Number',
                child: _buildTextField(hint: '1234 5678 9012 3456'),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildInputGroup(
                      label: 'Expiry',
                      child: _buildTextField(hint: 'MM/YY'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputGroup(
                      label: 'CVV',
                      child: _buildTextField(hint: '123'),
                    ),
                  ),
                ],
              ),
            ],
            _buildInputGroup(
              label: 'Note (Optional)',
              child: _buildTextField(
                controller: _noteCtrl,
                hint: 'Add a note...',
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              text: 'Continue',
              icon: Icons.chevron_right_rounded,
              onTap: () =>
                  setState(() => currentStep = TransactionStep.confirm),
            ),
          ],
        );

      case TransactionStep.confirm:
        final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
        return Column(
          children: [
            _GlassContainer(
              isDark: widget.isDarkMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Summary',
                    style: TextStyle(
                      color: widget.isDarkMode
                          ? Colors.teal.shade200
                          : Colors.teal.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(
                    'Type',
                    transactionType!.toUpperCase(),
                    widget.isDarkMode,
                  ),
                  _SummaryRow(
                    'Amount',
                    '\$${amount.toStringAsFixed(2)}',
                    widget.isDarkMode,
                  ),
                  if (_recipientCtrl.text.isNotEmpty)
                    _SummaryRow(
                      'Recipient',
                      _recipientCtrl.text,
                      widget.isDarkMode,
                    ),
                  _SummaryRow(
                    'Method',
                    _formatPaymentMethod(paymentMethod!),
                    widget.isDarkMode,
                  ),
                  _SummaryRow(
                    'Eco Points',
                    '+${(amount / 10).floor()} points',
                    widget.isDarkMode,
                    isHighlight: true,
                  ),
                  if (_noteCtrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Note',
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.teal.shade200
                                  : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _noteCtrl.text,
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Colors.amber.withValues(alpha: 0.1)
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isDarkMode
                      ? Colors.amber.withValues(alpha: 0.3)
                      : Colors.amber.shade200,
                ),
              ),
              child: Text(
                'Please review details carefully. This action cannot be undone.',
                style: TextStyle(
                  color: widget.isDarkMode
                      ? Colors.amber.shade400
                      : Colors.amber.shade800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              text: 'Confirm Transaction',
              icon: Icons.check_rounded,
              onTap: () {
                _generateQR();
                setState(() => currentStep = TransactionStep.qr);
              },
            ),
          ],
        );

      case TransactionStep.qr:
        return Column(
          children: [
            _GlassContainer(
              isDark: widget.isDarkMode,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_rounded,
                        color: widget.isDarkMode
                            ? Colors.green.shade400
                            : Colors.green.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Secure Transaction QR',
                        style: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- REAL QR CODE IMPLEMENTATION ---
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: QrImageView(
                        data:
                            qrDataString, // The actual JSON data from user input
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        // Fixed: Updated to valid qr_flutter class names (QrDataModuleStyle and QrEyeStyle)
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.blueGrey.shade900,
                        ),
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ),
                  ),

                  // -----------------------------------
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isExpired) ...[
                        Icon(
                          Icons.timer_rounded,
                          color: widget.isDarkMode
                              ? Colors.tealAccent
                              : Colors.teal,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Expires in ${timeLeft}s',
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.tealAccent
                                : Colors.teal,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.lock_clock_rounded,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'QR expired (data retained)',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? const Color(0xFF0A1F2F)
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'OTP Verification',
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.isDarkMode
                                ? Colors.teal.shade300
                                : Colors.teal.shade700,
                          ),
                        ),
                        Text(
                          qrToken,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: widget.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    // Fixed: Removed unnecessary braces from string interpolation
                    'Scan this at the ATM or POS to complete the $transactionType via ${_formatPaymentMethod(paymentMethod ?? "")}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDarkMode
                          ? Colors.teal.shade200
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!isExpired)
              _PrimaryButton(
                text: 'Simulate Scan Success',
                icon: Icons.check_circle_outline_rounded,
                onTap: _handleQRConfirm,
              )
            else
              Opacity(
                opacity: 0.45,
                child: _PrimaryButton(
                  text: 'QR Expired',
                  icon: Icons.block_rounded,
                  onTap: () {},
                ),
              ),
          ],
        );

      case TransactionStep.receipt:
        if (completedTransaction == null) return const SizedBox();
        return Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.greenAccent, Colors.green],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Transaction Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              'Your transaction has been processed',
              style: TextStyle(
                color: widget.isDarkMode
                    ? Colors.teal.shade200
                    : Colors.teal.shade600,
              ),
            ),
            const SizedBox(height: 24),

            _GlassContainer(
              isDark: widget.isDarkMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt',
                    style: TextStyle(
                      color: widget.isDarkMode
                          ? Colors.teal.shade200
                          : Colors.teal.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(
                    'ID',
                    completedTransaction!.id,
                    widget.isDarkMode,
                  ),
                  _SummaryRow(
                    'Date',
                    '${completedTransaction!.date.hour}:${completedTransaction!.date.minute}',
                    widget.isDarkMode,
                  ),
                  _SummaryRow(
                    'Type',
                    completedTransaction!.type.toUpperCase(),
                    widget.isDarkMode,
                  ),
                  _SummaryRow(
                    'Amount',
                    '\$${completedTransaction!.amount.toStringAsFixed(2)}',
                    widget.isDarkMode,
                  ),
                  if (completedTransaction!.recipient != null)
                    _SummaryRow(
                      'Recipient',
                      completedTransaction!.recipient!,
                      widget.isDarkMode,
                    ),
                  _SummaryRow(
                    'Status',
                    completedTransaction!.status.toUpperCase(),
                    widget.isDarkMode,
                    isSuccess: true,
                  ),
                  const Divider(color: Colors.white10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.eco,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Eco Points',
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '+${completedTransaction!.ecoPoints} pts',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              text: 'Download Receipt',
              icon: Icons.download_rounded,
              isOutlined: true,
              isDark: widget.isDarkMode,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _PrimaryButton(
              text: 'Back to Dashboard',
              onTap: () {
                if (completedTransaction != null) {
                  widget.onComplete(completedTransaction!);
                } else {
                  widget.onBack();
                }
              },
            ),
            const SizedBox(height: 30),
          ],
        );
    }
  }

  // --- Helper Widgets Internal ---

  Widget _buildInputGroup({
    required String label,
    required Widget child,
    String? footer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _GlassContainer(
        isDark: widget.isDarkMode,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: widget.isDarkMode
                    ? Colors.teal.shade200
                    : Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            child,
            if (footer != null) ...[
              const SizedBox(height: 8),
              Text(
                footer,
                style: TextStyle(
                  color: widget.isDarkMode
                      ? Colors.teal.shade500
                      : Colors.teal.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String hint,
    String? prefix,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: widget.isDarkMode ? Colors.white : Colors.black87,
        fontSize: 18,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: widget.isDarkMode
              ? Colors.teal.shade700
              : Colors.teal.shade200,
        ),
        prefixText: prefix,
        prefixStyle: TextStyle(
          color: widget.isDarkMode ? Colors.white : Colors.black87,
          fontSize: 18,
        ),
        filled: true,
        fillColor: widget.isDarkMode ? const Color(0xFF0A1F2F) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

// --- Shared Widgets for Transaction Flow ---

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final MaterialColor color;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: _GlassContainer(
          isDark: isDark,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color.shade400, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.blueGrey.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark
                            ? Colors.teal.shade400
                            : Colors.teal.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
              ),
            ],
          ),
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
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isOutlined;
  final bool isDark;

  const _PrimaryButton({
    required this.text,
    this.icon,
    required this.onTap,
    this.isOutlined = false,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2F3F) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.teal.withValues(alpha: 0.3)
                  : Colors.green.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool isDark;
  final bool isHighlight;
  final bool isSuccess;
  const _SummaryRow(
    this.label,
    this.value,
    this.isDark, {
    this.isHighlight = false,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    Color valueColor = isDark ? Colors.white : Colors.black87;
    if (isHighlight) valueColor = Colors.green;
    if (isSuccess) valueColor = Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.teal.shade200 : Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Lightweight starfield (duplicated from dashboard for consistent background)
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
