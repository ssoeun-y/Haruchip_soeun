import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/travel_default_data.dart';
import '../models/inter_trip_plan.dart';
import '../models/trip_item.dart';

/// 여행 목록 상태 관리 Notifier
class TravelTripListNotifier extends StateNotifier<List<TripItem>> {
  TravelTripListNotifier([List<TripItem>? initial])
      : super(initial ?? getInitialMockTrips());

  /// 새 여행 추가
  void addTrip(TripItem trip) {
    final next = [...state, trip];
    _sortTrips(next);
  }

  /// 여행 정보 수정
  void updateTrip(TripItem trip) {
    final next = [
      for (final t in state)
        if (t.id == trip.id) trip else t
    ];
    _sortTrips(next);
  }

  /// 여행 삭제
  void deleteTrip(String tripId) {
    state = state.where((t) => t.id != tripId).toList();
  }

  /// 짐 싸기 체크박스 토글
  void togglePackingItem(String tripId, String itemId) {
    state = [
      for (final trip in state)
        if (trip.id == tripId)
          trip.copyWith(
            packingList: [
              for (final p in trip.packingList)
                if (p.id == itemId) p.copyWith(isChecked: !p.isChecked) else p,
            ],
          )
        else
          trip,
    ];
  }

  /// 짐 싸기 항목 직접 추가
  void addPackingItem(String tripId, String title, [String category = '기타']) {
    final newItem = PackingCheckItem(
      id: 'pack-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      isChecked: false,
    );

    state = [
      for (final trip in state)
        if (trip.id == tripId)
          trip.copyWith(
            packingList: [...trip.packingList, newItem],
          )
        else
          trip,
    ];
  }

  /// 짐 싸기 항목 삭제
  void removePackingItem(String tripId, String itemId) {
    state = [
      for (final trip in state)
        if (trip.id == tripId)
          trip.copyWith(
            packingList: trip.packingList.where((p) => p.id != itemId).toList(),
          )
        else
          trip,
    ];
  }

  /// 기본 필수 템플릿(여권, 항공권, 보조배터리 등) 일괄 불러오기
  void loadDefaultPackingList(String tripId) {
    final tpls = kDefaultPackingTemplates.map((p) => PackingCheckItem(
      id: 'pack-tpl-${DateTime.now().microsecondsSinceEpoch}-${p.id}',
      title: p.title,
      category: p.category,
      isChecked: false,
    )).toList();

    state = [
      for (final trip in state)
        if (trip.id == tripId)
          trip.copyWith(
            packingList: [
              ...trip.packingList,
              // 중복되지 않는 것만 추가
              for (final t in tpls)
                if (!trip.packingList.any((e) => e.title == t.title)) t,
            ],
          )
        else
          trip,
    ];
  }

  /// '이전 여행 체크리스트 복사해오기'
  void copyPackingListFrom(String toTripId, String fromTripId) {
    final fromTrip = state.firstWhere((t) => t.id == fromTripId, orElse: () => state.first);
    final copiedList = fromTrip.packingList.map((p) => PackingCheckItem(
      id: 'copy-${DateTime.now().microsecondsSinceEpoch}-${p.id}',
      title: p.title,
      category: p.category,
      isChecked: false, // 복사 시에는 미완료 상태로 리셋
    )).toList();

    state = [
      for (final trip in state)
        if (trip.id == toTripId)
          trip.copyWith(
            packingList: [
              ...trip.packingList,
              for (final c in copiedList)
                if (!trip.packingList.any((e) => e.title == c.title)) c,
            ],
          )
        else
          trip,
    ];
  }

  /// Day별 세부 일정 추가
  void addDaySchedule(String tripId, DayScheduleItem item) {
    state = [
      for (final trip in state)
        if (trip.id == tripId)
          trip.copyWith(
            daySchedules: [...trip.daySchedules, item]..sort((a, b) {
              final dayCmp = a.dayNumber.compareTo(b.dayNumber);
              if (dayCmp != 0) return dayCmp;
              return (a.time ?? '').compareTo(b.time ?? '');
            }),
          )
        else
          trip,
    ];
  }

  /// Day별 세부 일정 수정
  void updateDaySchedule(String tripId, DayScheduleItem item) {
    state = [
      for (final trip in state)
        if (trip.id == tripId)
          trip.copyWith(
            daySchedules: [
              for (final s in trip.daySchedules)
                if (s.id == item.id) item else s,
            ]..sort((a, b) {
              final dayCmp = a.dayNumber.compareTo(b.dayNumber);
              if (dayCmp != 0) return dayCmp;
              return (a.time ?? '').compareTo(b.time ?? '');
            }),
          )
        else
          trip,
    ];
  }

  /// Day별 세부 일정 삭제
  void deleteDaySchedule(String tripId, String scheduleId) {
    state = [
      for (final trip in state)
        if (trip.id == tripId)
          trip.copyWith(
            daySchedules: trip.daySchedules.where((s) => s.id != scheduleId).toList(),
          )
        else
          trip,
    ];
  }

  void _sortTrips(List<TripItem> list) {
    list.sort((a, b) => a.startDate.compareTo(b.startDate));
    state = list;
  }
}

/// 여행 목록 StateNotifierProvider
final travelTripListProvider =
    StateNotifierProvider<TravelTripListNotifier, List<TripItem>>((ref) {
  return TravelTripListNotifier();
});

/// 여행 사이사이 계획 Notifier
class InterTripPlanNotifier extends StateNotifier<List<InterTripPlan>> {
  InterTripPlanNotifier([List<InterTripPlan>? initial])
      : super(initial ?? getInitialMockInterPlans());

  /// 사이 계획 추가
  void addPlan(InterTripPlan plan) {
    final next = [...state, plan]..sort((a, b) => a.date.compareTo(b.date));
    state = next;
  }

  /// 사이 계획 수정
  void updatePlan(InterTripPlan plan) {
    final next = [
      for (final p in state)
        if (p.id == plan.id) plan else p
    ]..sort((a, b) => a.date.compareTo(b.date));
    state = next;
  }

  /// 완료 체크박스 토글
  void togglePlan(String planId) {
    state = [
      for (final p in state)
        if (p.id == planId) p.copyWith(isCompleted: !p.isCompleted) else p,
    ];
  }

  /// 사이 계획 삭제
  void deletePlan(String planId) {
    state = state.where((p) => p.id != planId).toList();
  }
}

/// 여행 사이사이 계획 StateNotifierProvider
final interTripPlanListProvider =
    StateNotifierProvider<InterTripPlanNotifier, List<InterTripPlan>>((ref) {
  return InterTripPlanNotifier();
});

/// 현재 진행 중이거나 가장 임박한 여행(Next Trip) 계산 Provider
final nextTripProvider = Provider<TripItem?>((ref) {
  final trips = ref.watch(travelTripListProvider);
  if (trips.isEmpty) return null;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // 1. 현재 진행 중인 여행이 있다면 최우선 반환
  for (final trip in trips) {
    if (trip.isOngoing(now)) {
      return trip;
    }
  }

  // 2. 진행 중인 여행이 없다면 미래의 여행 중 가장 빠른 여행 반환
  final upcomingTrips = trips.where((t) {
    final sDate = DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
    return !today.isAfter(sDate);
  }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));

  if (upcomingTrips.isNotEmpty) {
    return upcomingTrips.first;
  }

  // 3. 미래 여행도 없다면 최근에 다녀온 마지막 여행 반환
  final sorted = [...trips]..sort((a, b) => b.endDate.compareTo(a.endDate));
  return sorted.first;
});
