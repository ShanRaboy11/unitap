import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:unitap/models.dart';

class TransactionHistory extends StatefulWidget {
  final List<Transaction> transactions;
  final bool isDarkMode;
  final VoidCallback onBack;

  const TransactionHistory({
    super.key,
    required this.transactions,
    required this.isDarkMode,
    required this.onBack,
  });

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  String searchQuery = '';
  String filter = 'all'; // all | transfer | deposit | withdraw

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

    final filtered = widget.transactions.where((t) {
      final q = searchQuery.toLowerCase();
      final matchesSearch =
          t.id.toLowerCase().contains(q) ||
          (t.recipient?.toLowerCase().contains(q) ?? false) ||
          t.paymentMethod.toLowerCase().contains(q);
      final matchesFilter = filter == 'all' || t.type == filter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: bgGradient)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark, filtered.length),
                  const SizedBox(height: 16),
                  _buildSearchBar(isDark),
                  const SizedBox(height: 12),
                  _buildFilterChips(isDark),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty) _buildEmpty(isDark),
                  ...filtered.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TransactionTile(
                        txn: e.value,
                        isDark: isDark,
                        onTap: () => _showDetails(context, e.value, isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 56,
              color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
            ),
            const SizedBox(height: 12),
            Text(
              'No transactions found',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.blueGrey.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, int count) {
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
              'Transaction History',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.blueGrey.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$count transactions',
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

  Widget _buildSearchBar(bool isDark) {
    return _GlassContainer(
      isDark: isDark,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions... ',
                hintStyle: TextStyle(
                  color: isDark ? Colors.teal.shade600 : Colors.teal.shade700,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.blueGrey.shade900,
                fontSize: 14,
              ),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),
          if (searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => searchQuery = ''),
              child: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final items = ['all', 'transfer', 'deposit', 'withdraw'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final t in items) ...[
            GestureDetector(
              onTap: () => setState(() => filter = t),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: filter == t
                      ? const LinearGradient(
                          colors: [Color(0xFF34D399), Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: filter == t
                      ? null
                      : (isDark ? const Color(0xFF0F2F3F) : Colors.white),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: filter == t
                        ? Colors.transparent
                        : (isDark
                              ? Colors.teal.withValues(alpha: 0.3)
                              : Colors.green.withValues(alpha: 0.2)),
                  ),
                  boxShadow: filter == t
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
                  t == 'all' ? 'All' : (t[0].toUpperCase() + t.substring(1)),
                  style: TextStyle(
                    color: filter == t
                        ? Colors.white
                        : (isDark
                              ? Colors.teal.shade300
                              : Colors.teal.shade600),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, Transaction txn, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: _GlassContainer(
                isDark: isDark,
                padding: const EdgeInsets.all(20),
                child: ListView(
                  controller: controller,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaction Details',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.blueGrey.shade900,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0A1F2F)
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: isDark
                                  ? Colors.teal.shade400
                                  : Colors.teal.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._detailRow(isDark, 'Transaction ID', txn.id),
                    ..._divider(isDark),
                    ..._detailRow(
                      isDark,
                      'Date & Time',
                      _formatDateTime(txn.date),
                    ),
                    ..._divider(isDark),
                    ..._detailRow(isDark, 'Type', _capitalize(txn.type)),
                    ..._divider(isDark),
                    ..._detailRow(
                      isDark,
                      'Amount',
                      '${txn.type == 'deposit' ? '+' : '-'}\$${txn.amount.toStringAsFixed(2)}',
                      color: txn.type == 'deposit' ? Colors.green : Colors.red,
                    ),
                    if (txn.recipient != null) ...[
                      ..._divider(isDark),
                      ..._detailRow(isDark, 'Recipient', txn.recipient!),
                    ],
                    ..._divider(isDark),
                    ..._detailRow(isDark, 'Payment Method', txn.paymentMethod),
                    ..._divider(isDark),
                    ..._detailRow(
                      isDark,
                      'Status',
                      _capitalize(txn.status),
                      color: txn.status == 'completed'
                          ? Colors.green
                          : (txn.status == 'pending'
                                ? Colors.orange
                                : Colors.red),
                    ),
                    ..._divider(isDark),
                    ..._detailRow(
                      isDark,
                      'Blockchain Hash',
                      txn.blockchainHash ?? '—',
                      isMonospace: true,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.eco_rounded,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Eco Points Earned',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.teal.shade200
                                      : Colors.green.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '+${txn.ecoPoints} points',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PrimaryButton(
                      text: 'Download Receipt',
                      icon: Icons.download_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Receipt for ${txn.id} downloaded!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = '${dt.month}/${dt.day}/${dt.year}';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$d $h:$m $ampm';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  List<Widget> _detailRow(
    bool isDark,
    String label,
    String value, {
    Color? color,
    bool isMonospace = false,
  }) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.teal.shade300 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color:
                    color ?? (isDark ? Colors.white : Colors.blueGrey.shade900),
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _divider(bool isDark) => [
    const SizedBox(height: 10),
    Divider(
      color: isDark
          ? Colors.teal.withValues(alpha: 0.2)
          : Colors.green.withValues(alpha: 0.2),
    ),
    const SizedBox(height: 10),
  ];
}

class _TransactionTile extends StatelessWidget {
  final Transaction txn;
  final bool isDark;
  final VoidCallback onTap;
  const _TransactionTile({
    required this.txn,
    required this.isDark,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final color = txn.type == 'deposit'
        ? Colors.green
        : txn.type == 'withdraw'
        ? Colors.red
        : Colors.blue;
    return GestureDetector(
      onTap: onTap,
      child: _GlassContainer(
        isDark: isDark,
        padding: const EdgeInsets.all(16),
        child: Column(
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
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        txn.type == 'deposit'
                            ? Icons.arrow_downward_rounded
                            : txn.type == 'withdraw'
                            ? Icons.arrow_upward_rounded
                            : Icons.compare_arrows_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capitalize(txn.type),
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
                                ? Colors.teal.shade300
                                : Colors.teal.shade700,
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
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.eco_rounded,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${txn.ecoPoints}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  txn.id,
                  style: TextStyle(
                    color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDate(txn.date),
                  style: TextStyle(
                    color: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}/${dt.year}';
  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF34D399), Color(0xFF14B8A6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF34D399).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
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
