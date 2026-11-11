import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/home/screens/trash_bin_screen.dart';
import 'package:haruchip/features/trash/models/trash_item.dart';
import 'package:haruchip/features/trash/providers/trash_provider.dart';

void main() {
  group('TrashItem Model Tests', () {
    test('Calculates remaining days correctly within 30-day retention period', () {
      final now = DateTime.now();
      final item = TrashItem(
        id: 'trash_1',
        originalTitle: '커플 100일 기념 여행',
        entityType: TrashEntityType.plan,
        deletedAt: now.subtract(const Duration(days: 5)),
        originalData: {'title': '커플 100일 기념 여행'},
      );

      expect(item.daysRemaining, 25);
      expect(item.daysRemainingLabel, '남은 복구 기간 D-25');
      expect(item.isExpired, isFalse);
    });

    test('Identifies expired items over 30 days', () {
      final now = DateTime.now();
      final expiredItem = TrashItem(
        id: 'trash_2',
        originalTitle: '지난 토익 시험',
        entityType: TrashEntityType.goal,
        deletedAt: now.subtract(const Duration(days: 31)),
        originalData: {'title': '지난 토익 시험'},
      );

      expect(expiredItem.daysRemaining, 0);
      expect(expiredItem.daysRemainingLabel, 'D-Day (오늘 영구 삭제 예정)');
      expect(expiredItem.isExpired, isTrue);
    });

    test('JSON serialization & deserialization works seamlessly', () {
      final now = DateTime.now();
      final original = TrashItem(
        id: 'trash_json',
        originalTitle: '반려동물 예방접종',
        entityType: TrashEntityType.appointment,
        deletedAt: now,
        originalData: {'key': 'value'},
      );

      final json = original.toJson();
      final fromJson = TrashItem.fromJson(json);

      expect(fromJson.id, original.id);
      expect(fromJson.originalTitle, original.originalTitle);
      expect(fromJson.entityType, original.entityType);
      expect(fromJson.originalData['key'], 'value');
    });
  });

  group('TrashBinNotifier Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('moveToTrash adds new item to trash bin', () {
      final notifier = container.read(trashBinProvider.notifier);
      final initialCount = container.read(trashBinProvider).length;

      notifier.moveToTrash(
        TrashItem(
          id: 'new_trash',
          originalTitle: '새로 삭제된 D-Day',
          entityType: TrashEntityType.plan,
          deletedAt: DateTime.now(),
          originalData: {'dday': '2026-12-31'},
        ),
      );

      final updated = container.read(trashBinProvider);
      expect(updated.length, initialCount + 1);
      expect(updated.first.originalTitle, '새로 삭제된 D-Day');
    });

    test('restore removes item from trash and returns original data', () {
      final notifier = container.read(trashBinProvider.notifier);
      final itemToRestore = container.read(trashBinProvider).first;

      final restoredData = notifier.restore(itemToRestore.id);

      expect(restoredData, isNotNull);
      final updatedList = container.read(trashBinProvider);
      expect(updatedList.any((i) => i.id == itemToRestore.id), isFalse);
    });

    test('permanentlyDelete removes item permanently', () {
      final notifier = container.read(trashBinProvider.notifier);
      final itemToDelete = container.read(trashBinProvider).first;

      notifier.permanentlyDelete(itemToDelete.id);

      final updatedList = container.read(trashBinProvider);
      expect(updatedList.any((i) => i.id == itemToDelete.id), isFalse);
    });

    test('emptyTrash clears all items', () {
      final notifier = container.read(trashBinProvider.notifier);

      notifier.emptyTrash();

      final updatedList = container.read(trashBinProvider);
      expect(updatedList.isEmpty, isTrue);
    });
  });

  group('TrashBinScreen Widget Tests', () {
    testWidgets('renders trash bin screen with items and filter chips', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrashBinScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header and Top Notice
      expect(find.textContaining('휴지통'), findsWidgets);
      expect(find.textContaining('30일 동안 안전하게 보존'), findsOneWidget);

      // Verify default mock items are rendered
      expect(find.text('주말 제주도 여행 계획'), findsOneWidget);
      expect(find.text('토익 900점 달성하기'), findsOneWidget);

      // Verify Restore and Delete Buttons exist
      expect(find.text('복구하기'), findsWidgets);
      expect(find.text('영구 삭제'), findsWidgets);
    });

    testWidgets('searches items by query text', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrashBinScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), '제주도');
      await tester.pumpAndSettle();

      expect(find.text('주말 제주도 여행 계획'), findsOneWidget);
      expect(find.text('토익 900점 달성하기'), findsNothing);
    });

    testWidgets('restores an item when tapping 복구하기', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrashBinScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap restore on the first item
      final restoreButtons = find.text('복구하기');
      expect(restoreButtons, findsWidgets);

      await tester.tap(restoreButtons.first);
      await tester.pumpAndSettle();

      // Should show SnackBar
      expect(find.textContaining('복구되었습니다'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when tapping 영구 삭제', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrashBinScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteButtons = find.text('영구 삭제');
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Check dialog
      expect(find.text('항목 영구 삭제'), findsOneWidget);
      expect(find.textContaining('영구 삭제하시겠습니까?'), findsOneWidget);

      // Confirm deletion in dialog
      final confirmBtn = find.widgetWithText(ElevatedButton, '영구 삭제');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('영구 삭제되었습니다'), findsOneWidget);
    });

    testWidgets('supports multi-selection mode with selective restore and batch delete', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrashBinScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter selection mode
      final selectionToggle = find.text('선택 관리');
      expect(selectionToggle, findsOneWidget);
      await tester.tap(selectionToggle);
      await tester.pumpAndSettle();

      // Checkboxes appear
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);

      // Select first item
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Bottom bar appears
      expect(find.textContaining('1개 복원하기'), findsOneWidget);
      expect(find.textContaining('1개 완전 삭제'), findsOneWidget);

      // Tap 1개 완전 삭제
      await tester.tap(find.textContaining('1개 완전 삭제'));
      await tester.pumpAndSettle();

      // Warning dialog appears with exact mandatory string
      expect(find.text('선택 항목 완전 삭제'), findsOneWidget);
      expect(find.textContaining('영구 삭제 시 복원이 불가능합니다. 계속하시겠습니까?'), findsOneWidget);

      // Confirm
      await tester.tap(find.widgetWithText(ElevatedButton, '완전 삭제'));
      await tester.pumpAndSettle();

      expect(find.textContaining('영구 삭제되었습니다'), findsOneWidget);
    });
  });
}
