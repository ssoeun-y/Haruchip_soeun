import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hobby_default_data.dart';
import '../models/hobby_item.dart';

/// 복수 취미 목록 상태 관리 Notifier
class HobbyListNotifier extends StateNotifier<List<HobbyItem>> {
  HobbyListNotifier() : super(getInitialHobbies());

  void addHobby(HobbyItem hobby) {
    state = [...state, hobby];
  }

  void updateHobby(HobbyItem updated) {
    state = [
      for (final h in state)
        if (h.id == updated.id) updated else h,
    ];
  }

  void deleteHobby(String id) {
    state = state.where((h) => h.id != id).toList();
  }
}

/// 복수 취미 목록 프로바이더
final hobbyListProvider = StateNotifierProvider<HobbyListNotifier, List<HobbyItem>>((ref) {
  return HobbyListNotifier();
});

/// 현재 화면에서 선택된 활성 취미 ID 프로바이더
final selectedHobbyIdProvider = StateProvider<String?>((ref) {
  final hobbies = ref.watch(hobbyListProvider);
  return hobbies.isNotEmpty ? hobbies.first.id : null;
});

/// 현재 선택된 취미 객체 프로바이더
final selectedHobbyProvider = Provider<HobbyItem?>((ref) {
  final hobbies = ref.watch(hobbyListProvider);
  if (hobbies.isEmpty) return null;
  final selectedId = ref.watch(selectedHobbyIdProvider);
  if (selectedId == null) return hobbies.first;
  return hobbies.firstWhere(
    (h) => h.id == selectedId,
    orElse: () => hobbies.first,
  );
});

/// 취미 세부 일정(스케줄러) 상태 관리 Notifier
class HobbyScheduleNotifier extends StateNotifier<List<HobbyScheduleItem>> {
  HobbyScheduleNotifier() : super(getInitialHobbySchedules());

  void addSchedule(HobbyScheduleItem schedule) {
    state = [...state, schedule];
  }

  void updateSchedule(HobbyScheduleItem updated) {
    state = [
      for (final s in state)
        if (s.id == updated.id) updated else s,
    ];
  }

  void toggleSchedule(String id) {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(isCompleted: !s.isCompleted) else s,
    ];
  }

  void deleteSchedule(String id) {
    state = state.where((s) => s.id != id).toList();
  }
}

/// 취미 세부 일정 전체 목록 프로바이더
final hobbyScheduleListProvider =
    StateNotifierProvider<HobbyScheduleNotifier, List<HobbyScheduleItem>>((ref) {
  return HobbyScheduleNotifier();
});

/// 특정 취미에 속한 일정 목록 프로바이더
/// (미완료 다가오는 일정 우선 정렬 후 완료/지난 일정 순으로 정돈)
final schedulesForHobbyProvider =
    Provider.family<List<HobbyScheduleItem>, String>((ref, hobbyId) {
  final all = ref.watch(hobbyScheduleListProvider);
  final filtered = all.where((s) => s.hobbyId == hobbyId).toList();
  final now = DateTime.now();

  filtered.sort((a, b) {
    // 1. 완료 여부: 미완료가 상단
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }
    // 2. 시간 경과 여부: 안 지난 것이 상단
    final aPast = a.isPast(now);
    final bPast = b.isPast(now);
    if (aPast != bPast) {
      return aPast ? 1 : -1;
    }
    // 3. 날짜 오름차순 (가까운 날짜 우선)
    return a.date.compareTo(b.date);
  });

  return filtered;
});

/// 전체 취미 중 가장 임박한 다음 일정 1개 프로바이더 (대시보드 노출용)
final nextHobbyScheduleProvider =
    Provider<({HobbyItem hobby, HobbyScheduleItem schedule})?>((ref) {
  final hobbies = ref.watch(hobbyListProvider);
  final schedules = ref.watch(hobbyScheduleListProvider);
  if (hobbies.isEmpty || schedules.isEmpty) return null;

  final now = DateTime.now();
  // 미완료이면서 아직 지나지 않았거나 오늘인 일정 중 가장 가까운 것
  final upcoming = schedules
      .where((s) => !s.isCompleted && !s.isPast(now))
      .toList();

  if (upcoming.isEmpty) return null;

  upcoming.sort((a, b) => a.date.compareTo(b.date));
  final earliest = upcoming.first;

  final hobby = hobbies.firstWhere(
    (h) => h.id == earliest.hobbyId,
    orElse: () => hobbies.first,
  );

  return (hobby: hobby, schedule: earliest);
});

/// 가장 오래 지속 중인 취미 1개 프로바이더 (시작일이 가장 오래된 것)
final longestRunningHobbyProvider = Provider<HobbyItem?>((ref) {
  final hobbies = ref.watch(hobbyListProvider);
  if (hobbies.isEmpty) return null;

  final sorted = [...hobbies];
  sorted.sort((a, b) => a.startDate.compareTo(b.startDate));
  return sorted.first;
});
