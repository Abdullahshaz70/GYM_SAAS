import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A single shimmer "box" — reusable building block for all skeletons.
Widget skeletonBox({
  double? width,
  double height = 16,
  double radius = 8,
}) {
  return Shimmer.fromColors(
    baseColor: Colors.white10,
    highlightColor: Colors.white24,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

/// ─────────────────────────────────────────────
///  GymUser home screen skeleton
/// ─────────────────────────────────────────────
class GymUserSkeleton extends StatelessWidget {
  const GymUserSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Welcome back," + name
          skeletonBox(width: 100, height: 14),
          const SizedBox(height: 8),
          skeletonBox(width: 220, height: 32),
          const SizedBox(height: 25),

          // Stats tiles row
          Row(
            children: [
              Expanded(child: _statsTileSkeleton()),
              const SizedBox(width: 15),
              Expanded(child: _statsTileSkeleton()),
            ],
          ),
          const SizedBox(height: 20),

          // Payment card
          _paymentCardSkeleton(),
          const SizedBox(height: 30),

          // Section header
          skeletonBox(width: 160, height: 14),
          const SizedBox(height: 15),

          // Calendar placeholder
          _calendarSkeleton(),
        ],
      ),
    );
  }

  Widget _statsTileSkeleton() => Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );

  Widget _paymentCardSkeleton() => Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      );

  Widget _calendarSkeleton() => Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
}

/// ─────────────────────────────────────────────
///  MemberDetail screen skeleton
/// ─────────────────────────────────────────────
class MemberDetailSkeleton extends StatelessWidget {
  const MemberDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Avatar + name + badge
          _profileHeaderSkeleton(),
          const SizedBox(height: 25),
          // Action row (call / whatsapp circles)
          _actionRowSkeleton(),
          const SizedBox(height: 30),
          // Nav tiles
          _navTileSkeleton(),
          const SizedBox(height: 12),
          _navTileSkeleton(),
          const SizedBox(height: 25),
          // Section header
          Align(
              alignment: Alignment.centerLeft,
              child: skeletonBox(width: 140, height: 11)),
          const SizedBox(height: 12),
          // 3 membership list tiles
          _membershipTileSkeleton(),
          _membershipTileSkeleton(),
          _membershipTileSkeleton(),
          const SizedBox(height: 25),
          // Section header
          Align(
              alignment: Alignment.centerLeft,
              child: skeletonBox(width: 160, height: 11)),
          const SizedBox(height: 12),
          // 3 fee tiles
          _feeTileSkeleton(),
          _feeTileSkeleton(),
          _feeTileSkeleton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _profileHeaderSkeleton() => Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: Column(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                  color: Colors.white10, shape: BoxShape.circle),
            ),
            const SizedBox(height: 15),
            Container(
                width: 160, height: 22, color: Colors.white10,
                margin: const EdgeInsets.only(bottom: 8)),
            Container(
                width: 80, height: 24,
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20))),
          ],
        ),
      );

  Widget _actionRowSkeleton() => Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circle(54),
            const SizedBox(width: 40),
            _circle(54),
          ],
        ),
      );

  Widget _circle(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            color: Colors.white10, shape: BoxShape.circle),
      );

  Widget _navTileSkeleton() => Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: Container(
          height: 56,
          margin: const EdgeInsets.only(bottom: 0),
          decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16)),
        ),
      );

  Widget _membershipTileSkeleton() => Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: Container(
          height: 54,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(15)),
        ),
      );

  Widget _feeTileSkeleton() => Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: Container(
          height: 60,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16)),
        ),
      );
}

/// ─────────────────────────────────────────────
///  PaymentHistory list skeleton
/// ─────────────────────────────────────────────
class PaymentHistorySkeleton extends StatelessWidget {
  const PaymentHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: Container(
          height: 70,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
///  GymOwner full-screen skeleton
///  (mirrors: attendance card, 2 stat cards,
///   search bar, member tiles)
/// ─────────────────────────────────────────────
class GymOwnerSkeleton extends StatelessWidget {
  const GymOwnerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance status card
          _shimmerBox(height: 90, radius: 15),
          const SizedBox(height: 25),

          // Revenue + Members stat cards
          Row(
            children: [
              Expanded(child: _shimmerBox(height: 110, radius: 15)),
              const SizedBox(width: 15),
              Expanded(child: _shimmerBox(height: 110, radius: 15)),
            ],
          ),
          const SizedBox(height: 30),

          // "MANAGE MEMBERS" header
          skeletonBox(width: 150, height: 13),
          const SizedBox(height: 15),

          // Search bar
          _shimmerBox(height: 52, radius: 12),
          const SizedBox(height: 20),

          // Member tiles × 5
          for (int i = 0; i < 5; i++) ...[
            _memberTileSkeleton(),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _shimmerBox({required double height, double radius = 8}) =>
      Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );

  Widget _memberTileSkeleton() => Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: Container(
          height: 70,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Avatar circle
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                    color: Colors.white24, shape: BoxShape.circle),
              ),
              const SizedBox(width: 15),
              // Name bar
              Expanded(
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 15),
              // Badge pill
              Container(
                width: 55,
                height: 24,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10)),
              ),
            ],
          ),
        ),
      );
}

/// ─────────────────────────────────────────────
///  Member list inline skeleton
///  (used while loadingMembers == true)
/// ─────────────────────────────────────────────
class MemberListSkeleton extends StatelessWidget {
  const MemberListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (_) => Shimmer.fromColors(
          baseColor: Colors.white10,
          highlightColor: Colors.white24,
          child: Container(
            height: 70,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                      color: Colors.white24, shape: BoxShape.circle),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 15),
                Container(
                  width: 55,
                  height: 24,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
///  AttendanceScreen skeleton  (calendar + list)
/// ─────────────────────────────────────────────
class AttendanceScreenSkeleton extends StatelessWidget {
  const AttendanceScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Calendar block
        Shimmer.fromColors(
          baseColor: Colors.white10,
          highlightColor: Colors.white24,
          child: Container(
            margin: const EdgeInsets.all(10),
            height: 340,
            decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20)),
          ),
        ),
        const Divider(color: Colors.white10),
        // List items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            itemBuilder: (_, __) => Shimmer.fromColors(
              baseColor: Colors.white10,
              highlightColor: Colors.white24,
              child: Container(
                height: 54,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}