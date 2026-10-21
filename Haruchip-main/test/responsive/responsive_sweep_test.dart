import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/calendar/screens/calendar_screen.dart';
import 'package:haruchip/features/calendar/screens/schedule_room_detail_screen.dart';
import 'package:haruchip/features/calendar/screens/schedule_room_list_screen.dart';
import 'package:haruchip/features/calendar/screens/settlement_screen.dart';
import 'package:haruchip/features/categories/models/category.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/features/categories/screens/category_detail_screen.dart';
import 'package:haruchip/features/categories/screens/couple_category_detail_screen.dart';
import 'package:haruchip/features/couple/providers/couple_provider.dart';
import 'package:haruchip/features/couple/screens/couple_room_screen.dart';
import 'package:haruchip/features/couple/screens/couple_screen.dart';
import 'package:haruchip/features/home/screens/dashboard_screen.dart';
import 'package:haruchip/features/home/screens/main_shell_screen.dart';
import 'package:haruchip/features/home/screens/trash_bin_screen.dart';
import 'package:haruchip/features/onboarding/data/onboarding_categories.dart';
import 'package:haruchip/features/onboarding/screens/calendar_integration_screen.dart';
import 'package:haruchip/features/onboarding/screens/category_selection_screen.dart';
import 'package:haruchip/features/onboarding/screens/dashboard_view_mode_screen.dart';
import 'package:haruchip/features/onboarding/screens/login_screen.dart';
import 'package:haruchip/features/onboarding/screens/onboarding_complete_screen.dart';
import 'package:haruchip/features/onboarding/screens/widget_guide_screen.dart';
import 'package:haruchip/features/plan/screens/plan_screen.dart';
import 'package:haruchip/features/settings/screens/hidden_categories_screen.dart';
import 'package:haruchip/features/settings/screens/settings_screen.dart';
import 'package:haruchip/features/widgets/screens/widget_simulator_screen.dart';

/// 반응형 점검: 주요 화면을 여러 폰 크기·큰 글씨로 그려서 레이아웃 오류
/// (RenderFlex 넘침 등)가 없는지 확인한다. 새 화면을 만들면 [_screens]에 추가할 것.
class _Device {
  const _Device(this.name, this.size, [this.textScale = 1.0]);
  final String name;
  final Size size;
  final double textScale;
}

const _devices = [
  _Device('작은 안드로이드 320', Size(320, 640)),
  _Device('폴드 커버 344', Size(344, 882)),
  _Device('갤럭시 360', Size(360, 780)),
  _Device('iPhone SE 375', Size(375, 667)),
  _Device('iPhone 15 390', Size(390, 844)),
  _Device('Pro Max 430', Size(430, 932)),
  _Device('폴드 펼침 674', Size(674, 841)),
  _Device('갤럭시 360 + 큰 글씨 1.3', Size(360, 780), 1.3),
];

typedef _Setup = void Function(ProviderContainer c);

class _Screen {
  const _Screen(this.name, this.build, {this.setup, this.tapTab});
  final String name;
  final Widget Function() build;
  final _Setup? setup;
  /// 화면을 띄운 뒤 눌러볼 탭 이름 (탭 화면 점검용)
  final String? tapTab;
}

Category _initialized(ProviderContainer c, String key, String label) {
  final n = c.read(categoryListProvider.notifier);
  final cat = n.addCategory(categoryKey: key, name: label, emoji: '✨', colorHex: '#4F46E5');
  final ready = cat.copyWith(metadata: {'isInitialized': true});
  n.updateCategory(ready);
  return ready;
}

void _seedAllCategories(ProviderContainer c) {
  for (final t in kOnboardingCategories) {
    _initialized(c, t.key, t.labelKo);
  }
}

void _realCouple(ProviderContainer c) {
  // 목업 날짜(2024-05-14)면 커플 화면이 설정 시트를 띄우므로 실제 날짜로 바꿔둔다.
  c.read(coupleProvider.notifier).updateRelationship(startDate: DateTime(2025, 3, 14), reunions: const []);
}

final _screens = <_Screen>[
  // 온보딩
  _Screen('로그인', () => LoginScreen(onNext: () {})),
  _Screen('카테고리 선택', () => const CategorySelectionScreen()),
  _Screen('대시보드 보기 방식', () => DashboardViewModeScreen(onNext: () {})),
  _Screen('온보딩 완료', () => OnboardingCompleteScreen(onFinish: () {})),
  _Screen('캘린더 연동 설정', () => const CalendarIntegrationScreen()),
  _Screen('위젯 가이드', () => const WidgetGuideScreen()),
  // 메인 탭
  _Screen('메인 셸(하단 탭)', () => const MainShellScreen(), setup: _seedAllCategories),
  _Screen('대시보드(전체 카테고리)', () => const DashboardScreen(), setup: _seedAllCategories),
  _Screen('캘린더', () => const CalendarScreen()),
  _Screen('모임방 목록', () => const ScheduleRoomListScreen()),
  _Screen('커플방', () => const CoupleRoomScreen(), setup: _realCouple),
  _Screen('커플(기록)', () => const CoupleScreen(), setup: _realCouple),
  _Screen('계획(칸반)', () => const PlanScreen()),
  // 모임방
  _Screen('모임방 상세-공유 캘린더', () => const ScheduleRoomDetailScreen(roomId: 'room-1')),
  _Screen('모임방 상세-일정 조율', () => const ScheduleRoomDetailScreen(roomId: 'room-1'), tapTab: '일정 조율'),
  _Screen('모임방 상세-공지/투표', () => const ScheduleRoomDetailScreen(roomId: 'room-1'), tapTab: '공지 / 투표'),
  _Screen('모임방 상세-정산 장부', () => const ScheduleRoomDetailScreen(roomId: 'room-1'), tapTab: '정산 장부'),
  _Screen('정산', () => const SettlementScreen(roomId: 'room-1')),
  // 설정류
  _Screen('설정', () => const SettingsScreen()),
  _Screen('휴지통', () => const TrashBinScreen()),
  _Screen('숨김 카드 보관함', () => const HiddenCategoriesScreen()),
  _Screen('위젯 시뮬레이터', () => const WidgetSimulatorScreen()),
];

Future<List<String>> _pumpAndCollect(
  WidgetTester tester,
  _Device d,
  Widget Function(ProviderContainer c) builder, {
  _Setup? setup,
  String? tapTab,
}) async {
  final problems = <String>[];
  final oldOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString().split('\n').first;
    final where = RegExp(r'lib/[^\s:]+\.dart:\d+').firstMatch(details.toString())?.group(0) ?? '';
    problems.add('$msg ${where.isEmpty ? '' : '@ $where'}'.trim());
  };
  try {
    await tester.binding.setSurfaceSize(d.size);
    tester.view.physicalSize = d.size;
    tester.view.devicePixelRatio = 1.0;
    final c = ProviderContainer();
    setup?.call(c);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: d.size, textScaler: TextScaler.linear(d.textScale)),
            child: builder(c),
          ),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (tapTab != null && find.text(tapTab).evaluate().isNotEmpty) {
      await tester.tap(find.text(tapTab).first);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    await tester.pumpWidget(const SizedBox()); // 타이머/애니메이션 정리
    c.dispose();
  } catch (e) {
    problems.add('예외: ${e.toString().split('\n').first}');
  } finally {
    FlutterError.onError = oldOnError;
  }
  return problems.toSet().toList();
}

void main() {
  testWidgets('반응형 점검: 모든 주요 화면 × 폰 크기 × 큰 글씨', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.setSurfaceSize(null);
    });
    final report = <String>[];

    Future<void> check(String name, Widget Function(ProviderContainer c) builder,
        {_Setup? setup, String? tapTab}) async {
      for (final d in _devices) {
        final problems = await _pumpAndCollect(tester, d, builder, setup: setup, tapTab: tapTab);
        for (final p in problems) {
          report.add('[$name] (${d.name}) $p');
        }
      }
    }

    for (final s in _screens) {
      await check(s.name, (_) => s.build(), setup: s.setup, tapTab: s.tapTab);
    }

    // 카테고리 상세 (종류별)
    for (final t in kOnboardingCategories) {
      late Category cat;
      await check(
        '카테고리 상세-${t.labelKo}',
        (_) => t.key == 'couple' ? CoupleCategoryDetailScreen(category: cat) : CategoryDetailScreen(category: cat),
        setup: (c) {
          if (t.key == 'couple') _realCouple(c);
          cat = _initialized(c, t.key, t.labelKo);
        },
      );
    }
    // 문제가 있으면 어느 화면·기기·코드 줄인지 한 줄씩 출력
    for (final line in report) {
      // ignore: avoid_print
      print('RESPONSIVE| $line');
    }
    expect(report, isEmpty, reason: '반응형 문제 ${report.length}건 — 위 RESPONSIVE| 줄 참고');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
