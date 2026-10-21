import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/schedule_room.dart';

/// 모임 공유 일정 추가 다이얼로그
Future<RoomSharedEvent?> showAddRoomEventDialog(
  BuildContext context, {
  required String roomId,
  required String authorUid,
  DateTime? initialDate,
}) {
  return showModalBottomSheet<RoomSharedEvent>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddRoomEventDialog(
      roomId: roomId,
      authorUid: authorUid,
      initialDate: initialDate,
    ),
  );
}

class _AddRoomEventDialog extends StatefulWidget {
  const _AddRoomEventDialog({
    required this.roomId,
    required this.authorUid,
    this.initialDate,
  });

  final String roomId;
  final String authorUid;
  final DateTime? initialDate;

  @override
  State<_AddRoomEventDialog> createState() => _AddRoomEventDialogState();
}

class _AddRoomEventDialogState extends State<_AddRoomEventDialog> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _memoController;
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  bool _isAllDay = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _locationController = TextEditingController();
    _memoController = TextEditingController();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _openDatePicker() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HaruCalendarPicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2035, 12, 31),
                onDateChanged: (picked) {
                  setState(() => _selectedDate = picked);
                  Navigator.of(dialogCtx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTimePicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 일정 제목을 입력해주세요.')),
      );
      return;
    }

    final timeStr = _isAllDay
        ? null
        : '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final event = RoomSharedEvent(
      id: 'room-ev-${DateTime.now().microsecondsSinceEpoch}',
      roomId: widget.roomId,
      title: title,
      authorUid: widget.authorUid,
      date: _selectedDate,
      time: timeStr,
      isAllDay: _isAllDay,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      memo: _memoController.text.trim().isNotEmpty
          ? _memoController.text.trim()
          : null,
    );

    Navigator.of(context).pop(event);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '📅 모임 공유 일정 등록',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardLabel.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.protoHeading,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 22, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      '일정 제목',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '예: 1차 회식, 팀 주간회의, 정기 모임',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    Text(
                      '날짜',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _openDatePicker,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 10),
                            Text(
                              '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time / All Day
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '시간',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.protoSubtitle,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _isAllDay ? null : _openTimePicker,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isAllDay ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 18,
                                        color: _isAllDay ? Colors.grey : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _isAllDay
                                            ? '종일'
                                            : '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _isAllDay ? Colors.grey : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '하루 종일',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.protoSubtitle,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Switch(
                              value: _isAllDay,
                              onChanged: (v) => setState(() => _isAllDay = v),
                              activeTrackColor: const Color(0xFF0F172A),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location
                    Text(
                      '장소 (선택)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _locationController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '예: 강남역 3번 출구 스타벅스',
                        prefixIcon: const Icon(Icons.place_outlined, size: 18, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Memo
                    Text(
                      '메모 (선택)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _memoController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '준비물, 공지사항 등 메모 입력',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            // Bottom Action
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('일정 등록하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
