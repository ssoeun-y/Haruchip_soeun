import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:haruchip/features/categories/logic/repeat_rule.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';
import 'package:haruchip/features/settings/screens/hidden_categories_screen.dart';
import 'package:haruchip/features/settings/screens/settings_screen.dart';
import 'package:haruchip/services/calendar/external_calendar_push_service.dart';

void main() {
  group('Settings & Backup & Calendar Sync Tests', () {
    test('ExternalCalendarPushService formats KST date correctly and builds standard RRULE', () {
      final service = ExternalCalendarPushService.instance;

      // KST formatting test (+09:00)
      final utcDate = DateTime.utc(2026, 10, 7, 0, 0, 0);
      final kstIso = service.formatKstDate(utcDate, isAllDay: false);
      expect(kstIso.contains('+09:00'), isTrue);

      final allDayKst = service.formatKstDate(DateTime(2026, 12, 25), isAllDay: true);
      expect(allDayKst, equals('2026-12-25'));

      // RRULE builder test
      final rruleYearly = service.buildRRule(
        RepeatConfig.yearlyDefault,
        repeatEndDate: DateTime(2030, 12, 31),
      );
      expect(rruleYearly, isNotNull);
      expect(rruleYearly!.contains('FREQ=YEARLY'), isTrue);
      expect(rruleYearly.contains('UNTIL=20301231T235959Z'), isTrue);

      final rruleNone = service.buildRRule(RepeatConfig.none);
      expect(rruleNone, isNull);

      // Pastel color to Google Calendar ColorId Euclidean distance mapping test
      expect(service.mapHexToGoogleColorId('#FF8DA1'), equals('4')); // Flamingo for pastel pink
      expect(service.mapHexToGoogleColorId('#C084FC'), equals('1')); // Lavender for pastel lavender/purple
      expect(service.mapHexToGoogleColorId('#FBBF24'), equals('5')); // Banana for pastel yellow
      expect(service.mapCategoryToGoogleColorId('couple'), equals('4'));
      expect(service.mapCategoryToGoogleColorId('custom', colorHex: '#38BDF8'), equals('7')); // Peacock for sky blue
    });

    test('PlanItem JSON serialization includes reminder and round-trips accurately', () {
      final item = PlanItem(
        id: 'plan-reminder-test-1',
        title: '신제품 런칭 미팅',
        date: DateTime(2026, 11, 15, 14, 0),
        reminder: EventReminder.before30m,
        categoryKey: 'plan',
        isAllDay: false,
      );

      final jsonMap = item.toJson();
      expect(jsonMap['reminder'], equals('before30m'));
      expect(jsonMap['title'], equals('신제품 런칭 미팅'));

      final restored = PlanItem.fromJson(jsonMap);
      expect(restored.id, equals('plan-reminder-test-1'));
      expect(restored.reminder, equals(EventReminder.before30m));
      expect(restored.reminder.minutesBefore, equals(30));
    });

    test('CategoryListNotifier reorderCategories, hideCategory and unhideCategory operate correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(categoryListProvider.notifier);

      final catA = notifier.addCategory(
        categoryKey: 'couple',
        name: '우리의 사랑',
        emoji: '💑',
        colorHex: '#FF5733',
      );
      final catB = notifier.addCategory(
        categoryKey: 'military',
        name: '곰신 일기',
        emoji: '🪖',
        colorHex: '#33FF57',
      );
      notifier.addCategory(
        categoryKey: 'baby',
        name: '우리아기 수첩',
        emoji: '🍼',
        colorHex: '#3357FF',
      );

      expect(container.read(categoryListProvider).length, equals(3));
      expect(container.read(visibleCategoriesProvider).length, equals(3));
      expect(container.read(hiddenCategoriesProvider).length, equals(0));

      // Reorder test
      notifier.reorderCategories(0, 3); // Move first item to the end
      final reordered = container.read(categoryListProvider);
      expect(reordered.first.id, equals(catB.id));
      expect(reordered.last.id, equals(catA.id));

      // Hide category test
      notifier.hideCategory(catB.id);
      expect(container.read(visibleCategoriesProvider).length, equals(2));
      expect(container.read(hiddenCategoriesProvider).length, equals(1));
      expect(container.read(hiddenCategoriesProvider).first.id, equals(catB.id));
      expect(container.read(hiddenCategoriesProvider).first.isDashboardHidden, isTrue);

      // Unhide category test
      notifier.unhideCategory(catB.id);
      expect(container.read(visibleCategoriesProvider).length, equals(3));
      expect(container.read(hiddenCategoriesProvider).length, equals(0));
      expect(container.read(categoryListProvider).firstWhere((c) => c.id == catB.id).isDashboardHidden, isFalse);
    });

    testWidgets('HiddenCategoriesScreen renders empty state and hidden items with restore button', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(categoryListProvider.notifier);
      final cat = notifier.addCategory(
        categoryKey: 'exam',
        name: '정보처리기사 대비',
        emoji: '📚',
        colorHex: '#4F46E5',
      );
      notifier.hideCategory(cat.id);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HiddenCategoriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('대시보드 숨김 카드 보관함'), findsOneWidget);
      expect(find.text('정보처리기사 대비'), findsOneWidget);
      expect(find.text('대시보드에 복구'), findsOneWidget);

      // Tap restore
      await tester.tap(find.text('대시보드에 복구'));
      await tester.pumpAndSettle();

      expect(container.read(hiddenCategoriesProvider).length, equals(0));
      expect(container.read(visibleCategoriesProvider).any((c) => c.id == cat.id), isTrue);
      expect(find.text('숨겨진 카테고리가 없습니다.'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders account, calendar sync, backup export/import and shortcuts', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('환경 설정 및 데이터 관리'), findsOneWidget);
      expect(find.text(SettingsScreen.userUniqueCode), findsOneWidget);
      expect(find.text('대시보드 숨김 카드 보관함'), findsOneWidget);
      expect(find.text('휴지통 (30일 복구 보존)'), findsOneWidget);
      expect(find.text('모바일 홈/잠금화면 위젯 시뮬레이터'), findsOneWidget);

      // Verify Backup Export Dialog opens
      await tester.ensureVisible(find.text('백업 내보내기'));
      await tester.tap(find.text('백업 내보내기'));
      await tester.pumpAndSettle();

      expect(find.text('전체 데이터 백업 내보내기'), findsOneWidget);
      expect(find.text('클립보드에 복사'), findsOneWidget);
      expect(find.text('백업 파일 저장'), findsOneWidget);

      await tester.tap(find.text('클립보드에 복사'));
      await tester.pumpAndSettle();

      // Verify Backup Import Dialog opens
      await tester.ensureVisible(find.text('백업 복원하기'));
      await tester.tap(find.text('백업 복원하기'));
      await tester.pumpAndSettle();

      expect(find.text('백업 데이터 복원하기'), findsOneWidget);
      expect(find.text('데이터 복원 적용'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
    });
  });
}
