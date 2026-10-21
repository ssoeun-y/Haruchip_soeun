import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import 'package:haruchip/features/shared/widgets/add_event_bottom_sheet.dart';
import '../../onboarding/screens/calendar_integration_screen.dart';
import '../models/calendar_event.dart';
import '../providers/calendar_provider.dart';
import '../widgets/event_list_tile.dart';
import '../widgets/month_grid.dart';

/// 프로 플래너 스타일 스마트 캘린더 화면 (그룹웨어/다우오피스 감성 컬러 칩 라벨링 & 월간/주간/목록 뷰)
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const List<({String? key, String label, Color color, String emoji})> _kCategoryFilters = [
    (key: null, label: '전체', color: Color(0xFF1E293B), emoji: '🌈'),
    (key: 'plan', label: '내 일정', color: Color(0xFF007AFF), emoji: '📝'),
    (key: 'couple', label: '커플', color: Color(0xFFFF2D55), emoji: '❤️'),
    (key: 'solo', label: '솔로', color: Color(0xFF9333EA), emoji: '🌟'),
    (key: 'fandom', label: '덕질', color: Color(0xFFF59E0B), emoji: '⭐'),
    (key: 'group', label: '모임', color: Color(0xFF10B981), emoji: '👥'),
    (key: 'exam', label: '시험', color: Color(0xFF4F46E5), emoji: '📚'),
    (key: 'birthday', label: '생일', color: Color(0xFFEC4899), emoji: '🎂'),
    (key: 'baby', label: '아기', color: Color(0xFFF59E0B), emoji: '👶'),
    (key: 'pet', label: '반려동물', color: Color(0xFFD97706), emoji: '🐾'),
    (key: 'military', label: '군대', color: Color(0xFF556B2F), emoji: '🎖️'),
  ];

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return const Color(0xFF007AFF);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(calendarViewModeProvider);
    final selectedFilter = ref.watch(calendarCategoryFilterProvider);
    final focusedMonth = ref.watch(selectedMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider) ?? DateTime.now();
    final events = ref.watch(eventsForDateProvider(selectedDate));
    final allEvents = ref.watch(allCalendarEventsProvider);
    final notifier = ref.read(calendarSelectionProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 타이틀 & 연동 설정 버튼
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '스마트 캘린더',
                          style: AppTypography.heading1.copyWith(
                            color: AppColors.protoHeading,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '구글 / 네이버 / 하루칩 캘린더 단방향 자동 동기화',
                          style: AppTypography.bodyMuted.copyWith(
                            color: AppColors.protoSubtitle,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CalendarIntegrationScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.protoCardSelectedBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.protoCardSelectedBorder, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sync_rounded,
                            size: 14,
                            color: AppColors.protoCardSelectedText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '연동 설정',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.protoCardSelectedText,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. 상단 뷰 모드 세그먼트: [월간 | 주간 | 목록] & [오늘] 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 36,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildViewModeTab(context, ref, '월간', CalendarViewMode.month, viewMode),
                        _buildViewModeTab(context, ref, '주간', CalendarViewMode.week, viewMode),
                        _buildViewModeTab(context, ref, '목록', CalendarViewMode.list, viewMode),
                      ],
                    ),
                  ),
                  // 오늘 이동 버튼
                  InkWell(
                    onTap: notifier.goToToday,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD1D1D6), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.today_rounded, size: 14, color: AppColors.protoHeading),
                          const SizedBox(width: 4),
                          Text(
                            '오늘',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.protoHeading,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. 카테고리 필터 칩 토글 (가로 스크롤 & 고유 테마 도트 뱃지)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in _kCategoryFilters)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () {
                            ref.read(calendarCategoryFilterProvider.notifier).state = filter.key;
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: selectedFilter == filter.key
                                  ? filter.color.withValues(alpha: 0.15)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selectedFilter == filter.key
                                    ? filter.color
                                    : const Color(0xFFE5E5EA),
                                width: selectedFilter == filter.key ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: filter.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  filter.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selectedFilter == filter.key ? FontWeight.bold : FontWeight.w600,
                                    color: selectedFilter == filter.key ? filter.color : const Color(0xFF48484A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. 뷰 모드별 캘린더 본문
              if (viewMode == CalendarViewMode.month) ...[
                // 월간 뷰
                MonthGrid(
                  focusedMonth: focusedMonth,
                  selectedDate: selectedDate,
                  hasEventOnDate: (date) =>
                      ref.watch(eventsForDateProvider(date)).isNotEmpty,
                  getEventsOnDate: (date) =>
                      ref.watch(eventsForDateProvider(date)),
                  onDateSelected: notifier.selectDate,
                  onPreviousMonth: notifier.previousMonth,
                  onNextMonth: notifier.nextMonth,
                ),
                const SizedBox(height: 14),

                // 선택일 상세 일정 카드
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.protoCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.protoCardBorder,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.event_note_rounded, size: 17, color: AppColors.protoHeading),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${selectedDate.month}월 ${selectedDate.day}일 일정 (${events.length})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.cardLabel.copyWith(
                                      color: AppColors.protoHeading,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => showAddEventBottomSheet(
                              context,
                              categoryKey: selectedFilter ?? 'plan',
                              initialDate: selectedDate,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 14, color: Colors.white),
                                  SizedBox(width: 2),
                                  Text(
                                    '일정 등록',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (events.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Column(
                              children: [
                                const Text('🗓️', style: TextStyle(fontSize: 24)),
                                const SizedBox(height: 6),
                                Text(
                                  '등록된 일정이 없습니다.',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.protoSubtitle,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        for (final e in events) EventListTile(event: e),
                    ],
                  ),
                ),
              ] else if (viewMode == CalendarViewMode.week) ...[
                // 주간 뷰
                _buildWeekView(context, ref, selectedDate, allEvents),
              ] else ...[
                // 목록 (Agenda) 뷰
                _buildListView(context, ref, allEvents),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeTab(
    BuildContext context,
    WidgetRef ref,
    String label,
    CalendarViewMode mode,
    CalendarViewMode currentMode,
  ) {
    final isSelected = mode == currentMode;
    return GestureDetector(
      onTap: () => ref.read(calendarViewModeProvider.notifier).state = mode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppColors.protoHeading : AppColors.protoSubtitle,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekView(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    List<CalendarEvent> allEvents,
  ) {
    // Current week starting from Sunday or Monday
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Column(
      children: [
        for (final day in weekDays)
          Builder(
            builder: (ctx) {
              final dayEvents = allEvents.where((e) {
                return e.date.year == day.year && e.date.month == day.month && e.date.day == day.day;
              }).toList();
              final isToday = day.year == DateTime.now().year &&
                  day.month == DateTime.now().month &&
                  day.day == DateTime.now().day;
              final isSelected = day.year == selectedDate.year &&
                  day.month == selectedDate.month &&
                  day.day == selectedDate.day;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF0F7FF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isToday ? const Color(0xFF007AFF) : const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${day.month}.${day.day} (${['일', '월', '화', '수', '목', '금', '토'][day.weekday % 7]})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isToday ? Colors.white : AppColors.protoHeading,
                                ),
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 6),
                              const Text('오늘', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF007AFF))),
                            ],
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF007AFF)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => showAddEventBottomSheet(
                            context,
                            categoryKey: 'plan',
                            initialDate: day,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (dayEvents.isEmpty)
                      const Text('일정 없음', style: TextStyle(fontSize: 12, color: AppColors.protoSubtitle))
                    else
                      for (final ev in dayEvents)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _parseColor(ev.colorHex).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _parseColor(ev.colorHex).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _parseColor(ev.colorHex),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ev.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _parseColor(ev.colorHex),
                                  ),
                                ),
                              ),
                              if (ev.time != null)
                                Text(
                                  ev.time!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _parseColor(ev.colorHex),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    List<CalendarEvent> allEvents,
  ) {
    if (allEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text('등록된 일정이 없습니다.', style: TextStyle(color: AppColors.protoSubtitle)),
        ),
      );
    }

    final sorted = [...allEvents]..sort((a, b) => a.date.compareTo(b.date));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '전체 일정 목록 (${sorted.length}개)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
              ),
              InkWell(
                onTap: () => showAddEventBottomSheet(
                  context,
                  categoryKey: 'plan',
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 16, color: Color(0xFF007AFF)),
                    Text('일정 추가', style: TextStyle(fontSize: 13, color: Color(0xFF007AFF), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          for (final ev in sorted)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _parseColor(ev.colorHex).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _parseColor(ev.colorHex).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _parseColor(ev.colorHex),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${ev.date.month}.${ev.date.day}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ev.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                        ),
                        if (ev.time != null)
                          Text(
                            '시간: ${ev.time}',
                            style: const TextStyle(fontSize: 12, color: AppColors.protoSubtitle),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD1D1D6)),
                    ),
                    child: Text(
                      ev.source == 'google' ? 'Google' : (ev.source == 'naver' ? 'Naver' : '하루칩'),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.protoSubtitle),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
