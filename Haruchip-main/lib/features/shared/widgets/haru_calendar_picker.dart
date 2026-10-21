import 'package:flutter/material.dart';
import '../../../design_system/colors.dart';

Future<DateTime?> showHaruDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  DateTime selectedDate = initialDate;
  final fDate = firstDate ?? DateTime(1900);
  final lDate = lastDate ?? DateTime(2100);

  return showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HaruCalendarPicker(
                  initialDate: selectedDate,
                  firstDate: fDate,
                  lastDate: lDate,
                  onDateChanged: (d) {
                    selectedDate = d;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      child: const Text('취소', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx, selectedDate);
                      },
                      child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class HaruCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;

  const HaruCalendarPicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
  });

  @override
  State<HaruCalendarPicker> createState() => _HaruCalendarPickerState();
}

class _HaruCalendarPickerState extends State<HaruCalendarPicker> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  final List<String> _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  @override
  void didUpdateWidget(HaruCalendarPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _selectedDate = widget.initialDate;
      _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    }
  }

  int get _daysInMonth {
    return DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
  }

  int get _firstWeekdayOfMonth {
    final int weekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    return weekday == 7 ? 0 : weekday;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _onDaySelected(DateTime date) {
    if (_isSelectable(date)) {
      setState(() {
        _selectedDate = date;
      });
      widget.onDateChanged(date);
    }
  }

  bool _isSelectable(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final first = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final last = DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
    return !d.isBefore(first) && !d.isAfter(last);
  }

  void _showYearMonthSelector() async {
    final DateTime? result = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return _YearMonthPickerDialog(
          initialMonth: _currentMonth,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
        );
      },
    );

    if (result != null) {
      setState(() {
        _currentMonth = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildWeekdays(),
          const SizedBox(height: 8),
          _buildDaysGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, size: 28),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: _previousMonth,
        ),
        // 좁은 폰·큰 글씨에서는 "YYYY년 M월"을 자르지 않고 살짝 줄여서 보여준다
        Flexible(
          child: InkWell(
          onTap: _showYearMonthSelector,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_currentMonth.year}년 ${_currentMonth.month}월',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Color(0xFF007AFF),
                  size: 22,
                ),
              ],
            ),
            ),
          ),
        ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary, size: 28),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: _nextMonth,
        ),
      ],
    );
  }

  Widget _buildWeekdays() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _weekdays.map((day) {
        final bool isSunday = day == '일';
        final bool isSaturday = day == '토';
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSunday
                    ? const Color(0xFFEF4444)
                    : isSaturday
                        ? const Color(0xFF3B82F6)
                        : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysGrid() {
    final int emptySlots = _firstWeekdayOfMonth;
    final int totalSlots = emptySlots + _daysInMonth;
    final int rows = (totalSlots / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final int index = rowIndex * 7 + colIndex;
              final int day = index - emptySlots + 1;

              if (day <= 0 || day > _daysInMonth) {
                return const Expanded(child: SizedBox(height: 38));
              }

              final date = DateTime(_currentMonth.year, _currentMonth.month, day);
              final bool isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final bool selectable = _isSelectable(date);
              final bool isSunday = colIndex == 0;
              final bool isSaturday = colIndex == 6;

              Color defaultColor = AppColors.textPrimary;
              if (isSunday) defaultColor = const Color(0xFFEF4444);
              if (isSaturday) defaultColor = const Color(0xFF3B82F6);

              return Expanded(
                child: Center(
                  child: InkWell(
                    onTap: selectable ? () => _onDaySelected(date) : null,
                    borderRadius: BorderRadius.circular(19),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (selectable ? defaultColor : AppColors.textDisabled),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _YearMonthPickerDialog extends StatefulWidget {
  final DateTime initialMonth;
  final DateTime firstDate;
  final DateTime lastDate;

  const _YearMonthPickerDialog({
    required this.initialMonth,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_YearMonthPickerDialog> createState() => _YearMonthPickerDialogState();
}

class _YearMonthPickerDialogState extends State<_YearMonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  late ScrollController _yearScrollController;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialMonth.year;
    _selectedMonth = widget.initialMonth.month;

    final initialIndex = (_selectedYear - widget.firstDate.year).clamp(0, widget.lastDate.year - widget.firstDate.year);
    _yearScrollController = ScrollController(
      initialScrollOffset: (initialIndex * 44.0).clamp(0.0, double.infinity),
    );
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '연도 및 월 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$_selectedYear년 $_selectedMonth월',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  // Year list selector (1900 - 2100)
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        controller: _yearScrollController,
                        physics: const BouncingScrollPhysics(),
                        itemExtent: 44.0,
                        itemCount: widget.lastDate.year - widget.firstDate.year + 1,
                        itemBuilder: (context, index) {
                          final int year = widget.firstDate.year + index;
                          final bool isSelected = year == _selectedYear;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedYear = year;
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Text(
                                '$year년',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Month 3x4 grid selector (1월 - 12월)
                  Expanded(
                    flex: 6,
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final int month = index + 1;
                        final bool isSelected = month == _selectedMonth;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMonth = month;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$month월',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(DateTime(_selectedYear, _selectedMonth, 1));
                  },
                  child: const Text('선택 완료', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
