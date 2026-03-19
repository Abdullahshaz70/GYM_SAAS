// import 'package:flutter/material.dart';
// import '../../user/screens/skeleton_loaders.dart';
// import 'member_tile.dart';

// class MemberListSection extends StatelessWidget {
//   const MemberListSection({
//     super.key,
//     required this.members,
//     required this.gymId,
//     required this.isLoading,
//     required this.activeFilter,
//     required this.searchController,
//     required this.onSearchChanged,
//     required this.onFilterChanged,
//   });

//   final List<Map<String, dynamic>> members;
//   final String gymId;
//   final bool isLoading;
//   final String activeFilter;
//   final TextEditingController searchController;
//   final ValueChanged<String> onSearchChanged;
//   final ValueChanged<String> onFilterChanged;

//   static const _filters = ['all', 'paid', 'unpaid', 'pending'];

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 24),
//         const Text(
//           'MEMBERS',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.w900,
//             letterSpacing: 1.2,
//           ),
//         ),
//         const Divider(color: Colors.white10, thickness: 1, height: 20),
//         const SizedBox(height: 12),
//         _SearchBar(
//           controller: searchController,
//           onChanged: onSearchChanged,
//         ),
//         const SizedBox(height: 18),
//         _FilterChips(
//           filters: _filters,
//           activeFilter: activeFilter,
//           onSelected: onFilterChanged,
//         ),
//         const SizedBox(height: 20),
//         _MemberListBody(
//           members: members,
//           gymId: gymId,
//           isLoading: isLoading,
//         ),
//       ],
//     );
//   }
// }

// class _SearchBar extends StatelessWidget {
//   const _SearchBar({required this.controller, required this.onChanged});

//   final TextEditingController controller;
//   final ValueChanged<String> onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       controller: controller,
//       onChanged: onChanged,
//       style: const TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         hintText: 'Search members...',
//         hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
//         prefixIcon:
//             const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
//         filled: true,
//         fillColor: Colors.white.withOpacity(0.05),
//         contentPadding: const EdgeInsets.symmetric(vertical: 12),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Colors.white10),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Colors.yellowAccent),
//         ),
//       ),
//     );
//   }
// }

// class _FilterChips extends StatelessWidget {
//   const _FilterChips({
//     required this.filters,
//     required this.activeFilter,
//     required this.onSelected,
//   });

//   final List<String> filters;
//   final String activeFilter;
//   final ValueChanged<String> onSelected;

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       physics: const BouncingScrollPhysics(),
//       child: Row(
//         children: filters.map((f) {
//           final isActive = activeFilter == f;
//           return Padding(
//             padding: const EdgeInsets.only(right: 10),
//             child: GestureDetector(
//               onTap: () => onSelected(f),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: isActive
//                       ? Colors.yellowAccent
//                       : Colors.white.withOpacity(0.05),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: isActive ? Colors.yellowAccent : Colors.white10,
//                   ),
//                   boxShadow: isActive
//                       ? [
//                           BoxShadow(
//                             color: Colors.yellowAccent.withOpacity(0.2),
//                             blurRadius: 8,
//                           )
//                         ]
//                       : [],
//                 ),
//                 child: Text(
//                   f[0].toUpperCase() + f.substring(1),
//                   style: TextStyle(
//                     color: isActive ? Colors.black : Colors.white70,
//                     fontSize: 14,
//                     fontWeight:
//                         isActive ? FontWeight.bold : FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

// class _MemberListBody extends StatelessWidget {
//   const _MemberListBody({
//     required this.members,
//     required this.gymId,
//     required this.isLoading,
//   });

//   final List<Map<String, dynamic>> members;
//   final String gymId;
//   final bool isLoading;

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) return const MemberListSkeleton();

//     if (members.isEmpty) {
//       return const Center(
//         child: Padding(
//           padding: EdgeInsets.all(40),
//           child: Text(
//             'No matches found',
//             style: TextStyle(color: Colors.white24),
//           ),
//         ),
//       );
//     }

//     return ListView.separated(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: members.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 12),
//       itemBuilder: (_, i) => MemberTile(member: members[i], gymId: gymId),
//     );
//   }
// }


import 'package:flutter/material.dart';
import '../../user/screens/skeleton_loaders.dart';
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
  });

  final List<Map<String, dynamic>> members;
  final String gymId;
  final bool isLoading;
  final String activeFilter;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;

  /// Pass the unfiltered total so the badge always shows the gym's full count.
  final int? totalCount;

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
        ),
      ],
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

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

// ─── Search bar ───────────────────────────────────────────────────────────────

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
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded,
            color: Colors.white38, size: 18),
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

// ─── Filter chips ─────────────────────────────────────────────────────────────

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

// ─── List body ────────────────────────────────────────────────────────────────

class _MemberListBody extends StatelessWidget {
  const _MemberListBody({
    required this.members,
    required this.gymId,
    required this.isLoading,
  });

  final List<Map<String, dynamic>> members;
  final String gymId;
  final bool isLoading;

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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => MemberTile(member: members[i], gymId: gymId),
    );
  }
}