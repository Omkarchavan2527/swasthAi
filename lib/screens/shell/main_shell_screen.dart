import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/settings_provider.dart';

class MainShellScreen extends ConsumerWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard/home');
        break;
      case 1:
        context.go('/dashboard/assistant');
        break;
      case 2:
        context.go('/dashboard/records');
        break;
      case 3:
        context.go('/dashboard/medicines');
        break;
      case 4:
        _showMoreMenu(context);
        break;
    }
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final lang = ref.watch(languageProvider);
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.72,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.grid_view, color: Color(0xFF00685F), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          AppTranslations.tr(lang, 'allModules'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF121C2A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppTranslations.tr(lang, 'modulesSubtitle'),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _MenuIcon(
                            icon: Icons.family_restroom,
                            label: AppTranslations.tr(lang, 'familyTitle'),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/dashboard/family');
                            },
                          ),
                          _MenuIcon(
                            icon: Icons.trending_up,
                            label: AppTranslations.tr(lang, 'trendsTitle'),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/dashboard/trends');
                            },
                          ),
                          _MenuIcon(
                            icon: Icons.vaccines,
                            label: AppTranslations.tr(lang, 'vaccinesTitle'),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/dashboard/vaccinations');
                            },
                          ),
                          _MenuIcon(
                            icon: Icons.bloodtype,
                            label: AppTranslations.tr(lang, 'bloodTitle'),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/dashboard/blood');
                            },
                          ),
                          _MenuIcon(
                            icon: Icons.local_hospital,
                            label: AppTranslations.tr(lang, 'hospitalsTitle'),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/dashboard/hospitals');
                            },
                          ),
                          _MenuIcon(
                            icon: Icons.emergency,
                            label: AppTranslations.tr(lang, 'emergencyTitle'),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/dashboard/emergency');
                            },
                          ),
                          _MenuIcon(
                            icon: Icons.qr_code,
                            label: AppTranslations.tr(lang, 'doctorAccessTitle'),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/dashboard/doctor-access');
                            },
                          ),
                          _MenuIcon(
                            icon: Icons.pregnant_woman,
                            label: AppTranslations.tr(lang, 'maternalTitle'),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/dashboard/maternal');
                            },
                          ),
                          _MenuIcon(
                            icon: Icons.restaurant,
                            label: AppTranslations.tr(lang, 'nutritionTitle'),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/dashboard/nutrition');
                            },
                          ),
                          _MenuIcon(
                            icon: Icons.calculate,
                            label: AppTranslations.tr(lang, 'calculatorsTitle'),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/dashboard/calculators');
                            },
                          ),
                          _MenuIcon(
                            icon: Icons.notifications,
                            label: AppTranslations.tr(lang, 'actionAlerts'),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/dashboard/notifications');
                            },
                          ),
                          _MenuIcon(
                            icon: Icons.settings,
                            label: AppTranslations.tr(lang, 'settingsTitle'),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/dashboard/settings');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard/home')) return 0;
    if (location.startsWith('/dashboard/assistant')) return 1;
    if (location.startsWith('/dashboard/records')) return 2;
    if (location.startsWith('/dashboard/medicines')) return 3;
    return 0; // Default to Home if in 'More' sections
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIdx = _calculateSelectedIndex(context);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavTab(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: AppTranslations.tr(lang, 'navHome'),
                  isSelected: selectedIdx == 0,
                  onTap: () => _onItemTapped(0, context),
                ),
                _NavTab(
                  icon: Icons.smart_toy_outlined,
                  activeIcon: Icons.smart_toy,
                  label: AppTranslations.tr(lang, 'navAiChat'),
                  isSelected: selectedIdx == 1,
                  onTap: () => _onItemTapped(1, context),
                ),
                _NavTab(
                  icon: Icons.folder_shared_outlined,
                  activeIcon: Icons.folder_shared,
                  label: AppTranslations.tr(lang, 'navRecords'),
                  isSelected: selectedIdx == 2,
                  onTap: () => _onItemTapped(2, context),
                ),
                _NavTab(
                  icon: Icons.medication_outlined,
                  activeIcon: Icons.medication,
                  label: AppTranslations.tr(lang, 'navMedicines'),
                  isSelected: selectedIdx == 3,
                  onTap: () => _onItemTapped(3, context),
                ),
                _NavTab(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view,
                  label: AppTranslations.tr(lang, 'navMore'),
                  isSelected: false,
                  onTap: () => _onItemTapped(4, context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF00685F);
    const inactiveColor = Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuIcon({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFCCFBF1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: const Color(0xFF00685F)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF121C2A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
