import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../data/wedding_standard_items.dart';
import '../logic/wedding_scheduler_engine.dart';
import '../models/wedding_item.dart';

/// 초기에 메인 화면에 간결하게 노출할 스타터 핵심 마일스톤 5개
List<WeddingItem> createStarterWeddingItems() {
  final all = createDefaultWeddingMasterItems();
  const starterIds = {
    'wedding-std-1', // 양가 부모님 인사드리기 (신부 쪽)
    'wedding-std-5', // 본식 웨딩홀 계약
    'wedding-std-10', // 드레스샵 계약
    'wedding-std-27', // 스튜디오 촬영 진행
    'wedding-std-57', // 본식(결혼식) 당일
  };
  return all.where((i) => starterIds.contains(i.id)).toList();
}

/// 결혼 준비 전용 상태 및 개별 항목 관리 Notifier
class WeddingNotifier extends Notifier<List<WeddingItem>> {
  DateTime? _weddingDate;

  DateTime? get weddingDate => _weddingDate;

  @override
  List<WeddingItem> build() {
    // 57개 항목이 한꺼번에 펼쳐지지 않도록 스타터 5개 핵심 일정으로 시작
    return createStarterWeddingItems();
  }

  void setWeddingDate(DateTime date) {
    _weddingDate = date;
  }

  /// 템플릿 매니저로부터 선택된 템플릿 ID 목록과 신규 추가 항목들을 일괄 동기화
  void syncSelectedTemplates(
    Set<String> selectedTemplateIds,
    List<WeddingItem> newCustomItems,
  ) {
    final allMasters = createDefaultWeddingMasterItems();
    final existingMap = {for (final item in state) item.id: item};
    final planNotifier = ref.read(planListProvider.notifier);

    // 1. 기존 항목 중 선택 해제된 항목 삭제 (캘린더 동기화 연쇄 해제)
    for (final existing in state) {
      if (!selectedTemplateIds.contains(existing.id) &&
          !existing.id.startsWith('wedding-custom-')) {
        if (existing.syncedPlanId != null) {
          planNotifier.removeItem(existing.syncedPlanId!);
        }
      }
    }

    final newList = <WeddingItem>[];

    // 2. 선택된 마스터 템플릿 추가 또는 기존 수정 내역 보존
    for (final master in allMasters) {
      if (selectedTemplateIds.contains(master.id)) {
        if (existingMap.containsKey(master.id)) {
          newList.add(existingMap[master.id]!);
        } else {
          newList.add(master);
        }
      }
    }

    // 3. 기존 커스텀 항목 유지
    for (final existing in state) {
      if (existing.id.startsWith('wedding-custom-')) {
        newList.add(existing);
      }
    }

    // 4. 새 커스텀 항목 추가
    for (final custom in newCustomItems) {
      newList.add(custom);
    }

    newList.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    state = newList;
  }

  /// 스마트 역산 스케줄러 실행 및 메인 캘린더 연쇄 동기화
  void applySmartSchedule({
    required DateTime weddingDate,
    required Set<AvailableTimeSlot> availableSlots,
  }) {
    _weddingDate = weddingDate;

    final itemsToSchedule =
        state.isEmpty ? createDefaultWeddingMasterItems() : state;

    const engine = WeddingSchedulerEngine();
    final scheduled = engine.scheduleItems(
      weddingDate: weddingDate,
      items: itemsToSchedule,
      availableSlots: availableSlots,
    );

    final planNotifier = ref.read(planListProvider.notifier);
    final updatedList = <WeddingItem>[];

    for (final item in scheduled) {
      if (item.targetDate != null) {
        final planId = item.syncedPlanId ?? 'plan-wedding-${item.id}';
        final planItem = PlanItem(
          id: planId,
          title: '💍 ${item.title}',
          date: item.targetDate!,
          categoryKey: 'wedding',
          deadlineTime: item.deadlineTime,
        );

        if (item.syncedPlanId != null) {
          planNotifier.updateItem(planItem);
        } else {
          planNotifier.addItem(planItem);
        }

        updatedList.add(item.copyWith(syncedPlanId: planId));
      } else {
        updatedList.add(item);
      }
    }

    state = updatedList;
  }

  /// 체크리스트 완료 상태 토글
  void toggleItemCompletion(String id) {
    state = state.map((item) {
      if (item.id == id) {
        final nextCompleted = !item.isCompleted;
        return item.copyWith(
          isCompleted: nextCompleted,
          completedAt: nextCompleted ? DateTime.now() : null,
        );
      }
      return item;
    }).toList();
  }

  /// 개별 항목 수정 및 캘린더 동기화 반영
  void updateItem(WeddingItem updated) {
    final planNotifier = ref.read(planListProvider.notifier);

    WeddingItem finalItem = updated;

    if (updated.targetDate != null) {
      final planId = updated.syncedPlanId ?? 'plan-wedding-${updated.id}';
      final planItem = PlanItem(
        id: planId,
        title: '💍 ${updated.title}',
        date: updated.targetDate!,
        categoryKey: 'wedding',
        deadlineTime: updated.deadlineTime,
      );

      if (updated.syncedPlanId != null) {
        planNotifier.updateItem(planItem);
      } else {
        planNotifier.addItem(planItem);
      }
      finalItem = updated.copyWith(syncedPlanId: planId);
    } else if (updated.syncedPlanId != null) {
      // 날짜가 해제된 경우 캘린더에서 제거
      planNotifier.removeItem(updated.syncedPlanId!);
      finalItem = updated.copyWith(
          clearDate: true, clearTime: true, syncedPlanId: null);
    }

    state = state
        .map((item) => item.id == updated.id ? finalItem : item)
        .toList();
  }

  /// 신규 맞춤 일정 항목 추가
  void addItem(WeddingItem newItem) {
    WeddingItem finalItem = newItem;
    if (newItem.targetDate != null) {
      final planId = 'plan-wedding-${newItem.id}';
      final planItem = PlanItem(
        id: planId,
        title: '💍 ${newItem.title}',
        date: newItem.targetDate!,
        categoryKey: 'wedding',
        deadlineTime: newItem.deadlineTime,
      );
      ref.read(planListProvider.notifier).addItem(planItem);
      finalItem = newItem.copyWith(syncedPlanId: planId);
    }

    state = [...state, finalItem];
  }

  /// 항목 삭제 및 캘린더 연쇄 제거
  void removeItem(String id) {
    final target = state.firstWhere((item) => item.id == id,
        orElse: () => state.first);
    if (target.syncedPlanId != null) {
      ref.read(planListProvider.notifier).removeItem(target.syncedPlanId!);
    }
    state = state.where((item) => item.id != id).toList();
  }
}

final weddingListProvider =
    NotifierProvider<WeddingNotifier, List<WeddingItem>>(WeddingNotifier.new);

/// 본식일 Provider
final weddingDateProvider = Provider<DateTime?>((ref) {
  final notifier = ref.watch(weddingListProvider.notifier);
  return notifier.weddingDate;
});

/// 결혼 준비 완료 통계
final weddingStatsProvider =
    Provider<({int completed, int total, double ratio})>((ref) {
  final items = ref.watch(weddingListProvider);
  if (items.isEmpty) return (completed: 0, total: 0, ratio: 0.0);
  final completed = items.where((i) => i.isCompleted).length;
  return (
    completed: completed,
    total: items.length,
    ratio: completed / items.length,
  );
});

/// 다가오는 결혼 준비 일정 (날짜가 정해진 미완료 항목)
final upcomingWeddingItemsProvider = Provider<List<WeddingItem>>((ref) {
  final items = ref.watch(weddingListProvider);

  final scheduled = items
      .where((i) => !i.isCompleted && i.targetDate != null)
      .toList()
    ..sort((a, b) => a.targetDate!.compareTo(b.targetDate!));

  return scheduled;
});
