import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage/local_store.dart';
import '../data/category_types.dart';
import '../models/category.dart';

/// 사용자가 만든 카테고리 인스턴스 전체 목록 및 순서/숨김 상태 관리
class CategoryListNotifier extends Notifier<List<Category>> {
  /// 로컬 저장소에서 복원(첫 실행이면 빈 목록), 변경 시마다 저장한다.
  /// 대시보드 숨김 상태(isDashboardHidden/hiddenAt)도 같이 저장된다.
  @override
  List<Category> build() {
    final store = ref.watch(localStoreProvider);
    listenSelf((_, next) {
      writeJsonList(store, LocalStoreKeys.categories, next, (c) => c.toJson());
    });
    return readJsonList(store, LocalStoreKeys.categories, Category.fromJson) ??
        const <Category>[];
  }

  static int _idCounter = 0;

  Category addCategory({
    required String categoryKey,
    required String name,
    required String emoji,
    required String colorHex,
    String? backgroundImageUrl,
  }) {
    final category = newDraft(
      categoryKey: categoryKey,
      name: name,
      emoji: emoji,
      colorHex: colorHex,
      backgroundImageUrl: backgroundImageUrl,
    );
    state = [...state, category];
    return category;
  }

  /// 아직 목록에 넣지 않은 카테고리를 만든다 — 내용 입력 시트에서 저장을
  /// 눌렀을 때 [upsertCategory]로 비로소 추가된다(빈 카테고리 방지).
  Category newDraft({
    required String categoryKey,
    required String name,
    required String emoji,
    required String colorHex,
    String? backgroundImageUrl,
  }) {
    return Category(
      id: 'cat-${DateTime.now().microsecondsSinceEpoch}-${++_idCounter}',
      categoryKey: categoryKey,
      name: name,
      emoji: emoji,
      colorHex: colorHex,
      createdAt: DateTime.now(),
      backgroundImageUrl: backgroundImageUrl,
    );
  }

  /// 있으면 교체, 없으면(초안이면) 맨 뒤에 추가.
  void upsertCategory(Category category) {
    if (state.any((c) => c.id == category.id)) {
      updateCategory(category);
    } else {
      state = [...state, category];
    }
  }

  /// 온보딩에서 고른 카테고리 타입([keys])마다 기본값으로 인스턴스를 하나씩 만든다.
  void seedFromKeys(
    Iterable<({String key, String labelKo, String emoji})> types,
  ) {
    final existingKeys = state.map((c) => c.categoryKey).toSet();
    final seeded = <Category>[];
    for (final type in types) {
      if (existingKeys.contains(type.key)) continue;
      seeded.add(
        Category(
          id: 'cat-${DateTime.now().microsecondsSinceEpoch}-${type.key}',
          categoryKey: type.key,
          name: type.labelKo,
          emoji: type.emoji,
          colorHex: getCategoryColorHex(type.key),
          createdAt: DateTime.now(),
        ),
      );
    }
    if (seeded.isNotEmpty) {
      state = [...state, ...seeded];
    }
  }

  void removeCategory(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void updateCategory(Category category) {
    state = state.map((c) => c.id == category.id ? category : c).toList();
  }

  /// 대시보드 카테고리 순서 재배치 (드래그 앤 드롭)
  void reorderCategories(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length || newIndex < 0 || newIndex > state.length) {
      return;
    }
    final list = List<Category>.from(state);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }

  /// 대시보드에서 카테고리 숨기기 (영구 삭제 아님)
  void hideCategory(String id) {
    state = state.map((c) {
      if (c.id == id) {
        return c.copyWith(
          isDashboardHidden: true,
          hiddenAt: DateTime.now(),
        );
      }
      return c;
    }).toList();
  }

  /// 숨긴 카테고리를 대시보드로 다시 복구(노출)
  void unhideCategory(String id) {
    state = state.map((c) {
      if (c.id == id) {
        return c.copyWith(
          isDashboardHidden: false,
          hiddenAt: null,
        );
      }
      return c;
    }).toList();
  }

  /// 백업 복원 시 카테고리 전체 교체
  void replaceAll(List<Category> categories) {
    state = categories;
  }
}

final categoryListProvider =
    NotifierProvider<CategoryListNotifier, List<Category>>(
  CategoryListNotifier.new,
);

/// 대시보드에 정상 노출되는 (숨겨지지 않은) 카테고리 목록
final visibleCategoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoryListProvider).where((c) => !c.isDashboardHidden).toList();
});

/// 대시보드에서 숨김 처리된 카테고리 보관함 목록
final hiddenCategoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoryListProvider).where((c) => c.isDashboardHidden).toList();
});

/// categoryKey별로 필터링한 인스턴스 목록
final categoriesOfKeyProvider =
    Provider.family<List<Category>, String>((ref, categoryKey) {
  return ref
      .watch(categoryListProvider)
      .where((c) => c.categoryKey == categoryKey)
      .toList();
});

/// 전용 카드 노출 조건
final hasCategoryOfKeyProvider = Provider.family<bool, String>((ref, key) {
  return ref.watch(categoriesOfKeyProvider(key)).isNotEmpty;
});
