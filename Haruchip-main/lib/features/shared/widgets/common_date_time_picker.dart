import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 전사 공통 날짜/시간 인라인 휠 피커 활성 대상
enum _PickerTarget {
  none,
  startDate,
  startTime,
  endDate,
  endTime,
}

/// 전사 공통 날짜/시간 컴포넌트 (iOS Cupertino 인라인 휠 드럼롤 스타일)
class CommonDateTimePicker extends StatefulWidget {
  const CommonDateTimePicker({
    super.key,
    required this.initialStartDate,
    this.initialEndDate,
    this.isAllDay = false,
    this.showAllDayToggle = true,
    this.hasEndDate = true,
    this.firstDate,
    this.lastDate,
    this.startLabel = '시작',
    this.endLabel = '종료',
    this.timeZoneLabel = '시간대: 서울 >',
    this.timeZone,
    this.onTimeZoneChanged,
    this.minuteInterval = 1,
    this.accentColor = const Color(0xFFFF5A5F), // 소프트 오렌지/레드 포인트 컬러
    this.onDateTimeChanged,
    this.onStartChanged,
    this.onEndChanged,
    this.onAllDayChanged,
  });

  final DateTime initialStartDate;
  final DateTime? initialEndDate;
  final bool isAllDay;
  final bool showAllDayToggle;
  final bool hasEndDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String startLabel;
  final String endLabel;
  final String timeZoneLabel;
  final String? timeZone;
  final ValueChanged<String>? onTimeZoneChanged;
  final int minuteInterval;
  final Color accentColor;

  /// (시작일시, 종료일시, 하루종일여부) 콜백
  final void Function(DateTime start, DateTime? end, bool isAllDay)? onDateTimeChanged;
  final void Function(DateTime start)? onStartChanged;
  final void Function(DateTime end)? onEndChanged;
  final void Function(bool isAllDay)? onAllDayChanged;

  @override
  State<CommonDateTimePicker> createState() => _CommonDateTimePickerState();
}

class _CommonDateTimePickerState extends State<CommonDateTimePicker> {
  late DateTime _startDate;
  late DateTime? _endDate;
  late bool _isAllDay;
  late String _selectedTimeZone;
  _PickerTarget _activeTarget = _PickerTarget.none;

  late int _firstYear;
  late int _lastYear;

  // Controllers for CupertinoPickers
  FixedExtentScrollController? _yearController;
  FixedExtentScrollController? _monthController;
  FixedExtentScrollController? _dayController;
  FixedExtentScrollController? _amPmController;
  FixedExtentScrollController? _hourController;
  FixedExtentScrollController? _minuteController;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.hasEndDate
        ? (widget.initialEndDate ?? widget.initialStartDate.add(const Duration(hours: 1)))
        : null;
    _isAllDay = widget.isAllDay;
    _selectedTimeZone = widget.timeZone ?? '서울';

    _firstYear = widget.firstDate?.year ?? 1950;
    _lastYear = widget.lastDate?.year ?? 2050;
    if (_startDate.year < _firstYear) _firstYear = _startDate.year - 5;
    if (_startDate.year > _lastYear) _lastYear = _startDate.year + 5;
  }

  @override
  void didUpdateWidget(covariant CommonDateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStartDate != widget.initialStartDate) {
      _startDate = widget.initialStartDate;
      if (_endDate != null && _endDate!.isBefore(_startDate)) {
        _endDate = _isAllDay ? _startDate : _startDate.add(const Duration(hours: 1));
      }
    }
    if (oldWidget.initialEndDate != widget.initialEndDate) {
      _endDate = widget.initialEndDate ?? (widget.hasEndDate ? _startDate.add(const Duration(hours: 1)) : null);
      if (_endDate != null && _endDate!.isBefore(_startDate)) {
        _endDate = _isAllDay ? _startDate : _startDate.add(const Duration(hours: 1));
      }
    }
    if (oldWidget.isAllDay != widget.isAllDay) {
      _isAllDay = widget.isAllDay;
    }
    if (widget.timeZone != null && widget.timeZone != oldWidget.timeZone) {
      _selectedTimeZone = widget.timeZone!;
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _yearController?.dispose();
    _monthController?.dispose();
    _dayController?.dispose();
    _amPmController?.dispose();
    _hourController?.dispose();
    _minuteController?.dispose();

    _yearController = null;
    _monthController = null;
    _dayController = null;
    _amPmController = null;
    _hourController = null;
    _minuteController = null;
  }

  void _notifyChange() {
    widget.onDateTimeChanged?.call(_startDate, _endDate, _isAllDay);
    widget.onStartChanged?.call(_startDate);
    if (_endDate != null) widget.onEndChanged?.call(_endDate!);
    widget.onAllDayChanged?.call(_isAllDay);
  }

  DateTime get _activeDateTime {
    if (_activeTarget == _PickerTarget.endDate || _activeTarget == _PickerTarget.endTime) {
      return _endDate ?? _startDate;
    }
    return _startDate;
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _initDateControllers(DateTime targetDate) {
    _disposeControllers();
    final yearIndex = (targetDate.year - _firstYear).clamp(0, _lastYear - _firstYear);
    final monthIndex = (targetDate.month - 1).clamp(0, 11);
    final maxDay = _daysInMonth(targetDate.year, targetDate.month);
    final dayIndex = (targetDate.day - 1).clamp(0, maxDay - 1);

    _yearController = FixedExtentScrollController(initialItem: yearIndex);
    _monthController = FixedExtentScrollController(initialItem: monthIndex);
    _dayController = FixedExtentScrollController(initialItem: dayIndex);
  }

  void _initTimeControllers(DateTime targetDate) {
    _disposeControllers();
    final isPm = targetDate.hour >= 12;
    final hour12 = targetDate.hour == 0 ? 12 : (targetDate.hour > 12 ? targetDate.hour - 12 : targetDate.hour);
    final hourIndex = hour12 - 1; // 0..11 for 1..12
    final minuteIndex = (targetDate.minute ~/ widget.minuteInterval).clamp(0, (60 ~/ widget.minuteInterval) - 1);

    _amPmController = FixedExtentScrollController(initialItem: isPm ? 1 : 0);
    _hourController = FixedExtentScrollController(initialItem: hourIndex);
    _minuteController = FixedExtentScrollController(initialItem: minuteIndex);
  }

  void _onToggleTarget(_PickerTarget target) {
    setState(() {
      if (_activeTarget == target) {
        _activeTarget = _PickerTarget.none;
        _disposeControllers();
      } else {
        _activeTarget = target;
        final cur = (target == _PickerTarget.endDate || target == _PickerTarget.endTime)
            ? (_endDate ?? _startDate)
            : _startDate;

        if (target == _PickerTarget.startDate || target == _PickerTarget.endDate) {
          _initDateControllers(cur);
        } else if (target == _PickerTarget.startTime || target == _PickerTarget.endTime) {
          _initTimeControllers(cur);
        }
      }
    });
  }

  void _showValidationErrorToast() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('종료일시는 시작일시 이후여야 합니다.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _updateActiveDate({int? year, int? month, int? day}) {
    final cur = _activeDateTime;
    final newYear = year ?? cur.year;
    final newMonth = month ?? cur.month;
    final maxDays = _daysInMonth(newYear, newMonth);
    final newDay = (day ?? cur.day).clamp(1, maxDays);

    final updated = DateTime(
      newYear,
      newMonth,
      newDay,
      cur.hour,
      cur.minute,
      cur.second,
    );

    setState(() {
      if (_activeTarget == _PickerTarget.endDate || _activeTarget == _PickerTarget.endTime) {
        if (updated.isBefore(_startDate)) {
          _endDate = _startDate;
          _showValidationErrorToast();
        } else {
          _endDate = updated;
        }
      } else {
        _startDate = updated;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = _isAllDay ? _startDate : _startDate.add(const Duration(hours: 1));
        }
      }
    });
    _notifyChange();
  }

  void _updateActiveTime({bool? isPm, int? hour12, int? minute}) {
    final cur = _activeDateTime;
    final currentIsPm = cur.hour >= 12;
    final targetIsPm = isPm ?? currentIsPm;

    final curHour12 = cur.hour == 0 ? 12 : (cur.hour > 12 ? cur.hour - 12 : cur.hour);
    final targetHour12 = hour12 ?? curHour12;

    int newHour24;
    if (targetIsPm) {
      newHour24 = targetHour12 == 12 ? 12 : targetHour12 + 12;
    } else {
      newHour24 = targetHour12 == 12 ? 0 : targetHour12;
    }

    final newMinute = minute ?? cur.minute;

    final updated = DateTime(
      cur.year,
      cur.month,
      cur.day,
      newHour24,
      newMinute,
    );

    setState(() {
      if (_activeTarget == _PickerTarget.endDate || _activeTarget == _PickerTarget.endTime) {
        if (updated.isBefore(_startDate)) {
          _endDate = _startDate.add(Duration(minutes: widget.minuteInterval));
          _showValidationErrorToast();
        } else {
          _endDate = updated;
        }
      } else {
        _startDate = updated;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 1));
        }
      }
    });
    _notifyChange();
  }

  String _formatDatePill(DateTime d) {
    return '${d.year}. ${d.month}. ${d.day}.';
  }

  String _formatTimePill(DateTime d) {
    final isPm = d.hour >= 12;
    final h12 = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final mStr = d.minute.toString().padLeft(2, '0');
    return '${isPm ? '오후' : '오전'} $h12:$mStr';
  }

  @override
  Widget build(BuildContext context) {
    final isStartDateActive = _activeTarget == _PickerTarget.startDate;
    final isStartTimeActive = _activeTarget == _PickerTarget.startTime;
    final isEndDateActive = _activeTarget == _PickerTarget.endDate;
    final isEndTimeActive = _activeTarget == _PickerTarget.endTime;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // (1) 상단 컨트롤 및 [하루 종일] 토글 스위치
          if (widget.showAllDayToggle) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '하루 종일',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                CupertinoSwitch(
                  value: _isAllDay,
                  activeTrackColor: widget.accentColor,
                  onChanged: (val) {
                    setState(() {
                      _isAllDay = val;
                      if (_isAllDay &&
                          (_activeTarget == _PickerTarget.startTime ||
                              _activeTarget == _PickerTarget.endTime)) {
                        _activeTarget = _PickerTarget.none;
                        _disposeControllers();
                      }
                    });
                    _notifyChange();
                  },
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Color(0xFFF3F4F6)),
            ),
          ],

          // (2) [시작] 행 (Row) 구조
          Row(
            children: [
              Text(
                widget.startLabel,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 시작 날짜 버튼
                  _buildPillButton(
                    text: _formatDatePill(_startDate),
                    isActive: isStartDateActive,
                    onTap: () => _onToggleTarget(_PickerTarget.startDate),
                  ),
                  // 시작 시간 버튼 (하루 종일 꺼져 있을 때만)
                  if (!_isAllDay) ...[
                    const SizedBox(width: 6),
                    _buildPillButton(
                      text: _formatTimePill(_startDate),
                      isActive: isStartTimeActive,
                      onTap: () => _onToggleTarget(_PickerTarget.startTime),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // [시작] 날짜 또는 시간 인라인 피커 영역
          if (isStartDateActive) _buildInlineDatePicker(),
          if (isStartTimeActive && !_isAllDay) _buildInlineTimePicker(),

          // (2-1) 시간대 서브 라벨 (시작과 종료 사이 배치 - iOS 표준 캘린더 스타일)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                InkWell(
                  onTap: _showTimeZonePickerModal,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '시간대: $_selectedTimeZone >',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // (2-2) [종료] 행 (Row) 구조 (옵션)
          if (widget.hasEndDate && _endDate != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Color(0xFFF3F4F6)),
            ),
            Row(
              children: [
                Text(
                  widget.endLabel,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 종료 날짜 버튼
                    _buildPillButton(
                      text: _formatDatePill(_endDate!),
                      isActive: isEndDateActive,
                      onTap: () => _onToggleTarget(_PickerTarget.endDate),
                    ),
                    // 종료 시간 버튼
                    if (!_isAllDay) ...[
                      const SizedBox(width: 6),
                      _buildPillButton(
                        text: _formatTimePill(_endDate!),
                        isActive: isEndTimeActive,
                        onTap: () => _onToggleTarget(_PickerTarget.endTime),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // [종료] 날짜 또는 시간 인라인 피커 영역
            if (isEndDateActive) _buildInlineDatePicker(),
            if (isEndTimeActive && !_isAllDay) _buildInlineTimePicker(),
          ],
        ],
      ),
    );
  }

  static const List<({String city, String label, String gmt})> _kTimeZones = [
    (city: '서울', label: '대한민국 (서울)', gmt: 'GMT+9'),
    (city: '도쿄', label: '일본 (도쿄)', gmt: 'GMT+9'),
    (city: '베이징', label: '중국 (베이징)', gmt: 'GMT+8'),
    (city: '싱가포르', label: '싱가포르', gmt: 'GMT+8'),
    (city: '홍콩', label: '홍콩', gmt: 'GMT+8'),
    (city: '방콕', label: '태국 (방콕)', gmt: 'GMT+7'),
    (city: '두바이', label: '아랍에미리트 (두바이)', gmt: 'GMT+4'),
    (city: '파리', label: '프랑스 (파리)', gmt: 'GMT+1'),
    (city: '베를린', label: '독일 (베를린)', gmt: 'GMT+1'),
    (city: '런던', label: '영국 (런던)', gmt: 'GMT+0'),
    (city: '뉴욕', label: '미국 (뉴욕)', gmt: 'GMT-5'),
    (city: '토론토', label: '캐나다 (토론토)', gmt: 'GMT-5'),
    (city: '시카고', label: '미국 (시카고)', gmt: 'GMT-6'),
    (city: '로스앤젤레스', label: '미국 (로스앤젤레스)', gmt: 'GMT-8'),
    (city: '시드니', label: '호주 (시드니)', gmt: 'GMT+11'),
    (city: '오클랜드', label: '뉴질랜드 (오클랜드)', gmt: 'GMT+12'),
    (city: '호놀룰루', label: '미국 (호놀룰루)', gmt: 'GMT-10'),
  ];

  void _showTimeZonePickerModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _kTimeZones.where((tz) {
              if (searchQuery.trim().isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return tz.city.toLowerCase().contains(q) ||
                  tz.label.toLowerCase().contains(q) ||
                  tz.gmt.toLowerCase().contains(q);
            }).toList();

            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '시간대 설정',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '도시 또는 시간대 검색',
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = item.city == _selectedTimeZone;
                        return ListTile(
                          leading: isSelected
                              ? Icon(Icons.check, size: 20, color: widget.accentColor)
                              : const SizedBox(width: 20),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? widget.accentColor : const Color(0xFF1F2937),
                            ),
                          ),
                          trailing: Text(
                            item.gmt,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedTimeZone = item.city;
                            });
                            widget.onTimeZoneChanged?.call(item.city);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  }

  Widget _buildPillButton({
    required String text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? widget.accentColor.withValues(alpha: 0.12)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? widget.accentColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive ? widget.accentColor : const Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }

  /// (3) 인라인 드럼롤 휠 피커 - 날짜 (CupertinoPicker 스타일)
  Widget _buildInlineDatePicker() {
    final cur = _activeDateTime;
    final maxDays = _daysInMonth(cur.year, cur.month);
    final totalYears = _lastYear - _firstYear + 1;

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 [2026년 11월 ∨] 헤더
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${cur.year}년 ${cur.month}월 ∨',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor,
                  ),
                ),
              ],
            ),
          ),

          // 휠 피커 영역 [연도] [월] [일]
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                // 중앙 옅은 회색 라운드 하이라이트 바
                Center(
                  child: Container(
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x0F000000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Row(
                  children: [
                    // [연도] 휠
                    Expanded(
                      flex: 3,
                      child: CupertinoPicker.builder(
                        scrollController: _yearController,
                        itemExtent: 36,
                        selectionOverlay: const SizedBox.shrink(),
                        childCount: totalYears,
                        onSelectedItemChanged: (index) {
                          _updateActiveDate(year: _firstYear + index);
                        },
                        itemBuilder: (context, index) {
                          final yr = _firstYear + index;
                          return Center(
                            child: Text(
                              '$yr년',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),

                    // [월] 휠
                    Expanded(
                      flex: 2,
                      child: CupertinoPicker.builder(
                        scrollController: _monthController,
                        itemExtent: 36,
                        selectionOverlay: const SizedBox.shrink(),
                        childCount: 12,
                        onSelectedItemChanged: (index) {
                          _updateActiveDate(month: index + 1);
                        },
                        itemBuilder: (context, index) {
                          final m = index + 1;
                          return Center(
                            child: Text(
                              '$m월',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),

                    // [일] 휠
                    Expanded(
                      flex: 2,
                      child: CupertinoPicker.builder(
                        scrollController: _dayController,
                        itemExtent: 36,
                        selectionOverlay: const SizedBox.shrink(),
                        childCount: maxDays,
                        onSelectedItemChanged: (index) {
                          _updateActiveDate(day: index + 1);
                        },
                        itemBuilder: (context, index) {
                          final d = index + 1;
                          return Center(
                            child: Text(
                              '$d일',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// (3) 인라인 드럼롤 휠 피커 - 시간 (CupertinoPicker 스타일)
  Widget _buildInlineTimePicker() {
    final minuteCount = 60 ~/ widget.minuteInterval;

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SizedBox(
        height: 160,
        child: Stack(
          children: [
            // 중앙 옅은 회색 라운드 하이라이트 바
            Center(
              child: Container(
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0x0F000000),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Row(
              children: [
                // [오전 / 오후] 휠
                Expanded(
                  flex: 2,
                  child: CupertinoPicker(
                    scrollController: _amPmController,
                    itemExtent: 36,
                    selectionOverlay: const SizedBox.shrink(),
                    onSelectedItemChanged: (index) {
                      _updateActiveTime(isPm: index == 1);
                    },
                    children: const [
                      Center(child: Text('오전', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                      Center(child: Text('오후', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),

                // [시] 휠 (1 ~ 12)
                Expanded(
                  flex: 2,
                  child: CupertinoPicker.builder(
                    scrollController: _hourController,
                    itemExtent: 36,
                    selectionOverlay: const SizedBox.shrink(),
                    childCount: 12,
                    onSelectedItemChanged: (index) {
                      _updateActiveTime(hour12: index + 1);
                    },
                    itemBuilder: (context, index) {
                      return Center(
                        child: Text(
                          '${index + 1}시',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ),

                // [분] 휠 (00, 01.. / 00, 05..)
                Expanded(
                  flex: 2,
                  child: CupertinoPicker.builder(
                    scrollController: _minuteController,
                    itemExtent: 36,
                    selectionOverlay: const SizedBox.shrink(),
                    childCount: minuteCount,
                    onSelectedItemChanged: (index) {
                      _updateActiveTime(minute: index * widget.minuteInterval);
                    },
                    itemBuilder: (context, index) {
                      final m = index * widget.minuteInterval;
                      return Center(
                        child: Text(
                          '${m.toString().padLeft(2, '0')}분',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 공통 날짜 단일 선택 모달 바텀시트
Future<DateTime?> showCommonDatePickerModal(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String title = '날짜 선택',
  Color accentColor = const Color(0xFFFF5A5F),
}) async {
  DateTime selected = initialDate;

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  child: Text(
                    '완료',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CommonDateTimePicker(
              initialStartDate: initialDate,
              hasEndDate: false,
              isAllDay: true,
              showAllDayToggle: false,
              firstDate: firstDate,
              lastDate: lastDate,
              accentColor: accentColor,
              onDateTimeChanged: (start, _, __) {
                selected = start;
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

/// 공통 날짜 & 시간 선택 모달 바텀시트
Future<DateTime?> showCommonDateTimePickerModal(
  BuildContext context, {
  required DateTime initialDateTime,
  DateTime? firstDate,
  DateTime? lastDate,
  bool isAllDay = false,
  bool showAllDayToggle = true,
  String title = '일시 선택',
  Color accentColor = const Color(0xFFFF5A5F),
}) async {
  DateTime selected = initialDateTime;
  bool allDay = isAllDay;

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  child: Text(
                    '완료',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CommonDateTimePicker(
              initialStartDate: initialDateTime,
              hasEndDate: false,
              isAllDay: allDay,
              showAllDayToggle: showAllDayToggle,
              firstDate: firstDate,
              lastDate: lastDate,
              accentColor: accentColor,
              onDateTimeChanged: (start, _, ad) {
                selected = start;
                allDay = ad;
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

/// 공통 기간(시작일시 ~ 종료일시) 선택 모달 바텀시트
Future<({DateTime start, DateTime end, bool isAllDay})?> showCommonDateRangePickerModal(
  BuildContext context, {
  required DateTime initialStartDate,
  DateTime? initialEndDate,
  bool isAllDay = false,
  bool showAllDayToggle = true,
  String title = '기간 설정',
  Color accentColor = const Color(0xFFFF5A5F),
}) async {
  DateTime start = initialStartDate;
  DateTime end = initialEndDate ?? initialStartDate.add(const Duration(hours: 1));
  bool allDay = isAllDay;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    '완료',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CommonDateTimePicker(
              initialStartDate: initialStartDate,
              initialEndDate: end,
              hasEndDate: true,
              isAllDay: allDay,
              showAllDayToggle: showAllDayToggle,
              accentColor: accentColor,
              onDateTimeChanged: (s, e, ad) {
                start = s;
                if (e != null) end = e;
                allDay = ad;
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );

  if (result == true) {
    return (start: start, end: end, isAllDay: allDay);
  }
  return null;
}
