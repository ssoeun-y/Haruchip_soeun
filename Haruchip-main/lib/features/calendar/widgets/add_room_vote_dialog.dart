import 'package:flutter/material.dart';

import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/schedule_room.dart';

/// 모임 투표 생성 및 수정 다이얼로그 (마감 기한, 복수 선택, 익명 투표 지원)
Future<RoomVote?> showAddRoomVoteDialog(
  BuildContext context, {
  required String authorUid,
  RoomVote? existingVote,
}) {
  return showModalBottomSheet<RoomVote>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddRoomVoteDialog(
      authorUid: authorUid,
      existingVote: existingVote,
    ),
  );
}

class _AddRoomVoteDialog extends StatefulWidget {
  const _AddRoomVoteDialog({
    required this.authorUid,
    this.existingVote,
  });

  final String authorUid;
  final RoomVote? existingVote;

  @override
  State<_AddRoomVoteDialog> createState() => _AddRoomVoteDialogState();
}

class _AddRoomVoteDialogState extends State<_AddRoomVoteDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final List<TextEditingController> _optionControllers = [];
  bool _allowMultiple = false;
  bool _isAnonymous = false;
  bool _hasDeadline = false;
  DateTime? _deadlineDate;
  TimeOfDay _deadlineTime = const TimeOfDay(hour: 23, minute: 59);

  @override
  void initState() {
    super.initState();
    final ev = widget.existingVote;
    _titleController = TextEditingController(text: ev?.title ?? '');
    _descriptionController = TextEditingController(text: ev?.description ?? '');
    _allowMultiple = ev?.allowMultiple ?? false;
    _isAnonymous = ev?.isAnonymous ?? false;

    if (ev?.deadline != null) {
      _hasDeadline = true;
      _deadlineDate = ev!.deadline;
      _deadlineTime = TimeOfDay(hour: ev.deadline!.hour, minute: ev.deadline!.minute);
    } else {
      _hasDeadline = false;
      _deadlineDate = DateTime.now().add(const Duration(days: 1));
    }

    if (ev != null && ev.options.isNotEmpty) {
      for (final opt in ev.options) {
        _optionControllers.add(TextEditingController(text: opt.text));
      }
    } else {
      _optionControllers.add(TextEditingController());
      _optionControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택지는 최대 10개까지 추가할 수 있습니다.')),
      );
      return;
    }
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택지는 최소 2개 이상이어야 합니다.')),
      );
      return;
    }
    setState(() {
      final c = _optionControllers.removeAt(index);
      c.dispose();
    });
  }

  Future<void> _pickDeadlineDate() async {
    final picked = await showHaruDatePicker(
      context,
      initialDate: _deadlineDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _deadlineDate = picked;
      });
    }
  }

  Future<void> _pickDeadlineTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _deadlineTime,
    );
    if (picked != null) {
      setState(() {
        _deadlineTime = picked;
      });
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 투표 제목을 입력해주세요.')),
      );
      return;
    }

    final options = <VoteOption>[];
    final ev = widget.existingVote;
    for (int i = 0; i < _optionControllers.length; i++) {
      final text = _optionControllers[i].text.trim();
      if (text.isNotEmpty) {
        final existingOpt = (ev != null && i < ev.options.length) ? ev.options[i] : null;
        options.add(
          VoteOption(
            id: existingOpt?.id ?? 'opt-$i-${DateTime.now().microsecondsSinceEpoch}',
            text: text,
            voterUids: existingOpt?.voterUids ?? const [],
          ),
        );
      }
    }

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 최소 2개 이상의 유효한 선택지를 입력해주세요.')),
      );
      return;
    }

    DateTime? finalDeadline;
    if (_hasDeadline && _deadlineDate != null) {
      finalDeadline = DateTime(
        _deadlineDate!.year,
        _deadlineDate!.month,
        _deadlineDate!.day,
        _deadlineTime.hour,
        _deadlineTime.minute,
      );
    }

    final vote = RoomVote(
      id: widget.existingVote?.id ?? 'vote-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      authorUid: widget.existingVote?.authorUid ?? widget.authorUid,
      allowMultiple: _allowMultiple,
      isAnonymous: _isAnonymous,
      options: options,
      createdAt: widget.existingVote?.createdAt ?? DateTime.now(),
      deadline: finalDeadline,
      isClosed: widget.existingVote?.isClosed ?? false,
    );

    Navigator.of(context).pop(vote);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingVote != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // 흰 배경 위에 체크박스 터치 물결이 보이도록
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
        top: false,
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? '🗳️ 투표 수정하기' : '🗳️ 새 투표 만들기',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    const Text('투표 제목', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: '예: 2차 장소 어디로 갈까요?',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('설명 / 메모 (선택)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: '투표 관련 추가 설명이나 안내 사항',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 옵션 선택지 리스트
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('선택 항목', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        TextButton.icon(
                          onPressed: _addOption,
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('항목 추가', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    for (int i = 0; i < _optionControllers.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _optionControllers[i],
                                decoration: InputDecoration(
                                  hintText: '선택지 ${i + 1}',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 20),
                              onPressed: () => _removeOption(i),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),

                    // 투표 설정 옵션
                    const Text('투표 설정 및 마감 기한', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),

                    // 복수 선택 허용
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('복수 선택 허용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('멤버들이 여러 개의 선택지를 동시에 고를 수 있습니다.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      value: _allowMultiple,
                      onChanged: (val) => setState(() => _allowMultiple = val ?? false),
                    ),

                    // 익명 투표
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('익명 투표', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('투표자 명단을 숨기고 득표 수 및 비율 막대만 표시합니다.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      value: _isAnonymous,
                      onChanged: (val) => setState(() => _isAnonymous = val ?? false),
                    ),

                    // 마감 기한 설정
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('마감 기한 설정', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('설정한 일시가 지나면 자동으로 투표가 종료됩니다.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      value: _hasDeadline,
                      onChanged: (val) => setState(() => _hasDeadline = val ?? false),
                    ),

                    if (_hasDeadline) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickDeadlineDate,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                                      const SizedBox(width: 6),
                                      Text(
                                        _deadlineDate != null
                                            ? '${_deadlineDate!.year}.${_deadlineDate!.month.toString().padLeft(2, '0')}.${_deadlineDate!.day.toString().padLeft(2, '0')}'
                                            : '날짜 선택',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: _pickDeadlineTime,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_deadlineTime.hour.toString().padLeft(2, '0')}:${_deadlineTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    isEditing ? '투표 수정 완료' : '투표 등록하기',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
