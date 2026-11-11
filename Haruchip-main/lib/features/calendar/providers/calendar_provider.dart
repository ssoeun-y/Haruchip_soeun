import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/data/category_types.dart' as cat_types;
import '../../categories/providers/category_provider.dart';
import '../../hobby/providers/hobby_provider.dart';
import '../../plan/providers/plan_provider.dart';
import '../../travel/providers/travel_provider.dart';
import '../data/calendar_mock_data.dart';
import '../models/calendar_event.dart';

const Object _unset = Object();

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 캘린더 상단 뷰 전환 모드
enum CalendarViewMode { month, week, list }

final calendarViewModeProvider = StateProvider<CalendarViewMode>((ref) => CalendarViewMode.month);

/// 캘린더 카테고리 필터 (null = '전체')
final calendarCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// 카테고리별 테마 Hex 색상 매핑 (파스텔 톤 통일)
String getCategoryColorHex(String categoryKey) {
  return cat_types.getCategoryColorHex(categoryKey);
}

/// 캘린더 화면에서 사용자가 보고 있는 연/월과 선택한 날짜.
class CalendarSelectionState {
  const CalendarSelectionState({
    required this.focusedMonth,
    this.selectedDate,
  });

  /// 현재 보고 있는 달의 1일 (연/월 내비게이션용).
  final DateTime focusedMonth;

  /// 사용자가 탭한 날짜. 아직 선택 안 했으면 null.
  final DateTime? selectedDate;

  CalendarSelectionState copyWith({
    DateTime? focusedMonth,
    Object? selectedDate = _unset,
  }) {
    return CalendarSelectionState(
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate: identical(selectedDate, _unset)
          ? this.selectedDate
          : selectedDate as DateTime?,
    );
  }
}

class CalendarSelectionNotifier extends Notifier<CalendarSelectionState> {
  @override
  CalendarSelectionState build() {
    final today = _dateOnly(DateTime.now());
    return CalendarSelectionState(
      focusedMonth: DateTime(today.year, today.month, 1),
      selectedDate: today,
    );
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: _dateOnly(date));
  }

  void changeMonth(DateTime month) {
    state = state.copyWith(
      focusedMonth: DateTime(month.year, month.month, 1),
      selectedDate: null,
    );
  }

  void goToToday() {
    final today = _dateOnly(DateTime.now());
    state = state.copyWith(
      focusedMonth: DateTime(today.year, today.month, 1),
      selectedDate: today,
    );
  }

  void nextMonth() {
    final m = state.focusedMonth;
    changeMonth(DateTime(m.year, m.month + 1, 1));
  }

  void previousMonth() {
    final m = state.focusedMonth;
    changeMonth(DateTime(m.year, m.month - 1, 1));
  }
}

final calendarSelectionProvider =
    NotifierProvider<CalendarSelectionNotifier, CalendarSelectionState>(
  CalendarSelectionNotifier.new,
);

final selectedMonthProvider = Provider<DateTime>(
  (ref) => ref.watch(calendarSelectionProvider).focusedMonth,
);

final selectedDateProvider = Provider<DateTime?>(
  (ref) => ref.watch(calendarSelectionProvider).selectedDate,
);

/// PlanList, MockCalendarEvents, 여행(Travel) 및 사이 계획(Inter-Trip Plans)을 결합한 통합 일정 프로바이더
final allCalendarEventsProvider = Provider<List<CalendarEvent>>((ref) {
  final planItems = ref.watch(planListProvider);
  final categories = ref.watch(categoryListProvider);
  final filter = ref.watch(calendarCategoryFilterProvider);
  final travelTrips = ref.watch(travelTripListProvider);
  final interPlans = ref.watch(interTripPlanListProvider);
  final hobbyList = ref.watch(hobbyListProvider);
  final hobbySchedules = ref.watch(hobbyScheduleListProvider);

  final dynamicEvents = planItems.map((item) {
    final matches = categories.where((c) => c.categoryKey == item.categoryKey || c.id == item.categoryKey);
    final colorHex = matches.isNotEmpty ? matches.first.colorHex : getCategoryColorHex(item.categoryKey);

    return CalendarEvent(
      id: item.id,
      date: item.date,
      title: item.title,
      time: item.deadlineTime != null
          ? '${item.deadlineTime!.hour.toString().padLeft(2, '0')}:${item.deadlineTime!.minute.toString().padLeft(2, '0')}'
          : null,
      source: item.calendarSync.google
          ? 'google'
          : (item.calendarSync.naver ? 'naver' : 'personal'),
      colorHex: colorHex,
      categoryKey: item.categoryKey,
      isPublic: false,
    );
  }).toList();

  final travelEvents = <CalendarEvent>[];
  for (final trip in travelTrips) {
    final s = _dateOnly(trip.startDate);
    final e = _dateOnly(trip.endDate);
    final days = e.difference(s).inDays + 1;
    for (int d = 0; d < days; d++) {
      final curDate = s.add(Duration(days: d));
      final dayLabel = days > 1 ? ' (${d + 1}/$days일차)' : '';
      travelEvents.add(CalendarEvent(
        id: 'cal-trip-${trip.id}-$d',
        date: curDate,
        title: '${trip.emoji} ${trip.destination}$dayLabel',
        time: null,
        source: 'personal',
        colorHex: trip.themeColorHex,
        categoryKey: 'travel',
        isPublic: false,
      ));
    }
  }

  for (final plan in interPlans) {
    travelEvents.add(CalendarEvent(
      id: 'cal-inter-${plan.id}',
      date: plan.date,
      title: '📍 ${plan.title}',
      time: plan.time,
      source: 'personal',
      colorHex: '#0284C7',
      categoryKey: 'travel',
      isPublic: false,
    ));
  }

  final hobbyEvents = <CalendarEvent>[];
  for (final sched in hobbySchedules) {
    final matching = hobbyList.where((h) => h.id == sched.hobbyId);
    final hobby = matching.isNotEmpty ? matching.first : null;
    final icon = hobby?.icon ?? '🎨';
    final timeStr = sched.hasTime
        ? '${sched.date.hour.toString().padLeft(2, '0')}:${sched.date.minute.toString().padLeft(2, '0')}'
        : null;

    hobbyEvents.add(CalendarEvent(
      id: 'cal-hobby-${sched.id}',
      date: sched.date,
      title: '$icon ${sched.title}',
      time: timeStr,
      source: 'personal',
      colorHex: '#354235',
      categoryKey: 'hobby',
      isPublic: false,
    ));
  }

  final all = [...mockCalendarEvents, ...dynamicEvents, ...travelEvents, ...hobbyEvents];

  if (filter == null) {
    return all;
  }
  return all.where((e) => e.categoryKey == filter).toList();
});

/// 주어진 날짜의 CalendarEvent 목록.
final eventsForDateProvider =
    Provider.family<List<CalendarEvent>, DateTime>((ref, date) {
  final target = _dateOnly(date);
  final allEvents = ref.watch(allCalendarEventsProvider);
  return allEvents.where((e) => _dateOnly(e.date) == target).toList();
});

