import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/group_default_data.dart';
import '../models/group_category_item.dart';

/// 복수 모임 목록 관리 노티파이어
class GroupListNotifier extends StateNotifier<List<GroupCategoryItem>> {
  GroupListNotifier([List<GroupCategoryItem>? initial])
      : super(initial ?? kDefaultGroupCategories);

  void addGroup(GroupCategoryItem item) {
    state = [...state, item];
  }

  void updateGroup(GroupCategoryItem item) {
    state = state.map((g) => g.id == item.id ? item : g).toList();
  }

  void deleteGroup(String id) {
    state = state.where((g) => g.id != id).toList();
  }
}

final groupListProvider =
    StateNotifierProvider<GroupListNotifier, List<GroupCategoryItem>>((ref) {
  return GroupListNotifier();
});

/// 현재 선택된 모임 ID 프로바이더
final selectedGroupIdProvider = StateProvider<String?>((ref) {
  final groups = ref.watch(groupListProvider);
  return groups.isNotEmpty ? groups.first.id : null;
});

/// 현재 선택된 모임 객체 프로바이더
final selectedGroupProvider = Provider<GroupCategoryItem?>((ref) {
  final groups = ref.watch(groupListProvider);
  final selectedId = ref.watch(selectedGroupIdProvider);
  if (selectedId == null) return groups.isNotEmpty ? groups.first : null;
  return groups.firstWhere(
    (g) => g.id == selectedId,
    orElse: () => groups.first,
  );
});

/// 모임 세부 D-Day 일정 관리 노티파이어
class GroupScheduleListNotifier
    extends StateNotifier<List<GroupMeetingScheduleItem>> {
  GroupScheduleListNotifier([List<GroupMeetingScheduleItem>? initial])
      : super(initial ?? kDefaultGroupMeetingSchedules);

  void addSchedule(GroupMeetingScheduleItem item) {
    state = [...state, item];
  }

  void updateSchedule(GroupMeetingScheduleItem item) {
    state = state.map((s) => s.id == item.id ? item : s).toList();
  }

  void deleteSchedule(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  /// 참석 여부 원터치 토글 (true: 참석, false: 불참, 동일 값 재터치 시 미정 해제)
  void toggleAttendance(String scheduleId, bool attending) {
    state = state.map((s) {
      if (s.id == scheduleId) {
        final current = s.isAttending;
        if (current == attending) {
          // 동일한 버튼을 다시 누르면 미정 상태로 토글 해제
          return s.copyWith(clearAttendance: true);
        } else {
          return s.copyWith(isAttending: attending);
        }
      }
      return s;
    }).toList();
  }

  /// 정기 모임 주기 경과 시 다음 회차 D-Day 자동 생성/갱신 로직
  void checkAndRenewRecurringMeetings() {
    final now = DateTime.now();
    final updatedList = List<GroupMeetingScheduleItem>.from(state);
    bool changed = false;

    // 그룹별로 정기 모임 필터링
    final groupIds = state.map((s) => s.groupId).toSet();

    for (final grpId in groupIds) {
      final grpSchedules = state.where((s) => s.groupId == grpId).toList();
      final regularSchedules = grpSchedules.where((s) => s.isRegular).toList();

      // 미래의 정기 모임이 아직 하나라도 있으면 새로 만들지 않음
      final hasFutureRegular = regularSchedules.any((s) => !s.isPassed);
      if (hasFutureRegular) continue;

      // 가장 최근 지난 정기 모임 탐색
      final passedRegulars = regularSchedules.where((s) => s.isPassed).toList();
      if (passedRegulars.isEmpty) continue;

      passedRegulars.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      final latestPassed = passedRegulars.first;

      // 다음 회차 일정 계산 (월간 모임은 +1개월, 주간 모임은 +7일)
      DateTime nextDate;
      final rule = latestPassed.recurringRule ?? '';
      if (rule.contains('weekly') || rule.contains('Sunday')) {
        nextDate = latestPassed.dateTime.add(const Duration(days: 7));
      } else if (rule.contains('biweekly')) {
        nextDate = latestPassed.dateTime.add(const Duration(days: 14));
      } else {
        // 기본 매월 둘째 주 토요일 또는 +30일
        nextDate = DateTime(
          latestPassed.dateTime.year,
          latestPassed.dateTime.month + 1,
          latestPassed.dateTime.day,
          latestPassed.dateTime.hour,
          latestPassed.dateTime.minute,
        );
      }

      // 만약 계산된 날짜가 여전히 과거라면 오늘 이후로 보정
      while (nextDate.isBefore(now)) {
        nextDate = nextDate.add(const Duration(days: 7));
      }

      final nextTitle = latestPassed.title.contains('정기')
          ? '${nextDate.month}월 정기 모임'
          : '${latestPassed.title} (다음 회차)';

      final newSchedule = GroupMeetingScheduleItem(
        id: 'sched-auto-${DateTime.now().millisecondsSinceEpoch}-${latestPassed.groupId}',
        groupId: latestPassed.groupId,
        title: nextTitle,
        dateTime: nextDate,
        location: latestPassed.location,
        isAttending: null,
        isRegular: true,
        recurringRule: latestPassed.recurringRule,
        memo: '이전 정기 모임 완료에 따라 자동으로 연동 생성된 다음 회차 일정입니다.',
        createdAt: DateTime.now(),
      );

      updatedList.add(newSchedule);
      changed = true;
    }

    if (changed) {
      state = updatedList;
    }
  }
}

final groupScheduleListProvider = StateNotifierProvider<
    GroupScheduleListNotifier, List<GroupMeetingScheduleItem>>((ref) {
  final notifier = GroupScheduleListNotifier();
  notifier.checkAndRenewRecurringMeetings();
  return notifier;
});

/// 현재 선택된 모임의 다가오는 일정 목록 (미래 일정, D-Day 오름차순)
final upcomingSchedulesForSelectedGroupProvider =
    Provider<List<GroupMeetingScheduleItem>>((ref) {
  final selectedId = ref.watch(selectedGroupIdProvider);
  if (selectedId == null) return [];

  final all = ref.watch(groupScheduleListProvider);
  final filtered = all
      .where((s) => s.groupId == selectedId && !s.isPassed)
      .toList();
  filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  return filtered;
});

/// 현재 선택된 모임의 지난 기록 아카이브 목록 (과거 일정, 최신순)
final pastSchedulesForSelectedGroupProvider =
    Provider<List<GroupMeetingScheduleItem>>((ref) {
  final selectedId = ref.watch(selectedGroupIdProvider);
  if (selectedId == null) return [];

  final all = ref.watch(groupScheduleListProvider);
  final filtered = all
      .where((s) => s.groupId == selectedId && s.isPassed)
      .toList();
  filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  return filtered;
});
