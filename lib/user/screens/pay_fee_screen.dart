// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/firestore_service.dart';
// import 'payment_pending_screen.dart';

// class PayFeeScreen extends StatefulWidget {
//   final String gymId;
//   final String memberId;
//   final String plan;
//   final double currentFee;

//   const PayFeeScreen({
//     super.key,
//     required this.gymId,
//     required this.memberId,
//     required this.plan,
//     required this.currentFee,
//   });

//   @override
//   State<PayFeeScreen> createState() => _PayFeeScreenState();
// }

// class _PayFeeScreenState extends State<PayFeeScreen> {
//   final FirestoreService _fs = FirestoreService();

//   bool _isLoading = true;
//   bool _isSubmitting = false;

//   String _easypaisaNumber = '';
//   String _accountName = '';
//   double _amount = 0;
//   late String _referenceCode;
//   File? _screenshotFile;
//   String _bankName = '';

//   @override
//   void initState() {
//     super.initState();
//     _referenceCode =
//         _fs.generateReferenceCode(widget.gymId, widget.memberId);
//     _loadConfig();
//   }

// Future<void> _loadConfig() async {
//   try {
//     // 1. Fetch the specific gym document
//     final doc = await FirebaseFirestore.instance
//         .collection('gyms')
//         .doc(widget.gymId)
//         .get();

//     if (!doc.exists || !mounted) return;

//     final data = doc.data();
//     // 2. Access the depositAccounts array
//     final List<dynamic>? accounts = data?['depositAccounts'];

//     setState(() {
//       if (accounts != null && accounts.isNotEmpty) {
//         // Taking the first account in the list as the primary one
//         final primaryAccount = accounts[0];
        
//         _easypaisaNumber = primaryAccount['accountNumber'] ?? 'Not configured';
//         _accountName = primaryAccount['accountTitle'] ?? 'ProTracker';
//         // You can also capture the bankName (e.g., "Easypaisa" or "JazzCash")
//         _bankName = primaryAccount['bankName'] ?? 'Wallet';
//       } else {
//         _easypaisaNumber = 'Not configured';
//         _accountName = 'No account found';
//       }
      
//       _amount = _calculateAmount();
//       _isLoading = false;
//     });
//   } catch (e) {
//     debugPrint("Error loading gym config: $e");
//     if (mounted) {
//       setState(() => _isLoading = false);
//       _showSnack('Failed to load payment details', Colors.redAccent);
//     }
//   }
// }

//   double _calculateAmount() {
//     switch (widget.plan) {
//       case '6 Months':
//         return widget.currentFee * 5.0;
//       case 'Yearly':
//         return widget.currentFee * 9.0;
//       default:
//         return widget.currentFee;
//     }
//   }

//   Future<void> _pickScreenshot() async {
//     final picker = ImagePicker();
//     final picked =
//         await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
//     if (picked != null) {
//       setState(() => _screenshotFile = File(picked.path));
//     }
//   }

//   Future<void> _submit() async {
//     if (_screenshotFile == null) {
//       _showSnack('Please upload your payment screenshot', Colors.orange);
//       return;
//     }

//     setState(() => _isSubmitting = true);

//     try {
//       final ref = FirebaseStorage.instance.ref().child(
//           'payment_screenshots/${widget.gymId}/$_referenceCode.jpg');
//       await ref.putFile(_screenshotFile!);
//       final screenshotUrl = await ref.getDownloadURL();

//       final paymentId = await _fs.createPayment(
//         gymId: widget.gymId,
//         memberId: widget.memberId,
//         amount: _amount,
//         plan: widget.plan,
//         referenceCode: _referenceCode,
//         screenshotUrl: screenshotUrl,
//       );

//       if (!mounted) return;

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => PaymentPendingScreen(
//             gymId: widget.gymId,
//             paymentId: paymentId,
//             referenceCode: _referenceCode,
//             amount: _amount,
//           ),
//         ),
//       );
//     } catch (e) {
//       if (mounted) _showSnack('Error: $e', Colors.redAccent);
//     } finally {
//       if (mounted) setState(() => _isSubmitting = false);
//     }
//   }

//   void _showSnack(String msg, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(msg),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating));
//   }

//   void _copyToClipboard(String text) {
//     Clipboard.setData(ClipboardData(text: text));
//     _showSnack('Copied!', Colors.green);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         title: const Text('PAY FEES',
//             style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: _isLoading
//           ? const Center(
//               child: CircularProgressIndicator(color: Colors.yellowAccent))
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _stepCard(
//                     step: '1',
//                     color: Colors.yellowAccent,
//                     title: 'Send Payment',
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text('Send exactly this amount to:',
//                             style:
//                                 TextStyle(color: Colors.white54, fontSize: 13)),
//                         const SizedBox(height: 16),
//                         _infoRow(_bankName, _easypaisaNumber, Colors.greenAccent, copyable: true),
//                         const SizedBox(height: 10),
//                         _infoRow('Account Name', _accountName, Colors.white70),
//                         const SizedBox(height: 10),
//                         _infoRow('Amount',
//                             'Rs ${_amount.toStringAsFixed(0)}', Colors.yellowAccent),
//                         const SizedBox(height: 16),
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(14),
//                           decoration: BoxDecoration(
//                             color: Colors.redAccent.withOpacity(0.07),
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                                 color: Colors.redAccent.withOpacity(0.2)),
//                           ),
//                           child: const Text(
//                             '⚠️  You MUST include the reference code in the remarks/description when sending',
//                             style:
//                                 TextStyle(color: Colors.white70, fontSize: 12),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _stepCard(
//                     step: '2',
//                     color: Colors.blueAccent,
//                     title: 'Use This Reference Code',
//                     child: Column(
//                       children: [
//                         GestureDetector(
//                           onTap: () => _copyToClipboard(_referenceCode),
//                           child: Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.all(18),
//                             decoration: BoxDecoration(
//                               color: Colors.blueAccent.withOpacity(0.08),
//                               borderRadius: BorderRadius.circular(14),
//                               border: Border.all(
//                                   color: Colors.blueAccent.withOpacity(0.3)),
//                             ),
//                             child: Row(
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     _referenceCode,
//                                     style: const TextStyle(
//                                       color: Colors.blueAccent,
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 15,
//                                       letterSpacing: 1.5,
//                                     ),
//                                   ),
//                                 ),
//                                 const Icon(Icons.copy_rounded,
//                                     color: Colors.blueAccent, size: 18),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         const Text(
//                           'Tap to copy. Paste this in the remarks field when sending money.',
//                           style:
//                               TextStyle(color: Colors.white38, fontSize: 12),
//                           textAlign: TextAlign.center,
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _stepCard(
//                     step: '3',
//                     color: Colors.purpleAccent,
//                     title: 'Upload Screenshot',
//                     child: Column(
//                       children: [
//                         GestureDetector(
//                           onTap: _pickScreenshot,
//                           child: Container(
//                             width: double.infinity,
//                             height: _screenshotFile != null ? null : 130,
//                             decoration: BoxDecoration(
//                               color: Colors.purpleAccent.withOpacity(0.06),
//                               borderRadius: BorderRadius.circular(14),
//                               border: Border.all(
//                                 color: _screenshotFile != null
//                                     ? Colors.purpleAccent.withOpacity(0.4)
//                                     : Colors.purpleAccent.withOpacity(0.2),
//                               ),
//                             ),
//                             child: _screenshotFile != null
//                                 ? ClipRRect(
//                                     borderRadius: BorderRadius.circular(14),
//                                     child: Image.file(_screenshotFile!,
//                                         fit: BoxFit.cover),
//                                   )
//                                 : const Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.upload_rounded,
//                                           color: Colors.purpleAccent, size: 36),
//                                       SizedBox(height: 10),
//                                       Text('Tap to upload screenshot',
//                                           style: TextStyle(
//                                               color: Colors.white54,
//                                               fontSize: 13)),
//                                     ],
//                                   ),
//                           ),
//                         ),
//                         if (_screenshotFile != null) ...[
//                           const SizedBox(height: 10),
//                           GestureDetector(
//                             onTap: _pickScreenshot,
//                             child: const Text('Change screenshot',
//                                 style: TextStyle(
//                                     color: Colors.purpleAccent, fontSize: 12)),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 58,
//                     child: ElevatedButton(
//                       onPressed: _isSubmitting ? null : _submit,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.yellowAccent,
//                         foregroundColor: Colors.black,
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16)),
//                         elevation: 0,
//                       ),
//                       child: _isSubmitting
//                           ? const SizedBox(
//                               width: 22,
//                               height: 22,
//                               child: CircularProgressIndicator(
//                                   color: Colors.black, strokeWidth: 2.5))
//                           : const Text('I HAVE PAID',
//                               style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 15,
//                                   letterSpacing: 1)),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _stepCard({
//     required String step,
//     required Color color,
//     required String title,
//     required Widget child,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.04),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: Colors.white.withOpacity(0.07)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 26,
//                 height: 26,
//                 decoration:
//                     BoxDecoration(color: color, shape: BoxShape.circle),
//                 child: Center(
//                   child: Text(step,
//                       style: const TextStyle(
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12)),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Text(title,
//                   style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14)),
//             ],
//           ),
//           const SizedBox(height: 18),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _infoRow(String label, String value, Color valueColor,
//       {bool copyable = false}) {
//     return Row(
//       children: [
//         Text('$label: ',
//             style: const TextStyle(color: Colors.white38, fontSize: 13)),
//         Expanded(
//           child: Text(value,
//               style: TextStyle(
//                   color: valueColor,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 13)),
//         ),
//         if (copyable)
//           GestureDetector(
//             onTap: () => _copyToClipboard(value),
//             child: const Icon(Icons.copy_rounded,
//                 color: Colors.white38, size: 16),
//           ),
//       ],
//     );
//   }
// }


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'payment_pending_screen.dart';

// ─────────────────────────────────────────────
// Model for a single deposit account
// Matches: gyms/{gymId}.depositAccounts[]
// ─────────────────────────────────────────────
class DepositAccount {
  final String accountTitle;
  final String accountNumber;
  final String bankName;
  final String accountType; // "Wallet (EP/JC)" | "Bank Account"

  const DepositAccount({
    required this.accountTitle,
    required this.accountNumber,
    required this.bankName,
    required this.accountType,
  });

  factory DepositAccount.fromMap(Map<String, dynamic> m) => DepositAccount(
        accountTitle: m['accountTitle'] ?? '',
        accountNumber: m['accountNumber'] ?? '',
        bankName: m['bankName'] ?? '',
        accountType: m['accountType'] ?? '',
      );

  /// Friendly icon emoji based on bank name
  String get icon {
    final b = bankName.toLowerCase();
    if (b.contains('easypaisa')) return '💚';
    if (b.contains('jazz'))     return '🔴';
    if (b.contains('meezan'))   return '🏦';
    if (b.contains('hbl'))      return '🏛️';
    if (b.contains('naya'))     return '💙';
    return '💳';
  }

  /// Accent color per bank
  Color get accentColor {
    final b = bankName.toLowerCase();
    if (b.contains('easypaisa')) return const Color(0xFF00C853);
    if (b.contains('jazz'))      return const Color(0xFFE53935);
    if (b.contains('meezan'))    return const Color(0xFF1565C0);
    if (b.contains('hbl'))       return const Color(0xFF6A1B9A);
    if (b.contains('naya'))      return const Color(0xFF0288D1);
    return const Color(0xFFFFD600);
  }
}

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────
class PayFeeScreen extends StatefulWidget {
  final String gymId;
  final String memberId;
  final String plan;
  final double currentFee;

  const PayFeeScreen({
    super.key,
    required this.gymId,
    required this.memberId,
    required this.plan,
    required this.currentFee,
  });

  @override
  State<PayFeeScreen> createState() => _PayFeeScreenState();
}

class _PayFeeScreenState extends State<PayFeeScreen>
    with TickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();

  // ── State ──
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<DepositAccount> _accounts = [];
  int _selectedAccountIndex = 0;
  double _amount = 0;
  late String _referenceCode;
  File? _screenshotFile;

  // ── Animation ──
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Colours / tokens ──
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF13131A);
  static const _border    = Color(0xFF1E1E2C);
  static const _accent    = Color(0xFFE8FE54); // lime-yellow
  static const _textHigh  = Color(0xFFF0F0F5);
  static const _textMid   = Color(0xFF8A8A9A);
  static const _textLow   = Color(0xFF3A3A4A);

  @override
  void initState() {
    super.initState();
    _referenceCode = _fs.generateReferenceCode(widget.gymId, widget.memberId);
    _amount = _calculateAmount();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _loadConfig();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('gyms')
          .doc(widget.gymId)
          .get();

      if (!doc.exists || !mounted) return;

      final data = doc.data() ?? {};
      final raw  = data['depositAccounts'] as List<dynamic>? ?? [];

      setState(() {
        _accounts = raw
            .map((e) => DepositAccount.fromMap(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });

      _fadeCtrl.forward();
    } catch (e) {
      debugPrint('PayFeeScreen._loadConfig error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Failed to load payment details', isError: true);
      }
    }
  }

  double _calculateAmount() {
    switch (widget.plan) {
      case '6 Months':
        return widget.currentFee * 5.0;
      case 'Yearly':
        return widget.currentFee * 9.0;
      default:
        return widget.currentFee;
    }
  }

  // ── Actions ───────────────────────────────────────────────

  Future<void> _pickScreenshot() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _screenshotFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (_screenshotFile == null) {
      _snack('Please upload your payment screenshot', isError: false);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final ref = FirebaseStorage.instance.ref().child(
          'payment_screenshots/${widget.gymId}/$_referenceCode.jpg');
      await ref.putFile(_screenshotFile!);
      final url = await ref.getDownloadURL();

      final paymentId = await _fs.createPayment(
        gymId: widget.gymId,
        memberId: widget.memberId,
        amount: _amount,
        plan: widget.plan,
        referenceCode: _referenceCode,
        screenshotUrl: url,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPendingScreen(
            gymId: widget.gymId,
            paymentId: paymentId,
            referenceCode: _referenceCode,
            amount: _amount,
          ),
        ),
      );
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _snack('$label copied!', isError: false);
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: isError ? const Color(0xFFB00020) : const Color(0xFF1C1C2A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: _accent, strokeWidth: 2))
          : FadeTransition(
              opacity: _fadeAnim,
              child: _accounts.isEmpty
                  ? _emptyState()
                  : _buildBody(),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textMid, size: 18),
        ),
        title: const Text(
          'PAY FEES',
          style: TextStyle(
            color: _textHigh,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      );

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: _surface, borderRadius: BorderRadius.circular(20)),
              child:
                  const Icon(Icons.account_balance_outlined, color: _textLow, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('No payment accounts configured',
                style: TextStyle(color: _textMid, fontSize: 14)),
            const SizedBox(height: 6),
            const Text('Contact your gym admin',
                style: TextStyle(color: _textLow, fontSize: 12)),
          ],
        ),
      );

  Widget _buildBody() {
    final selected = _accounts[_selectedAccountIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Amount hero ──
          _amountHero(),
          const SizedBox(height: 28),

          // ── Step 1: Choose account ──
          _stepLabel('01', 'SELECT ACCOUNT'),
          const SizedBox(height: 12),
          _accountSelector(),
          const SizedBox(height: 24),

          // ── Step 2: Account details ──
          _stepLabel('02', 'SEND TO'),
          const SizedBox(height: 12),
          _accountDetailsCard(selected),
          const SizedBox(height: 24),

          // ── Step 3: Reference code ──
          _stepLabel('03', 'USE REFERENCE CODE'),
          const SizedBox(height: 12),
          _referenceCard(),
          const SizedBox(height: 24),

          // ── Step 4: Screenshot ──
          _stepLabel('04', 'UPLOAD PROOF'),
          const SizedBox(height: 12),
          _screenshotCard(),
          const SizedBox(height: 32),

          // ── Submit ──
          _submitButton(),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────

  Widget _amountHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.plan.toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFF3A4000),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Rs ${_amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('DUE NOW',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _stepLabel(String num, String label) => Row(
        children: [
          Text(num,
              style: const TextStyle(
                  color: _accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: _textMid,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
        ],
      );

  /// Horizontal scrollable account chips
  Widget _accountSelector() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final acc     = _accounts[i];
          final isSelected = i == _selectedAccountIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedAccountIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? acc.accentColor.withOpacity(0.15)
                    : _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? acc.accentColor : _border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(acc.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(acc.bankName,
                          style: TextStyle(
                              color: isSelected ? _textHigh : _textMid,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(acc.accountType,
                      style: const TextStyle(
                          color: _textLow, fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _accountDetailsCard(DepositAccount acc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: acc.accentColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // Bank header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: acc.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(acc.icon,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(acc.bankName,
                      style: const TextStyle(
                          color: _textHigh,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text(acc.accountType,
                      style: const TextStyle(
                          color: _textMid, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _divider(),
          const SizedBox(height: 18),
          // Account number — large & copyable
          _detailRow(
            label: 'Account Number',
            value: acc.accountNumber,
            valueStyle: TextStyle(
                color: acc.accentColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 1.2),
            onCopy: () => _copy(acc.accountNumber, 'Account number'),
          ),
          const SizedBox(height: 14),
          _detailRow(
            label: 'Account Name',
            value: acc.accountTitle,
            valueStyle: const TextStyle(
                color: _textHigh,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          const SizedBox(height: 14),
          _detailRow(
            label: 'Amount',
            value: 'Rs ${_amount.toStringAsFixed(0)}',
            valueStyle: const TextStyle(
                color: _accent,
                fontWeight: FontWeight.w800,
                fontSize: 15),
          ),
          const SizedBox(height: 18),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.redAccent.withOpacity(0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.redAccent, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Include the reference code in remarks when sending',
                    style: TextStyle(
                        color: Color(0xFFFF8A80), fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceCard() {
    return GestureDetector(
      onTap: () => _copy(_referenceCode, 'Reference code'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _referenceCode,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.copy_rounded,
                      color: Colors.blueAccent, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to copy · Paste this in the remarks/description field',
              style: TextStyle(color: _textLow, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _screenshotCard() {
    return GestureDetector(
      onTap: _pickScreenshot,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        constraints:
            BoxConstraints(minHeight: _screenshotFile != null ? 0 : 130),
        decoration: BoxDecoration(
          color: _screenshotFile != null
              ? Colors.transparent
              : _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _screenshotFile != null
                ? Colors.purpleAccent.withOpacity(0.4)
                : _border,
          ),
        ),
        child: _screenshotFile != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child:
                        Image.file(_screenshotFile!, fit: BoxFit.cover,
                            width: double.infinity),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _pickScreenshot,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_rounded,
                                color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text('Change',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.upload_rounded,
                          color: Colors.purpleAccent, size: 26),
                    ),
                    const SizedBox(height: 12),
                    const Text('Tap to upload screenshot',
                        style: TextStyle(
                            color: _textMid,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('JPG, PNG accepted',
                        style:
                            TextStyle(color: _textLow, fontSize: 11)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _submitButton() => SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.black,
            disabledBackgroundColor: _accent.withOpacity(0.4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2.5))
              : const Text(
                  'I HAVE PAID',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 2),
                ),
        ),
      );

  // ── Helpers ───────────────────────────────────────────────

  Widget _divider() => Container(height: 1, color: _border);

  Widget _detailRow({
    required String label,
    required String value,
    required TextStyle valueStyle,
    VoidCallback? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: _textLow, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: valueStyle),
            ],
          ),
        ),
        if (onCopy != null)
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _textLow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.copy_rounded,
                  color: _textMid, size: 14),
            ),
          ),
      ],
    );
  }
}