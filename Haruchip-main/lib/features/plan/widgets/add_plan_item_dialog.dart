import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/plan_item.dart';
import '../providers/plan_provider.dart';

/// 실용형 카테고리(§5) 선택지 — categoryKey는 태그성 문자열이라 자유롭게
/// 확장 가능하지만(§5 "동일 카테고리 다중 인스턴스 항상 허용"), 이 다이얼로그는
/// CLAUDE.md §2 plan 폴더 설명("계획/업무/학업/시험/군대 공통")에 맞춰
/// 대표 5개만 고정 선택지로 제공한다.
const _kPlanCategoryOptions = <(String key, String labelKo)>[
  ('plan', '계획'),
  ('exam', '시험'),
  ('study', '학업'),
  ('military', '군대'),
  ('work', '업무'),
];

/// "+ 추가" 다이얼로그 — 제목/날짜/카테고리 입력 후 [planListProvider]에
/// 새 [PlanItem]을 추가한다.
///
/// 동일 카테고리를 여러 개 추가하는 것을 UI에서 막지 않는다(§5 다중 인스턴스
/// 허용 원칙) — 카테고리 선택은 그저 태그일 뿐, 중복 검사를 하지 않는다.
///
/// 모달 닫기는 CLAUDE.md 공통 규칙대로 X 버튼 / 하단 "닫기" 버튼 / 배경
/// 클릭(`barrierDismissible: true`) 3가지를 모두 지원한다.
class AddPlanItemDialog extends ConsumerStatefulWidget {
  const AddPlanItemDialog({super.key});

  /// 다이얼로그를 열고, 추가에 성공하면 true, 취소/닫기면 null/false를 돌려준다.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AddPlanItemDialog(),
    );
  }

  @override
  ConsumerState<AddPlanItemDialog> createState() => _AddPlanItemDialogState();
}

class _AddPlanItemDialogState extends ConsumerState<AddPlanItemDialog> {
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _categoryKey = _kPlanCategoryOptions.first.$1;
  bool _repeat = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showHaruDatePicker(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _handleAdd() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요.')),
      );
      return;
    }
    ref.read(planListProvider.notifier).addItem(
          PlanItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            date: _selectedDate,
            categoryKey: _categoryKey,
            repeat: _repeat,
          ),
        );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.protoCardBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '새 항목 추가',
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.protoHeading,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.protoSubtitle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '제목',
                style: AppTypography.caption.copyWith(
                  color: AppColors.protoSubtitle,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
                style: AppTypography.body.copyWith(
                  color: AppColors.protoHeading,
                ),
                decoration: InputDecoration(
                  hintText: '예: 정보처리기사 필기시험',
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '날짜',
                style: AppTypography.caption.copyWith(
                  color: AppColors.protoSubtitle,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: AppColors.protoStepLabel,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(_selectedDate),
                        style: AppTypography.cardLabel.copyWith(
                          color: AppColors.protoHeading,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '카테고리',
                style: AppTypography.caption.copyWith(
                  color: AppColors.protoSubtitle,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in _kPlanCategoryOptions)
                    _CategoryChip(
                      label: option.$2,
                      selected: _categoryKey == option.$1,
                      onTap: () => setState(() => _categoryKey = option.$1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(() => _repeat = !_repeat),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Icon(
                      _repeat
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 20,
                      color: _repeat
                          ? AppColors.protoRadioAccent
                          : AppColors.protoRadioUnselected,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '매년 반복',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoCardText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.protoCardText,
                        side: const BorderSide(
                          color: AppColors.protoCardBorder,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('닫기'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.protoButtonBg,
                        disabledBackgroundColor: AppColors.surfaceMuted,
                        foregroundColor: AppColors.protoButtonText,
                        disabledForegroundColor: AppColors.textDisabled,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('추가'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.protoCardSelectedBg
              : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.protoCardSelectedBorder
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected
                ? AppColors.protoCardSelectedText
                : AppColors.protoCardText,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
