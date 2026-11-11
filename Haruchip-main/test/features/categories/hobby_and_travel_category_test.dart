import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/data/category_types.dart';
import 'package:haruchip/features/categories/models/category.dart';
import 'package:haruchip/features/categories/widgets/unified_category_top_card.dart';
import 'package:haruchip/features/home/screens/dashboard_screen.dart';
import 'package:haruchip/features/home/widgets/category_summary_dashboard_card.dart';
import 'package:haruchip/features/onboarding/data/onboarding_categories.dart';
import 'package:haruchip/features/plan/models/plan_item.dart';

void main() {
  group('Hobby & Travel Category Definitions', () {
    test('kOnboardingCategories contains hobby and travel with assigned emojis', () {
      final hobby = kOnboardingCategories.firstWhere((c) => c.key == 'hobby');
      final travel = kOnboardingCategories.firstWhere((c) => c.key == 'travel');

      expect(hobby.labelKo, '취미');
      expect(hobby.emoji, '🎨');
      expect(travel.labelKo, '여행');
      expect(travel.emoji, '✈️');

      expect(ddayTitlePlaceholder['hobby'], isNotNull);
      expect(ddayTitlePlaceholder['travel'], isNotNull);
    });

    test('CategoryThemePalette provides accurate colors for hobby and travel', () {
      final hobbyPalette = CategoryThemePalette.forCategoryKey('hobby');
      expect(hobbyPalette.bg, const Color(0xFFF4F7F4));
      expect(hobbyPalette.border, const Color(0xFFDDE7DD));
      expect(hobbyPalette.text, const Color(0xFF354235));

      final travelPalette = CategoryThemePalette.forCategoryKey('travel');
      expect(travelPalette.bg, const Color(0xFFF0F8FF));
      expect(travelPalette.border, const Color(0xFFD6ECFF));
      expect(travelPalette.text, const Color(0xFF2C3E50));
    });
  });

  group('UnifiedCategoryTopCard for Hobby and Travel', () {
    testWidgets('UnifiedCategoryTopCard renders hobby card with theme palette', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedCategoryTopCard(
              categoryKey: 'hobby',
              title: '기타 연습',
              symbol: '🎸',
              coreDDayText: '기타 친 지 45일째',
              startDateText: '시작일: 2026.09.15',
              reunionOrExtraBadge: '이번 달 12회 완료',
              onManageSection: () {},
            ),
          ),
        ),
      );

      expect(find.text('기타 연습'), findsOneWidget);
      expect(find.text('🎸'), findsOneWidget);
      expect(find.text('기타 친 지 45일째'), findsOneWidget);
      expect(find.text('시작일: 2026.09.15'), findsOneWidget);
      expect(find.text('이번 달 12회 완료'), findsOneWidget);
      expect(find.text('섹션 관리'), findsOneWidget);
    });

    testWidgets('UnifiedCategoryTopCard renders travel card with theme palette', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedCategoryTopCard(
              categoryKey: 'travel',
              title: '오사카 여행',
              symbol: '✈️',
              coreDDayText: '출발 D-14',
              startDateText: '여행 기간: 2026.11.20 ~ 2026.11.24',
              reunionOrExtraBadge: '여행 준비 일정 3개',
              onManageSection: () {},
            ),
          ),
        ),
      );

      expect(find.text('오사카 여행'), findsOneWidget);
      expect(find.text('✈️'), findsWidgets);
      expect(find.text('출발 D-14'), findsOneWidget);
      expect(find.text('여행 기간: 2026.11.20 ~ 2026.11.24'), findsOneWidget);
      expect(find.text('섹션 관리'), findsOneWidget);
    });
  });

  group('CategorySummaryDashboardCard for Hobby and Travel', () {
    testWidgets('CategorySummaryDashboardCard renders hobby summary', (tester) async {
      final category = Category(
        id: 'cat-hobby-1',
        categoryKey: 'hobby',
        name: '기타 연습',
        emoji: '🎸',
        colorHex: '#354235',
        createdAt: DateTime(2026, 1, 1),
        metadata: {'completedCount': 12},
      );

      final plan = PlanItem(
        id: 'plan-1',
        title: '마라톤 대회',
        date: DateTime.now().add(const Duration(days: 30)),
        categoryKey: 'hobby',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CategorySummaryDashboardCard(
                category: category,
                countUpItems: const [],
                countDownItems: [plan],
              ),
            ),
          ),
        ),
      );

      expect(find.text('기타 연습'), findsOneWidget);
      expect(find.text('이번 달 12회 완료'), findsOneWidget);
      expect(find.text('마라톤 대회 D-30'), findsOneWidget);
    });

    testWidgets('CategorySummaryDashboardCard renders travel summary with auto transition', (tester) async {
      final category = Category(
        id: 'cat-travel-1',
        categoryKey: 'travel',
        name: '오사카 여행',
        emoji: '✈️',
        colorHex: '#2C3E50',
        createdAt: DateTime(2026, 1, 1),
        metadata: {
          'startDate': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
          'endDate': DateTime.now().add(const Duration(days: 18)).toIso8601String(),
        },
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

      expect(find.text('오사카 여행'), findsOneWidget);
      expect(find.text('출발 D-14'), findsOneWidget);
    });
  });

  group('DashboardScreen Horizontal Category Filter Chip Bar', () {
    testWidgets('DashboardScreen renders horizontal chip bar with 전체, 취미, 여행', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      expect(find.text('전체'), findsOneWidget);
      expect(find.text('취미'), findsOneWidget);
      expect(find.text('여행'), findsOneWidget);

      // Tap 취미 filter chip
      await tester.tap(find.text('취미'));
      await tester.pumpAndSettle();

      // Tap 전체 filter chip
      await tester.tap(find.text('전체'));
      await tester.pumpAndSettle();
    });
  });
}
