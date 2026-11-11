import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/group/models/group_category_item.dart';
import 'package:haruchip/features/group/providers/group_category_provider.dart';
import 'package:haruchip/features/group/widgets/group_category_view.dart';

void main() {
  group('Group Category Model Tests', () {
    test('Calculates days since foundation correctly', () {
      final foundationDate = DateTime.now().subtract(const Duration(days: 449));
      final group = GroupCategoryItem(
        id: 'group_test_1',
        name: '고교 동창회',
        foundationDate: foundationDate,
        regularScheduleInfo: '매월 둘째 주 토요일',
        createdAt: DateTime.now(),
      );

      expect(group.daysSinceFoundation(), 450);
      expect(group.daysCountText(), '모임 450일째');
      expect(group.regularScheduleInfo, '매월 둘째 주 토요일');
      expect(group.themeColorHex, '#FFF5F2');
    });

    test('Meeting Schedule D-Day and attendance calculations', () {
      final now = DateTime.now();
      final targetDate = now.add(const Duration(days: 5));
      final schedule = GroupMeetingScheduleItem(
        id: 'meeting_test_1',
        groupId: 'group_test_1',
        title: '11월 정기 모임 (삼겹살 번개)',
        dateTime: targetDate,
        location: '강남역 11번 출구 맛집',
        isAttending: true,
        isRegular: true,
        createdAt: now,
      );

      expect(schedule.dDayText(), 'D-5');
      expect(schedule.attendanceLabel, '참여 예정');
      expect(schedule.isPassed, isFalse);

      final declinedSchedule = schedule.copyWith(isAttending: false);
      expect(declinedSchedule.attendanceLabel, '불참');
    });
  });

  group('Group Category Providers Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('groupListProvider loads default groups and supports adding a new group', () {
      final initial = container.read(groupListProvider);
      expect(initial.isNotEmpty, isTrue);

      final notifier = container.read(groupListProvider.notifier);
      final newGroup = GroupCategoryItem(
        id: 'group_custom_1',
        name: '주말 보드게임 모임',
        icon: '🎲',
        foundationDate: DateTime(2025, 1, 1),
        regularScheduleInfo: '매주 일요일 오후 2시',
        createdAt: DateTime.now(),
      );

      notifier.addGroup(newGroup);
      final updated = container.read(groupListProvider);
      expect(updated.any((g) => g.id == 'group_custom_1'), isTrue);
    });

    test('toggleAttendance updates attendance state in groupScheduleListProvider', () {
      final schedules = container.read(groupScheduleListProvider);
      expect(schedules.isNotEmpty, isTrue);

      final firstId = schedules.first.id;
      final notifier = container.read(groupScheduleListProvider.notifier);

      notifier.toggleAttendance(firstId, false);
      final updated = container.read(groupScheduleListProvider);
      expect(updated.firstWhere((s) => s.id == firstId).isAttending, isFalse);

      notifier.toggleAttendance(firstId, true);
      final updatedAgain = container.read(groupScheduleListProvider);
      expect(updatedAgain.firstWhere((s) => s.id == firstId).isAttending, isTrue);
    });

    test('checkAndRenewRecurringMeetings creates next regular meeting when passed', () {
      final notifier = container.read(groupScheduleListProvider.notifier);

      // Add a past regular meeting for a group without future meetings
      const testGroupId = 'group_recurring_only';
      final pastMeeting = GroupMeetingScheduleItem(
        id: 'past_reg_1',
        groupId: testGroupId,
        title: '지난 정기 모임',
        dateTime: DateTime.now().subtract(const Duration(days: 2)),
        isRegular: true,
        recurringRule: 'MONTHLY_SECOND_SATURDAY',
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
      );

      notifier.addSchedule(pastMeeting);
      final beforeCount = container.read(groupScheduleListProvider).length;

      notifier.checkAndRenewRecurringMeetings();
      final afterCount = container.read(groupScheduleListProvider).length;
      expect(afterCount, greaterThan(beforeCount));
    });
  });

  group('GroupCategoryView Widget Tests', () {
    testWidgets('renders top representative group card and meeting list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GroupCategoryView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top representative card items
      expect(find.text('고교 동창회'), findsWidgets);
      expect(find.textContaining('모임'), findsWidgets);
      expect(find.textContaining('일째'), findsWidgets);
      expect(find.text('매월 둘째 주 토요일'), findsOneWidget);

      // Action Chip to add group
      expect(find.text('새 모임 추가'), findsOneWidget);

      // Section toggle tabs
      expect(find.textContaining('다가오는 모임 D-Day'), findsOneWidget);
      expect(find.textContaining('지난 모임 기록'), findsOneWidget);

      // Attendance check buttons
      expect(find.text('참여'), findsWidgets);
      expect(find.text('불참'), findsWidgets);
    });

    testWidgets('toggles attendance on meeting card', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GroupCategoryView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final declineButtons = find.text('불참');
      expect(declineButtons, findsWidgets);

      await tester.tap(declineButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('불참'), findsWidgets);
    });

    testWidgets('switches to past archive records view', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GroupCategoryView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to 지난 모임 기록
      final pastTab = find.textContaining('지난 모임 기록');
      await tester.tap(pastTab);
      await tester.pumpAndSettle();

      expect(find.text('지난 모임 히스토리'), findsOneWidget);
    });
  });
}
