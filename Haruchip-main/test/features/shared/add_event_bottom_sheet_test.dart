import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/categories/providers/custom_tags_provider.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';
import 'package:haruchip/features/shared/widgets/add_event_bottom_sheet.dart';
import 'package:haruchip/services/notification/local_push_notification_service.dart';

void main() {
  group('CategoryCustomTagsNotifier Tests', () {
    test('adds and removes custom tags per category', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(categoryCustomTagsProvider.notifier);

      // Add custom tag for pet
      notifier.addCustomTag('pet', '영양제급여');
      notifier.addCustomTag('pet', '발톱정리');

      var state = container.read(categoryCustomTagsProvider);
      expect(state['pet'], contains('영양제급여'));
      expect(state['pet'], contains('발톱정리'));

      // Remove custom tag
      notifier.removeCustomTag('pet', '영양제급여');
      state = container.read(categoryCustomTagsProvider);
      expect(state['pet'], isNot(contains('영양제급여')));
      expect(state['pet'], contains('발톱정리'));
    });
  });

  group('AddEventBottomSheet Widget Tests', () {
    testWidgets('renders single unified modal without top double segment tab', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddEventBottomSheet(categoryKey: 'plan'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top segment tabs [이벤트], [미리 알림] must not exist
      expect(find.text('이벤트'), findsNothing);
      expect(find.text('내 일정 일정 추가'), findsOneWidget);

      // Pre-event reminder row exists in the unified form
      expect(find.text('미리알림 (사전 알림)'), findsOneWidget);
    });

    testWidgets('renders clean title textfield with placeholder and accepts input', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddEventBottomSheet(categoryKey: 'plan'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check placeholder is "일정 제목을 입력하세요"
      expect(find.text('일정 제목을 입력하세요'), findsOneWidget);

      // Enter text
      await tester.enterText(find.byType(TextField).first, '새로운 기획 회의');
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.controller?.text, '새로운 기획 회의');
    });

    testWidgets('renders single category card selector without top horizontal chips and syncs selection', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddEventBottomSheet(categoryKey: 'plan'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top redundant category chips area must be completely removed
      expect(find.text('등록 카테고리 (D-Day 자동 연동)'), findsNothing);

      // Both 시작 and 종료 rows must be displayed
      expect(find.text('시작'), findsOneWidget);
      expect(find.text('종료'), findsOneWidget);
      expect(find.textContaining('시간대: 서울'), findsOneWidget);

      // White Card 1: 반복
      expect(find.text('반복'), findsOneWidget);
      expect(find.text('안 함'), findsOneWidget);

      // White Card 2: 카테고리 (renamed from 캘린더)
      expect(find.text('카테고리'), findsOneWidget);
      expect(find.text('캘린더'), findsNothing);

      // Tap '반복' card to open repeat modal
      await tester.tap(find.text('반복'));
      await tester.pumpAndSettle();

      expect(find.text('매일'), findsOneWidget);
      expect(find.text('매주'), findsOneWidget);

      // Tap '매일'
      await tester.tap(find.text('매일'));
      await tester.pumpAndSettle();

      // Repeat card now displays '매일'
      expect(find.text('매일'), findsOneWidget);

      // Tap '카테고리' card to open category selection modal
      await tester.tap(find.text('카테고리'));
      await tester.pumpAndSettle();

      expect(find.text('카테고리 선택'), findsOneWidget);
      expect(find.text('캘린더 선택'), findsNothing);
      expect(find.text('+ 새 카테고리 추가'), findsOneWidget);
      expect(find.text('커플'), findsWidgets);

      // Tap '커플' in the modal
      await tester.tap(find.text('커플').last);
      await tester.pumpAndSettle();

      // Modal closed, header and card synced to 커플
      expect(find.text('카테고리 선택'), findsNothing);
      expect(find.text('커플 일정 추가'), findsOneWidget);
    });

    testWidgets('new category creation popup creates pastel category and syncs to DB and selector', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AddEventBottomSheet(categoryKey: 'plan'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap '카테고리' card
      await tester.tap(find.text('카테고리'));
      await tester.pumpAndSettle();

      // Tap '+ 새 카테고리 추가'
      await tester.tap(find.text('+ 새 카테고리 추가'));
      await tester.pumpAndSettle();

      // Dialog opens with title and notice banner
      expect(find.text('새 카테고리 추가'), findsOneWidget);
      expect(find.text('이 카테고리 색상은 캘린더 일정 표시에도 동일하게 적용됩니다'), findsOneWidget);

      // Enter new category name
      await tester.enterText(find.byType(TextField).last, '필라테스');
      await tester.pumpAndSettle();

      // Tap '추가' button inside the dialog
      await tester.tap(find.widgetWithText(ElevatedButton, '추가'));
      await tester.pumpAndSettle();

      // Dialog closed and newly created category is selected
      expect(find.text('새 카테고리 추가'), findsNothing);
      expect(find.text('필라테스 일정 추가'), findsOneWidget);

      // Category is registered in categoryListProvider
      final cats = container.read(categoryListProvider);
      expect(cats.any((c) => c.name == '필라테스'), isTrue);
    });

    testWidgets('opens reminder bottom sheet and selects option without overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddEventBottomSheet(categoryKey: 'plan'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap reminder row
      final reminderTile = find.text('미리알림 (사전 알림)');
      expect(reminderTile, findsOneWidget);
      await tester.tap(reminderTile);
      await tester.pumpAndSettle();

      // Verify reminder modal header and options are displayed
      expect(find.text('🔔 미리알림 시간 선택'), findsOneWidget);
      expect(find.text('10분 전'), findsOneWidget);
      expect(find.text('1일 전 오전 9시'), findsOneWidget);

      // Tap '10분 전'
      await tester.tap(find.text('10분 전'));
      await tester.pumpAndSettle();

      // Reminder modal closed and 10분 전 badge is shown
      expect(find.text('🔔 미리알림 시간 선택'), findsNothing);
      expect(find.text('10분 전'), findsOneWidget);
    });

    testWidgets('resolves category record with non-null id without Record Type Nullability TypeError', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Add a custom category to populate categoryListProvider
      final catNotifier = container.read(categoryListProvider.notifier);
      catNotifier.addCategory(
        categoryKey: 'custom',
        name: '나만의 카테고리',
        emoji: '✨',
        colorHex: '#9333EA',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AddEventBottomSheet(categoryKey: 'custom'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('나만의 카테고리 일정 추가'), findsOneWidget);
    });
  });

  group('LocalPushNotificationService Tests', () {
    test('schedules reminder for plan item and cancels on demand', () async {
      final service = LocalPushNotificationService.instance;
      await service.initialize();

      final futureDate = DateTime.now().add(const Duration(days: 2));
      final item = PlanItem(
        id: 'test_plan_item_1',
        categoryKey: 'plan',
        title: '미팅 알림 테스트',
        date: futureDate,
        deadlineTime: const TimeOfDay(hour: 14, minute: 0),
        reminder: EventReminder.before10m,
      );

      final scheduled = await service.schedulePlanReminder(item);
      expect(scheduled, isNotNull);
      expect(scheduled!.title, '미팅 알림 테스트');
      expect(service.activeNotifications.any((n) => n.planItemId == item.id), isTrue);

      // Cancel reminder
      service.cancelReminder(item.id);
      expect(service.activeNotifications.any((n) => n.planItemId == item.id), isFalse);
    });

    test('immediate banner notification dispatches to listener stream', () async {
      final service = LocalPushNotificationService.instance;
      ScheduledNotification? received;
      final sub = service.onNotificationTriggered.listen((notif) {
        received = notif;
      });
      addTearDown(sub.cancel);

      service.showImmediateNotification(title: '긴급 공지', body: '서버 점검 예정');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(received, isNotNull);
      expect(received!.title, '긴급 공지');
      expect(received!.body, '서버 점검 예정');
    });
  });
}
