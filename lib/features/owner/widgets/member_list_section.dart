import 'package:flutter/material.dart';
import '../../../shared/skeleton_loaders.dart';
import 'member_tile.dart';

class MemberListSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _SectionHeader(count: totalCount),
        const SizedBox(height: 14),
        _SearchBar(
          controller: searchController,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        _FilterChips(
          filters: _filters,
          activeFilter: activeFilter,
          onSelected: onFilterChanged,
        ),
        const SizedBox(height: 16),
        _MemberListBody(
          members: members,
          gymId: gymId,
          isLoading: isLoading,
          hasMore: hasMore,
          isLoadingMore: isLoadingMore,
          onLoadMore: onLoadMore,
          isReadOnly: isReadOnly,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'MEMBERS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search members...',
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
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.yellowAccent
                      : const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? Colors.yellowAccent
                        : Colors.white.withOpacity(0.07),
                  ),
                ),
                child: Text(
                  f[0].toUpperCase() + f.substring(1),
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.white54,
                    fontSize: 13,
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

class _MemberListBody extends StatelessWidget {
  const _MemberListBody({
    required this.members,
    required this.gymId,
    required this.isLoading,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.isReadOnly = false,  // ✅ correct parameter syntax
  });

  final List<Map<String, dynamic>> members;
  final String gymId;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const MemberListSkeleton();

    if (members.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Text(
            'No members found',
            style: TextStyle(color: Colors.white24, fontSize: 14),
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
                child:
                    CircularProgressIndicator(color: Colors.yellowAccent),
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