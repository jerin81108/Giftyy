import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/theme.dart';
import '../../providers/wedding_provider.dart';

class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _withdrawAmountController = TextEditingController();

  bool _isSavingBank = false;
  bool _isRequestingPayout = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeddingProvider>(context, listen: false).fetchPayouts();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    _withdrawAmountController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveBank() async {
    final name = _nameController.text.trim();
    final acc = _accountController.text.trim();
    final ifsc = _ifscController.text.trim();
    final upi = _upiController.text.trim();

    if (name.isEmpty || acc.isEmpty || ifsc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill Account Name, Number, and IFSC code')),
      );
      return;
    }

    setState(() => _isSavingBank = true);
    final provider = Provider.of<WeddingProvider>(context, listen: false);
    final success = await provider.saveBankDetails(
      accountHolderName: name,
      accountNumber: acc,
      ifscCode: ifsc,
      upiId: upi.isNotEmpty ? upi : null,
    );

    if (!mounted) return;
    setState(() => _isSavingBank = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank account and UPI details saved securely!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save bank details')),
      );
    }
  }

  Future<void> _handleRequestPayout(int maxAvailable) async {
    final amount = int.tryParse(_withdrawAmountController.text.trim()) ?? 0;

    if (amount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum withdrawal amount is ₹500')),
      );
      return;
    }

    if (amount > maxAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amount exceeds available balance (${AppTheme.formatINR(maxAvailable)})')),
      );
      return;
    }

    setState(() => _isRequestingPayout = true);
    final provider = Provider.of<WeddingProvider>(context, listen: false);
    final success = await provider.requestPayout(amount);

    if (!mounted) return;
    setState(() => _isRequestingPayout = false);

    if (success) {
      _withdrawAmountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout initiated to your verified bank account!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not process withdrawal request')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeddingProvider>(context);
    final payoutInfo = provider.payoutInfo ?? {};
    final totalRaised = (payoutInfo['totalRaised'] ?? 0) as int;
    final totalPaidOut = (payoutInfo['totalPaidOut'] ?? 0) as int;
    final availableBalance = (payoutInfo['availableBalance'] ?? totalRaised - totalPaidOut) as int;
    final bankDetails = payoutInfo['bankDetails'] as Map<String, dynamic>?;
    final payoutsList = (payoutInfo['payouts'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          'PAYOUTS & BANK SETTLEMENT',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: AppTheme.accentYellow,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVAILABLE TO WITHDRAW',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppTheme.textDark.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppTheme.formatINR(availableBalance),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Raised',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            AppTheme.formatINR(totalRaised),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settled to Bank',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            AppTheme.formatINR(totalPaidOut),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Withdraw Form
            if (availableBalance >= 500) ...[
              Text(
                'Request Fund Transfer',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _withdrawAmountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.accentYellow,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold),
                        hintText: 'Enter amount (max ${AppTheme.formatINR(availableBalance)})',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isRequestingPayout ? null : () => _handleRequestPayout(availableBalance),
                        child: _isRequestingPayout
                            ? const CircularProgressIndicator(color: AppTheme.textDark)
                            : Text(
                                'Transfer to Bank Account',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Bank Account Form
            Text(
              bankDetails != null ? 'Linked Bank Account' : 'Link Bank Account & UPI',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'RBI compliant: Funds are deposited directly to your KYC-verified bank account.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Holder Name',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                    decoration: InputDecoration(
                      hintText: bankDetails?['accountHolderName'] ?? 'e.g. Aisha Sharma',
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Bank Account Number',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _accountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                    decoration: InputDecoration(
                      hintText: bankDetails?['accountNumber'] != null
                          ? 'xxxx${bankDetails!['accountNumber'].toString().substring(bankDetails['accountNumber'].toString().length - 4)}'
                          : '123456789012',
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'IFSC Code',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ifscController,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                    decoration: InputDecoration(
                      hintText: bankDetails?['ifscCode'] ?? 'HDFC0001234',
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'UPI ID (Optional)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _upiController,
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                    decoration: InputDecoration(
                      hintText: bankDetails?['upiId'] ?? 'couple@okaxis',
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isSavingBank ? null : _handleSaveBank,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.accentYellow),
                      ),
                      child: _isSavingBank
                          ? const CircularProgressIndicator(color: AppTheme.accentYellow)
                          : Text(
                              'Save Bank Details',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.accentYellow,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Payout History
            if (payoutsList.isNotEmpty) ...[
              Text(
                'Settlement History',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 12),
              ...payoutsList.map((p) {
                final date = p['createdAt'] != null ? DateTime.parse(p['createdAt']) : DateTime.now();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTheme.formatINR(p['amount'] ?? 0),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textLight,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy · hh:mm a').format(date),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (p['status'] ?? 'COMPLETED').toString().toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.successGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
