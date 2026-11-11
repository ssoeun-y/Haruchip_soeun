import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../services/notification/local_push_notification_service.dart';
import '../../../services/storage/local_store.dart';
import '../../categories/logic/repeat_rule.dart';
import '../data/plan_mock_data.dart';
import '../models/plan_item.dart';

List<PlanItem> _sortedByDate(List<PlanItem> items) {
  final sorted = [...items];
  sorted.sort((a, b) => a.date.compareTo(b.date));
  return sorted;
}

/// plan(D-day 리스트) 상태. 항상 날짜 오름차순 정렬을 유지한다.
///
/// 카테고리는 태그 개념(CLAUDE.md §5)이라 동일 categoryKey를 가진 항목을
/// 몇 개든 추가할 수 있다 — [addItem]에 카테고리 중복 제한이 없다.
class PlanListNotifier extends Notifier<List<PlanItem>> {
  /// 로컬 저장소에 저장된 목록이 있으면 그걸, 첫 실행이면 기존 목업으로
  /// 시작한다. 이후 상태가 바뀔 때마다 저장소에 다시 쓴다.
  @override
  List<PlanItem> build() {
    final store = ref.watch(localStoreProvider);
    listenSelf((_, next) {
      writeJsonList(store, LocalStoreKeys.plans, next, (p) => p.toJson());
    });
    final saved = readJsonList(store, LocalStoreKeys.plans, PlanItem.fromJson);
    return _sortedByDate(saved ?? mockPlanItems);
  }

  void addItem(PlanItem item) {
    state = _sortedByDate([...state, item]);
    LocalPushNotificationService.instance.schedulePlanReminder(item);
  }

  void addItems(List<PlanItem> items) {
    state = _sortedByDate([...state, ...items]);
    for (final item in items) {
      LocalPushNotificationService.instance.schedulePlanReminder(item);
    }
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
    LocalPushNotificationService.instance.cancelReminder(id);
  }

  void updateItem(PlanItem updatedItem) {
    state = _sortedByDate([
      for (final item in state)
        if (item.id == updatedItem.id) updatedItem else item
    ]);
    LocalPushNotificationService.instance.schedulePlanReminder(updatedItem);
  }

  /// 계획 카테고리 칸반 보드(§5.7)에서 카드를 다른 상태로 옮길 때 쓴다.
  /// 정렬 기준(날짜)은 바뀌지 않으므로 재정렬은 하지 않는다.
  void updateKanbanStatus(String id, KanbanStatus status) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(kanbanStatus: status) else item,
    ];
  }

  /// 백업 복원 시 전체 일정 교체
  void replaceAll(List<PlanItem> items) {
    state = _sortedByDate(items);
  }
}

final planListProvider =
    NotifierProvider<PlanListNotifier, List<PlanItem>>(PlanListNotifier.new);

/// 카테고리(§5 태그 개념)별로 필터링한 항목 목록.
/// 대시보드 카드가 categoryKey별로 자기 항목만 뽑아 쓸 때 사용한다.
/// 가족(family) provider 스타일과 맞춰 `.family` 수정자로 categoryKey를
/// 파라미터로 받는다 — 정렬 순서는 [planListProvider]와 동일(날짜 오름차순).
final planItemsByCategoryProvider =
    Provider.family<List<PlanItem>, String>((ref, categoryKey) {
  return ref
      .watch(planListProvider)
      .where((item) => item.categoryKey == categoryKey)
      .toList();
});

/// [Category] 인스턴스 하나에 속한 항목만 필터링 — 다중 인스턴스 카드
/// (`GenericCategoryDashboardCard`)가 같은 categoryKey라도 인스턴스별로
/// 서로 다른 항목만 보여줄 때 쓴다. legacy(categoryInstanceId가 없는)
/// 항목은 어떤 인스턴스에도 매칭되지 않는다.
final planItemsByCategoryInstanceProvider =
    Provider.family<List<PlanItem>, String>((ref, categoryInstanceId) {
  return ref
      .watch(planListProvider)
      .where((item) => item.categoryInstanceId == categoryInstanceId)
      .toList();
});

/// "예측 리스트업" 섹션 — 디데이 추가 화면 명세 §3: `repeat.type != none`
/// 이거나 `isPredicted == true`인 항목은 항상 이 섹션에 노출된다. 일반
/// 목록에서 제외하지 않는 **추가(additive)** 노출이라 [planListProvider]
/// 자체는 건드리지 않고 필터링된 뷰만 별도로 만든다.
final predictedPlanItemsProvider = Provider<List<PlanItem>>((ref) {
  return ref
      .watch(planListProvider)
      .where((item) => item.repeatConfig.isRepeating || item.isPredicted)
      .toList();
});

/// haruchip_app.html의 daysUntil() 포팅.
/// 'D-n'(미래) / 'D-day'(오늘) / 'D+n'(지남) 문자열을 반환한다.
String dDayLabel(DateTime date) {
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final targetOnly = DateTime(date.year, date.month, date.day);
  final diff = targetOnly.difference(todayOnly).inDays;
  if (diff == 0) return 'D-day';
  if (diff > 0) return 'D-$diff';
  return 'D+${diff.abs()}';
}

/// pet 카테고리 전용 — dDayLabel(카운트다운)과 달리 [date](태어난/입양된 날)
/// 로부터 오늘까지 지난 일수를 그대로 정수로 반환한다(카운트업).
/// 반려동물 카드의 "D+650일째" 표시는 화면 담당자가
/// `'D+${daysSince(date)}일째'`처럼 조합해 쓰면 된다.
int daysSince(DateTime date) {
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final dateOnly = DateTime(date.year, date.month, date.day);
  return todayOnly.difference(dateOnly).inDays;
}

/// 아기 카테고리(§5.5) 등 "N개월째" 표기용 — [date]로부터 오늘까지 지난
/// 개월 수(달력월 기준, 일자 미도달 시 내림).
int monthsSince(DateTime date) {
  final today = DateTime.now();
  var months = (today.year - date.year) * 12 + (today.month - date.month);
  if (today.day < date.day) months -= 1;
  return months < 0 ? 0 : months;
}

/// 항목 [item]의 `displayMode`에 맞춰 카드에 보여줄 라벨을 만든다
/// (핸드오프 문서 §3 "표시방식(D-Day/N일째/개월수)").
///
/// D-day 모드에서 항목이 반복([RepeatConfig.isRepeating])이면 지난
/// [PlanItem.date]를 그대로 쓰지 않고 [nextOccurrence]로 계산한 다음
/// 발생일 기준으로 표시한다 — 그래야 작년 생일이 아니라 올해/내년 생일의
/// D-day가 보인다.
String displayLabel(PlanItem item) {
  switch (item.displayMode) {
    case DdayDisplayMode.dday:
      final target = item.repeatConfig.isRepeating
          ? nextOccurrence(item.date, item.repeatConfig)
          : item.date;
      return dDayLabel(target);
    case DdayDisplayMode.daysCount:
      return '${daysSince(item.date)}일째';
    case DdayDisplayMode.monthsCount:
      return '${monthsSince(item.date)}개월째';
  }
}

/// 아기 카테고리(§5.5) "N일째 + 개월수 병기"용 — 예: "125일째 · 4개월
/// 5일째". [daysSince]/[monthsSince]를 조합해서 만든다(따로 계산 로직을
/// 새로 만들지 않고 기존 두 함수를 재사용).
String babyAgeLabel(DateTime date) {
  final days = daysSince(date);
  final months = monthsSince(date);
  final anchor = DateTime(date.year, date.month + months, date.day);
  final today = DateTime.now();
  final remainderDays = DateTime(today.year, today.month, today.day)
      .difference(DateTime(anchor.year, anchor.month, anchor.day))
      .inDays;
  return '$days일째 · $months개월 $remainderDays일째';
}

/// 계획 카테고리 칸반 카드 우선순위 색(§5.7 "중요도별 컬러 라벨") — 새
/// 색을 만들지 않고 기존 디자인 토큰에 매핑한다(§6 하드코딩 금지).
Color priorityColor(PlanPriority priority) {
  switch (priority) {
    case PlanPriority.high:
      return AppColors.danger;
    case PlanPriority.medium:
      return AppColors.protoStepLabel;
    case PlanPriority.low:
      return AppColors.textSecondary;
  }
}
