import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import 'package:haruchip/features/shared/widgets/add_event_bottom_sheet.dart';

import '../models/calendar_event.dart';

/// 한국 주요 양력 공휴일 맵 (MM-DD)
const Map<String, String> kKoreanHolidays = {
  '01-01': '신정',
  '03-01': '삼일절',
  '05-05': '어린이날',
  '06-06': '현충일',
  '08-15': '광복절',
  '10-03': '개천절',
  '10-09': '한글날',
  '12-25': '성탄절',
};

/// 한국형 맞춤 월간 캘린더 그리드 (그룹웨어/다우오피스 스타일 컬러 칩 라벨링, 공휴일 표기, 일/월 시작 토글)
class MonthGrid extends StatefulWidget {
  const MonthGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.hasEventOnDate,
    this.getEventsOnDate,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.startOnMonday = false,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final bool Function(DateTime date) hasEventOnDate;
  final List<CalendarEvent> Function(DateTime date)? getEventsOnDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool startOnMonday;

  @override
  State<MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends State<MonthGrid> {
  late bool _startOnMonday;

  @override
  void initState() {
    super.initState();
    _startOnMonday = widget.startOnMonday;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String? _getHolidayName(DateTime date) {
    final key = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return kKoreanHolidays[key];
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return const Color(0xFF007AFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstOfMonth = DateTime(widget.focusedMonth.year, widget.focusedMonth.month, 1);
    final daysInMonth = DateTime(
      widget.focusedMonth.year,
      widget.focusedMonth.month + 1,
      0,
    ).day;

    // 요일 시작 계산 (일요일 시작 vs 월요일 시작)
    final leadingBlanks = _startOnMonday
        ? (firstOfMonth.weekday - 1) % 7
        : firstOfMonth.weekday % 7;

    final weekLabels = _startOnMonday
        ? const ['월', '화', '수', '목', '금', '토', '일']
        : const ['일', '월', '화', '수', '목', '금', '토'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.protoCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.protoCardBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 상단 년/월 헤더 & 이동 버튼 & 일/월 시작 토글
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 4,
                children: [
                  Text(
                    '${widget.focusedMonth.year}년 ${widget.focusedMonth.month}월',
                    style: AppTypography.cardLabel.copyWith(
                      color: AppColors.protoHeading,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _startOnMonday = !_startOnMonday),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _startOnMonday ? '월요일 시작' : '일요일 시작',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.protoSubtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onPreviousMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: AppColors.protoCardText,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: widget.onNextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: AppColors.protoCardText,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 요일 헤더
          Row(
            children: [
              for (int i = 0; i < weekLabels.length; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      weekLabels[i],
                      style: AppTypography.caption.copyWith(
                        color: (_startOnMonday ? i == 6 : i == 0)
                            ? AppColors.danger
                            : (i == (_startOnMonday ? 5 : 6)
                                ? const Color(0xFF1976D2)
                                : AppColors.protoSubtitle),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // 날짜 셀 그리드
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 3,
              childAspectRatio: 0.65,
            ),
            itemCount: leadingBlanks + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final day = index - leadingBlanks + 1;
              final date = DateTime(
                widget.focusedMonth.year,
                widget.focusedMonth.month,
                day,
              );

              final isToday = _isSameDay(date, today);
              final isSelected = _isSameDay(date, widget.selectedDate);
              final dayEvents = widget.getEventsOnDate?.call(date) ?? [];
              final holidayName = _getHolidayName(date);
              final isSunday = date.weekday == DateTime.sunday;
              final isSaturday = date.weekday == DateTime.saturday;

              Color dayTextColor;
              if (isToday) {
                dayTextColor = AppColors.protoButtonText;
              } else if (isSunday || holidayName != null) {
                dayTextColor = AppColors.danger;
              } else if (isSaturday) {
                dayTextColor = const Color(0xFF1976D2);
              } else {
                dayTextColor = AppColors.protoCardText;
              }

              return InkWell(
                onTap: () {
                  widget.onDateSelected(date);
                },
                onDoubleTap: () {
                  widget.onDateSelected(date);
                  showAddEventBottomSheet(
                    context,
                    categoryKey: 'plan',
                    initialDate: date,
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.protoButtonBg
                        : (isSelected
                            ? AppColors.protoCardSelectedBg
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected && !isToday
                          ? AppColors.protoCardSelectedBorder
                          : const Color(0xFFE5E5EA),
                      width: isSelected ? 1.8 : 0.6,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 날짜 숫자 및 공휴일 라벨
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 아주 좁은 폰·큰 글씨에서는 칸보다 숫자가 커질 수 있어 살짝 줄여 맞춘다.
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: isToday
                                ? BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  )
                                : null,
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontWeight: (isToday || isSelected)
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                color: dayTextColor,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                            ),
                          ),
                          if (holidayName != null)
                            Expanded(
                              child: Text(
                                holidayName,
                                style: const TextStyle(
                                  fontSize: 7.5,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // 그룹웨어 감성 둥근 컬러 라벨 바 (Badge Chips)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final ev in dayEvents.take(2))
                              Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: _parseColor(ev.colorHex).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: _parseColor(ev.colorHex).withValues(alpha: 0.7),
                                    width: 0.7,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 3.5,
                                      height: 3.5,
                                      decoration: BoxDecoration(
                                        color: _parseColor(ev.colorHex),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 2.5),
                                    Expanded(
                                      child: Text(
                                        ev.title,
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: _parseColor(ev.colorHex),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (dayEvents.length > 2)
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Text(
                                  '+${dayEvents.length - 2}',
                                  style: const TextStyle(
                                    fontSize: 7.5,
                                    color: AppColors.protoSubtitle,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
