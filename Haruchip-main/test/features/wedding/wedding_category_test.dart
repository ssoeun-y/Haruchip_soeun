import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/models/category.dart';
import 'package:haruchip/features/categories/screens/category_detail_screen.dart';
import 'package:haruchip/features/wedding/data/wedding_standard_items.dart';
import 'package:haruchip/features/wedding/logic/wedding_scheduler_engine.dart';
import 'package:haruchip/features/wedding/models/wedding_budget_item.dart';
import 'package:haruchip/features/wedding/models/wedding_item.dart';
import 'package:haruchip/features/wedding/providers/wedding_budget_provider.dart';
import 'package:haruchip/features/wedding/providers/wedding_provider.dart';
import 'package:haruchip/features/wedding/widgets/wedding_category_view.dart';
import 'package:haruchip/features/wedding/widgets/wedding_couple_share_modal.dart';
import 'package:haruchip/features/wedding/widgets/wedding_template_manager_modal.dart';

void main() {
  group('Wedding Standard Master Items & Starter Items', () {
    test('createDefaultWeddingMasterItems contains exactly 57 distinct individual items', () {
      final items = createDefaultWeddingMasterItems();
      expect(items.length, 57);

      final ids = items.map((i) => i.id).toSet();
      expect(ids.length, 57, reason: 'Every item must have a unique ID');

      final orderIndices = items.map((i) => i.orderIndex).toSet();
      expect(orderIndices.length, 57, reason: 'Every item must have a unique order index');
      expect(items.first.orderIndex, 1);
      expect(items.last.orderIndex, 57);
    });

    test('createStarterWeddingItems contains 5 key milestone items', () {
      final starter = createStarterWeddingItems();
      expect(starter.length, 5);
      expect(starter.any((i) => i.title.contains('부모님 인사')), isTrue);
      expect(starter.any((i) => i.title.contains('웨딩홀 계약')), isTrue);
      expect(starter.any((i) => i.title.contains('드레스샵 계약')), isTrue);
      expect(starter.any((i) => i.title.contains('스튜디오 촬영 진행')), isTrue);
      expect(starter.any((i) => i.title.contains('본식 당일')), isTrue);
    });

    test('All 6 wedding stages are covered in master items', () {
      final items = createDefaultWeddingMasterItems();
      final stages = items.map((i) => i.stage).toSet();
      expect(stages.length, WeddingStage.values.length);
      for (final stage in WeddingStage.values) {
        expect(stages.contains(stage), isTrue);
      }
    });

    test('Weekday preferred items have isWeekdayPreferred flag set to true', () {
      final items = createDefaultWeddingMasterItems();
      final weekdayItems = items.where((i) => i.isWeekdayPreferred).toList();

      expect(weekdayItems.isNotEmpty, isTrue);
      expect(weekdayItems.any((i) => i.title.contains('드레스샵 계약')), isTrue);
      expect(weekdayItems.any((i) => i.title.contains('스튜디오 촬영 진행')), isTrue);
      expect(weekdayItems.any((i) => i.title.contains('본식 드레스 최종 가봉')), isTrue);
      expect(weekdayItems.any((i) => i.title.contains('웨딩 네일')), isTrue);
    });
  });

  group('WeddingItem Model Tests', () {
    test('dDayLabel returns countdown label and formattedDateTime details with location', () {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final item = WeddingItem(
        id: 'test-1',
        orderIndex: 1,
        title: '웨딩홀 투어',
        standardOffsetDays: 300,
        stage: WeddingStage.hallAndPlanner,
        targetDate: futureDate,
        deadlineTime: const TimeOfDay(hour: 14, minute: 0),
        location: '더채플앳논현',
      );

      expect(item.dDayLabel(), 'D-10');
      expect(item.formattedDateTime.contains('14:00'), isTrue);
      expect(item.location, '더채플앳논현');
    });

    test('JSON serialization toJson and fromJson preserves location and time', () {
      final original = WeddingItem(
        id: 'wedding-std-10',
        orderIndex: 10,
        title: '드레스샵 계약',
        standardOffsetDays: 240,
        stage: WeddingStage.studimeAndRing,
        targetDate: DateTime(2025, 5, 20),
        deadlineTime: const TimeOfDay(hour: 14, minute: 30),
        location: '로브드K 청담',
        memo: '비즈 맛집 투어 예약',
        isCompleted: true,
        isWeekdayPreferred: true,
      );

      final json = original.toJson();
      final restored = WeddingItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.location, '로브드K 청담');
      expect(restored.memo, '비즈 맛집 투어 예약');
      expect(restored.isCompleted, isTrue);
      expect(restored.isWeekdayPreferred, isTrue);
    });
  });

  group('WeddingSchedulerEngine Smart Scheduling & Snapping', () {
    test('Snaps items strictly to Saturday slots when only Saturday is selected', () {
      final weddingDate = DateTime(2025, 10, 18);
      const engine = WeddingSchedulerEngine();
      final items = createDefaultWeddingMasterItems();
      final scheduled = engine.scheduleItems(
        weddingDate: weddingDate,
        items: items,
        availableSlots: {AvailableTimeSlot.saturday},
      );

      expect(scheduled.length, 57);
      for (final item in scheduled) {
        expect(item.targetDate, isNotNull);
        expect(item.targetDate!.weekday, DateTime.saturday,
            reason: 'Item "${item.title}" should be scheduled on a Saturday');
      }
    });

    test('Prioritizes weekday evening slots for weekday-preferred items when available', () {
      final weddingDate = DateTime(2025, 10, 18);
      const engine = WeddingSchedulerEngine();
      final items = createDefaultWeddingMasterItems();
      final scheduled = engine.scheduleItems(
        weddingDate: weddingDate,
        items: items,
        availableSlots: {
          AvailableTimeSlot.saturday,
          AvailableTimeSlot.weekdayEvening,
        },
      );

      final dressTour = scheduled.firstWhere((i) => i.title.contains('드레스샵 계약'));
      expect(
        dressTour.targetDate!.weekday != DateTime.saturday &&
            dressTour.targetDate!.weekday != DateTime.sunday,
        isTrue,
        reason: 'Dress tour should snap to a weekday evening slot',
      );
      expect(dressTour.deadlineTime, const TimeOfDay(hour: 19, minute: 30));
    });
  });

  group('WeddingNotifier & Riverpod State Flow', () {
    test('Initializes with 5 starter items and allows syncing templates and custom items', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialItems = container.read(weddingListProvider);
      expect(initialItems.length, 5);

      final initialStats = container.read(weddingStatsProvider);
      expect(initialStats.total, 5);
      expect(initialStats.completed, 0);

      // Sync with 10 templates and 1 custom item
      final tenTemplateIds = createDefaultWeddingMasterItems().take(10).map((i) => i.id).toSet();
      final customItem = WeddingItem(
        id: 'wedding-custom-1',
        orderIndex: 11,
        title: '청모 식당 예약',
        standardOffsetDays: 20,
        stage: WeddingStage.invitationAndGuest,
      );

      container.read(weddingListProvider.notifier).syncSelectedTemplates(tenTemplateIds, [customItem]);

      final updatedItems = container.read(weddingListProvider);
      expect(updatedItems.length, 11);
      expect(updatedItems.any((i) => i.title == '청모 식당 예약'), isTrue);
    });

    test('toggleItemCompletion updates completed count and ratio', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final items = container.read(weddingListProvider);
      container.read(weddingListProvider.notifier).toggleItemCompletion(items.first.id);

      final stats = container.read(weddingStatsProvider);
      expect(stats.completed, 1);
      expect(stats.ratio, closeTo(1 / items.length, 0.001));
    });
  });

  group('Wedding Budget & Expenses Provider', () {
    test('Calculates budget summary accurately across groom, bride, and joint', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final summary = container.read(weddingBudgetSummaryProvider);
      expect(summary.totalEstimated > 0, isTrue);
      expect(summary.totalActual > 0, isTrue);
      expect(summary.groomShare > 0, isTrue);
      expect(summary.brideShare > 0, isTrue);
      expect(summary.jointShare > 0, isTrue);
      expect(summary.totalActual, summary.groomShare + summary.brideShare + summary.jointShare);
    });

    test('Adds and deletes budget items', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialCount = container.read(weddingBudgetListProvider).length;

      const newItem = WeddingBudgetItem(
        id: 'budget-test-custom',
        title: '신부 웨딩슈즈',
        estimatedBudget: 300000,
        deposit: 100000,
        balance: 200000,
        payer: ExpensePayer.groom,
      );

      container.read(weddingBudgetListProvider.notifier).addItem(newItem);
      expect(container.read(weddingBudgetListProvider).length, initialCount + 1);

      container.read(weddingBudgetListProvider.notifier).removeItem('budget-test-custom');
      expect(container.read(weddingBudgetListProvider).length, initialCount);
    });
  });

  group('Wedding Widgets Rendering', () {
    testWidgets('WeddingCategoryView renders checklist header, + 일정 추가 button, cards and budget section', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WeddingCategoryView(),
              ),
            ),
          ),
        ),
      );

      // Checklist header and add button
      expect(find.textContaining('준비 항목 체크리스트'), findsOneWidget);
      expect(find.text('항목/일정 추가'), findsOneWidget);

      // Card items #순번, 일시, 장소
      expect(find.text('#01'), findsOneWidget);
      expect(find.textContaining('📅 '), findsWidgets);
      expect(find.textContaining('📍 '), findsWidgets);

      // Budget section
      expect(find.text('결혼 예산 & 지출 정리표'), findsOneWidget);
      expect(find.text('총 예상 예산'), findsOneWidget);
      expect(find.text('총 실제 결제(계약+잔금)'), findsOneWidget);
    });

    testWidgets('WeddingTemplateManagerModal renders 57 master templates and custom input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WeddingTemplateManagerModal(),
            ),
          ),
        ),
      );

      expect(find.text('결혼 준비 항목 매니저'), findsOneWidget);
      expect(find.text('57개 템플릿에서 원하는 일정만 담아보세요'), findsOneWidget);
      expect(find.text('직접 추가'), findsOneWidget);
      expect(find.text('선택한 5개 일정 추가/반영하기'), findsOneWidget);
    });

    testWidgets('WeddingCoupleShareModal renders invite code and partner connection input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WeddingCoupleShareModal(),
            ),
          ),
        ),
      );

      expect(find.text('신랑 · 신부 공동 관리'), findsOneWidget);
      expect(find.text('내 초대 코드'), findsOneWidget);
      expect(find.text('WED-7729-HARU'), findsOneWidget);
      expect(find.text('상대방 초대 코드 등록'), findsOneWidget);
      expect(find.text('연결하기'), findsOneWidget);
    });

    testWidgets('CategoryDetailScreen for wedding renders scheduler and couple share buttons in AppBar without giant profile card', (tester) async {
      final category = Category(
        id: 'cat-wedding',
        categoryKey: 'wedding',
        name: '결혼 준비',
        emoji: '💍',
        colorHex: '#E53E3E',
        createdAt: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CategoryDetailScreen(category: category),
          ),
        ),
      );

      // AppBar buttons
      expect(find.text('스케줄러'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);

      // Giant profile card should NOT be in wedding view
      expect(find.text('예식일 설정하기'), findsNothing);
      expect(find.text('스케줄러 설정'), findsNothing);

      // Category body should have the refined WeddingCategoryView
      expect(find.textContaining('준비 항목 체크리스트'), findsOneWidget);
    });
  });
}
