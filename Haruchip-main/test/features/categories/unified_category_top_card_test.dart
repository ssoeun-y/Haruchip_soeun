import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/widgets/unified_category_top_card.dart';

void main() {
  testWidgets('UnifiedCategoryTopCard renders couple preset layout matching baby card format', (tester) async {
    var manageTapped = false;
    var editAvatarTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnifiedCategoryTopCard(
            categoryKey: 'couple',
            title: '우리 사랑한 지',
            symbol: '❤️',
            coreDDayText: '사랑한 지 520일째',
            startDateText: '시작일: 2024.05.14',
            reunionOrExtraBadge: '재회 기간 제외: 14일',
            onEditAvatar: () => editAvatarTapped = true,
            onManageSection: () => manageTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('우리 사랑한 지'), findsOneWidget);
    expect(find.text('❤️'), findsWidgets);
    expect(find.text('사랑한 지 520일째'), findsOneWidget);
    expect(find.text('시작일: 2024.05.14'), findsOneWidget);
    expect(find.text('재회 기간 제외: 14일'), findsOneWidget);
    expect(find.text('섹션 관리'), findsOneWidget);

    await tester.tap(find.text('섹션 관리'));
    expect(manageTapped, isTrue);

    await tester.tap(find.byIcon(Icons.edit_rounded));
    expect(editAvatarTapped, isTrue);
  });

  testWidgets('UnifiedCategoryTopCard renders my category preset layout', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UnifiedCategoryTopCard(
            categoryKey: 'solo',
            title: '나만의 디데이',
            symbol: '📔',
            coreDDayText: '목표 D-45',
            startDateText: '시작일: 2026.01.01',
          ),
        ),
      ),
    );

    expect(find.text('나만의 디데이'), findsOneWidget);
    expect(find.text('📔'), findsWidgets);
    expect(find.text('목표 D-45'), findsOneWidget);
    expect(find.text('시작일: 2026.01.01'), findsOneWidget);
  });
}
