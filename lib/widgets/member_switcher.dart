import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/family_provider.dart';

class MemberSwitcher extends ConsumerWidget {
  const MemberSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersProvider);
    final activeId = ref.watch(activeMemberIdProvider);

    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: members.length + 1,
        itemBuilder: (context, index) {
          if (index == members.length) {
            return GestureDetector(
              onTap: () => context.push('/dashboard/family'),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: const Color(0xFF00685F).withOpacity(0.3), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Color(0xFF00685F)),
                    SizedBox(width: 4),
                    Text(
                      'Add Member',
                      style: TextStyle(
                        color: Color(0xFF00685F),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final member = members[index];
          final isActive = member.id == activeId;
          final initials = member.name.isNotEmpty ? member.name[0].toUpperCase() : '?';
          final firstName = member.name.split(' ')[0];
          final rel = member.relationship.isNotEmpty ? member.relationship : '';

          return GestureDetector(
            onTap: () {
              ref.read(activeMemberIdProvider.notifier).state = member.id;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF00685F) : Colors.white,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: isActive ? const Color(0xFF00685F) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00685F).withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [
                        const BoxShadow(
                          color: Color(0x080F172A),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        )
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? const Color(0xFF89F5E7) : const Color(0xFFCCFBF1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: isActive ? const Color(0xFF00201D) : const Color(0xFF006F67),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName,
                        style: TextStyle(
                          color: isActive ? Colors.white : const Color(0xFF121C2A),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (rel.isNotEmpty)
                        Text(
                          '$rel, ${member.age}',
                          style: TextStyle(
                            color: isActive ? Colors.white.withOpacity(0.8) : const Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF89F5E7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
