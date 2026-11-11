import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:haruchip/features/calendar/providers/calendar_provider.dart';
import 'package:haruchip/features/categories/models/category.dart';
import 'package:haruchip/features/categories/screens/category_detail_screen.dart';
import 'package:haruchip/features/hobby/models/hobby_item.dart';
import 'package:haruchip/features/hobby/providers/hobby_provider.dart';
import 'package:haruchip/features/hobby/widgets/add_hobby_modal.dart';
import 'package:haruchip/features/hobby/widgets/add_hobby_schedule_modal.dart';
import 'package:haruchip/features/hobby/widgets/hobby_category_view.dart';
import 'package:haruchip/features/home/widgets/category_summary_dashboard_card.dart';

void main() {
  group('HobbyItem & HobbyScheduleItem Model Unit Tests', () {
    test('HobbyItem calculates days since start and formatted start date accurately', () {
      final now = DateTime(2026, 11, 2);
      final hobby = HobbyItem(
        id: 'test-guitar',
        name: '기타 연습',
        icon: '🎸',
        startDate: DateTime(2026, 6, 14),
        createdAt: DateTime(2026, 6, 14),
      );

      final days = hobby.daysSinceStart(now);
      expect(days, 142);
      expect(hobby.daysSinceStartText(now), '시작한 지 142일째');
      expect(hobby.formattedStartDate, '2026.06.14 시작');
    });

    test('HobbyScheduleItem computes D-Day and countdown badge accurately', () {
      final now = DateTime(2026, 11, 2, 10, 0);

      // Future date
      final futureSched = HobbyScheduleItem(
        id: 'sched-1',
        hobbyId: 'test-guitar',
        title: '원데이 레슨',
        date: DateTime(2026, 11, 8, 14, 0),
        hasTime: true,
        createdAt: now,
      );
      expect(futureSched.dDayBadge(now), 'D-6');
      expect(futureSched.isPast(now), isFalse);

      // Today in 4 hours
      final todaySched = HobbyScheduleItem(
        id: 'sched-today',
        hobbyId: 'test-guitar',
        title: '스트링 교체',
        date: DateTime(2026, 11, 2, 13, 15),
        hasTime: true,
        createdAt: now,
      );
      expect(todaySched.dDayBadge(now), '03:15 남음');

      // Past date
      final pastSched = HobbyScheduleItem(
        id: 'sched-past',
        hobbyId: 'test-guitar',
        title: '지난 합주',
        date: DateTime(2026, 10, 20, 19, 0),
        hasTime: true,
        createdAt: now,
      );
      expect(pastSched.dDayBadge(now), 'D+13');
      expect(pastSched.isPast(now), isTrue);
    });
  });

  group('Hobby Providers State Management Tests', () {
    test('HobbyListNotifier manages hobbies cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(hobbyListProvider);
      expect(initial.length, 3);
      expect(initial.first.name, '기타 연습');

      // Add hobby
      final newHobby = HobbyItem(
        id: 'hobby-baking',
        name: '홈베이킹',
        icon: '🍳',
        startDate: DateTime(2026, 10, 1),
        createdAt: DateTime.now(),
      );
      container.read(hobbyListProvider.notifier).addHobby(newHobby);
      expect(container.read(hobbyListProvider).length, 4);

      // Update hobby
      final updatedHobby = newHobby.copyWith(name: '프리미엄 홈베이킹');
      container.read(hobbyListProvider.notifier).updateHobby(updatedHobby);
      expect(
        container.read(hobbyListProvider).firstWhere((h) => h.id == 'hobby-baking').name,
        '프리미엄 홈베이킹',
      );

      // Delete hobby
      container.read(hobbyListProvider.notifier).deleteHobby('hobby-baking');
      expect(container.read(hobbyListProvider).length, 3);
    });

    test('HobbyScheduleNotifier adds, toggles, and deletes schedules', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(hobbyScheduleListProvider);
      expect(initial.isNotEmpty, isTrue);

      final testSchedule = HobbyScheduleItem(
        id: 'test-sched-1',
        hobbyId: 'hobby-guitar',
        title: '핑거스타일 연습',
        date: DateTime(2026, 11, 10, 15, 0),
        hasTime: true,
        createdAt: DateTime.now(),
      );

      container.read(hobbyScheduleListProvider.notifier).addSchedule(testSchedule);
      expect(
        container.read(hobbyScheduleListProvider).any((s) => s.id == 'test-sched-1'),
        isTrue,
      );

      // Toggle completion
      container.read(hobbyScheduleListProvider.notifier).toggleSchedule('test-sched-1');
      expect(
        container
            .read(hobbyScheduleListProvider)
            .firstWhere((s) => s.id == 'test-sched-1')
            .isCompleted,
        isTrue,
      );

      // Delete schedule
      container.read(hobbyScheduleListProvider.notifier).deleteSchedule('test-sched-1');
      expect(
        container.read(hobbyScheduleListProvider).any((s) => s.id == 'test-sched-1'),
        isFalse,
      );
    });
  });

  group('HobbyCategoryView Widget Tests', () {
    testWidgets('renders top hobby card with pastel soft sage theme, Y2K dot badge, and clean start date',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HobbyCategoryView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top card hobby name
      expect(find.text('기타 연습'), findsWidgets);
      expect(find.text('🎸'), findsWidgets);

      // Y2K dot badge
      expect(find.textContaining('시작한 지'), findsOneWidget);

      // Clean 1-line start date without complex statistics
      expect(find.text('2026.06.14 시작'), findsOneWidget);
      expect(find.textContaining('12회 완료'), findsNothing);

      // Selector chips
      expect(find.text('주말 러닝'), findsWidgets);
      expect(find.text('핸드드립 커피'), findsWidgets);
      expect(find.text('새 취미'), findsOneWidget);

      // Schedule section header
      expect(find.text('다가오는 취미 일정'), findsOneWidget);
      expect(find.text('일정 추가'), findsOneWidget);
    });

    testWidgets('tapping choice chip switches active hobby in view', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HobbyCategoryView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to 주말 러닝
      await tester.tap(find.text('주말 러닝').first);
      await tester.pumpAndSettle();

      expect(find.text('🏃'), findsWidgets);
      expect(find.text('2026.08.01 시작'), findsOneWidget);
    });

    testWidgets('tapping 새 취미 opens AddHobbyModal', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HobbyCategoryView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('새 취미'));
      await tester.pumpAndSettle();

      expect(find.byType(AddHobbyModal), findsOneWidget);
      expect(find.text('새 취미 등록'), findsOneWidget);
      expect(find.text('취미 추가하기'), findsOneWidget);
    });

    testWidgets('tapping 일정 추가 opens AddHobbyScheduleModal', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HobbyCategoryView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('일정 추가'));
      await tester.pumpAndSettle();

      expect(find.byType(AddHobbyScheduleModal), findsOneWidget);
      expect(find.text('새 취미 일정 추가'), findsOneWidget);
      expect(find.text('일정 등록하기'), findsOneWidget);
    });
  });

  group('Calendar & Dashboard Integration Tests for Hobby', () {
    testWidgets('allCalendarEventsProvider contains hobby schedules with sage theme', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final events = container.read(allCalendarEventsProvider);
      final hobbyEvents = events.where((e) => e.categoryKey == 'hobby').toList();

      expect(hobbyEvents.isNotEmpty, isTrue);
      expect(hobbyEvents.any((e) => e.colorHex == '#354235'), isTrue);
      expect(hobbyEvents.any((e) => e.title.contains('기타 줄 갈기')), isTrue);
    });

    testWidgets('CategorySummaryDashboardCard displays Next Schedule or longest running hobby',
        (tester) async {
      final category = Category(
        id: 'cat-hobby-main',
        categoryKey: 'hobby',
        name: '취미',
        emoji: '🎨',
        colorHex: '#354235',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CategorySummaryDashboardCard(
                category: category,
                countUpItems: const [],
                countDownItems: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('취미'), findsOneWidget);
      // Clean display without legacy completedCount
      expect(find.textContaining('12회 완료'), findsNothing);
      expect(find.textContaining('러닝'), findsWidgets);
    });

    testWidgets('CategoryDetailScreen renders HobbyCategoryView when categoryKey is hobby',
        (tester) async {
      final category = Category(
        id: 'cat-hobby-1',
        categoryKey: 'hobby',
        name: '취미',
        emoji: '🎨',
        colorHex: '#354235',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CategoryDetailScreen(category: category),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HobbyCategoryView), findsOneWidget);
      expect(find.text('새 취미'), findsWidgets);
      expect(find.text('기타 연습'), findsWidgets);
    });
  });
}
