import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/common_date_time_picker.dart';
import '../models/group_category_item.dart';
import '../providers/group_category_provider.dart';

class AddGroupMeetingModal extends ConsumerStatefulWidget {
  const AddGroupMeetingModal({
    super.key,
    required this.groupId,
    this.existingSchedule,
  });

  final String groupId;
  final GroupMeetingScheduleItem? existingSchedule;

  static Future<void> show(
    BuildContext context, {
    required String groupId,
    GroupMeetingScheduleItem? existingSchedule,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddGroupMeetingModal(
        groupId: groupId,
        existingSchedule: existingSchedule,
      ),
    );
  }

  @override
  ConsumerState<AddGroupMeetingModal> createState() =>
      _AddGroupMeetingModalState();
}

class _AddGroupMeetingModalState extends ConsumerState<AddGroupMeetingModal> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _memoController = TextEditingController();

  late DateTime _meetingDateTime;
  bool _isRegular = true;
  String _recurringRule = 'monthlySecondSaturday';

  final List<String> _quickTitlePresets = [
    '정기 정모',
    '급 번개 모임',
    '회식 및 뒤풀이',
    '주말 정기전',
    '월간 스터디',
    '연말 송년회',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingSchedule != null) {
      final s = widget.existingSchedule!;
      _titleController.text = s.title;
      _locationController.text = s.location;
      _memoController.text = s.memo ?? '';
      _meetingDateTime = s.dateTime;
      _isRegular = s.isRegular;
      _recurringRule = s.recurringRule ?? 'monthlySecondSaturday';
    } else {
      final now = DateTime.now();
      _meetingDateTime = DateTime(now.year, now.month, now.day + 7, 18, 30);
      _titleController.text = '정기 정모';
      _locationController.text = '강남역 11번 출구';
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
        const SnackBar(content: Text('일정 제목을 입력해주세요.')),
      );
      return;
    }

    final location = _locationController.text.trim().isEmpty
        ? '장소 미정'
        : _locationController.text.trim();

    if (widget.existingSchedule != null) {
      final updated = widget.existingSchedule!.copyWith(
        title: title,
        dateTime: _meetingDateTime,
        location: location,
        isRegular: _isRegular,
        recurringRule: _isRegular ? _recurringRule : null,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
      );
      ref.read(groupScheduleListProvider.notifier).updateSchedule(updated);
    } else {
      final newSchedule = GroupMeetingScheduleItem(
        id: 'sched-grp-${DateTime.now().millisecondsSinceEpoch}',
        groupId: widget.groupId,
        title: title,
        dateTime: _meetingDateTime,
        location: location,
        isAttending: true, // 생성자 기본 참석
        isRegular: _isRegular,
        recurringRule: _isRegular ? _recurringRule : null,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
        createdAt: DateTime.now(),
      );
      ref.read(groupScheduleListProvider.notifier).addSchedule(newSchedule);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingSchedule != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 핸들 바
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 상단 타이틀
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? '모임 일정 수정' : '모임 일정 추가',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF42302A),
                      ),
                    ),
                    TextButton(
                      onPressed: _onSave,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE56B48),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      child: const Text('저장'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 1. 일정 제목 입력 & 퀵 프리셋
                const Text(
                  '일정 명칭',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: '일정 제목을 입력하세요',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickTitlePresets.map((tag) {
                    return ActionChip(
                      label: Text(tag, style: const TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFFFF5F2),
                      side: const BorderSide(color: Color(0xFFFFE2D9)),
                      onPressed: () {
                        setState(() {
                          _titleController.text = tag;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // 2. 모임 일시 (CommonDateTimePicker 적용)
                const Text(
                  '모임 일시',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                CommonDateTimePicker(
                  initialStartDate: _meetingDateTime,
                  hasEndDate: false,
                  showAllDayToggle: false,
                  accentColor: const Color(0xFFE56B48),
                  onDateTimeChanged: (start, _, __) {
                    setState(() {
                      _meetingDateTime = start;
                    });
                  },
                ),
                const SizedBox(height: 18),

                // 3. 모임 장소
                const Text(
                  '모임 장소',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.place_outlined,
                      size: 20,
                      color: Color(0xFFE56B48),
                    ),
                    hintText: '예: 강남역 11번 출구 스타벅스',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 4. 정기 모임 자동 연동 토글
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFE2D9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.autorenew_rounded,
                                  size: 16,
                                  color: Color(0xFFE56B48),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '정기 모임 자동 갱신',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF42302A),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              '일정 경과 시 다음 회차 D-Day가 자동으로 생성됩니다.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isRegular,
                        activeTrackColor: const Color(0xFFE56B48),
                        onChanged: (val) => setState(() => _isRegular = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 5. 메모
                const Text(
                  '안내 사항 / 회비 메모',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _memoController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: '회비, 준비물, 특이사항을 기록하세요.',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 하단 등록 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE56B48),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isEdit ? '일정 수정 완료' : '일정 등록하기',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
