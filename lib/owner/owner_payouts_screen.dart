import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../user/services/firestore_service.dart';

class OwnerPayoutsScreen extends StatefulWidget {
  final String gymId;

  const OwnerPayoutsScreen({super.key, required this.gymId});

  @override
  State<OwnerPayoutsScreen> createState() => _OwnerPayoutsScreenState();
}

class _OwnerPayoutsScreenState extends State<OwnerPayoutsScreen> {
  final FirestoreService _fs = FirestoreService();

  bool _isLoading = true;
  double _totalCollected = 0;
  double _platformFee = 0;
  double _platformFeePercent = 10;
  double _totalPaidOut = 0;
  double _available = 0;
  List<Map<String, dynamic>> _payouts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final balance = await _fs.getOwnerBalance(widget.gymId);
      final payouts = await _fs.getPayouts(widget.gymId);

      setState(() {
        _totalCollected = balance['totalCollected'];
        _platformFee = balance['platformFee'];
        _platformFeePercent = balance['platformFeePercent'];
        _totalPaidOut = balance['totalPaidOut'];
        _available = balance['available'];
        _payouts = payouts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showRequestPayoutSheet() {
    if (_available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No available balance to request'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating));
      return;
    }

    String selectedType = 'easypaisa';
    final accountCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('REQUEST PAYOUT',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text(
                    'Available: Rs ${_available.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.yellowAccent, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  const Text('Account Type',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(
                    children: ['easypaisa', 'jazzcash'].map((type) {
                      final selected = selectedType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedType = type),
                          child: Container(
                            margin: EdgeInsets.only(
                                right: type == 'easypaisa' ? 8 : 0),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.yellowAccent.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? Colors.yellowAccent
                                    : Colors.white12,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                type.toUpperCase(),
                                style: TextStyle(
                                    color: selected
                                        ? Colors.yellowAccent
                                        : Colors.white38,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Account Number',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: accountCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '03XX-XXXXXXX',
                      hintStyle:
                          const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.yellowAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final number =
                                  accountCtrl.text.trim();
                              if (number.isEmpty) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Enter account number'),
                                        behavior:
                                            SnackBarBehavior.floating));
                                return;
                              }
                              setSheetState(
                                  () => isSubmitting = true);
                              try {
                                await _fs.requestPayout(
                                  gymId: widget.gymId,
                                  amount: _available,
                                  accountType: selectedType,
                                  accountNumber: number,
                                );
                                if (ctx.mounted)
                                  Navigator.pop(ctx);
                                _loadData();
                              } catch (e) {
                                setSheetState(
                                    () => isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellowAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2.5))
                          : const Text('REQUEST PAYOUT',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('PAYOUTS',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Colors.yellowAccent))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.yellowAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _balanceCard(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _showRequestPayoutSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _available > 0
                              ? Colors.yellowAccent
                              : Colors.white10,
                          foregroundColor: _available > 0
                              ? Colors.black
                              : Colors.white38,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('REQUEST PAYOUT',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text('PAYOUT HISTORY',
                        style: TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 14),
                    if (_payouts.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Text('No payout requests yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white24, fontSize: 13)),
                      )
                    else
                      ..._payouts.map((p) => _payoutTile(p)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _balanceCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BALANCE SUMMARY',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 20),
          _balanceRow('Total Collected',
              'Rs ${_totalCollected.toStringAsFixed(0)}', Colors.white70),
          const SizedBox(height: 12),
          _balanceRow(
              'Platform Fee (${_platformFeePercent.toStringAsFixed(0)}%)',
              '- Rs ${_platformFee.toStringAsFixed(0)}',
              Colors.redAccent),
          const SizedBox(height: 12),
          _balanceRow('Already Paid Out',
              '- Rs ${_totalPaidOut.toStringAsFixed(0)}', Colors.white38),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Colors.white10),
          ),
          _balanceRow('Available Balance',
              'Rs ${_available.toStringAsFixed(0)}', Colors.yellowAccent,
              large: true),
        ],
      ),
    );
  }

  Widget _balanceRow(String label, String value, Color valueColor,
      {bool large = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white54,
                fontSize: large ? 14 : 13)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontWeight:
                    large ? FontWeight.bold : FontWeight.w500,
                fontSize: large ? 20 : 13)),
      ],
    );
  }

  Widget _payoutTile(Map<String, dynamic> payout) {
    final bool isProcessed = payout['status'] == 'processed';
    final ts = payout['requestedAt'] as Timestamp?;
    final date = ts != null
        ? DateFormat('dd MMM yyyy').format(ts.toDate())
        : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isProcessed
                  ? Colors.greenAccent.withOpacity(0.1)
                  : Colors.orangeAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isProcessed
                  ? Icons.check_rounded
                  : Icons.hourglass_top_rounded,
              color: isProcessed
                  ? Colors.greenAccent
                  : Colors.orangeAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rs ${(payout['amount'] as num).toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  '${payout['accountType']?.toUpperCase() ?? ''} · $date',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isProcessed
                  ? Colors.greenAccent.withOpacity(0.1)
                  : Colors.orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isProcessed ? 'PROCESSED' : 'PENDING',
              style: TextStyle(
                  color: isProcessed
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}