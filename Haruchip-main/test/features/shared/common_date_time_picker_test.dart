import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:haruchip/features/shared/widgets/common_date_time_picker.dart';

void main() {
  group('CommonDateTimePicker Widget Tests', () {
    testWidgets('renders all day toggle, start/end rows, and timezone label', (tester) async {
      final initialStart = DateTime(2026, 11, 2, 20, 0); // 오후 8:00
      final initialEnd = DateTime(2026, 11, 2, 21, 30); // 오후 9:30

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonDateTimePicker(
              initialStartDate: initialStart,
              initialEndDate: initialEnd,
              isAllDay: false,
              hasEndDate: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Controls check
      expect(find.text('하루 종일'), findsOneWidget);
      expect(find.byType(CupertinoSwitch), findsOneWidget);

      // Start row
      expect(find.text('시작'), findsOneWidget);
      expect(find.text('2026. 11. 2.'), findsWidgets);
      expect(find.text('오후 8:00'), findsOneWidget);

      // End row
      expect(find.text('종료'), findsOneWidget);
      expect(find.text('오후 9:30'), findsOneWidget);

      // Timezone label
      expect(find.text('시간대: 서울 >'), findsOneWidget);
    });

    testWidgets('toggling all day hides time pills and triggers onAllDayChanged', (tester) async {
      bool? lastAllDay;
      final initialStart = DateTime(2026, 11, 2, 14, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonDateTimePicker(
              initialStartDate: initialStart,
              isAllDay: false,
              hasEndDate: false,
              onAllDayChanged: (ad) => lastAllDay = ad,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('오후 2:00'), findsOneWidget);

      // Toggle switch to true
      await tester.tap(find.byType(CupertinoSwitch));
      await tester.pumpAndSettle();

      expect(lastAllDay, isTrue);
      // Time pill is hidden when all day is enabled
      expect(find.text('오후 2:00'), findsNothing);
    });

    testWidgets('tapping start date pill expands inline wheel date picker with header', (tester) async {
      final initialStart = DateTime(2026, 11, 2, 14, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonDateTimePicker(
              initialStartDate: initialStart,
              hasEndDate: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap date pill
      await tester.tap(find.text('2026. 11. 2.'));
      await tester.pumpAndSettle();

      // Inline picker header
      expect(find.text('2026년 11월 ∨'), findsOneWidget);
      // Wheels are present
      expect(find.byType(CupertinoPicker), findsWidgets);
    });

    testWidgets('tapping start time pill expands inline wheel time picker', (tester) async {
      final initialStart = DateTime(2026, 11, 2, 14, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonDateTimePicker(
              initialStartDate: initialStart,
              hasEndDate: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap time pill
      await tester.tap(find.text('오후 2:00'));
      await tester.pumpAndSettle();

      // Time wheels
      expect(find.text('오후'), findsWidgets);
      expect(find.text('2시'), findsWidgets);
      expect(find.text('00분'), findsWidgets);
      expect(find.byType(CupertinoPicker), findsWidgets);
    });

    testWidgets('tapping timezone opens timezone bottom sheet and updates selected timezone', (tester) async {
      String? updatedTz;
      final initialStart = DateTime(2026, 11, 2, 14, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonDateTimePicker(
              initialStartDate: initialStart,
              hasEndDate: false,
              onTimeZoneChanged: (tz) => updatedTz = tz,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap timezone pill
      expect(find.text('시간대: 서울 >'), findsOneWidget);
      await tester.tap(find.text('시간대: 서울 >'));
      await tester.pumpAndSettle();

      // Timezone modal opens
      expect(find.text('시간대 설정'), findsOneWidget);
      expect(find.text('일본 (도쿄)'), findsOneWidget);
      expect(find.text('중국 (베이징)'), findsOneWidget);

      // Tap Tokyo
      await tester.tap(find.text('일본 (도쿄)'));
      await tester.pumpAndSettle();

      expect(updatedTz, '도쿄');
      expect(find.text('시간대 설정'), findsNothing);
      expect(find.text('시간대: 도쿄 >'), findsOneWidget);
    });
  });

  group('CommonDateTimePicker Modal Helpers', () {
    testWidgets('showCommonDatePickerModal opens sheet and returns selected date', (tester) async {
      DateTime? resultDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  resultDate = await showCommonDatePickerModal(
                    ctx,
                    initialDate: DateTime(2026, 11, 15),
                    title: '날짜 선택',
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('날짜 선택'), findsOneWidget);
      expect(find.text('2026. 11. 15.'), findsOneWidget);
      expect(find.text('완료'), findsOneWidget);

      await tester.tap(find.text('완료'));
      await tester.pumpAndSettle();

      expect(resultDate, DateTime(2026, 11, 15));
    });

    testWidgets('showCommonDateTimePickerModal opens sheet and returns selected datetime', (tester) async {
      DateTime? resultDateTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  resultDateTime = await showCommonDateTimePickerModal(
                    ctx,
                    initialDateTime: DateTime(2026, 11, 2, 20, 0),
                    title: '일시 선택',
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('일시 선택'), findsOneWidget);
      expect(find.text('오후 8:00'), findsOneWidget);

      await tester.tap(find.text('완료'));
      await tester.pumpAndSettle();

      expect(resultDateTime, DateTime(2026, 11, 2, 20, 0));
    });
  });
}
