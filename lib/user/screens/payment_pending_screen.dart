// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/firestore_service.dart';

// class PaymentPendingScreen extends StatelessWidget {
//   final String gymId;
//   final String paymentId;
//   final String referenceCode;
//   final double amount;

//   const PaymentPendingScreen({
//     super.key,
//     required this.gymId,
//     required this.paymentId,
//     required this.referenceCode,
//     required this.amount,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final FirestoreService fs = FirestoreService();

//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         title: const Text('PAYMENT STATUS',
//             style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
//       ),
//       body: StreamBuilder<DocumentSnapshot>(
//         stream: fs.watchPayment(gymId, paymentId),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(
//                 child:
//                     CircularProgressIndicator(color: Colors.yellowAccent));
//           }

//           final data = snapshot.data!.data() as Map<String, dynamic>?;
//           final status = data?['status'] ?? 'pending';

//           if (status == 'completed') {
//             return _buildVerified(context);
//           }

//           if (status == 'failed') {
//             return _buildFailed(context);
//           }

//           return _buildPending(context);
//         },
//       ),
//     );
//   }

//   Widget _buildPending(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         children: [
//           const SizedBox(height: 30),
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.orange.withOpacity(0.07),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.hourglass_top_rounded,
//                 color: Colors.orangeAccent, size: 52),
//           ),
//           const SizedBox(height: 24),
//           const Text('Verification Pending',
//               style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold)),
//           const SizedBox(height: 10),
//           const Text(
//             'Your payment screenshot has been submitted.\nOur team will verify it shortly.',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
//           ),
//           const SizedBox(height: 36),
//           _infoCard(
//             label: 'Amount Submitted',
//             value: 'Rs ${amount.toStringAsFixed(0)}',
//             color: Colors.yellowAccent,
//           ),
//           const SizedBox(height: 12),
//           _infoCard(
//             label: 'Reference Code',
//             value: referenceCode,
//             color: Colors.blueAccent,
//             copyable: true,
//             context: context,
//           ),
//           const SizedBox(height: 36),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.04),
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(color: Colors.white10),
//             ),
//             child: const Row(
//               children: [
//                 Icon(Icons.info_outline, color: Colors.white38, size: 18),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     'This page updates automatically once your payment is verified. You can also close it and check back later.',
//                     style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 30),
//           SizedBox(
//             width: double.infinity,
//             height: 54,
//             child: OutlinedButton(
//               onPressed: () =>
//                   Navigator.of(context).popUntil((route) => route.isFirst),
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Colors.white24),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14)),
//               ),
//               child: const Text('BACK TO HOME',
//                   style: TextStyle(
//                       color: Colors.white54,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: 1)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildVerified(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         children: [
//           const SizedBox(height: 30),
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.green.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.check_circle_rounded,
//                 color: Colors.greenAccent, size: 52),
//           ),
//           const SizedBox(height: 24),
//           const Text('Payment Verified!',
//               style: TextStyle(
//                   color: Colors.greenAccent,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold)),
//           const SizedBox(height: 10),
//           const Text(
//             'Your membership is now active.\nEnjoy your workouts!',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
//           ),
//           const SizedBox(height: 40),
//           SizedBox(
//             width: double.infinity,
//             height: 54,
//             child: ElevatedButton(
//               onPressed: () =>
//                   Navigator.of(context).popUntil((route) => route.isFirst),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.yellowAccent,
//                 foregroundColor: Colors.black,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14)),
//                 elevation: 0,
//               ),
//               child: const Text('GO TO HOME',
//                   style: TextStyle(
//                       fontWeight: FontWeight.bold, letterSpacing: 1)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFailed(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         children: [
//           const SizedBox(height: 30),
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.red.withOpacity(0.08),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.cancel_rounded,
//                 color: Colors.redAccent, size: 52),
//           ),
//           const SizedBox(height: 24),
//           const Text('Payment Rejected',
//               style: TextStyle(
//                   color: Colors.redAccent,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold)),
//           const SizedBox(height: 10),
//           const Text(
//             'Your payment could not be verified.\nPlease contact support or try again.',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
//           ),
//           const SizedBox(height: 40),
//           SizedBox(
//             width: double.infinity,
//             height: 54,
//             child: ElevatedButton(
//               onPressed: () =>
//                   Navigator.of(context).popUntil((route) => route.isFirst),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.yellowAccent,
//                 foregroundColor: Colors.black,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14)),
//                 elevation: 0,
//               ),
//               child: const Text('TRY AGAIN',
//                   style: TextStyle(
//                       fontWeight: FontWeight.bold, letterSpacing: 1)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _infoCard({
//     required String label,
//     required String value,
//     required Color color,
//     bool copyable = false,
//     BuildContext? context,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.06),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(label,
//                     style: const TextStyle(
//                         color: Colors.white38, fontSize: 11)),
//                 const SizedBox(height: 4),
//                 Text(value,
//                     style: TextStyle(
//                         color: color,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                         letterSpacing: 1)),
//               ],
//             ),
//           ),
//           if (copyable && context != null)
//             GestureDetector(
//               onTap: () {
//                 Clipboard.setData(ClipboardData(text: value));
//                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                     content: Text('Copied!'),
//                     behavior: SnackBarBehavior.floating));
//               },
//               child: const Icon(Icons.copy_rounded,
//                   color: Colors.white38, size: 18),
//             ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class PaymentPendingScreen extends StatefulWidget {
  final String gymId;
  final String paymentId;
  final String referenceCode;
  final double amount;

  const PaymentPendingScreen({
    super.key,
    required this.gymId,
    required this.paymentId,
    required this.referenceCode,
    required this.amount,
  });

  @override
  State<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends State<PaymentPendingScreen>
    with TickerProviderStateMixin {
  // ── Design tokens (mirror PayFeeScreen) ──────────────────
  static const _bg       = Color(0xFF0A0A0F);
  static const _surface  = Color(0xFF13131A);
  static const _border   = Color(0xFF1E1E2C);
  static const _accent   = Color(0xFFE8FE54); // lime-yellow
  static const _textHigh = Color(0xFFF0F0F5);
  static const _textMid  = Color(0xFF8A8A9A);
  static const _textLow  = Color(0xFF3A3A4A);

  // ── Animations ──────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Copied to clipboard',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: _surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _goHome() => Navigator.of(context).popUntil((r) => r.isFirst);

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final FirestoreService fs = FirestoreService();

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: fs.watchPayment(widget.gymId, widget.paymentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                  color: _accent, strokeWidth: 2),
            );
          }

          final data   = snapshot.data!.data() as Map<String, dynamic>?;
          final status = data?['status'] ?? 'pending';

          return FadeTransition(
            opacity: _fadeAnim,
            child: switch (status) {
              'completed' => _StatusView(
                  icon: Icons.check_rounded,
                  iconColor: const Color(0xFF00E676),
                  ringColor: const Color(0xFF00E676),
                  label: 'Payment Verified',
                  sublabel: 'Your membership is now active.\nEnjoy your workouts!',
                  amount: widget.amount,
                  referenceCode: widget.referenceCode,
                  onCopy: _copy,
                  primaryAction: _PrimaryAction(
                    label: 'GO TO HOME',
                    onTap: _goHome,
                    color: _accent,
                    textColor: Colors.black,
                  ),
                  pulseAnim: null,
                  statusChipLabel: 'VERIFIED',
                  statusChipColor: const Color(0xFF00E676),
                ),
              'failed' => _StatusView(
                  icon: Icons.close_rounded,
                  iconColor: const Color(0xFFFF5252),
                  ringColor: const Color(0xFFFF5252),
                  label: 'Payment Rejected',
                  sublabel: 'We couldn\'t verify your payment.\nContact your gym admin or try again.',
                  amount: widget.amount,
                  referenceCode: widget.referenceCode,
                  onCopy: _copy,
                  primaryAction: _PrimaryAction(
                    label: 'TRY AGAIN',
                    onTap: _goHome,
                    color: const Color(0xFFFF5252),
                    textColor: Colors.white,
                  ),
                  pulseAnim: null,
                  statusChipLabel: 'REJECTED',
                  statusChipColor: const Color(0xFFFF5252),
                ),
              _ => _StatusView(
                  icon: Icons.hourglass_top_rounded,
                  iconColor: const Color(0xFFFFB300),
                  ringColor: const Color(0xFFFFB300),
                  label: 'Awaiting Verification',
                  sublabel: 'Your screenshot has been submitted.\nWe\'ll notify you once it\'s reviewed.',
                  amount: widget.amount,
                  referenceCode: widget.referenceCode,
                  onCopy: _copy,
                  primaryAction: _PrimaryAction(
                    label: 'BACK TO HOME',
                    onTap: _goHome,
                    color: _surface,
                    textColor: _textMid,
                    outlined: true,
                  ),
                  pulseAnim: _pulseAnim,
                  statusChipLabel: 'PENDING',
                  statusChipColor: const Color(0xFFFFB300),
                ),
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'PAYMENT STATUS',
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
}

// ─────────────────────────────────────────────────────────────
// Reusable status view — handles all three states
// ─────────────────────────────────────────────────────────────
class _PrimaryAction {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final bool outlined;

  const _PrimaryAction({
    required this.label,
    required this.onTap,
    required this.color,
    required this.textColor,
    this.outlined = false,
  });
}

class _StatusView extends StatelessWidget {
  static const _bg      = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF13131A);
  static const _border  = Color(0xFF1E1E2C);
  static const _textMid = Color(0xFF8A8A9A);
  static const _textLow = Color(0xFF3A3A4A);

  final IconData icon;
  final Color iconColor;
  final Color ringColor;
  final String label;
  final String sublabel;
  final double amount;
  final String referenceCode;
  final void Function(String) onCopy;
  final _PrimaryAction primaryAction;
  final Animation<double>? pulseAnim;
  final String statusChipLabel;
  final Color statusChipColor;

  const _StatusView({
    required this.icon,
    required this.iconColor,
    required this.ringColor,
    required this.label,
    required this.sublabel,
    required this.amount,
    required this.referenceCode,
    required this.onCopy,
    required this.primaryAction,
    required this.pulseAnim,
    required this.statusChipLabel,
    required this.statusChipColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon with optional pulse ──
          _buildIconRing(),
          const SizedBox(height: 24),

          // ── Status chip ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: statusChipColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusChipColor.withOpacity(0.3)),
            ),
            child: Text(
              statusChipLabel,
              style: TextStyle(
                color: statusChipColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Title ──
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF0F0F5),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // ── Subtitle ──
          Text(
            sublabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textMid,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),

          // ── Amount card ──
          _amountCard(),
          const SizedBox(height: 12),

          // ── Reference card ──
          _referenceCard(),
          const SizedBox(height: 24),

          // ── Auto-update note (pending only) ──
          if (pulseAnim != null) ...[
            _autoUpdateNote(),
            const SizedBox(height: 28),
          ],

          // ── Primary CTA ──
          _ctaButton(),
        ],
      ),
    );
  }

  Widget _buildIconRing() {
    final Widget ring = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor.withOpacity(0.08),
        border: Border.all(color: ringColor.withOpacity(0.2), width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ringColor.withOpacity(0.15),
          ),
          child: Icon(icon, color: iconColor, size: 32),
        ),
      ),
    );

    if (pulseAnim != null) {
      return ScaleTransition(scale: pulseAnim!, child: ring);
    }
    return ring;
  }

  Widget _amountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AMOUNT SUBMITTED',
                    style: TextStyle(
                        color: _textLow,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text(
                  'Rs ${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFE8FE54),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8FE54).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments_rounded,
                color: Color(0xFFE8FE54), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _referenceCard() {
    return GestureDetector(
      onTap: () => onCopy(referenceCode),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('REFERENCE CODE',
                      style: TextStyle(
                          color: _textLow,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text(
                    referenceCode,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
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
      ),
    );
  }

  Widget _autoUpdateNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: const Row(
        children: [
          Icon(Icons.sync_rounded, color: _textLow, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This page updates automatically. You can also close it and check back later.',
              style: TextStyle(
                  color: _textMid, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctaButton() {
    if (primaryAction.outlined) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: primaryAction.onTap,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF2A2A38), width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            primaryAction.label,
            style: TextStyle(
              color: primaryAction.textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: primaryAction.onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAction.color,
          foregroundColor: primaryAction.textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          primaryAction.label,
          style: TextStyle(
            color: primaryAction.textColor,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}