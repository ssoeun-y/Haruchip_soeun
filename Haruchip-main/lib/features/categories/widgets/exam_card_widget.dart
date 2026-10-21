import 'package:flutter/material.dart';
import '../controllers/exam_category_controller.dart';
import '../models/category.dart';
import '../models/exam_model.dart';

/// 시험 카드 종합 위젯 (자격증 다단계 파이프라인 트리 & 중간/기말 과목 타임테이블)
class ExamCardWidget extends StatefulWidget {
  const ExamCardWidget({
    super.key,
    required this.exam,
    required this.onEdit,
    required this.onDelete,
    required this.onExamChanged,
    this.initiallyExpanded = true,
  });

  final ExamProfile exam;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<ExamProfile> onExamChanged;
  final bool initiallyExpanded;

  @override
  State<ExamCardWidget> createState() => _ExamCardWidgetState();
}

class _ExamCardWidgetState extends State<ExamCardWidget> {
  late bool _isExpanded;
  final _controller = const ExamCategoryController();

  // 각 단계별/과목별 완료된 체크리스트 아이템 관리 (id -> Set<String>)
  final Map<String, Set<String>> _checkedItems = {};

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _weekdayKo(DateTime d) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[d.weekday - 1];
  }

  void _toggleStageCompletion(ExamStageItem stage) {
    final updatedStages = widget.exam.stages.map((s) {
      if (s.id == stage.id) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    widget.onExamChanged(widget.exam.copyWith(stages: updatedStages));
  }

  void _toggleSubjectCompletion(ExamSubjectItem subject) {
    final updatedSubjects = widget.exam.subjects.map((s) {
      if (s.id == subject.id) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    widget.onExamChanged(widget.exam.copyWith(subjects: updatedSubjects));
  }

  void _toggleChecklistItem(String parentId, String item) {
    setState(() {
      final current = _checkedItems[parentId] ?? {};
      if (current.contains(item)) {
        current.remove(item);
      } else {
        current.add(item);
      }
      _checkedItems[parentId] = current;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final themeColor = colorFromHex(exam.colorHex);
    final isSchool = exam.type == ExamType.midterm || exam.type == ExamType.finalExam;
    final rollingStatus = _controller.getRollingStatus(exam);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 카드 (상단 요약 & 대표 롤링 디데이 뱃지)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 메타 라인 (이모지, 카테고리 태그, 목표점수, 메뉴)
                  Row(
                    children: [
                      // 분류·목표 칩이 길면 다음 줄로 (오른쪽 메뉴 버튼 자리는 유지)
                      Expanded(
                        child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 4,
                      children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(exam.type.emoji, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          exam.categoryName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      if (exam.targetScore != null && exam.targetScore!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🎯', style: TextStyle(fontSize: 10)),
                              const SizedBox(width: 3),
                              Text(
                                exam.targetScore!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      ],
                        ),
                      ),
                      // 메뉴 버튼
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onSelected: (val) {
                          if (val == 'edit') {
                            widget.onEdit();
                          } else if (val == 'delete') {
                            widget.onDelete();
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0F172A)),
                                SizedBox(width: 8),
                                Text('수정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                SizedBox(width: 8),
                                Text('삭제', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 시험 제목 & 대표 롤링 디데이
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              rollingStatus.subDetailText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // 대표 실시간 롤링 뱃지
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: rollingStatus.isAllFinished
                              ? const Color(0xFFF1F5F9)
                              : themeColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: rollingStatus.isAllFinished
                              ? null
                              : [
                                  BoxShadow(
                                    color: themeColor.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Text(
                          rollingStatus.badgeText,
                          style: TextStyle(
                            color: rollingStatus.isAllFinished
                                ? const Color(0xFF64748B)
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. 펼쳐졌을 때의 세부 콘텐츠
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: isSchool
                  ? _buildSchoolTimetable(context, themeColor)
                  : _buildQualificationPipeline(context, themeColor, rollingStatus),
            ),
          ],
        ],
      ),
    );
  }

  // --- 자격증 다단계 파이프라인 트리 렌더링 ---
  Widget _buildQualificationPipeline(
    BuildContext context,
    Color themeColor,
    ExamRollingStatus rollingStatus,
  ) {
    final stages = widget.exam.stages;
    if (stages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('등록된 시험 단계가 없습니다.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    // 단계들을 시작일순 정렬
    final sortedStages = List<ExamStageItem>.from(stages)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좁은 폭에서는 잘라내지 않고 다음 줄로 넘긴다 (안내 문구라 전부 보여야 함).
            Expanded(
              child: Text(
                '📍 단계별 시험 일정 (원서접수 ➔ 최종합격)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${sortedStages.length}개 단계',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedStages.length,
          itemBuilder: (context, index) {
            final stage = sortedStages[index];
            final isLast = index == sortedStages.length - 1;
            final isEnded = stage.isEnded() || stage.isCompleted;
            final isActive = rollingStatus.activeStage?.id == stage.id;
            final days = stage.daysRemaining();
            final isCheckCompleted = stage.isCompleted;

            String dDayBadge = 'D-Day';
            if (isEnded) {
              dDayBadge = '완료 ✓';
            } else if (days > 0) {
              dDayBadge = 'D-$days';
            } else if (days == 0) {
              dDayBadge = 'D-Day';
            } else {
              dDayBadge = '종료';
            }

            String dateFormatted = '${_formatDate(stage.startDate)} (${_weekdayKo(stage.startDate)})';
            if (stage.endDate != null) {
              dateFormatted += ' ~ ${_formatDate(stage.endDate!)} (${_weekdayKo(stage.endDate!)})';
            }

            final checkedItems = _checkedItems[stage.id] ?? {};

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 타임라인 노드 인디케이터
                Column(
                  children: [
                    InkWell(
                      onTap: () => _toggleStageCompletion(stage),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isEnded
                              ? const Color(0xFF94A3B8)
                              : (isActive ? themeColor : const Color(0xFFE2E8F0)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: themeColor.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: isCheckCompleted || isEnded
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 54 + (stage.checklist.isNotEmpty ? 36.0 : 0.0),
                        color: isEnded
                            ? const Color(0xFFE2E8F0)
                            : (isActive ? themeColor.withValues(alpha: 0.5) : const Color(0xFFE2E8F0)),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // 2. 단계 콘텐츠 박스
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? themeColor.withValues(alpha: 0.04)
                            : (isEnded ? const Color(0xFFF8FAFC) : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive
                              ? themeColor.withValues(alpha: 0.4)
                              : (isEnded ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0)),
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 헤더 라인 (단계명 & D-Day 뱃지)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: stage.stageType.isExamDay
                                      ? themeColor.withValues(alpha: 0.15)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  stage.stageType.shortLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: stage.stageType.isExamDay ? themeColor : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  stage.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isEnded ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                    decoration: isEnded ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isEnded
                                      ? const Color(0xFFE2E8F0)
                                      : (isActive ? themeColor : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  dDayBadge,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isEnded
                                        ? const Color(0xFF64748B)
                                        : (isActive ? Colors.white : const Color(0xFF475569)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // 날짜 및 시간
                          // 기간(~) + 입실시간이 붙으면 한 줄을 넘는다 — 아이콘 옆에서 자연스럽게 줄바꿈.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(Icons.event_outlined, size: 14, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: dateFormatted,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                    children: [
                                      if (stage.testTime != null)
                                        TextSpan(
                                          text: '   •  ${stage.testTime}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // 고사장 / 좌석 / 수험번호 (있을 경우)
                          if (stage.location != null || stage.seatNumber != null || stage.registrationNumber != null) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (stage.location != null)
                                  Text(
                                    '🏫 ${stage.location}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                  ),
                                if (stage.seatNumber != null)
                                  Text(
                                    '🪑 좌석: ${stage.seatNumber}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                  ),
                                if (stage.registrationNumber != null)
                                  Text(
                                    '🎫 수험번호: ${stage.registrationNumber}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                  ),
                              ],
                            ),
                          ],

                          // 준비물 체크리스트 칩들
                          if (stage.checklist.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: stage.checklist.map((item) {
                                final isItemChecked = checkedItems.contains(item);
                                return InkWell(
                                  onTap: () => _toggleChecklistItem(stage.id, item),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isItemChecked
                                          ? const Color(0xFFDCFCE7)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isItemChecked ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isItemChecked ? Icons.check_box : Icons.check_box_outline_blank,
                                          size: 12,
                                          color: isItemChecked ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isItemChecked ? FontWeight.bold : FontWeight.normal,
                                            color: isItemChecked ? const Color(0xFF166534) : const Color(0xFF475569),
                                            decoration: isItemChecked ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // --- 학교 시험 (중간고사 / 기말고사) 과목 타임테이블 렌더링 ---
  Widget _buildSchoolTimetable(BuildContext context, Color themeColor) {
    final subjects = widget.exam.subjects;
    if (subjects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('등록된 시험 과목이 없습니다.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    // 날짜별 & 교시별 정렬
    final sortedSubjects = List<ExamSubjectItem>.from(subjects)
      ..sort((a, b) {
        final cmp = a.examDate.compareTo(b.examDate);
        if (cmp != 0) return cmp;
        return a.period.compareTo(b.period);
      });

    // 날짜별 그룹화
    final Map<String, List<ExamSubjectItem>> groupedByDate = {};
    for (final s in sortedSubjects) {
      final dateKey = _formatDate(s.examDate);
      groupedByDate.putIfAbsent(dateKey, () => []).add(s);
    }

    int dayCounter = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📝 과목별 시험 타임테이블',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            Text(
              '총 ${subjects.length}개 과목',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...groupedByDate.entries.map((group) {
          final dateStr = group.key;
          final daySubjects = group.value;
          final firstDate = daySubjects.first.examDate;
          final weekday = _weekdayKo(firstDate);
          final currentDayNum = dayCounter++;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day 헤더 (예: Day 1 • 2026.10.19 (월))
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Day $currentDayNum',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$dateStr ($weekday)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 해당 날짜의 과목 리스트
                ...daySubjects.map((sub) {
                  final timeLabel = _controller.getSubjectRemainingLabel(sub);
                  final isDone = sub.isCompleted || sub.isEnded();
                  final timeStr = sub.startTime != null ? '${sub.startTime} ~ ${sub.endTime ?? ""}' : '';
                  final checkedItems = _checkedItems[sub.id] ?? {};

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 교시 뱃지
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${sub.period}교시',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 과목명 + 시간/D-day 뱃지 — 폭이 모자라면 뱃지가 다음 줄로
                            // 내려간다 (D-day를 말줄임으로 자르지 않기 위해).
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    sub.subjectName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                      decoration: isDone ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDone ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      timeLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isDone ? const Color(0xFF64748B) : themeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            // 완료 체크박스
                            InkWell(
                              onTap: () => _toggleSubjectCompletion(sub),
                              child: Icon(
                                sub.isCompleted ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                size: 18,
                                color: sub.isCompleted ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                              ),
                            ),
                          ],
                        ),

                        if (timeStr.isNotEmpty || sub.classroom != null) ...[
                          const SizedBox(height: 4),
                          // 시간 + 고사장 — 한 덩어리 텍스트로 만들어 좁으면 자연스럽게 줄바꿈.
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              children: [
                                if (timeStr.isNotEmpty) ...[
                                  const WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                  TextSpan(text: timeStr),
                                  const TextSpan(text: '    '),
                                ],
                                if (sub.classroom != null) ...[
                                  const WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(Icons.room_outlined, size: 12, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                  TextSpan(text: sub.classroom!),
                                ],
                              ],
                            ),
                          ),
                        ],

                        if (sub.memo != null && sub.memo!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '📌 ${sub.memo!}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                          ),
                        ],

                        // 준비물 체크리스트
                        if (sub.checklist.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: sub.checklist.map((item) {
                              final isItemChecked = checkedItems.contains(item);
                              return InkWell(
                                onTap: () => _toggleChecklistItem(sub.id, item),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isItemChecked
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isItemChecked ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isItemChecked ? Icons.check_box : Icons.check_box_outline_blank,
                                        size: 10,
                                        color: isItemChecked ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isItemChecked ? const Color(0xFF166534) : const Color(0xFF475569),
                                          decoration: isItemChecked ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}
