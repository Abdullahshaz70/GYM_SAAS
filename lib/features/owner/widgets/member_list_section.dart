import 'package:flutter/material.dart';
import '../../../shared/skeleton_loaders.dart';
import 'member_tile.dart';

class MemberListSection extends StatefulWidget {
  const MemberListSection({
    super.key,
    required this.members,
    required this.gymId,
    required this.isLoading,
    required this.activeFilter,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterChanged,
    this.totalCount,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.isReadOnly = false,
  });

  final List<Map<String, dynamic>> members;
  final String gymId;
  final bool isLoading;
  final String activeFilter;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final int? totalCount;
  final bool isReadOnly;

  static const _filters = ['all', 'paid', 'unpaid', 'pending'];

  @override
  State<MemberListSection> createState() => _MemberListSectionState();
}

class _MemberListSectionState extends State<MemberListSection> {
  int _tabIndex = 0; // 0 = Active, 1 = Former

  @override
  Widget build(BuildContext context) {
    final activeMembers =
        widget.members.where((m) => m['isDeleted'] != true).toList();
    final formerMembers =
        widget.members.where((m) => m['isDeleted'] == true).toList();
    final displayMembers = _tabIndex == 0 ? activeMembers : formerMembers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // ── Tab header ──────────────────────────────────────────────────────
        Row(
          children: [
            _TabPill(
              label: 'ACTIVE',
              count: activeMembers.length,
              selected: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
            const SizedBox(width: 8),
            _TabPill(
              label: 'FORMER',
              count: formerMembers.length,
              selected: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Search ──────────────────────────────────────────────────────────
        _SearchBar(
          controller: widget.searchController,
          onChanged: widget.onSearchChanged,
          hint: _tabIndex == 0
              ? 'Search active members...'
              : 'Search former members...',
        ),
        const SizedBox(height: 12),

        // ── Fee filter chips — active tab only ──────────────────────────────
        if (_tabIndex == 0) ...[
          _FilterChips(
            filters: MemberListSection._filters,
            activeFilter: widget.activeFilter,
            onSelected: widget.onFilterChanged,
          ),
          const SizedBox(height: 16),
        ] else ...[
          const SizedBox(height: 4),
        ],

        // ── List ────────────────────────────────────────────────────────────
        _MemberListBody(
          members: displayMembers,
          gymId: widget.gymId,
          isLoading: widget.isLoading,
          hasMore: _tabIndex == 0 ? widget.hasMore : false,
          isLoadingMore: _tabIndex == 0 ? widget.isLoadingMore : false,
          onLoadMore: _tabIndex == 0 ? widget.onLoadMore : null,
          isReadOnly: widget.isReadOnly,
          isFormerTab: _tabIndex == 1,
        ),
      ],
    );
  }
}

// ── Tab pill ────────────────────────────────────────────────────────────────
class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.yellowAccent : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? Colors.yellowAccent
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.black.withOpacity(0.15)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search bar ──────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    this.hint = 'Search members...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
        prefixIcon:
            const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
        filled: true,
        fillColor: const Color(0xFF141414),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.yellowAccent),
        ),
      ),
    );
  }
}

// ── Filter chips ────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.activeFilter,
    required this.onSelected,
  });

  final List<String> filters;
  final String activeFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isActive = activeFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.yellowAccent.withOpacity(0.12)
                      : const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? Colors.yellowAccent.withOpacity(0.5)
                        : Colors.white.withOpacity(0.07),
                  ),
                ),
                child: Text(
                  f[0].toUpperCase() + f.substring(1),
                  style: TextStyle(
                    color: isActive ? Colors.yellowAccent : Colors.white54,
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Member list body ─────────────────────────────────────────────────────────
class _MemberListBody extends StatelessWidget {
  const _MemberListBody({
    required this.members,
    required this.gymId,
    required this.isLoading,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.isReadOnly = false,
    this.isFormerTab = false,
  });

  final List<Map<String, dynamic>> members;
  final String gymId;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final bool isReadOnly;
  final bool isFormerTab;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const MemberListSkeleton();

    if (members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFormerTab
                    ? Icons.person_off_rounded
                    : Icons.people_alt_rounded,
                color: Colors.white12,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                isFormerTab ? 'No former members' : 'No members found',
                style:
                    const TextStyle(color: Colors.white24, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 100 && hasMore) {
          onLoadMore?.call();
        }
        return false;
      },
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: members.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          if (i == members.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: Colors.yellowAccent),
              ),
            );
          }
          return MemberTile(
            member: members[i],
            gymId: gymId,
            isReadOnly: isReadOnly,
          );
        },
      ),
    );
  }
}
