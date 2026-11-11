import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/onboarding/screens/category_selection_screen.dart';
import 'package:haruchip/features/onboarding/screens/dashboard_view_mode_screen.dart';

Future<ProviderContainer> _pumpSelection(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CategorySelectionScreen()),
    ),
  );
  return container;
}

void main() {
  testWidgets('카테고리를 1개 이상 고르기 전에는 다음 단계로 이동하지 않는다', (tester) async {
    await _pumpSelection(tester);

    expect(find.text('카테고리를 1개 이상 선택해주세요'), findsOneWidget);
    expect(find.byType(DashboardViewModeScreen), findsNothing);
  });

  testWidgets('커플을 고르면 만난 날 설정을 마쳐야 다음 단계로 이동한다', (tester) async {
    final c = await _pumpSelection(tester);

    await tester.tap(find.text('커플'));
    await tester.pump();
    await tester.tap(find.text('다음으로'));
    await tester.pumpAndSettle();

    // 처음 시작할 때 커플 내용(만난 날 및 재회)을 먼저 입력
    expect(find.text('만난 날 및 재회 설정'), findsOneWidget);
    expect(find.byType(DashboardViewModeScreen), findsNothing);
    expect(c.read(categoryListProvider), isEmpty);

    await tester.tap(find.text('설정 완료'));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardViewModeScreen), findsOneWidget);
    final cat = c.read(categoryListProvider).single;
    expect(cat.categoryKey, 'couple');
    expect(cat.metadata?['isInitialized'], isTrue);
  });

  testWidgets('내용 입력을 닫으면 "다시 입력 / 빼기"를 묻고, 다시 입력하면 입력창이 또 뜬다', (tester) async {
    final c = await _pumpSelection(tester);

    await tester.tap(find.text('커플'));
    await tester.pump();
    await tester.tap(find.text('다음으로'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close).last); // 설정 시트 X
    await tester.pumpAndSettle();
    expect(find.text("'커플' 내용을 입력해주세요"), findsOneWidget);

    await tester.tap(find.text('다시 입력하기'));
    await tester.pumpAndSettle();
    expect(find.text('만난 날 및 재회 설정'), findsOneWidget);
    expect(c.read(categoryListProvider), isEmpty);
  });

  testWidgets('"이 카테고리 빼기"를 고르면 추가되지 않고, 남은 게 없으면 선택 화면에 머문다', (tester) async {
    final c = await _pumpSelection(tester);

    await tester.tap(find.text('커플'));
    await tester.pump();
    await tester.tap(find.text('다음으로'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 카테고리 빼기'));
    await tester.pumpAndSettle();

    expect(c.read(categoryListProvider), isEmpty);
    expect(find.byType(DashboardViewModeScreen), findsNothing);
    expect(find.text('카테고리를 1개 이상 선택해주세요'), findsOneWidget);
  });
}
