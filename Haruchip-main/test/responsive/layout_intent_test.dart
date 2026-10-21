import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/categories/screens/category_detail_screen.dart';
import 'package:haruchip/features/home/screens/dashboard_screen.dart';
import 'package:haruchip/features/home/screens/trash_bin_screen.dart';
import 'package:haruchip/features/home/widgets/dashboard_view_mode_toggle.dart';

/// 반응형 수정(줄바꿈 허용)이 "보통 폰에서는 원래 배치 그대로"인지 확인.
/// 줄바꿈은 자리가 모자랄 때만 일어나야 한다.
Future<ProviderContainer> _pump(WidgetTester tester, Widget Function(ProviderContainer) build,
    {double width = 430, void Function(ProviderContainer)? setup}) async {
  await tester.binding.setSurfaceSize(Size(width, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final c = ProviderContainer();
  addTearDown(c.dispose);
  setup?.call(c);
  await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(home: build(c))));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return c;
}

void main() {
  testWidgets('대시보드: 보통 폰(430)에서는 보기 방식 토글과 [순서 편집]이 한 줄, 버튼은 오른쪽 끝', (tester) async {
    await _pump(tester, (_) => const DashboardScreen());

    final toggle = tester.getRect(find.byType(DashboardViewModeToggle));
    final edit = tester.getRect(find.text('순서 편집'));
    expect((edit.center.dy - toggle.center.dy).abs(), lessThan(8), reason: '같은 줄');
    expect(edit.right, greaterThan(430 - 80), reason: '오른쪽 끝 쪽');
  });

  testWidgets('시험 요약 바: 보통 폰(430)에서는 [공식 DB][추가]가 제목과 한 줄, 오른쪽 끝', (tester) async {
    late dynamic category;
    await _pump(
      tester,
      (_) => CategoryDetailScreen(category: category),
      setup: (c) {
        final n = c.read(categoryListProvider.notifier);
        final cat = n.addCategory(categoryKey: 'exam', name: '자격증', emoji: '📚', colorHex: '#4F46E5');
        category = cat.copyWith(metadata: {'isInitialized': true});
        n.updateCategory(category);
      },
    );

    final title = tester.getRect(find.text('시험 파이프라인 관리'));
    final add = tester.getRect(find.text('추가').first);
    expect((add.center.dy - title.center.dy).abs(), lessThan(10), reason: '같은 줄');
    expect(add.right, greaterThan(430 - 80), reason: '오른쪽 끝 쪽');
  });

  testWidgets('휴지통 카드: 남은 기간 배지는 오른쪽 끝', (tester) async {
    await _pump(tester, (_) => const TrashBinScreen());

    final badge = tester.getRect(find.textContaining('남은 복구 기간').first);
    expect(badge.right, greaterThan(430 - 80));
  });
}
