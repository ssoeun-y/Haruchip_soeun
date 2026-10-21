import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../shared/widgets/event_sync_options_section.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/goal_model.dart';

/// 목표 / 버킷리스트 추가 및 수정 모달
Future<GoalItem?> showAddGoalModal(
  BuildContext context, {
  GoalItem? existingGoal,
  bool allowDelete = false,
  VoidCallback? onDelete,
}) {
  return showModalBottomSheet<GoalItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddGoalModal(
      existingGoal: existingGoal,
      allowDelete: allowDelete,
      onDelete: onDelete,
    ),
  );
}

class _AddGoalModal extends StatefulWidget {
  const _AddGoalModal({
    this.existingGoal,
    this.allowDelete = false,
    this.onDelete,
  });

  final GoalItem? existingGoal;
  final bool allowDelete;
  final VoidCallback? onDelete;

  @override
  State<_AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<_AddGoalModal> {
  late TextEditingController _titleController;
  late TextEditingController _memoController;
  late GoalType _goalType;
  late int _targetMonth;
  DateTime? _deadline;
  late bool _noDeadline;
  late GoalStatus _status;
  late HighlighterColor _highlighter;
  late bool _showInCalendar;
  bool _syncGoogle = false;
  bool _syncNaver = false;
  bool _syncRoom = false;
  final List<String> _selectedRoomIds = [];

  @override
  void initState() {
    super.initState();
    final goal = widget.existingGoal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _memoController = TextEditingController(text: goal?.memo ?? '');
    _goalType = goal?.goalType ?? GoalType.yearly;
    _targetMonth = goal?.targetMonth ?? DateTime.now().month;
    _deadline = goal?.deadline ?? (goal?.goalType == GoalType.bucket ? null : DateTime(DateTime.now().year, 12, 31));
    _noDeadline = goal?.deadline == null && goal?.goalType == GoalType.bucket;
    _status = goal?.status ?? GoalStatus.inProgress;
    _highlighter = goal?.highlighter ?? HighlighterColor.yellow;
    _showInCalendar = goal?.showInCalendar ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _openDatePicker() {
    final initialDate = _deadline ?? DateTime.now();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HaruCalendarPicker(
                initialDate: initialDate,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2035, 12, 31),
                onDateChanged: (picked) {
                  setState(() {
                    _deadline = picked;
                    _noDeadline = false;
                  });
                  Navigator.of(dialogCtx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 목표 제목을 입력해주세요.')),
      );
      return;
    }

    final isCompleted = _status == GoalStatus.completed;

    final item = GoalItem(
      id: widget.existingGoal?.id ?? 'goal-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      goalType: _goalType,
      targetYear: DateTime.now().year,
      targetMonth: _goalType == GoalType.monthly ? _targetMonth : null,
      deadline: _noDeadline ? null : _deadline,
      status: _status,
      isCompleted: isCompleted,
      completedAt: isCompleted ? (widget.existingGoal?.completedAt ?? DateTime.now()) : null,
      highlighter: _highlighter,
      showInCalendar: _showInCalendar,
      memo: _memoController.text.trim().isNotEmpty ? _memoController.text.trim() : null,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingGoal != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? '목표 / 버킷리스트 수정' : '새 목표 / 버킷리스트 추가',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading2.copyWith(
                            color: AppColors.protoHeading,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppColors.protoSubtitle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 분류 선택 탭
                    Text(
                      '목표 분류',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          for (final type in GoalType.values)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _goalType = type;
                                  if (type == GoalType.bucket) {
                                    _noDeadline = true;
                                  }
                                }),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _goalType == type ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _goalType == type
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 3,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    type.labelKo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: _goalType == type ? FontWeight.bold : FontWeight.w500,
                                      color: _goalType == type ? AppColors.protoHeading : AppColors.protoSubtitle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. 제목 입력
                    Text(
                      '목표 제목',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      style: AppTypography.body.copyWith(
                        color: AppColors.protoHeading,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '예: 토익 900점 달성하기, 스위스 패러글라이딩',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 매달 목표일 때 월 선택 드롭다운
                    if (_goalType == GoalType.monthly) ...[
                      Text(
                        '목표 월 선택',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.protoSubtitle,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(12, (index) {
                          final month = index + 1;
                          final isSelected = _targetMonth == month;
                          return ChoiceChip(
                            label: Text('$month월', style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            selected: isSelected,
                            onSelected: (val) => setState(() => _targetMonth = month),
                            selectedColor: const Color(0xFF0F172A),
                            labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF0F172A)),
                            backgroundColor: const Color(0xFFF8FAFC),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            showCheckmark: false,
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 3. 기한 설정
                    Text(
                      '목표 기한',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _noDeadline ? null : _openDatePicker,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _noDeadline ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event_outlined,
                                    size: 18,
                                    color: _noDeadline ? Colors.grey : const Color(0xFF0F172A),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _noDeadline || _deadline == null
                                          ? '기한 없음'
                                          : '${_deadline!.year}.${_deadline!.month.toString().padLeft(2, '0')}.${_deadline!.day.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _noDeadline ? Colors.grey : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilterChip(
                          label: const Text('기한 없음', style: TextStyle(fontSize: 12)),
                          selected: _noDeadline,
                          onSelected: (val) => setState(() {
                            _noDeadline = val;
                            if (!val && _deadline == null) {
                              _deadline = DateTime(DateTime.now().year, 12, 31);
                            }
                          }),
                          selectedColor: const Color(0xFFE2E8F0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          showCheckmark: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 4. 상태 태그 선택 (3단계)
                    Text(
                      '진행 상태',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: GoalStatus.values.map((s) {
                        final isSelected = _status == s;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () => setState(() => _status = s),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? s.tagBgColor : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? s.tagColor : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  s.labelKo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    color: isSelected ? s.tagColor : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // 5. 형광펜 하이라이트 우선순위
                    Text(
                      '형광펜 하이라이트 (우선순위)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: HighlighterColor.values.map((h) {
                        final isSelected = _highlighter == h;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => _highlighter = h),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: h == HighlighterColor.none ? const Color(0xFFF1F5F9) : h.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 18, color: Color(0xFF0F172A))
                                  : (h == HighlighterColor.none
                                      ? const Icon(Icons.block, size: 16, color: Colors.grey)
                                      : null),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // 6. 캘린더 & 모임 연동 설정
                    EventSyncOptionsSection(
                      showInCalendar: _showInCalendar,
                      onShowInCalendarChanged: (val) => setState(() => _showInCalendar = val),
                      showInCalendarLabel: '하루칩 캘린더에 표시',
                      showInCalendarSubLabel: '메인 캘린더 화면에 목표 마감일을 표시합니다',
                      syncGoogle: _syncGoogle,
                      onSyncGoogleChanged: (v) => setState(() => _syncGoogle = v),
                      syncNaver: _syncNaver,
                      onSyncNaverChanged: (v) => setState(() => _syncNaver = v),
                      syncRoom: _syncRoom,
                      onSyncRoomChanged: (v) => setState(() => _syncRoom = v),
                      selectedRoomIds: _selectedRoomIds,
                      onToggleRoomId: (id) {
                        setState(() {
                          if (_selectedRoomIds.contains(id)) {
                            _selectedRoomIds.remove(id);
                          } else {
                            _selectedRoomIds.add(id);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 18),

                    // 7. 메모
                    Text(
                      '세부 메모 (선택)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _memoController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '실행 전략, 필요한 준비물 등 메모',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  if (isEditing && widget.allowDelete) ...[
                    IconButton(
                      onPressed: () {
                        widget.onDelete?.call();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      tooltip: '삭제하기',
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A), // Minimal Slate Black
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isEditing ? '수정 완료' : '목표 등록하기',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
