import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../calendar/screens/schedule_room_list_screen.dart';
import '../../settings/screens/profile_settings_screen.dart';
import '../providers/main_tab_provider.dart';
import '../widgets/notification_center_modal.dart';
import 'dashboard_screen.dart';

/// 메인 셸 — 홈/대시보드(칩 데이), 캘린더, 모임, 프로필 & 설정 4대 코어 탭을 제공하는 메인 네비게이션 셸.
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  static const List<_TabSpec> _tabs = [
    _TabSpec(
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.grid_view_rounded,
      label: '칩 데이',
    ),
    _TabSpec(
      icon: Icons.calendar_month_rounded,
      activeIcon: Icons.calendar_month_rounded,
      label: '칩 캘린더',
    ),
    _TabSpec(
      icon: Icons.people_alt_rounded,
      activeIcon: Icons.people_alt_rounded,
      label: '칩 모임',
    ),
    _TabSpec(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: '프로필 & 설정',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(mainTabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _TopAppBar(
                  onNotificationTap: () => showNotificationCenterModal(context),
                ),
                Expanded(
                  child: IndexedStack(
                    index: tabIndex,
                    children: const [
                      DashboardScreen(),
                      CalendarScreen(),
                      ScheduleRoomListScreen(),
                      ProfileSettingsScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: tabIndex,
        tabs: _tabs,
        onSelect: (index) =>
            ref.read(mainTabIndexProvider.notifier).select(index),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.icon,
    this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({
    required this.onNotificationTap,
  });

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.protoCardBg,
        border: Border(
          bottom: BorderSide(
            color: AppColors.protoCardSelectedBg,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '하루칩',
            style: AppTypography.heading1.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.protoHeading,
              letterSpacing: -0.5,
            ),
          ),
          _IconButtonBadge(
            icon: Icons.notifications_rounded,
            onTap: onNotificationTap,
          ),
        ],
      ),
    );
  }
}

/// 알림 버튼 전용 — 우측 상단 점(뱃지) 포함
class _IconButtonBadge extends StatelessWidget {
  const _IconButtonBadge({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.protoCardSelectedBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 20, color: AppColors.protoStepLabel),
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.protoStepLabel,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onSelect,
  });

  final int selectedIndex;
  final List<_TabSpec> tabs;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.protoCardBg,
        border: Border(
          top: BorderSide(color: AppColors.protoCardSelectedBg, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < tabs.length; i++)
              _NavBarButton(
                tab: tabs[i],
                selected: i == selectedIndex,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavBarButton extends StatelessWidget {
  const _NavBarButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.protoStepLabel : AppColors.protoSubtitle;
    final displayIcon = selected ? (tab.activeIcon ?? tab.icon) : tab.icon;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(displayIcon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
