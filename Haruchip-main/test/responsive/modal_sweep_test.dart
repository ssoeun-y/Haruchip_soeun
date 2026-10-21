import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/calendar/widgets/add_room_event_dialog.dart';
import 'package:haruchip/features/calendar/widgets/add_room_notice_dialog.dart';
import 'package:haruchip/features/calendar/widgets/add_room_vote_dialog.dart';
import 'package:haruchip/features/calendar/widgets/calendar_sync_dialog.dart';
import 'package:haruchip/features/calendar/widgets/create_room_dialog.dart';
import 'package:haruchip/features/calendar/widgets/join_room_dialog.dart';
import 'package:haruchip/features/calendar/widgets/member_color_picker_dialog.dart';
import 'package:haruchip/features/categories/models/category_model.dart';
import 'package:haruchip/features/categories/widgets/add_exam_modal.dart';
import 'package:haruchip/features/categories/widgets/baby_care_history_modal.dart';
import 'package:haruchip/features/categories/widgets/baby_growth_record_modal.dart';
import 'package:haruchip/features/categories/widgets/birthday_friend_modal.dart';
import 'package:haruchip/features/categories/widgets/category_edit_modal.dart';
import 'package:haruchip/features/categories/widgets/category_onboarding_sheets.dart';
import 'package:haruchip/features/categories/widgets/exam_official_db_modal.dart';
import 'package:haruchip/features/couple/widgets/breakup_reunite_dialog.dart';
import 'package:haruchip/features/couple/widgets/couple_relationship_setup_sheet.dart';
import 'package:haruchip/features/couple/widgets/y2k_sticker_drawer.dart';
import 'package:haruchip/features/home/widgets/add_category_dashboard_modal.dart';
import 'package:haruchip/features/home/widgets/add_category_item_dialog.dart';
import 'package:haruchip/features/home/widgets/notification_center_modal.dart';
import 'package:haruchip/features/home/widgets/settings_modal.dart';
import 'package:haruchip/features/military/widgets/military_setup_dialog.dart';
import 'package:haruchip/features/plan/widgets/add_plan_item_dialog.dart';
import 'package:haruchip/features/professional/widgets/add_appointment_modal.dart';
import 'package:haruchip/features/professional/widgets/add_goal_modal.dart';
import 'package:haruchip/features/professional/widgets/add_routine_modal.dart';
import 'package:haruchip/features/professional/widgets/professional_archive_modal.dart';
import 'package:haruchip/features/shared/widgets/haru_calendar_picker.dart';

/// 반응형 점검 (바텀시트/다이얼로그): 화면 점검(responsive_sweep_test)이 못 잡는
/// 팝업류를 여러 폰 크기·큰 글씨·키보드 열림 상태로 띄워서 넘침이 없는지 확인한다.
/// 새 시트/다이얼로그를 만들면 [_modals]에 추가할 것.
class _Device {
  const _Device(this.name, this.size, {this.textScale = 1.0, this.keyboard = 0});
  final String name;
  final Size size;
  final double textScale;
  /// 키보드 높이 (viewInsets.bottom)
  final double keyboard;
}

const _devices = [
  _Device('작은 안드로이드 320', Size(320, 640)),
  _Device('폴드 커버 344', Size(344, 882)),
  _Device('갤럭시 360', Size(360, 780)),
  _Device('iPhone SE 375', Size(375, 667)),
  _Device('iPhone 15 390', Size(390, 844)),
  _Device('Pro Max 430', Size(430, 932)),
  _Device('폴드 펼침 674', Size(674, 841)),
  _Device('갤럭시 360 + 큰 글씨 1.3', Size(360, 780), textScale: 1.3),
  _Device('iPhone SE + 키보드', Size(375, 667), keyboard: 260),
];

typedef _Open = Future<Object?> Function(BuildContext context, WidgetRef ref);

class _Modal {
  const _Modal(this.name, this.open);
  final String name;
  final _Open open;
}

CategoryModel _cat(String key) => CategoryModel(
      id: 'cat-$key',
      categoryKey: key,
      name: key,
      emoji: '✨',
      createdAt: DateTime(2026, 1, 1),
      metadata: const {'isInitialized': true},
    );

final _modals = <_Modal>[
  // 모임방
  _Modal('모임방 일정 추가', (c, r) => showAddRoomEventDialog(c, roomId: 'room-1', authorUid: 'u1')),
  _Modal('모임방 공지 추가', (c, r) => showAddRoomNoticeDialog(c, authorName: '소은', authorIcon: '🐰')),
  _Modal('모임방 투표 추가', (c, r) => showAddRoomVoteDialog(c, authorUid: 'u1')),
  _Modal('캘린더 연동', (c, r) => showCalendarSyncDialog(c, '저녁 약속')),
  _Modal('모임방 만들기', (c, r) => showCreateRoomDialog(c, r)),
  _Modal('모임방 참여', (c, r) => showJoinRoomDialog(c, r)),
  _Modal('멤버 색 고르기', (c, r) => showMemberColorPickerDialog(c, currentColorHex: '#F9A8D4', takenColorHexList: const [])),
  // 카테고리
  _Modal('시험 추가', (c, r) => showAddExamModal(c)),
  _Modal('시험 공식 DB', (c, r) => showExamOfficialDbModal(c)),
  _Modal('육아 기록 내역', (c, r) => showBabyCareHistoryModal(c, careLogs: const [])),
  _Modal('성장 기록', (c, r) => showBabyGrowthRecordModal(c)),
  _Modal('생일 친구 추가', (c, r) => showBirthdayFriendModal(c)),
  _Modal('카테고리 편집', (c, r) => showCategoryEditModal(c, category: _cat('custom'))),
  for (final k in ['military', 'baby', 'solo', 'fandom', 'pet', 'custom'])
    _Modal('온보딩 시트-$k', (c, r) => showContentSheetForCategory(c, category: _cat(k), ref: r)),
  // 커플
  _Modal('이별 날짜', (c, r) => BreakupReuniteDialog.show(c, mode: BreakupReuniteDialogMode.breakup)),
  _Modal('재회 날짜', (c, r) => BreakupReuniteDialog.show(c, mode: BreakupReuniteDialogMode.reunite)),
  _Modal('커플 관계 설정', (c, r) => showCoupleRelationshipSetupSheet(c, r)),
  _Modal('Y2K 스티커', (c, r) => showY2KStickerDrawer(c, onSelectSticker: (_, {customText, tapeColor}) {})),
  // 홈
  _Modal('카테고리 추가', (c, r) => showAddCategoryDashboardModal(c)),
  _Modal('카테고리 항목 추가', (c, r) => showAddCategoryItemDialog(c, categoryKey: 'plan')),
  _Modal('알림 센터', (c, r) => showNotificationCenterModal(c)),
  _Modal('설정 모달', (c, r) => showSettingsModal(c)),
  // 군대/계획/전문
  _Modal('군대 설정', (c, r) => showMilitarySetupDialog(c)),
  _Modal('계획 추가', (c, r) => AddPlanItemDialog.show(c)),
  _Modal('약속 추가', (c, r) => showAddAppointmentModal(c)),
  _Modal('목표 추가', (c, r) => showAddGoalModal(c)),
  _Modal('루틴 추가', (c, r) => showAddRoutineModal(c)),
  _Modal('보관함', (c, r) => showProfessionalArchiveModal(c,
      goals: const [], appointments: const [], onGoalsChanged: (_) {}, onAppointmentsChanged: (_) {})),
  // 공통
  _Modal('일정 추가 시트', (c, r) => showAddEventBottomSheet(c, categoryKey: 'plan')),
  _Modal('날짜 피커', (c, r) => showHaruDatePicker(c, initialDate: DateTime(2026, 10, 21))),
];

Future<List<String>> _openAndCollect(WidgetTester tester, _Device d, _Modal m) async {
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
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          // builder로 감싸야 Navigator 위로 뜨는 시트/다이얼로그에도 적용된다.
          builder: (context, child) => MediaQuery(
            data: MediaQueryData(
              size: d.size,
              textScaler: TextScaler.linear(d.textScale),
              viewInsets: EdgeInsets.only(bottom: d.keyboard),
            ),
            child: child!,
          ),
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(onPressed: () => m.open(context, ref), child: const Text('OPEN')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  } catch (e) {
    problems.add('예외: ${e.toString().split('\n').first}');
  } finally {
    FlutterError.onError = oldOnError;
  }
  return problems.toSet().toList();
}

void main() {
  testWidgets('반응형 점검: 모든 바텀시트/다이얼로그 × 폰 크기 × 큰 글씨 × 키보드', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.setSurfaceSize(null);
    });
    final report = <String>[];
    for (final m in _modals) {
      for (final d in _devices) {
        for (final p in await _openAndCollect(tester, d, m)) {
          report.add('[${m.name}] (${d.name}) $p');
        }
      }
    }
    for (final line in report) {
      // ignore: avoid_print
      print('RESPONSIVE| $line');
    }
    expect(report, isEmpty, reason: '반응형 문제 ${report.length}건 — 위 RESPONSIVE| 줄 참고');
  }, timeout: const Timeout(Duration(minutes: 15)));
}
