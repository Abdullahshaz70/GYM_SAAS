// member_tile.dart
import 'package:flutter/material.dart';
import '../member_detail.dart';

class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    required this.gymId,
    this.isReadOnly = false,
  });

  final Map<String, dynamic> member;
  final String gymId;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final status =
        (member['feeStatus'] ?? 'unpaid').toString().toLowerCase();
    final statusColor = switch (status) {
      'paid' => Colors.greenAccent,
      'pending' => Colors.orangeAccent,
      _ => Colors.redAccent,
    };

    return GestureDetector(
      // ✅ null disables tap entirely in read-only mode
      onTap: isReadOnly
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemberDetailScreen(
                    uid: member['uid'] ?? '',
                    gymId: gymId,
                  ),
                ),
              ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          // Slightly dimmer in read-only to hint non-interactivity
          color: isReadOnly
              ? Colors.white.withOpacity(0.02)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            _Avatar(name: member['name'] ?? 'G', statusColor: statusColor),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member['name'] ?? 'New Member',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member['plan'] ?? 'Monthly',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            _StatusBadge(status: status, color: statusColor),
            const SizedBox(width: 6),
            // Hide chevron in read-only — nothing to navigate to
            if (!isReadOnly)
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.statusColor});

  final String name;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: statusColor, width: 2),
          ),
        ),
        CircleAvatar(
          radius: 19,
          backgroundColor: Colors.yellowAccent.withOpacity(0.1),
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.yellowAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}