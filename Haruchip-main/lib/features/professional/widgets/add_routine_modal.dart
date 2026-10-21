import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../shared/widgets/event_sync_options_section.dart';
import '../models/routine_model.dart';

/// 루틴 / 주간 계획표 추가 및 수정 모달
Future<RoutineItem?> showAddRoutineModal(
  BuildContext context, {
  RoutineItem? existingRoutine,
  bool allowDelete = false,
  VoidCallback? onDelete,
}) {
  return showModalBottomSheet<RoutineItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddRoutineModal(
      existingRoutine: existingRoutine,
      allowDelete: allowDelete,
      onDelete: onDelete,
    ),
  );
}

class _AddRoutineModal extends StatefulWidget {
  const _AddRoutineModal({
    this.existingRoutine,
    this.allowDelete = false,
    this.onDelete,
  });

  final RoutineItem? existingRoutine;
  final bool allowDelete;
  final VoidCallback? onDelete;

  @override
  State<_AddRoutineModal> createState() => _AddRoutineModalState();
}

class _AddRoutineModalState extends State<_AddRoutineModal> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _memoController;

  late Set<int> _daysOfWeek;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _colorHex;
  bool _showInCalendar = false;
  bool _syncGoogle = false;
  bool _syncNaver = false;
  bool _syncRoom = false;
  final List<String> _selectedRoomIds = [];

  final List<String> _colorPresets = [
    '#DBEAFE', // 블루
    '#FEF08A', // 옐로우
    '#DCFCE7', // 민트
    '#FCE7F3', // 핑크
    '#F3E8FF', // 라벤더
    '#FFEDD5', // 살구
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existingRoutine;
    _titleController = TextEditingController(text: item?.title ?? '');
    _locationController = TextEditingController(text: item?.location ?? '');
    _memoController = TextEditingController(text: item?.memo ?? '');

    _daysOfWeek = Set.from(item?.daysOfWeek ?? [1, 3, 5]);
    _startTime = item?.startTime ?? const TimeOfDay(hour: 18, minute: 0);
    _endTime = item?.endTime ?? const TimeOfDay(hour: 19, minute: 0);
    _colorHex = item?.colorHex ?? '#DBEAFE';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 루틴 제목을 입력해주세요.')),
      );
      return;
    }

    if (_daysOfWeek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 최소 1개 이상의 요일을 선택해주세요.')),
      );
      return;
    }

    final item = RoutineItem(
      id: widget.existingRoutine?.id ?? 'rtn-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      daysOfWeek: _daysOfWeek,
      startTime: _startTime,
      endTime: _endTime,
      colorHex: _colorHex,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      memo: _memoController.text.trim().isNotEmpty ? _memoController.text.trim() : null,
      isArchived: widget.existingRoutine?.isArchived ?? false,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRoutine != null;
    const dayLabels = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};

    final stStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final etStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

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
            // Header
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
                          isEditing ? '루틴 / 주간 일정 수정' : '새 루틴 / 주간 일정 추가',
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
                    // 1. 루틴 제목
                    Text(
                      '루틴 / 일정 제목',
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
                        hintText: '예: 필라테스 강습, 영어 회화 학원, 주말 러닝',
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

                    // 2. 반복 요일 선택
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '반복 요일',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.protoSubtitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _daysOfWeek = {1, 2, 3, 4, 5}),
                              child: const Text('평일 ', style: TextStyle(fontSize: 12, color: Color(0xFF007AFF), fontWeight: FontWeight.bold)),
                            ),
                            const Text('· ', style: TextStyle(color: Colors.grey)),
                            GestureDetector(
                              onTap: () => setState(() => _daysOfWeek = {6, 7}),
                              child: const Text('주말 ', style: TextStyle(fontSize: 12, color: Color(0xFF007AFF), fontWeight: FontWeight.bold)),
                            ),
                            const Text('· ', style: TextStyle(color: Colors.grey)),
                            GestureDetector(
                              onTap: () => setState(() => _daysOfWeek = {1, 2, 3, 4, 5, 6, 7}),
                              child: const Text('매일', style: TextStyle(fontSize: 12, color: Color(0xFF007AFF), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final day = index + 1;
                        final isSelected = _daysOfWeek.contains(day);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (isSelected) {
                              _daysOfWeek.remove(day);
                            } else {
                              _daysOfWeek.add(day);
                            }
                          }),
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              dayLabels[day]!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // 3. 시간대 선택 (시작 ~ 종료)
                    Text(
                      '시간대 설정',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickStartTime,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('시작 시간', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(stStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('~', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _pickEndTime,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('종료 시간', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(etStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 4. 컬러 태그
                    Text(
                      '타임테이블 블록 컬러',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      runSpacing: 8,
                      children: _colorPresets.map((hex) {
                        final isSelected = _colorHex.toLowerCase() == hex.toLowerCase();
                        final color = Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => _colorHex = hex),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0F172A) : Colors.black12,
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 18, color: Color(0xFF0F172A))
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // 5. 장소 (Location)
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
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '예: 바디랩 필라테스 스튜디오',
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 6. 캘린더 & 모임 연동 설정
                    EventSyncOptionsSection(
                      showInCalendar: _showInCalendar,
                      onShowInCalendarChanged: (v) => setState(() => _showInCalendar = v),
                      showInCalendarLabel: '하루칩 캘린더에 표시',
                      showInCalendarSubLabel: '메인 캘린더 화면에 주간 루틴 일정을 표시합니다',
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

                    // 7. 메모 (Memo)
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
                        hintText: '준비물, 운동 루틴 메모 등',
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
                        isEditing ? '수정 완료' : '루틴 등록하기',
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
