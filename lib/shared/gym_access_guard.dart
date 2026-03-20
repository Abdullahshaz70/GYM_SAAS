import 'package:flutter/material.dart';
import 'gym_status_service.dart';

class GymAccessGuard extends StatelessWidget {
  final String role;          // 'owner' | 'staff' | 'member'
  final GymStatusResult status;
  final Widget child;

  const GymAccessGuard({
    super.key,
    required this.role,
    required this.status,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Full lockout: everyone sees the blocked screen
    if (status.access == GymAccessLevel.locked) {
      return _LockedScreen(message: status.message, icon: Icons.lock_outline);
    }

    // readOnly: members still get normal access, owners/staff see a banner
    // but cannot perform write actions (buttons disabled via _isReadOnly flag)
    if (status.access == GymAccessLevel.readOnly && role != 'member') {
      return _ReadOnlyWrapper(message: status.message, child: child);
    }

    return child;
  }
}

// ─── Full lockout screen ───────────────────────────────────────────────────
class _LockedScreen extends StatelessWidget {
  final String message;
  final IconData icon;
  const _LockedScreen({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    color: Colors.redAccent, size: 36),
              ),
              const SizedBox(height: 24),
              const Text('Access Restricted',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 14, height: 1.5)),
              const SizedBox(height: 32),
              const Text('Please contact your gym administrator.',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Read-only banner wrapper (owner/staff) ────────────────────────────────
class _ReadOnlyWrapper extends StatelessWidget {
  final String message;
  final Widget child;
  const _ReadOnlyWrapper({required this.message, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0, left: 0, right: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.orangeAccent.withOpacity(0.92),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.black, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(message,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}