import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../shared/widgets/common_date_time_picker.dart';
import '../../shared/widgets/event_sync_options_section.dart';
import '../models/appointment_model.dart';

/// 일정 / 약속 추가 및 수정 모달
Future<AppointmentItem?> showAddAppointmentModal(
  BuildContext context, {
  AppointmentItem? existingAppointment,
  bool allowDelete = false,
  VoidCallback? onDelete,
}) {
  return showModalBottomSheet<AppointmentItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddAppointmentModal(
      existingAppointment: existingAppointment,
      allowDelete: allowDelete,
      onDelete: onDelete,
    ),
  );
}

class _AddAppointmentModal extends StatefulWidget {
  const _AddAppointmentModal({
    this.existingAppointment,
    this.allowDelete = false,
    this.onDelete,
  });

  final AppointmentItem? existingAppointment;
  final bool allowDelete;
  final VoidCallback? onDelete;

  @override
  State<_AddAppointmentModal> createState() => _AddAppointmentModalState();
}

class _AddAppointmentModalState extends State<_AddAppointmentModal> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _memoController;
  late TextEditingController _personInputController;
  late TextEditingController _subTaskInputController;

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  late bool _isAllDay;
  late List<String> _withPeople;
  late List<SubTaskItem> _subTasks;
  bool _syncGoogle = false;
  bool _syncNaver = false;
  bool _syncRoom = false;
  final List<String> _selectedRoomIds = [];

  @override
  void initState() {
    super.initState();
    final item = widget.existingAppointment;
    _titleController = TextEditingController(text: item?.title ?? '');
    _locationController = TextEditingController(text: item?.location ?? '');
    _memoController = TextEditingController(text: item?.memo ?? '');
    _personInputController = TextEditingController();
    _subTaskInputController = TextEditingController();

    _selectedDate = item?.date ?? DateTime.now();
    _selectedTime = item?.time ?? const TimeOfDay(hour: 14, minute: 0);
    _isAllDay = item?.isAllDay ?? false;
    _withPeople = List.from(item?.withPeople ?? []);
    _subTasks = List.from(item?.subTasks ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _memoController.dispose();
    _personInputController.dispose();
    _subTaskInputController.dispose();
    super.dispose();
  }

  void _openDatePicker() async {
    final picked = await showCommonDatePickerModal(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      title: '약속 날짜 선택',
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _openTimePicker() async {
    final curTime = _selectedTime ?? const TimeOfDay(hour: 14, minute: 0);
    final currentDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      curTime.hour,
      curTime.minute,
    );
    final picked = await showCommonDateTimePickerModal(
      context,
      initialDateTime: currentDt,
      isAllDay: false,
      showAllDayToggle: false,
      title: '약속 시간 선택',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTime = TimeOfDay(hour: picked.hour, minute: picked.minute);
        _isAllDay = false;
      });
    }
  }

  void _addPerson() {
    final text = _personInputController.text.trim();
    if (text.isNotEmpty && !_withPeople.contains(text)) {
      setState(() {
        _withPeople.add(text);
        _personInputController.clear();
      });
    }
  }

  void _addSubTask() {
    final text = _subTaskInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subTasks.add(SubTaskItem(
          id: 'st-${DateTime.now().microsecondsSinceEpoch}',
          title: text,
          isDone: false,
        ));
        _subTaskInputController.clear();
      });
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

    final item = AppointmentItem(
      id: widget.existingAppointment?.id ?? 'apt-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      date: _selectedDate,
      time: _isAllDay ? null : _selectedTime,
      isAllDay: _isAllDay,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      withPeople: _withPeople,
      subTasks: _subTasks,
      memo: _memoController.text.trim().isNotEmpty ? _memoController.text.trim() : null,
      isArchived: widget.existingAppointment?.isArchived ?? false,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAppointment != null;
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    final dateDisplay = '${_selectedDate.year}.$m.$d';

    final timeDisplay = _isAllDay
        ? '하루 종일'
        : (_selectedTime != null
            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
            : '시간 미지정');

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
                      Text(
                        isEditing ? '일정 / 약속 수정' : '새 일정 / 약속 추가',
                        style: AppTypography.heading2.copyWith(
                          color: AppColors.protoHeading,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
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
                    // 1. 제목 (What)
                    Text(
                      '일정 제목 (What)',
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
                        hintText: '예: 팀 디자인 싱크 미팅, 동창 저녁 약속',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. 일시 (When)
                    Text(
                      '일시 (When)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Date Picker
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: _openDatePicker,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0F172A)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      dateDisplay,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Time Picker
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: _isAllDay ? null : _openTimePicker,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: _isAllDay ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: _isAllDay ? Colors.grey : const Color(0xFF0F172A),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      timeDisplay,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _isAllDay ? Colors.grey : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // All Day Toggle
                    Row(
                      children: [
                        Checkbox(
                          value: _isAllDay,
                          onChanged: (val) => setState(() => _isAllDay = val ?? false),
                          activeColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        const Text('하루 종일', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3. 장소 (Where)
                    Text(
                      '장소 (Where)',
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
                        hintText: '예: 강남 위워크 3층 회의실, 성수동 파스타바',
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4. 함께하는 사람 (With)
                    Text(
                      '함께하는 사람 (With)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _personInputController,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: '이름 입력 후 추가',
                              prefixIcon: const Icon(Icons.people_alt_outlined, size: 18, color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            onSubmitted: (_) => _addPerson(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addPerson,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF0F172A),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('추가', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (_withPeople.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _withPeople.map((person) {
                          return Chip(
                            label: Text(person, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _withPeople.remove(person)),
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // 5. 하위 할 일 / 준비물 (Sub-tasks)
                    Text(
                      '하위 할 일 / 준비물 (Sub-tasks)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subTaskInputController,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: '준비물 또는 하위 체크리스트 입력',
                              prefixIcon: const Icon(Icons.check_box_outlined, size: 18, color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            onSubmitted: (_) => _addSubTask(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addSubTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF0F172A),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('추가', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (_subTasks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        // ListTile 잉크/배경은 가장 가까운 Material에 그려지므로, 배경색 있는
                        // 컨테이너 안에서는 투명 Material을 한 겹 둬야 보인다.
                        child: Material(
                          type: MaterialType.transparency,
                          child: Column(
                          children: [
                            for (int i = 0; i < _subTasks.length; i++)
                              ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                leading: Checkbox(
                                  value: _subTasks[i].isDone,
                                  onChanged: (val) => setState(() {
                                    _subTasks[i] = _subTasks[i].copyWith(isDone: val ?? false);
                                  }),
                                  activeColor: const Color(0xFF0F172A),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                title: Text(
                                  _subTasks[i].title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    decoration: _subTasks[i].isDone ? TextDecoration.lineThrough : null,
                                    color: _subTasks[i].isDone ? Colors.grey : const Color(0xFF0F172A),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.grey),
                                  onPressed: () => setState(() => _subTasks.removeAt(i)),
                                ),
                              ),
                          ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // 6. 캘린더 & 모임 연동 설정
                    EventSyncOptionsSection(
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
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '회의 아젠다, 예약 번호 등 세부 사항',
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
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        isEditing ? '수정 완료' : '일정 등록하기',
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
