import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/settings/screens/storage_manager_screen.dart';
import 'package:haruchip/features/trash/providers/trash_provider.dart';

void main() {
  group('StorageManagerScreen Widget Tests', () {
    testWidgets('renders top gauge card and category storage breakdown', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StorageManagerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top title & gauge
      expect(find.text('저장공간 관리'), findsOneWidget);
      expect(find.textContaining('기록 데이터'), findsOneWidget);
      expect(find.text('여유 공간 충분'), findsOneWidget);

      // Category list items
      expect(find.text('결혼 기록'), findsOneWidget);
      expect(find.text('아기 기록'), findsOneWidget);
      expect(find.text('모임 기록'), findsOneWidget);
      expect(find.text('여행 기록'), findsOneWidget);
      expect(find.text('취미 기록'), findsOneWidget);

      // Temporary cache card
      expect(find.text('임시 캐시 파일'), findsOneWidget);
      expect(find.text('비우기'), findsOneWidget);
    });

    testWidgets('toggles over-capacity warning banner', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StorageManagerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Warning banner not visible initially
      expect(find.text('저장공간이 부족해요. 지난 기록을 정리해주세요'), findsNothing);

      // Tap simulation toggle
      final simulationButton = find.byTooltip('용량 부족 시뮬레이션');
      expect(simulationButton, findsOneWidget);
      await tester.tap(simulationButton);
      await tester.pumpAndSettle();

      // Warning banner now visible
      expect(find.text('저장공간이 부족해요. 지난 기록을 정리해주세요'), findsOneWidget);
      expect(find.text('정리하기'), findsOneWidget);
    });

    testWidgets('opens category cleanup sheet and selectively deletes past records', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: StorageManagerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap wedding record tile
      final weddingTile = find.text('결혼 기록');
      await tester.tap(weddingTile);
      await tester.pumpAndSettle();

      // Verify bottom sheet opened
      expect(find.text('결혼 기록 정리'), findsOneWidget);
      expect(find.text('지난 기록 일괄 삭제'), findsOneWidget);

      // Check the first record
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Tap selective delete button
      final deleteSelectedBtn = find.textContaining('선택 삭제 (휴지통 이동)');
      expect(deleteSelectedBtn, findsOneWidget);
      await tester.tap(deleteSelectedBtn);
      await tester.pumpAndSettle();

      // Verify SnackBar and item added to trash bin
      expect(find.textContaining('휴지통으로 이동되었습니다'), findsOneWidget);
      final trashList = container.read(trashBinProvider);
      expect(trashList.any((t) => t.categoryKey == 'wedding'), isTrue);
    });

    testWidgets('cleans up all past records for a category with one click', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: StorageManagerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap group record tile
      final groupTile = find.text('모임 기록');
      await tester.ensureVisible(groupTile);
      await tester.tap(groupTile);
      await tester.pumpAndSettle();

      // Tap 일괄 삭제
      final batchDeleteBtn = find.text('지난 기록 일괄 삭제');
      expect(batchDeleteBtn, findsOneWidget);
      await tester.tap(batchDeleteBtn);
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.textContaining('모든 지난 기록(4건)을 정리하시겠습니까?'), findsOneWidget);

      final confirmBtn = find.widgetWithText(ElevatedButton, '일괄 삭제');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify completion message
      expect(find.textContaining('정리할 지난 기록이 없습니다'), findsOneWidget);
    });
  });
}
