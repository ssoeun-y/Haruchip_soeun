import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/calendar/providers/calendar_provider.dart';
import 'package:haruchip/features/categories/models/category_model.dart';
import 'package:haruchip/features/categories/screens/category_detail_screen.dart';
import 'package:haruchip/features/home/widgets/category_summary_dashboard_card.dart';
import 'package:haruchip/features/travel/models/inter_trip_plan.dart';
import 'package:haruchip/features/travel/models/trip_item.dart';
import 'package:haruchip/features/travel/providers/travel_provider.dart';
import 'package:haruchip/features/travel/widgets/add_inter_plan_modal.dart';
import 'package:haruchip/features/travel/widgets/add_trip_modal.dart';
import 'package:haruchip/features/travel/widgets/travel_category_view.dart';
import 'package:haruchip/features/travel/widgets/trip_detail_sheet.dart';

void main() {
  group('TripItem & InterTripPlan Model Unit Tests', () {
    test('TripItem calculates duration, ongoing status, and D-Day badge accurately', () {
      final now = DateTime(2026, 11, 10);

      // 미래 여행 (D-5)
      final futureTrip = TripItem(
        id: 'trip-f1',
        destination: '오사카',
        startDate: DateTime(2026, 11, 15),
        endDate: DateTime(2026, 11, 18),
      );
      expect(futureTrip.durationInDays, equals(4));
      expect(futureTrip.isOngoing(now), isFalse);
      expect(futureTrip.dDayBadge(now), equals('D-5'));

      // 당일 시작 여행 (D-Day)
      final todayTrip = TripItem(
        id: 'trip-t1',
        destination: '제주도',
        startDate: DateTime(2026, 11, 10),
        endDate: DateTime(2026, 11, 12),
      );
      expect(todayTrip.isOngoing(now), isTrue);
      expect(todayTrip.currentDayNumber(now), equals(1));
      expect(todayTrip.dDayBadge(now), equals('1일차'));

      // 여행 2일차 진행 중
      final ongoingTrip = TripItem(
        id: 'trip-o1',
        destination: '삿포로',
        startDate: DateTime(2026, 11, 9),
        endDate: DateTime(2026, 11, 13),
      );
      expect(ongoingTrip.isOngoing(now), isTrue);
      expect(ongoingTrip.currentDayNumber(now), equals(2));
      expect(ongoingTrip.dDayBadge(now), equals('2일차'));

      // 이미 종료된 여행 (D+3)
      final pastTrip = TripItem(
        id: 'trip-p1',
        destination: '후쿠오카',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 7),
      );
      expect(pastTrip.isOngoing(now), isFalse);
      expect(pastTrip.dDayBadge(now), equals('D+3'));
    });

    test('TripItem computes packing progress correctly', () {
      final trip = TripItem(
        id: 'trip-pack',
        destination: '도쿄',
        startDate: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, 4),
        packingList: const [
          PackingCheckItem(id: '1', title: '여권', isChecked: true),
          PackingCheckItem(id: '2', title: '충전기', isChecked: true),
          PackingCheckItem(id: '3', title: '보조배터리', isChecked: false),
          PackingCheckItem(id: '4', title: '상비약', isChecked: false),
        ],
      );

      expect(trip.totalPackingCount, equals(4));
      expect(trip.completedPackingCount, equals(2));
      expect(trip.packingProgress, equals(0.5));
      expect(trip.packingProgressText, equals('2/4 완료'));
    });

    test('DayScheduleItem computes countdown label when scheduled today', () {
      final now = DateTime(2026, 11, 10, 10, 0); // 10:00 AM

      final flightSchedule = DayScheduleItem(
        id: 's-1',
        dayNumber: 1,
        date: DateTime(2026, 11, 10),
        time: '12:40', // 2 hours 40 mins later
        title: '인천공항 피치항공 탑승',
      );

      expect(flightSchedule.countdownLabel(now), equals('탑승까지 02:40 남음'));

      final checkinSchedule = DayScheduleItem(
        id: 's-2',
        dayNumber: 1,
        date: DateTime(2026, 11, 10),
        time: '15:15',
        title: '호텔 체크인',
      );
      expect(checkinSchedule.countdownLabel(now), equals('체크인까지 05:15 남음'));

      // 과거 시간
      final pastSchedule = DayScheduleItem(
        id: 's-3',
        dayNumber: 1,
        date: DateTime(2026, 11, 10),
        time: '08:00',
        title: '공항 리무진 탑승',
      );
      expect(pastSchedule.countdownLabel(now), equals('일정 진행 완료'));
    });

    test('InterTripPlan calculates D-Day and formats date correctly', () {
      final now = DateTime(2026, 11, 10);

      final plan = InterTripPlan(
        id: 'inter-1',
        title: '호텔 잔금 결제',
        date: DateTime(2026, 11, 25),
        time: '14:00',
      );

      expect(plan.dDayLabel(now), equals('D-15'));
      expect(plan.formattedDate, contains('11.25'));
    });
  });

  group('Travel Provider StateNotifier Tests', () {
    test('TravelTripListNotifier adds, updates, deletes, and manages packing & schedules', () {
      final notifier = TravelTripListNotifier([]);
      expect(notifier.state, isEmpty);

      final trip1 = TripItem(
        id: 't-1',
        destination: '제주도',
        startDate: DateTime(2026, 11, 10),
        endDate: DateTime(2026, 11, 12),
        packingList: const [
          PackingCheckItem(id: 'p-1', title: '신분증', isChecked: false),
        ],
      );

      notifier.addTrip(trip1);
      expect(notifier.state.length, equals(1));
      expect(notifier.state.first.destination, equals('제주도'));

      // 짐 토글
      notifier.togglePackingItem('t-1', 'p-1');
      expect(notifier.state.first.packingList.first.isChecked, isTrue);

      // 직접 짐 추가
      notifier.addPackingItem('t-1', '선크림', '위생');
      expect(notifier.state.first.packingList.length, equals(2));

      // 기본 필수 템플릿 로드
      notifier.loadDefaultPackingList('t-1');
      expect(notifier.state.first.packingList.length, greaterThan(5));

      // Day 일정 추가
      notifier.addDaySchedule(
        't-1',
        DayScheduleItem(id: 'ds-1', dayNumber: 1, title: '렌터카 인수', time: '11:00'),
      );
      expect(notifier.state.first.daySchedules.length, equals(1));

      // 여행 삭제
      notifier.deleteTrip('t-1');
      expect(notifier.state, isEmpty);
    });

    test('InterTripPlanNotifier adds, toggles, and deletes plans', () {
      final notifier = InterTripPlanNotifier([]);
      final plan = InterTripPlan(
        id: 'plan-1',
        title: '엔화 환전 신청',
        date: DateTime(2026, 12, 1),
      );

      notifier.addPlan(plan);
      expect(notifier.state.length, equals(1));
      expect(notifier.state.first.isCompleted, isFalse);

      notifier.togglePlan('plan-1');
      expect(notifier.state.first.isCompleted, isTrue);

      notifier.deletePlan('plan-1');
      expect(notifier.state, isEmpty);
    });
  });

  group('TravelCategoryView Widget Tests', () {
    testWidgets('renders top summary card with pastel sky blue theme and Next Trip info', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TravelCategoryView(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 상단 요약 카드 확인
      expect(find.text('새 여행 추가'), findsOneWidget);
      expect(find.textContaining('다음 여행:'), findsOneWidget);
      expect(find.text('여행 로드맵 타임라인'), findsOneWidget);

      // 여행 노드 티켓들 렌더링 확인 (제주도, 오사카, 삿포로)
      expect(find.text('제주도 힐링 여행'), findsOneWidget);
      expect(find.text('오사카 & 교토 단풍 투어'), findsOneWidget);
      expect(find.text('삿포로 & 오타루 눈꽃 축제'), findsOneWidget);

      // 짐 싸기 진행률 바 및 텍스트 노출 확인
      expect(find.text('짐 싸기 진행률'), findsWidgets);

      // 여행 사이사이 계획 인서트 확인
      expect(find.textContaining('사이 준비'), findsWidgets);
      expect(find.text('사이 계획 추가'), findsWidgets);
      expect(find.text('오사카 특급 라피트 열차 왕복권 예매'), findsOneWidget);
      expect(find.text('엔화(JPY) 우대 환전 신청 (트래블로그)'), findsOneWidget);
    });

    testWidgets('tapping 새 여행 추가 opens AddTripModal', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TravelCategoryView(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('새 여행 추가'));
      await tester.pumpAndSettle();

      expect(find.byType(AddTripModal), findsOneWidget);
      expect(find.text('새 여행 등록'), findsOneWidget);
      expect(find.text('여행지 명칭'), findsOneWidget);
      expect(find.text('여행 기간 (출발일 ~ 도착일)'), findsOneWidget);
    });

    testWidgets('tapping 사이 계획 추가 opens AddInterPlanModal', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TravelCategoryView(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('사이 계획 추가').first);
      await tester.pumpAndSettle();

      expect(find.byType(AddInterPlanModal), findsOneWidget);
      expect(find.text('여행 사이사이 계획 추가'), findsOneWidget);
      expect(find.text('마일스톤 / 태스크 명칭'), findsOneWidget);
    });

    testWidgets('tapping a trip card opens TripDetailSheet with packing & schedule tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TravelCategoryView(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 제주도 여행 카드 탭
      await tester.tap(find.text('제주도 힐링 여행'));
      await tester.pumpAndSettle();

      // 세부 플래너 바텀시트 확인
      expect(find.byType(TripDetailSheet), findsOneWidget);
      expect(find.textContaining('가방 싸기'), findsWidgets);
      expect(find.textContaining('일자별 일정'), findsOneWidget);
      expect(find.text('필수 템플릿 불러오기'), findsOneWidget);
      expect(find.text('이전 여행 짐 복사'), findsOneWidget);

      // 일자별 일정 탭으로 전환
      await tester.tap(find.textContaining('일자별 일정'));
      await tester.pumpAndSettle();

      expect(find.text('Day 1'), findsWidgets);
      expect(find.text('일정 추가'), findsOneWidget);
    });
  });

  group('Calendar & Dashboard Integration Tests for Travel', () {
    testWidgets('allCalendarEventsProvider contains continuous date bands for registered trips and inter-trip plans', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final events = container.read(allCalendarEventsProvider);
      final travelEvents = events.where((e) => e.categoryKey == 'travel').toList();

      expect(travelEvents, isNotEmpty);
      // 여행 기간 연속 띠 확인
      final jejuEvents = travelEvents.where((e) => e.title.contains('제주도')).toList();
      expect(jejuEvents.length, greaterThanOrEqualTo(3)); // 3일 연속 표시

      // 사이 계획 마일스톤 확인
      final interEvent = travelEvents.where((e) => e.title.contains('라피트')).toList();
      expect(interEvent, isNotEmpty);
    });

    testWidgets('CategorySummaryDashboardCard displays Next Trip info when category is travel', (tester) async {
      final travelCategory = CategoryModel(
        id: 'cat-travel',
        categoryKey: 'travel',
        name: '여행',
        icon: '✈️',
        createdAt: DateTime(2026, 1, 1),
        colorHex: '#2C3E50',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CategorySummaryDashboardCard(
                category: travelCategory,
                countUpItems: const [],
                countDownItems: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('여행'), findsOneWidget);
      expect(find.textContaining('다음 여행:'), findsOneWidget);
      expect(find.textContaining('짐 싸기'), findsOneWidget);
    });

    testWidgets('CategoryDetailScreen renders TravelCategoryView when categoryKey is travel', (tester) async {
      final travelCategory = CategoryModel(
        id: 'cat-travel-2',
        categoryKey: 'travel',
        name: '여행',
        icon: '✈️',
        createdAt: DateTime(2026, 1, 1),
        colorHex: '#2C3E50',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CategoryDetailScreen(category: travelCategory),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TravelCategoryView), findsOneWidget);
      expect(find.text('새 여행'), findsOneWidget);
    });
  });
}
