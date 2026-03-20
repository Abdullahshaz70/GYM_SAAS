import 'package:flutter/material.dart';

class ActionMenuSheet extends StatelessWidget {
  const ActionMenuSheet({
    super.key,
    required this.gymName,
    required this.isLoggingOut,
    required this.onRegistrationQrTap,
    required this.onStaffManagerTap,
    required this.onLogoutTap,
  });

  final String gymName;
  final bool isLoggingOut;
  final VoidCallback onRegistrationQrTap;
  final VoidCallback onStaffManagerTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E1E)),
          left: BorderSide(color: Color(0xFF1E1E1E)),
          right: BorderSide(color: Color(0xFF1E1E1E)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 20),

          // Gym identity header
          _GymHeader(gymName: gymName),

          const SizedBox(height: 8),

          // Actions
          _SheetItem(
            icon: Icons.qr_code_2_rounded,
            iconColor: Colors.yellowAccent,
            label: 'Registration QR',
            subtitle: 'Share to onboard new members',
            onTap: () {
              Navigator.pop(context);
              onRegistrationQrTap();
            },
          ),
          _SheetItem(
            icon: Icons.group_rounded,
            iconColor: const Color(0xFF60a5fa),
            label: 'Staff manager',
            subtitle: 'Manage roles and access',
            onTap: () {
              Navigator.pop(context);
              onStaffManagerTap();
            },
          ),

          const _SheetDivider(),

          // Logout
          _LogoutItem(
            isLoading: isLoggingOut,
            onTap: () {
              Navigator.pop(context);
              onLogoutTap();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Gym header ───────────────────────────────────────────────────────────────

class _GymHeader extends StatelessWidget {
  const _GymHeader({required this.gymName});

  final String gymName;

  String get _initials {
    final words = gymName.trim().split(RegExp(r'\s+'));
    if (words.length == 1) return gymName.substring(0, 2).toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF181818))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.yellowAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gymName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Owner · Active',
                style: TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Menu item ────────────────────────────────────────────────────────────────

class _SheetItem extends StatelessWidget {
  const _SheetItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF333333), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _SheetDivider extends StatelessWidget {
  const _SheetDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: const Color(0xFF181818),
    );
  }
}

// ─── Logout ───────────────────────────────────────────────────────────────────

class _LogoutItem extends StatelessWidget {
  const _LogoutItem({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.redAccent.withOpacity(0.08),
        highlightColor: Colors.redAccent.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: Colors.redAccent,
                        ),
                      )
                    : const Icon(Icons.logout_rounded,
                        color: Colors.redAccent, size: 18),
              ),
              const SizedBox(width: 14),
              const Text(
                'Log out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}