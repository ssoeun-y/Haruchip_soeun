import 'package:flutter/material.dart' show TimeOfDay;
import '../models/wedding_item.dart';

/// 사용자가 선택 가능한 가용 요일 및 시간대 슬롯
enum AvailableTimeSlot {
  weekdayEvening(
    labelKo: '평일 저녁 (19:00~21:00)',
    shortLabel: '평일 저녁',
    defaultHour: 19,
    defaultMinute: 30,
    allowedWeekdays: [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ],
  ),
  saturday(
    labelKo: '토요일 (11:00~17:00)',
    shortLabel: '토요일 낮',
    defaultHour: 13,
    defaultMinute: 0,
    allowedWeekdays: [DateTime.saturday],
  ),
  sunday(
    labelKo: '일요일 (11:00~17:00)',
    shortLabel: '일요일 낮',
    defaultHour: 13,
    defaultMinute: 0,
    allowedWeekdays: [DateTime.sunday],
  ),
  weekdayDaytime(
    labelKo: '평일 낮 (10:00~17:00)',
    shortLabel: '평일 낮 (휴가/월차)',
    defaultHour: 14,
    defaultMinute: 0,
    allowedWeekdays: [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ],
  );

  const AvailableTimeSlot({
    required this.labelKo,
    required this.shortLabel,
    required this.defaultHour,
    required this.defaultMinute,
    required this.allowedWeekdays,
  });

  final String labelKo;
  final String shortLabel;
  final int defaultHour;
  final int defaultMinute;
  final List<int> allowedWeekdays;

  TimeOfDay get defaultTime =>
      TimeOfDay(hour: defaultHour, minute: defaultMinute);
}

/// 대한민국 웨딩 표준 타임라인 기반 결정론적(Deterministic) 역산 알고리즘 엔진
class WeddingSchedulerEngine {
  const WeddingSchedulerEngine();

  /// 본식일(weddingDate, T) 및 사용자 가용 요일/시간대 목록을 받아 57개 항목에
  /// 스마트 자동 스냅(Auto-Snapping)된 날짜와 시간을 일괄 계산하여 반환한다.
  List<WeddingItem> scheduleItems({
    required DateTime weddingDate,
    required List<WeddingItem> items,
    required Set<AvailableTimeSlot> availableSlots,
  }) {
    final effectiveSlots = availableSlots.isEmpty
        ? {
            AvailableTimeSlot.saturday,
            AvailableTimeSlot.sunday,
            AvailableTimeSlot.weekdayEvening,
          }
        : availableSlots;

    final weddingDayOnly =
        DateTime(weddingDate.year, weddingDate.month, weddingDate.day);

    return items.map((item) {
      // 본식 당일 (T-0)인 경우 예식일 본식 시간(예: 12:30)으로 확정
      if (item.standardOffsetDays == 0) {
        return item.copyWith(
          targetDate: weddingDayOnly,
          deadlineTime: const TimeOfDay(hour: 12, minute: 30),
        );
      }

      // 본식일 기준 T - N일 계산
      final rawTargetDate = weddingDayOnly
          .subtract(Duration(days: item.standardOffsetDays));

      // 평일 방문이 필수적이거나 유리한 항목 (드레스 투어, 본식 가봉, 웨딩 네일 등)
      // 사용자 가용 목록에 평일이 포함되어 있으면 평일 슬롯을 우선 적용
      Set<AvailableTimeSlot> targetSlots = effectiveSlots;
      if (item.isWeekdayPreferred) {
        final weekdaySlots = effectiveSlots.where((s) =>
            s == AvailableTimeSlot.weekdayEvening ||
            s == AvailableTimeSlot.weekdayDaytime).toSet();
        if (weekdaySlots.isNotEmpty) {
          targetSlots = weekdaySlots;
        }
      }

      // rawTargetDate 주변의 날짜 중 가용 요일에 부합하는 가장 가까운 날짜 탐색
      // 여유 있는 준비를 위해 동일 거리일 경우 약간 더 이른 날짜(버퍼 확보) 우선
      final snappedResult = _findNearestAvailableDate(
        rawTargetDate: rawTargetDate,
        targetSlots: targetSlots,
      );

      return item.copyWith(
        targetDate: snappedResult.date,
        deadlineTime: snappedResult.time,
      );
    }).toList();
  }

  /// 기준일(rawTargetDate)에서 가용 요일/시간대 조건을 만족하는 가장 가까운 날짜 스냅
  ({DateTime date, TimeOfDay time}) _findNearestAvailableDate({
    required DateTime rawTargetDate,
    required Set<AvailableTimeSlot> targetSlots,
  }) {
    // 0일, -1일, +1일, -2일, +2일 ... 최대 14일 반경 탐색
    const searchDeltas = [
      0,
      -1, 1,
      -2, 2,
      -3, 3,
      -4, 4,
      -5, 5,
      -6, 6,
      -7, 7,
      -8, 8,
      -9, 9,
      -10, 10,
      -11, 11,
      -12, 12,
      -13, 13,
      -14, 14,
    ];

    for (final delta in searchDeltas) {
      final candidateDate = rawTargetDate.add(Duration(days: delta));
      final candidateWeekday = candidateDate.weekday;

      // 해당 요일을 지원하는 가용 슬롯 탐색
      for (final slot in targetSlots) {
        if (slot.allowedWeekdays.contains(candidateWeekday)) {
          return (
            date: candidateDate,
            time: slot.defaultTime,
          );
        }
      }
    }

    // 만약 탐색 반경 내 매칭되지 않을 경우 rawTargetDate 및 첫 번째 슬롯 시간대 반환
    return (
      date: rawTargetDate,
      time: targetSlots.first.defaultTime,
    );
  }
}
