import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/goal_model.dart';
import 'add_goal_modal.dart';

/// 목표 / 버킷리스트 노션 스타일 카테고리 뷰
class GoalCategoryView extends StatefulWidget {
  const GoalCategoryView({
    super.key,
    required this.goals,
    required this.onGoalsChanged,
    required this.onOpenAddModal,
  });

  final List<GoalItem> goals;
  final ValueChanged<List<GoalItem>> onGoalsChanged;
  final VoidCallback onOpenAddModal;

  @override
  State<GoalCategoryView> createState() => _GoalCategoryViewState();
}

class _GoalCategoryViewState extends State<GoalCategoryView> {
  int _selectedFilterIndex = 0; // 0=전체, 1=올해 목표, 2=매달 목표, 3=버킷리스트
  int _selectedMonth = DateTime.now().month;

  final List<String> _filters = ['전체', '올해 목표', '매달 목표', '버킷리스트'];

  List<GoalItem> _getFilteredGoals() {
    final activeGoals = widget.goals;
    List<GoalItem> list;

    switch (_selectedFilterIndex) {
      case 1:
        list = activeGoals.where((g) => g.goalType == GoalType.yearly).toList();
        break;
      case 2:
        list = activeGoals
            .where((g) => g.goalType == GoalType.monthly && (g.targetMonth == null || g.targetMonth == _selectedMonth))
            .toList();
        break;
      case 3:
        list = activeGoals.where((g) => g.goalType == GoalType.bucket).toList();
        break;
      case 0:
      default:
        list = List.from(activeGoals);
        break;
    }

    // 미완료 항목 우선, 완료 항목은 하단으로 자동 정렬
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      if (a.deadline != null) return -1;
      if (b.deadline != null) return 1;
      return 0;
    });

    return list;
  }

  void _toggleGoal(GoalItem goal) {
    final newCompleted = !goal.isCompleted;
    final updated = goal.copyWith(
      isCompleted: newCompleted,
      status: newCompleted ? GoalStatus.completed : GoalStatus.inProgress,
      completedAt: newCompleted ? DateTime.now() : null,
    );
    final newList = widget.goals.map((g) => g.id == goal.id ? updated : g).toList();
    widget.onGoalsChanged(newList);
  }

  void _cycleStatus(GoalItem goal) {
    final nextStatus = switch (goal.status) {
      GoalStatus.notStarted => GoalStatus.inProgress,
      GoalStatus.inProgress => GoalStatus.completed,
      GoalStatus.completed => GoalStatus.notStarted,
    };
    final isCompleted = nextStatus == GoalStatus.completed;
    final updated = goal.copyWith(
      status: nextStatus,
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
    );
    final newList = widget.goals.map((g) => g.id == goal.id ? updated : g).toList();
    widget.onGoalsChanged(newList);
  }

  Future<void> _editGoal(GoalItem goal) async {
    final updated = await showAddGoalModal(
      context,
      existingGoal: goal,
      allowDelete: true,
      onDelete: () {
        final newList = widget.goals.where((g) => g.id != goal.id).toList();
        widget.onGoalsChanged(newList);
      },
    );
    if (updated != null) {
      final newList = widget.goals.map((g) => g.id == goal.id ? updated : g).toList();
      widget.onGoalsChanged(newList);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredGoals = _getFilteredGoals();
    final completedCount = widget.goals.where((g) => g.isCompleted).length;
    final totalCount = widget.goals.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 달성률 헤더 요약 (미니멀 프로페셔널 룩)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '전체 목표 달성률',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.protoHeading,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$completedCount / $totalCount 달성 (${totalCount > 0 ? ((completedCount / totalCount) * 100).toInt() : 0}%)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. 상단 미니멀 탭 필터: [전체] | [올해 목표] | [매달 목표] | [버킷리스트]
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: List.generate(_filters.length, (index) {
              final isSelected = _selectedFilterIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilterIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
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
                      _filters[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // 매달 목표 선택 시 월별 서브 필터 칩
        if (_selectedFilterIndex == 2) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(12, (index) {
                final month = index + 1;
                final isSelected = _selectedMonth == month;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('$month월', style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedMonth = month),
                    selectedColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
            ),
          ),
        ],
        const SizedBox(height: 14),

        // 3. 노션 스타일 아이템 리스트
        if (filteredGoals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.flag_outlined, size: 36, color: Colors.grey),
                const SizedBox(height: 10),
                const Text('등록된 목표가 없습니다', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: widget.onOpenAddModal,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('새 목표 등록하기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredGoals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final goal = filteredGoals[index];
              return _buildGoalRow(goal);
            },
          ),
      ],
    );
  }

  Widget _buildGoalRow(GoalItem goal) {
    return InkWell(
      onTap: () => _editGoal(goal),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. 체크박스
            GestureDetector(
              onTap: () => _toggleGoal(goal),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: goal.isCompleted ? const Color(0xFF16A34A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: goal.isCompleted ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                    width: 1.8,
                  ),
                ),
                child: goal.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // 2. 제목 (형광펜 하이라이트 배경 지원)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: goal.highlighter != HighlighterColor.none
                        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
                        : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: goal.highlighter.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: goal.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                        decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (goal.showInCalendar) ...[
                    const SizedBox(height: 3),
                    const Row(
                      children: [
                        Icon(Icons.calendar_today, size: 10, color: Color(0xFF64748B)),
                        SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '캘린더 연동됨',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 3. 3단계 상태 태그 (Select)
            GestureDetector(
              onTap: () => _cycleStatus(goal),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: goal.status.tagBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: goal.status.tagColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  goal.status.labelKo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: goal.status.tagColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // 4. D-Day / 기한 없음 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                goal.dDayLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: goal.isCompleted
                      ? const Color(0xFF16A34A)
                      : (goal.deadline == null ? const Color(0xFF64748B) : const Color(0xFF0F172A)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
