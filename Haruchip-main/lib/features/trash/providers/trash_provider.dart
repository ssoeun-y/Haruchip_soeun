import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/storage/local_store.dart';
import '../models/trash_item.dart';

/// 초기 목업 휴지통 샘플 데이터
final List<TrashItem> kDefaultMockTrashItems = [
  TrashItem(
    id: 'trash-demo-1',
    entityType: TrashEntityType.plan,
    originalTitle: '주말 제주도 여행 계획',
    deletedAt: DateTime.now().subtract(const Duration(days: 3)),
    originalData: {
      'id': 'demo-plan-jeju',
      'title': '주말 제주도 여행 계획',
      'date': DateTime.now().add(const Duration(days: 15)).toIso8601String(),
      'categoryKey': 'plan',
    },
    categoryKey: 'plan',
  ),
  TrashItem(
    id: 'trash-demo-2',
    entityType: TrashEntityType.goal,
    originalTitle: '토익 900점 달성하기',
    deletedAt: DateTime.now().subtract(const Duration(days: 12)),
    originalData: {
      'id': 'demo-goal-toeic',
      'title': '토익 900점 달성하기',
      'category': '자격증',
    },
    categoryKey: 'goal',
  ),
  TrashItem(
    id: 'trash-demo-3',
    entityType: TrashEntityType.settlement,
    originalTitle: '지난달 회식 2차 치맥 정산',
    deletedAt: DateTime.now().subtract(const Duration(days: 18)),
    originalData: {
      'id': 'demo-settle-beer',
      'title': '지난달 회식 2차 치맥 정산',
      'totalAmount': 64000,
    },
    roomId: 'room-1',
  ),
];

class TrashBinNotifier extends StateNotifier<List<TrashItem>> {
  TrashBinNotifier([List<TrashItem>? initial]) : super(initial ?? kDefaultMockTrashItems) {
    purgeExpired();
  }

  /// 30일 초과된 항목 자동 영구 정리
  void purgeExpired() {
    state = state.where((item) => !item.isExpired).toList();
  }

  /// 항목을 휴지통으로 이동
  void moveToTrash(TrashItem item) {
    state = [item, ...state.where((i) => i.id != item.id)];
    purgeExpired();
  }

  /// 휴지통에서 항목 영구 삭제
  void permanentlyDelete(String id) {
    state = state.where((i) => i.id != id).toList();
  }

  /// 복수 항목 영구 삭제
  void permanentlyDeleteMultiple(Iterable<String> ids) {
    final set = ids.toSet();
    state = state.where((i) => !set.contains(i.id)).toList();
  }

  /// 휴지통 전체 비우기
  void emptyTrash() {
    state = [];
  }

  /// 복구 시 휴지통 목록에서 제거
  TrashItem? restore(String id) {
    final match = state.where((i) => i.id == id).toList();
    if (match.isEmpty) return null;
    final item = match.first;
    state = state.where((i) => i.id != id).toList();
    return item;
  }

  /// 복수 항목 복구 시 휴지통 목록에서 일괄 제거
  List<TrashItem> restoreMultiple(Iterable<String> ids) {
    final set = ids.toSet();
    final matched = state.where((i) => set.contains(i.id)).toList();
    state = state.where((i) => !set.contains(i.id)).toList();
    return matched;
  }
}

/// 저장된 휴지통이 있으면 복원(생성자에서 30일 지난 항목은 바로 정리),
/// 첫 실행이면 기존 목업으로 시작한다. 변경 시마다 저장한다.
final trashBinProvider = StateNotifierProvider<TrashBinNotifier, List<TrashItem>>((ref) {
  final store = ref.watch(localStoreProvider);
  final saved = readJsonList(store, LocalStoreKeys.trash, TrashItem.fromJson);
  final notifier = TrashBinNotifier(saved);
  notifier.addListener(
    (items) => writeJsonList(store, LocalStoreKeys.trash, items, (t) => t.toJson()),
    fireImmediately: false,
  );
  return notifier;
});
