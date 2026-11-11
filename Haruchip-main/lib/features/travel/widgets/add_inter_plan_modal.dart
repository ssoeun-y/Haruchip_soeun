import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../shared/widgets/common_date_time_picker.dart';
import '../models/inter_trip_plan.dart';
import '../providers/travel_provider.dart';

/// 여행 사이사이 계획(사전 준비 마일스톤) 추가 및 수정 모달
class AddInterPlanModal extends ConsumerStatefulWidget {
  const AddInterPlanModal({
    super.key,
    this.initialPlan,
    this.beforeTripId,
    this.afterTripId,
    this.suggestedDate,
  });

  final InterTripPlan? initialPlan;
  final String? beforeTripId;
  final String? afterTripId;
  final DateTime? suggestedDate;

  static Future<void> show(
    BuildContext context, {
    InterTripPlan? initialPlan,
    String? beforeTripId,
    String? afterTripId,
    DateTime? suggestedDate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddInterPlanModal(
        initialPlan: initialPlan,
        beforeTripId: beforeTripId,
        afterTripId: afterTripId,
        suggestedDate: suggestedDate,
      ),
    );
  }

  @override
  ConsumerState<AddInterPlanModal> createState() => _AddInterPlanModalState();
}

class _AddInterPlanModalState extends ConsumerState<AddInterPlanModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _memoController;
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;

  final List<String> _quickPresets = [
    '🏨 숙소 잔금 결제 및 예약 확인',
    '💴 엔화/달러 우대 환전 신청',
    '🛂 여권 만료일 확인 및 재발급',
    '🎟️ 투어/교통패스 사전 예매',
    '📶 여행자 eSIM / 유심 구매',
    '🏥 해외 여행자 보험 가입',
  ];

  @override
  void initState() {
    super.initState();
    final plan = widget.initialPlan;
    _titleController = TextEditingController(text: plan?.title ?? '');
    _memoController = TextEditingController(text: plan?.memo ?? '');
    _selectedDate = plan?.date ?? widget.suggestedDate ?? DateTime.now().add(const Duration(days: 7));

    if (plan?.time != null) {
      final parts = plan!.time!.split(':');
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 10,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showCommonDatePickerModal(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      accentColor: const Color(0xFF0284C7),
      title: '일정 날짜 선택',
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final currentDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime?.hour ?? 12,
      _selectedTime?.minute ?? 0,
    );
    final picked = await showCommonDateTimePickerModal(
      context,
      initialDateTime: currentDt,
      isAllDay: false,
      showAllDayToggle: false,
      accentColor: const Color(0xFF0284C7),
      title: '일정 시간 선택',
    );
    if (picked != null) {
      setState(() => _selectedTime = TimeOfDay(hour: picked.hour, minute: picked.minute));
    }
  }

  void _savePlan() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 준비 일정 제목을 입력해 주세요.')),
      );
      return;
    }

    final timeStr = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : null;

    if (widget.initialPlan != null) {
      final updated = widget.initialPlan!.copyWith(
        title: title,
        date: _selectedDate,
        time: timeStr,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      );
      ref.read(interTripPlanListProvider.notifier).updatePlan(updated);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ [$title] 사이 계획이 수정되었습니다.')),
      );
    } else {
      final newPlan = InterTripPlan(
        id: 'inter-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        date: _selectedDate,
        time: timeStr,
        beforeTripId: widget.beforeTripId,
        afterTripId: widget.afterTripId,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      );
      ref.read(interTripPlanListProvider.notifier).addPlan(newPlan);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📌 [$title] 사이 계획이 타임라인에 등록되었습니다!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}';
    final timeStr = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : '시간 미지정';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('📍', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      widget.initialPlan != null ? '사이 계획 수정' : '여행 사이사이 계획 추가',
                      style: AppTypography.heading2.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.protoHeading,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '다음 여행을 위해 챙겨야 할 사전 예약이나 환전, 체크 태스크를 기록하세요.',
              style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
            ),
            const SizedBox(height: 14),

            // 빠른 템플릿 추천 칩
            const Text('자주 쓰는 사이 계획 추천', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final preset in _quickPresets)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(preset, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        backgroundColor: const Color(0xFFF0F9FF),
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onPressed: () {
                          setState(() {
                            _titleController.text = preset;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 할 일 명칭
            const Text('마일스톤 / 태스크 명칭', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'ex. 12/01 삿포로 호텔 잔금 결제, 엔화 환전 신청',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 날짜 & 시간 선택 행
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('일정 날짜', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_rounded, size: 16, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.protoHeading)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('시간 (선택)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Text(timeStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.protoHeading)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 메모 필드
            const Text('상세 메모 (선택)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
            const SizedBox(height: 6),
            TextField(
              controller: _memoController,
              decoration: InputDecoration(
                hintText: 'ex. 환율 900원 미만 진입 시 5만엔 즉시 환전하기',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _savePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  widget.initialPlan != null ? '수정 완료' : '사이 계획 추가',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
