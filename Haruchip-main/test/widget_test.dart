// 앱 최상위 스모크 테스트: 온보딩 진입점이 크래시 없이 뜨는지만 확인한다.
// (이전 버전은 flutter create 기본 카운터 템플릿을 그대로 남긴 것으로,
// 존재하지 않는 MyApp을 참조해 컴파일이 깨져 있었다.)
//
// (2부 갱신) 온보딩 재배선으로 앱 진입점이 로그인 화면에서 스플래시
// 화면으로 바뀌었다(CLAUDE.md §8: 스플래시 → 로그인 → ...).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:haruchip/main.dart';

void main() {
  testWidgets('앱 진입 시 온보딩 스플래시 화면이 뜬다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: HaruChipApp()),
    );

    expect(find.text('하루의 소중한 조각들을 담아봐요'), findsOneWidget);
  });
}
