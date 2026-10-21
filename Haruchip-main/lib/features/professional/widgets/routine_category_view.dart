import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/routine_model.dart';
import 'add_routine_modal.dart';

/// 루틴 / 주간 계획표 카테고리 뷰 (타임테이블 & 요일별 리스트 듀얼 모드)
class RoutineCategoryView extends StatefulWidget {
  const RoutineCategoryView({
    super.key,
    required this.routines,
    required this.onRoutinesChanged,
    required this.onOpenAddModal,
  });

  final List<RoutineItem> routines;
  final ValueChanged<List<RoutineItem>> onRoutinesChanged;
  final VoidCallback onOpenAddModal;

  @override
  State<RoutineCategoryView> createState() => _RoutineCategoryViewState();
}

class _RoutineCategoryViewState extends State<RoutineCategoryView> {
  bool _isTimetableView = true; // true: 주간 시간표, false: 요일별 리스트
  int _selectedDayFilter = DateTime.now().weekday; // 1=월..7=일

  final List<String> _dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  RoutineItem? _getClosestUpcomingRoutine() {
    if (widget.routines.isEmpty) return null;
    final list = List<RoutineItem>.from(widget.routines);
    list.sort((a, b) => a.nextUpcomingDate().compareTo(b.nextUpcomingDate()));
    return list.first;
  }

  Future<void> _editRoutine(RoutineItem routine) async {
    final updated = await showAddRoutineModal(
      context,
      existingRoutine: routine,
      allowDelete: true,
      onDelete: () {
        final newList = widget.routines.where((r) => r.id != routine.id).toList();
        widget.onRoutinesChanged(newList);
      },
    );
    if (updated != null) {
      final newList = widget.routines.map((r) => r.id == routine.id ? updated : r).toList();
      widget.onRoutinesChanged(newList);
    }
  }

  @override
  Widget build(BuildContext context) {
    final closest = _getClosestUpcomingRoutine();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 다가오는 가장 빠른 일정 카운트다운 알림 배너
        if (closest != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Slate Minimal Black
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text('⏱️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '다음 루틴 일정',
                              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                            ),
                            Text(
                              closest.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(
                    closest.nextDDayLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 2. 뷰 모드 토글 바: [주간 시간표 (타임테이블)] <-> [요일별 리스트]
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 아주 좁은 폰·큰 글씨에서만 토글을 살짝 줄여 한 줄에 맞춘다.
            Flexible(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
              height: 36,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isTimetableView = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _isTimetableView ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _isTimetableView
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '📊 주간 시간표',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _isTimetableView ? FontWeight.bold : FontWeight.w500,
                          color: _isTimetableView ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isTimetableView = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: !_isTimetableView ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !_isTimetableView
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '📋 요일별 리스트',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: !_isTimetableView ? FontWeight.bold : FontWeight.w500,
                          color: !_isTimetableView ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Text(
                '총 ${widget.routines.length}개 루틴',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 3. 메인 뷰 컨텐츠
        if (widget.routines.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.alarm_outlined, size: 40, color: Colors.grey),
                const SizedBox(height: 10),
                const Text('등록된 루틴 및 시간표가 없습니다', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: widget.onOpenAddModal,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('새 루틴 등록하기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          )
        else if (_isTimetableView)
          _buildWeeklyTimetableGrid()
        else
          _buildDailyListView(),
      ],
    );
  }

  /// 📊 주간 타임테이블 그리드 뷰 (월~일 x 06:00~24:00)
  Widget _buildWeeklyTimetableGrid() {
    // 06:00 부터 24:00 까지 2시간 간격
    final hours = [6, 8, 10, 12, 14, 16, 18, 20, 22, 24];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // 요일 헤더 행
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const SizedBox(width: 44), // 시간 라벨 폭
                for (int i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        _dayNames[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: (i + 1) == DateTime.now().weekday ? FontWeight.w900 : FontWeight.w600,
                          color: (i + 1) == DateTime.now().weekday
                              ? const Color(0xFF2563EB)
                              : (i >= 5 ? const Color(0xFFEF4444) : const Color(0xFF334155)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 타임테이블 바디 (시간대별 행)
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth - 44;
              final colWidth = totalWidth / 7;
              const totalHeight = 480.0;

              return SizedBox(
                height: 380,
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: totalHeight,
                    child: Stack(
                      children: [
                        // 배경 시간 가이드 라인
                        Column(
                          children: hours.map((hour) {
                            return Container(
                              height: 48,
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 44,
                                    child: Text(
                                      '${hour.toString().padLeft(2, '0')}:00',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(left: BorderSide(color: Color(0xFFF1F5F9))),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        // 루틴 컬러 블록들
                        ...widget.routines.expand((routine) {
                          return routine.daysOfWeek.map((day) {
                            final colIndex = day - 1; // 0=Mon..6=Sun
                            final left = 44 + (colIndex * colWidth);

                            // Calculate top and height (06:00 = 0px, 24:00 = 18*24px)
                            final startMinutes = routine.startTime.hour * 60 + routine.startTime.minute - (6 * 60);
                            final endMinutes = routine.endTime.hour * 60 + routine.endTime.minute - (6 * 60);
                            final clampedStart = startMinutes.clamp(0, 18 * 60);
                            final clampedEnd = endMinutes.clamp(clampedStart + 30, 18 * 60);

                            // Total 18 hours mapped to (hours.length - 1) * 48 = 9 * 48 = 432px
                            final pxPerMinute = (9 * 48.0) / (18 * 60);
                            final top = clampedStart * pxPerMinute;
                            final height = (clampedEnd - clampedStart) * pxPerMinute;

                            final color = Color(int.parse('0xFF${routine.colorHex.replaceAll('#', '')}'));

                            return Positioned(
                              top: top,
                              left: left + 2,
                              width: colWidth - 4,
                              height: height < 24 ? 24 : height,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _editRoutine(routine),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    routine.title,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            );
                          });
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 📋 요일별 리스트 뷰
  Widget _buildDailyListView() {
    return Column(
      children: [
        // 요일 셀렉터 칩
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(7, (index) {
              final day = index + 1;
              final isSelected = _selectedDayFilter == day;
              final count = widget.routines.where((r) => r.daysOfWeek.contains(day)).length;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text('${_dayNames[index]}요일 ($count)', style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedDayFilter = day),
                  selectedColor: const Color(0xFF0F172A),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  showCheckmark: false,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),

        // 선택된 요일의 루틴 목록
        () {
          final routinesForDay = widget.routines.where((r) => r.daysOfWeek.contains(_selectedDayFilter)).toList();
          routinesForDay.sort((a, b) {
            final aMin = a.startTime.hour * 60 + a.startTime.minute;
            final bMin = b.startTime.hour * 60 + b.startTime.minute;
            return aMin.compareTo(bMin);
          });

          if (routinesForDay.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                '${_dayNames[_selectedDayFilter - 1]}요일에 예정된 루틴이 없습니다',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: routinesForDay.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final routine = routinesForDay[index];
              final color = Color(int.parse('0xFF${routine.colorHex.replaceAll('#', '')}'));

              return InkWell(
                onTap: () => _editRoutine(routine),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routine.title,
                              style: AppTypography.heading2.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.protoHeading,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  routine.formattedTimeRange,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                ),
                                if (routine.location != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      routine.location!,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          routine.formattedDays,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }(),
      ],
    );
  }
}
