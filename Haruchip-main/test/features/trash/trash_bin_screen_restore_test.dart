import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/home/screens/trash_bin_screen.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';
import 'package:haruchip/features/plan/providers/plan_provider.dart';
import 'package:haruchip/features/trash/logic/trash_service.dart';
import 'package:haruchip/features/trash/models/trash_item.dart';
import 'package:haruchip/features/trash/providers/trash_provider.dart';

/// 휴지통 화면의 [복구하기]가 카테고리 항목(목표 등)도 원래 자리로 되돌리는지,
/// 되돌릴 곳이 없으면 휴지통에 그대로 남는지(데이터가 조용히 사라지지 않는지) 확인.
void main() {
  testWidgets('휴지통 화면에서 복구하면 카테고리 항목과 캘린더 일정이 돌아온다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(trashBinProvider.notifier).emptyTrash();
    final cats = c.read(categoryListProvider.notifier);
    final cat = cats.addCategory(categoryKey: 'goal', name: '자기계발', emoji: '🎯', colorHex: '#4F46E5');
    cats.updateCategory(cat.copyWith(metadata: {
      'isInitialized': true,
      'goals': [
        {'id': 'g1', 'title': '토익 900'},
      ],
    }));
    c.read(planListProvider.notifier).addItem(
          PlanItem(id: 'g1', title: '토익 900', date: DateTime(2026, 11, 30), categoryKey: 'goal', categoryInstanceId: cat.id),
        );

    // 삭제 → 휴지통
    final current = c.read(categoryListProvider).firstWhere((x) => x.id == cat.id);
    c.read(trashServiceProvider).trashCategoryEntry(
          type: TrashEntityType.goal,
          category: current,
          metaKey: 'goals',
          entry: {'id': 'g1', 'title': '토익 900'},
          title: '토익 900',
          mirrorPlanIds: {'g1'},
        );
    cats.updateCategory(current.copyWith(metadata: {'isInitialized': true, 'goals': <dynamic>[]}));
    expect(c.read(trashBinProvider).length, 1);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MaterialApp(home: TrashBinScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('복구하기').first);
    await tester.pumpAndSettle();

    expect(c.read(trashBinProvider), isEmpty);
    final restored = c.read(categoryListProvider).firstWhere((x) => x.id == cat.id);
    expect((restored.metadata!['goals'] as List).single['id'], 'g1');
    expect(c.read(planListProvider).any((p) => p.id == 'g1'), isTrue);
  });

  testWidgets('원래 카테고리가 없으면 복구 실패 — 휴지통에 그대로 남는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(trashBinProvider.notifier).emptyTrash();
    c.read(trashBinProvider.notifier).moveToTrash(
          TrashItem(
            id: 'trash-goal-orphan',
            entityType: TrashEntityType.goal,
            originalTitle: '고아 목표',
            deletedAt: DateTime.now(),
            categoryKey: 'goal',
            originalData: {
              'categoryInstanceId': 'no-such-category',
              'metaKey': 'goals',
              'entry': {'id': 'x1', 'title': '고아 목표'},
              'planItems': <dynamic>[],
            },
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MaterialApp(home: TrashBinScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('복구하기').first);
    await tester.pumpAndSettle();

    expect(c.read(trashBinProvider).length, 1, reason: '복구 실패 시 휴지통에 남아야 한다');
    expect(find.textContaining('복구하지 못했어요'), findsOneWidget);
  });
}
