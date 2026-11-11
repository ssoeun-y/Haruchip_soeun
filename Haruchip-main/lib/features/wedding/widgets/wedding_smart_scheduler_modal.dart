import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../logic/wedding_scheduler_engine.dart';
import '../providers/wedding_provider.dart';

/// 스마트 역산 스케줄러 모달 (3단계 플로우)
class WeddingSmartSchedulerModal extends ConsumerStatefulWidget {
  const WeddingSmartSchedulerModal({
    super.key,
    this.initialWeddingDate,
  });

  final DateTime? initialWeddingDate;

  static Future<void> show(BuildContext context, {DateTime? initialDate}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WeddingSmartSchedulerModal(initialWeddingDate: initialDate),
    );
  }

  @override
  ConsumerState<WeddingSmartSchedulerModal> createState() =>
      _WeddingSmartSchedulerModalState();
}

class _WeddingSmartSchedulerModalState
    extends ConsumerState<WeddingSmartSchedulerModal> {
  late DateTime _selectedWeddingDate;
  final Set<AvailableTimeSlot> _selectedSlots = {
    AvailableTimeSlot.weekdayEvening,
    AvailableTimeSlot.saturday,
    AvailableTimeSlot.sunday,
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedWeddingDate = widget.initialWeddingDate ??
        DateTime(now.year + 1, now.month, now.day);
  }

  Future<void> _selectDate() async {
    final picked = await showHaruDatePicker(
      context,
      initialDate: _selectedWeddingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );

    if (picked != null) {
      setState(() => _selectedWeddingDate = picked);
    }
  }

  void _generateSchedule() {
    ref.read(weddingListProvider.notifier).applySmartSchedule(
          weddingDate: _selectedWeddingDate,
          availableSlots: _selectedSlots,
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '예식일(${_selectedWeddingDate.year}.${_selectedWeddingDate.month}.${_selectedWeddingDate.day}) 기준 57개 일정이 스마트하게 배정되었습니다!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_selectedWeddingDate.year}년 ${_selectedWeddingDate.month}월 ${_selectedWeddingDate.day}일';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 타이틀 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('💍', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '스마트 역산 스케줄러',
                        style: AppTypography.heading1.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.protoHeading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '웨딩 표준 타임라인 데이터를 바탕으로 57개 일정을 자동 스냅 추천합니다.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.protoSubtitle,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Step 1: 예식 예정일 선택
            _buildStepTitle(1, '예식 예정일(본식일, T) 입력'),
            const SizedBox(height: 10),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 20, color: Color(0xFFE53E3E)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '결혼식 본식 날짜',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.protoHeading,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        '날짜 변경',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53E3E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Step 2: 신랑/신부 가용 요일 및 시간대 선택
            _buildStepTitle(2, '신랑/신부 가용 요일 및 시간대 다중 선택'),
            const SizedBox(height: 6),
            Text(
              '바쁜 두 분의 일정에 맞추어 가장 가까운 요일과 시간대로 자동 스냅(Auto-Snapping) 배정됩니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Column(
              children: AvailableTimeSlot.values.map((slot) {
                final isSelected = _selectedSlots.contains(slot);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          if (_selectedSlots.length > 1) {
                            _selectedSlots.remove(slot);
                          }
                        } else {
                          _selectedSlots.add(slot);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFF5F5)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFEB2B2)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: isSelected
                                ? const Color(0xFFE53E3E)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slot.labelKo,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFF742A2A)
                                        : AppColors.protoHeading,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (slot == AvailableTimeSlot.weekdayEvening)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFED7D7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '퇴근 후 추천',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9B2C2C),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Step 3: 추천 생성 버튼
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _generateSchedule,
                icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                label: const Text(
                  '57개 일정 스마트 추천 생성하기',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53E3E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTitle(int step, String title) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFE53E3E),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$step',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.protoHeading,
          ),
        ),
      ],
    );
  }
}
