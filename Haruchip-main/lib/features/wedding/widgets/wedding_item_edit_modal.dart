import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../shared/widgets/common_date_time_picker.dart';
import '../models/wedding_item.dart';
import '../providers/wedding_provider.dart';

/// 단일 결혼 준비 항목 상세 커스텀 편집 모달 (하루칩 공통 캘린더 피커 + 장소/메모)
class WeddingItemEditModal extends ConsumerStatefulWidget {
  const WeddingItemEditModal({
    super.key,
    this.item,
  });

  final WeddingItem? item;

  static Future<void> show(BuildContext context, [WeddingItem? item]) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WeddingItemEditModal(item: item),
    );
  }

  @override
  ConsumerState<WeddingItemEditModal> createState() =>
      _WeddingItemEditModalState();
}

class _WeddingItemEditModalState extends ConsumerState<WeddingItemEditModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _memoController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late bool _isAllDay;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _locationController = TextEditingController(text: widget.item?.location ?? '');
    _memoController = TextEditingController(text: widget.item?.memo ?? '');

    _selectedDate = widget.item?.targetDate ?? DateTime.now();
    _selectedTime = widget.item?.deadlineTime;
    _isAllDay = widget.item?.deadlineTime == null;
    _isCompleted = widget.item?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요.')),
      );
      return;
    }
    final location = _locationController.text.trim();
    final memo = _memoController.text.trim();

    final deadlineTime = _isAllDay ? null : _selectedTime;

    if (widget.item != null) {
      final updated = widget.item!.copyWith(
        title: title,
        targetDate: _selectedDate,
        deadlineTime: deadlineTime,
        location: location,
        memo: memo,
        isCompleted: _isCompleted,
        clearDate: _selectedDate == null,
        clearTime: _isAllDay || deadlineTime == null,
      );
      ref.read(weddingListProvider.notifier).updateItem(updated);
    } else {
      final currentItems = ref.read(weddingListProvider);
      final newItem = WeddingItem(
        id: 'wedding-custom-${DateTime.now().microsecondsSinceEpoch}',
        orderIndex: currentItems.length + 1,
        title: title,
        targetDate: _selectedDate,
        deadlineTime: deadlineTime,
        location: location,
        memo: memo,
        isCompleted: _isCompleted,
        standardOffsetDays: 30,
        stage: WeddingStage.finalCheckAndCeremony,
      );
      ref.read(weddingListProvider.notifier).addItem(newItem);
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ 일정이 안전하게 저장 및 캘린더에 동기화되었습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _delete() {
    if (widget.item == null) return;
    ref.read(weddingListProvider.notifier).removeItem(widget.item!.id);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('일정이 삭제되었습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 바
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 상단 타이틀 및 완료 체크 토글
            Row(
              children: [
                Checkbox(
                  value: _isCompleted,
                  activeColor: const Color(0xFFE53E3E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (val) =>
                      setState(() => _isCompleted = val ?? false),
                ),
                Expanded(
                  child: Text(
                    widget.item != null ? '결혼 준비 항목 수정' : '새 결혼 준비 항목 추가',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.protoHeading,
                    ),
                  ),
                ),
                if (widget.item != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFE11D48)),
                    tooltip: '항목 삭제',
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 1. 항목 이름
            const Text(
              '항목명 (준비 내용)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '예: 웨딩홀 투어 진행, 스튜디오 촬영',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // 2. 어디서 (위치/장소)
            const Text(
              '📍 장소 / 업체명',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: '예: 아펠가모 공덕 라포레홀, 로브드K',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // 3. 언제 (일시 - 하루칩 앱 공통 달력 팝업 및 월간 그리드 로직)
            const Text(
              '📅 일정 및 시간 (하루칩 공통 캘린더)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            CommonDateTimePicker(
              initialStartDate: _selectedDate != null
                  ? DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedTime?.hour ?? 14,
                      _selectedTime?.minute ?? 0,
                    )
                  : DateTime.now(),
              hasEndDate: false,
              isAllDay: _isAllDay,
              showAllDayToggle: true,
              accentColor: const Color(0xFFE53E3E),
              onDateTimeChanged: (start, _, isAllDay) {
                setState(() {
                  _selectedDate = DateTime(start.year, start.month, start.day);
                  _selectedTime = isAllDay ? null : TimeOfDay(hour: start.hour, minute: start.minute);
                  _isAllDay = isAllDay;
                });
              },
            ),
            const SizedBox(height: 16),

            // 4. 메모 & 준비 팁
            const Text(
              '메모 & 준비 팁',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _memoController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: '업체 담당자 연락처, 준비물, 특이사항 등을 적어두세요.',
                hintStyle:
                    const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53E3E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  widget.item != null ? '수정 사항 저장하기' : '새 일정 추가하기',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
