import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../shared/widgets/common_date_time_picker.dart';
import '../models/hobby_item.dart';
import '../providers/hobby_provider.dart';

/// 취미 세부 일정 추가 및 수정 모달
class AddHobbyScheduleModal extends ConsumerStatefulWidget {
  const AddHobbyScheduleModal({
    super.key,
    required this.hobbyId,
    this.initialSchedule,
  });

  final String hobbyId;
  final HobbyScheduleItem? initialSchedule;

  static Future<void> show(
    BuildContext context, {
    required String hobbyId,
    HobbyScheduleItem? initialSchedule,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddHobbyScheduleModal(
        hobbyId: hobbyId,
        initialSchedule: initialSchedule,
      ),
    );
  }

  @override
  ConsumerState<AddHobbyScheduleModal> createState() => _AddHobbyScheduleModalState();
}

class _AddHobbyScheduleModalState extends ConsumerState<AddHobbyScheduleModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _memoController;
  late DateTime _selectedDate;
  late bool _hasTime;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);

  final List<String> _quickSuggestions = [
    '원데이 레슨',
    '주말 정기 러닝',
    '기타 줄 갈기',
    '장비 점검 & 청소',
    '온라인 강좌 수강',
    '합주 / 연습 세션',
  ];

  @override
  void initState() {
    super.initState();
    final sched = widget.initialSchedule;
    _titleController = TextEditingController(text: sched?.title ?? '');
    _locationController = TextEditingController(text: sched?.location ?? '');
    _memoController = TextEditingController(text: sched?.memo ?? '');
    _selectedDate = sched?.date ?? DateTime.now().add(const Duration(days: 3));
    _hasTime = sched?.hasTime ?? true;

    if (sched != null && sched.hasTime) {
      _selectedTime = TimeOfDay(hour: sched.date.hour, minute: sched.date.minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _onSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 이름을 입력해 주세요.')),
      );
      return;
    }

    final scheduleDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _hasTime ? _selectedTime.hour : 0,
      _hasTime ? _selectedTime.minute : 0,
    );

    final isEdit = widget.initialSchedule != null;
    final scheduleId =
        widget.initialSchedule?.id ?? 'sched-${DateTime.now().millisecondsSinceEpoch}';

    final item = HobbyScheduleItem(
      id: scheduleId,
      hobbyId: widget.hobbyId,
      title: title,
      date: scheduleDate,
      hasTime: _hasTime,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      isCompleted: widget.initialSchedule?.isCompleted ?? false,
      createdAt: widget.initialSchedule?.createdAt ?? DateTime.now(),
    );

    if (isEdit) {
      ref.read(hobbyScheduleListProvider.notifier).updateSchedule(item);
    } else {
      ref.read(hobbyScheduleListProvider.notifier).addSchedule(item);
    }

    Navigator.pop(context);
  }

  void _onDelete() {
    if (widget.initialSchedule == null) return;
    ref.read(hobbyScheduleListProvider.notifier).deleteSchedule(widget.initialSchedule!.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialSchedule != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 24,
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
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 상단 타이틀 & 닫기
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? '취미 일정 수정' : '새 취미 일정 추가',
                  style: AppTypography.heading2.copyWith(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 빠른 일정 제안 칩
            const Text(
              '자주 등록하는 일정',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final suggestion in _quickSuggestions)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(
                          suggestion,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF354235),
                          ),
                        ),
                        backgroundColor: const Color(0xFFF4F7F4),
                        side: const BorderSide(color: Color(0xFFDDE7DD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onPressed: () {
                          setState(() {
                            _titleController.text = suggestion;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 일정 이름
            const Text(
              '일정 이름',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'ex. 원데이 레슨, 주말 정기 러닝, 기타 줄 갈기',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF354235), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            CommonDateTimePicker(
              initialStartDate: DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              ),
              hasEndDate: false,
              isAllDay: !_hasTime,
              showAllDayToggle: true,
              accentColor: const Color(0xFF354235),
              onDateTimeChanged: (start, _, isAllDay) {
                setState(() {
                  _selectedDate = DateTime(start.year, start.month, start.day);
                  _selectedTime = TimeOfDay(hour: start.hour, minute: start.minute);
                  _hasTime = !isAllDay;
                });
              },
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),

            // 장소 입력
            const Text(
              '장소 (선택)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'ex. 낙원상가, 반포 한강공원, 성수동 카페',
                prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF354235), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 메모 입력
            const Text(
              '메모 (선택)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _memoController,
              decoration: InputDecoration(
                hintText: 'ex. 준비물: 피크, 튜너, 물병 챙기기',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF354235), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 저장 및 삭제 버튼
            Row(
              children: [
                if (isEdit) ...[
                  IconButton(
                    onPressed: _onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    tooltip: '일정 삭제',
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF354235),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isEdit ? '수정 완료' : '일정 등록하기',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
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
