import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/models/exam_model.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/categories/screens/category_detail_screen.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';
import 'package:haruchip/features/plan/providers/plan_provider.dart';
import 'package:haruchip/features/trash/logic/trash_service.dart';
import 'package:haruchip/features/trash/models/trash_item.dart';
import 'package:haruchip/features/trash/providers/trash_provider.dart';

/// 실제 화면의 "삭제" 메뉴를 눌렀을 때 휴지통을 거치는지 확인하는 통합 테스트.
void main() {
  testWidgets('시험이 하나도 없으면 예시 시험이 375 폭에서 넘치지 않고 보인다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(categoryListProvider.notifier);
    final created = notifier.addCategory(categoryKey: 'exam', name: '자격증', emoji: '📚', colorHex: '#4F46E5');
    final category = created.copyWith(metadata: {'isInitialized': true, 'exams': <dynamic>[]});
    notifier.updateCategory(category);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: CategoryDetailScreen(category: category)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('정보처리기사'), findsWidgets, reason: '시험이 없으면 예시 시험이 1개 보인다');
    expect(tester.takeException(), isNull);
  });

  testWidgets('시험 카드 삭제 → 휴지통으로 이동 → 복구하면 카드와 캘린더 일정이 돌아온다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(trashBinProvider.notifier).emptyTrash();

    final exam = ExamProfile(
      id: 'exam-del-1',
      title: '정보처리기사 3회차',
      type: ExamType.qualification,
      stages: [
        ExamStageItem(
          id: 'st-del-1',
          stageType: ExamStageType.writtenTest,
          name: '1차 필기시험',
          startDate: DateTime.now().add(const Duration(days: 20)),
        ),
      ],
    );
    final notifier = container.read(categoryListProvider.notifier);
    final created = notifier.addCategory(categoryKey: 'exam', name: '자격증', emoji: '📚', colorHex: '#4F46E5');
    final category = created.copyWith(metadata: {
      'isInitialized': true,
      'exams': [exam.toJson()],
    });
    notifier.updateCategory(category);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: CategoryDetailScreen(category: category)),
      ),
    );
    await tester.pumpAndSettle();

    // 시험 저장 시 생기는 캘린더 미러 일정 (_saveExams가 만드는 id 규칙 그대로).
    const mirrorId = 'exam-plan-st-del-1';
    container.read(planListProvider.notifier).addItem(PlanItem(
          id: mirrorId,
          title: '[정보처리기사 3회차] 1차 필기시험',
          date: exam.stages.first.startDate,
          categoryKey: 'exam',
          categoryInstanceId: category.id,
        ));

    expect(find.text('정보처리기사 3회차'), findsWidgets);
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제').last);
    await tester.pumpAndSettle();

    final trash = container.read(trashBinProvider);
    expect(trash.length, 1);
    expect(trash.single.entityType, TrashEntityType.exam);
    expect(trash.single.originalTitle, '정보처리기사 3회차');
    final saved = container.read(categoryListProvider).firstWhere((c) => c.id == category.id);
    expect(saved.metadata!['exams'], isEmpty, reason: '삭제한 시험은 저장 목록에서 빠진다');
    expect(container.read(planListProvider).any((p) => p.id == mirrorId), isFalse);

    final ok = container.read(trashServiceProvider).restore(trash.single);
    expect(ok, isTrue);
    expect(container.read(trashBinProvider), isEmpty);
    final restored = container.read(categoryListProvider).firstWhere((c) => c.id == category.id);
    expect((restored.metadata!['exams'] as List).single['id'], 'exam-del-1');
    expect(container.read(planListProvider).any((p) => p.id == mirrorId), isTrue);
  });
}
