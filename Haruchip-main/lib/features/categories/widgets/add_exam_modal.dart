import 'package:flutter/material.dart';
import '../../../design_system/typography.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/category.dart';
import '../models/exam_model.dart';
import 'exam_official_db_modal.dart';

/// 시험 등록 / 편집 모달
Future<ExamProfile?> showAddExamModal(
  BuildContext context, {
  ExamProfile? existingExam,
  bool allowDelete = false,
  VoidCallback? onDelete,
}) {
  return showModalBottomSheet<ExamProfile>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddExamModalContent(
      existingExam: existingExam,
      allowDelete: allowDelete,
      onDelete: onDelete,
    ),
  );
}

class _AddExamModalContent extends StatefulWidget {
  const _AddExamModalContent({
    this.existingExam,
    this.allowDelete = false,
    this.onDelete,
  });

  final ExamProfile? existingExam;
  final bool allowDelete;
  final VoidCallback? onDelete;

  @override
  State<_AddExamModalContent> createState() => _AddExamModalContentState();
}

class _AddExamModalContentState extends State<_AddExamModalContent> {
  late ExamType _selectedType;
  late TextEditingController _titleController;
  late TextEditingController _targetScoreController;
  late TextEditingController _categoryNameController;
  late String _selectedColorHex;
  late bool _showInMainCalendar;

  late List<ExamStageItem> _stages;
  late List<ExamSubjectItem> _subjects;

  static const List<String> _colorPalette = [
    '#2563EB', // Blue
    '#4F46E5', // Indigo
    '#7C3AED', // Purple
    '#059669', // Emerald
    '#D97706', // Amber
    '#DC2626', // Red
    '#0891B2', // Cyan
    '#DB2777', // Pink
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingExam;

    _selectedType = existing?.type ?? ExamType.qualification;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _targetScoreController = TextEditingController(text: existing?.targetScore ?? '');
    _categoryNameController = TextEditingController(text: existing?.categoryName ?? '국가기술자격');
    _selectedColorHex = existing?.colorHex ?? '#2563EB';
    _showInMainCalendar = existing?.showInMainCalendar ?? true;

    if (existing != null) {
      _stages = List.from(existing.stages);
      _subjects = List.from(existing.subjects);
    } else {
      // 신규 기본 단계 (4단계 풀 플로우)
      final now = DateTime.now();
      _stages = [
        ExamStageItem(
          id: 'stage-1',
          stageType: ExamStageType.application,
          name: '원서 접수 마감',
          startDate: now.add(const Duration(days: 7)),
          endDate: now.add(const Duration(days: 12)),
          testTime: '마감일 18:00까지',
        ),
        ExamStageItem(
          id: 'stage-2',
          stageType: ExamStageType.writtenTest,
          name: '필기 시험일',
          startDate: now.add(const Duration(days: 30)),
          testTime: '09:20 입실완료',
          checklist: ['신분증', '수험표', '컴퓨터용 사인펜', '수정테이프'],
        ),
        ExamStageItem(
          id: 'stage-3',
          stageType: ExamStageType.writtenResult,
          name: '필기 합격자 발표',
          startDate: now.add(const Duration(days: 50)),
          testTime: '오전 09:00',
        ),
        ExamStageItem(
          id: 'stage-4',
          stageType: ExamStageType.practicalTest,
          name: '실기 / 2차 시험',
          startDate: now.add(const Duration(days: 75)),
          testTime: '09:00 입실',
          checklist: ['검정 볼펜', '신분증', '수험표'],
        ),
        ExamStageItem(
          id: 'stage-5',
          stageType: ExamStageType.finalResult,
          name: '최종 합격자 발표',
          startDate: now.add(const Duration(days: 100)),
          testTime: '오전 09:00',
        ),
      ];

      _subjects = [
        ExamSubjectItem(
          id: 'sub-1',
          subjectName: '국어',
          examDate: now.add(const Duration(days: 14)),
          period: 1,
          startTime: '09:00',
          endTime: '10:00',
          classroom: '지정 고사장',
          checklist: ['컴퓨터용 사인펜', '수정테이프'],
        ),
        ExamSubjectItem(
          id: 'sub-2',
          subjectName: '수학',
          examDate: now.add(const Duration(days: 14)),
          period: 2,
          startTime: '10:30',
          endTime: '11:40',
          classroom: '지정 고사장',
          checklist: ['컴퓨터용 사인펜', '수정테이프', '계산기'],
        ),
      ];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetScoreController.dispose();
    _categoryNameController.dispose();
    super.dispose();
  }

  Future<void> _openOfficialDb() async {
    final loaded = await showExamOfficialDbModal(context);
    if (loaded != null && mounted) {
      setState(() {
        _selectedType = loaded.type;
        _titleController.text = loaded.title;
        _categoryNameController.text = loaded.categoryName;
        _selectedColorHex = loaded.colorHex;
        _stages = List.from(loaded.stages);
        if (loaded.subjects.isNotEmpty) {
          _subjects = List.from(loaded.subjects);
        }
        _showInMainCalendar = loaded.showInMainCalendar;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ [${loaded.title}] 공식 일정을 불러왔습니다.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<DateTime?> _pickDate(DateTime initialDate) async {
    DateTime selected = initialDate;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('날짜 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                HaruCalendarPicker(
                  initialDate: initialDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                  onDateChanged: (d) {
                    selected = d;
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return selected;
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  // --- Stage Management ---
  void _addStage() {
    final now = DateTime.now();
    final newStage = ExamStageItem(
      id: 'stage-${DateTime.now().microsecondsSinceEpoch}',
      stageType: ExamStageType.writtenTest,
      name: '새 시험 단계',
      startDate: now.add(const Duration(days: 14)),
    );
    setState(() {
      _stages.add(newStage);
    });
  }

  void _removeStage(int index) {
    setState(() {
      _stages.removeAt(index);
    });
  }

  void _editStage(int index) {
    final stage = _stages[index];
    final nameCtrl = TextEditingController(text: stage.name);
    final timeCtrl = TextEditingController(text: stage.testTime ?? '');
    final locCtrl = TextEditingController(text: stage.location ?? '');
    final seatCtrl = TextEditingController(text: stage.seatNumber ?? '');
    final regCtrl = TextEditingController(text: stage.registrationNumber ?? '');
    final checklistCtrl = TextEditingController();

    DateTime sDate = stage.startDate;
    DateTime? eDate = stage.endDate;
    ExamStageType sType = stage.stageType;
    List<String> curChecklist = List.from(stage.checklist);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${sIdxLabel(sType)} 단계 편집', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 단계 유형 선택
                    const Text('단계 유형', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ExamStageType.values.map((t) {
                          final isSel = sType == t;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text('${t.defaultEmoji} ${t.shortLabel}'),
                              selected: isSel,
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() {
                                    sType = t;
                                    if (nameCtrl.text.isEmpty || nameCtrl.text == stage.name) {
                                      nameCtrl.text = t.labelKo;
                                    }
                                  });
                                }
                              },
                              selectedColor: const Color(0xFF0F172A),
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : const Color(0xFF475569),
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 단계 명칭
                    const Text('단계 명칭', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: '예: 1차 필기시험, 원서접수 마감',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 날짜 선택
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sType == ExamStageType.application ? '접수 시작일' : '시험일 / 발표일',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await _pickDate(sDate);
                                  if (picked != null) {
                                    setModalState(() => sDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatDate(sDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (sType == ExamStageType.application) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('접수 마감일', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await _pickDate(eDate ?? sDate.add(const Duration(days: 4)));
                                    if (picked != null) {
                                      setModalState(() => eDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(eDate != null ? _formatDate(eDate!) : '선택 안함', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 세부 정보 (입실시간, 고사장, 수험번호 등)
                    const Text('입실/시험 시간 & 고사장 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: timeCtrl,
                            decoration: InputDecoration(
                              hintText: '예: 09:20 입실',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: locCtrl,
                            decoration: InputDecoration(
                              hintText: '예: 서울공고 3고사장',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: seatCtrl,
                            decoration: InputDecoration(
                              hintText: '좌석번호 (예: 14번)',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: regCtrl,
                            decoration: InputDecoration(
                              hintText: '수험번호 (예: 20261025)',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 준비물 체크리스트
                    const Text('준비물 체크리스트', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: checklistCtrl,
                            decoration: InputDecoration(
                              hintText: '준비물 추가 (예: 신분증, 수험표, 컴싸)',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                setModalState(() {
                                  curChecklist.add(val.trim());
                                  checklistCtrl.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () {
                            final val = checklistCtrl.text.trim();
                            if (val.isNotEmpty) {
                              setModalState(() {
                                curChecklist.add(val);
                                checklistCtrl.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.add, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (curChecklist.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: curChecklist.map((c) {
                          return Chip(
                            label: Text(c, style: const TextStyle(fontSize: 11)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              setModalState(() => curChecklist.remove(c));
                            },
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _stages[index] = stage.copyWith(
                              stageType: sType,
                              name: nameCtrl.text.trim().isEmpty ? sType.labelKo : nameCtrl.text.trim(),
                              startDate: sDate,
                              endDate: eDate,
                              testTime: timeCtrl.text.trim().isEmpty ? null : timeCtrl.text.trim(),
                              location: locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim(),
                              seatNumber: seatCtrl.text.trim().isEmpty ? null : seatCtrl.text.trim(),
                              registrationNumber: regCtrl.text.trim().isEmpty ? null : regCtrl.text.trim(),
                              checklist: curChecklist,
                            );
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('단계 저장', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String sIdxLabel(ExamStageType t) => t.shortLabel;

  // --- Subject Management (for School Exams) ---
  void _addSubject() {
    final now = DateTime.now();
    final newSub = ExamSubjectItem(
      id: 'sub-${DateTime.now().microsecondsSinceEpoch}',
      subjectName: '새 과목',
      examDate: now.add(const Duration(days: 14)),
      period: _subjects.length + 1,
      startTime: '09:00',
      endTime: '10:00',
    );
    setState(() {
      _subjects.add(newSub);
    });
  }

  void _removeSubject(int index) {
    setState(() {
      _subjects.removeAt(index);
    });
  }

  void _editSubject(int index) {
    final sub = _subjects[index];
    final nameCtrl = TextEditingController(text: sub.subjectName);
    final periodCtrl = TextEditingController(text: sub.period.toString());
    final startCtrl = TextEditingController(text: sub.startTime ?? '09:00');
    final endCtrl = TextEditingController(text: sub.endTime ?? '10:00');
    final roomCtrl = TextEditingController(text: sub.classroom ?? '');
    final memoCtrl = TextEditingController(text: sub.memo ?? '');
    final checklistCtrl = TextEditingController();

    DateTime eDate = sub.examDate;
    List<String> curChecklist = List.from(sub.checklist);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('과목 타임테이블 편집', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 과목명
                    const Text('과목명', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: '예: 국어, 수학 I, 프로그래밍응용',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 시험일 & 교시
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('시험 날짜', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await _pickDate(eDate);
                                  if (picked != null) {
                                    setModalState(() => eDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatDate(eDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('교시', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: periodCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '1',
                                  suffixText: '교시',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 시작 & 종료 시간
                    const Text('시험 시간', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startCtrl,
                            decoration: InputDecoration(
                              hintText: '09:00',
                              prefixIcon: const Icon(Icons.access_time_rounded, size: 16),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('~'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: endCtrl,
                            decoration: InputDecoration(
                              hintText: '10:00',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 고사장 / 교실 & 시험범위 메모
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: roomCtrl,
                            decoration: InputDecoration(
                              hintText: '고사장/강의실 (예: 3반)',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: memoCtrl,
                      decoration: InputDecoration(
                        hintText: '시험 범위 및 메모 (예: 1~4단원, 유인물 포함)',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 준비물 체크리스트
                    const Text('준비물 체크리스트', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: checklistCtrl,
                            decoration: InputDecoration(
                              hintText: '준비물 추가 (예: 컴싸, 공학용 계산기)',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                setModalState(() {
                                  curChecklist.add(val.trim());
                                  checklistCtrl.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () {
                            final val = checklistCtrl.text.trim();
                            if (val.isNotEmpty) {
                              setModalState(() {
                                curChecklist.add(val);
                                checklistCtrl.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.add, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (curChecklist.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: curChecklist.map((c) {
                          return Chip(
                            label: Text(c, style: const TextStyle(fontSize: 11)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              setModalState(() => curChecklist.remove(c));
                            },
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final pNum = int.tryParse(periodCtrl.text.trim()) ?? 1;
                          setState(() {
                            _subjects[index] = sub.copyWith(
                              subjectName: nameCtrl.text.trim().isEmpty ? '과목' : nameCtrl.text.trim(),
                              examDate: eDate,
                              period: pNum,
                              startTime: startCtrl.text.trim().isEmpty ? null : startCtrl.text.trim(),
                              endTime: endCtrl.text.trim().isEmpty ? null : endCtrl.text.trim(),
                              classroom: roomCtrl.text.trim().isEmpty ? null : roomCtrl.text.trim(),
                              memo: memoCtrl.text.trim().isEmpty ? null : memoCtrl.text.trim(),
                              checklist: curChecklist,
                            );
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('과목 저장', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _saveExam() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시험명을 입력해주세요.')),
      );
      return;
    }

    final id = widget.existingExam?.id ?? 'exam-${DateTime.now().microsecondsSinceEpoch}';
    final targetScore = _targetScoreController.text.trim().isEmpty ? null : _targetScoreController.text.trim();
    final catName = _categoryNameController.text.trim().isEmpty ? '자격증' : _categoryNameController.text.trim();

    final profile = ExamProfile(
      id: id,
      title: title,
      type: _selectedType,
      categoryName: catName,
      colorHex: _selectedColorHex,
      stages: _stages,
      subjects: _subjects,
      targetScore: targetScore,
      showInMainCalendar: _showInMainCalendar,
      createdAt: widget.existingExam?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    final isSchoolExam = _selectedType == ExamType.midterm || _selectedType == ExamType.finalExam;
    final themeColor = colorFromHex(_selectedColorHex);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // 드래그 핸들 & 상단 바
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existingExam != null ? '시험 일정 수정' : '시험 / 자격증 추가',
                      style: AppTypography.heading2.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      children: [
                        if (widget.allowDelete && widget.onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                            onPressed: () {
                              widget.onDelete!();
                              Navigator.of(context).pop();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 메인 스크롤 콘텐츠
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  children: [
                    // 1. 공식 DB 불러오기 배너
                    InkWell(
                      onTap: _openOfficialDb,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF334155)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Text('📚', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '공식 시험일정 DB 불러오기',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '토익, 정보처리기사, 수능, 공무원 1초 풀 로드',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '불러오기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. 시험 대분류 유형 선택
                    const Text(
                      '시험 유형',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ExamType.values.map((type) {
                        final isSel = _selectedType == type;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedType = type;
                                  if (type == ExamType.midterm && _titleController.text.isEmpty) {
                                    _titleController.text = '2학기 중간고사';
                                    _categoryNameController.text = '학교시험';
                                  } else if (type == ExamType.finalExam && _titleController.text.isEmpty) {
                                    _titleController.text = '2학기 기말고사';
                                    _categoryNameController.text = '학교시험';
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF0F172A) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Text(type.emoji, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(height: 4),
                                    Text(
                                      type.labelKo,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                        color: isSel ? Colors.white : const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // 3. 기본 정보 (시험명 & 목표 점수/등급)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('시험명', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: isSchoolExam ? '예: 2학기 중간고사' : '예: 2026 정보처리기사 2회차',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('카테고리 구분', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _categoryNameController,
                                      decoration: InputDecoration(
                                        hintText: '예: 어학, 자격증',
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                    const Text('목표 점수 / 등급 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _targetScoreController,
                                      decoration: InputDecoration(
                                        hintText: '예: 850점, 1등급',
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 테마 컬러 팔레트
                          const Text('대표 색상', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          // 좁은 폰에서는 다음 줄로 넘김 (보통 폰에서는 원래처럼 한 줄 양끝 정렬)
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            runSpacing: 8,
                            children: _colorPalette.map((hex) {
                              final isSel = _selectedColorHex == hex;
                              final c = colorFromHex(hex);
                              return InkWell(
                                onTap: () => setState(() => _selectedColorHex = hex),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSel ? Colors.black : Colors.white,
                                      width: isSel ? 2.5 : 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: c.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: isSel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                                ),
                              );
                            }).toList(),
                          ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. 세부 일정 관리 (파이프라인 또는 과목 타임테이블)
                    if (isSchoolExam) ...[
                      // 학교 시험: 과목 타임테이블
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Text('📝', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 6),
                              Text(
                                '과목별 타임테이블',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _addSubject,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('과목 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_subjects.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text('등록된 과목이 없습니다. 과목을 추가해보세요.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        )
                      else
                        ..._subjects.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final sub = entry.value;
                          final timeStr = sub.startTime != null ? '${sub.startTime} ~ ${sub.endTime ?? ""}' : '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${sub.period}교시',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: themeColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sub.subjectName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_formatDate(sub.examDate)} $timeStr ${sub.classroom ?? ""}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                                  onPressed: () => _editSubject(idx),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                  onPressed: () => _removeSubject(idx),
                                ),
                              ],
                            ),
                          );
                        }),
                    ] else ...[
                      // 자격증/공인시험: 4~5단계 핵심 파이프라인
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Text('📍', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '단계별 연계 일정 (파이프라인)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addStage,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('단계 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_stages.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text('등록된 단계가 없습니다. 단계를 추가해보세요.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        )
                      else
                        ..._stages.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final stage = entry.value;

                          String dateStr = _formatDate(stage.startDate);
                          if (stage.endDate != null) {
                            dateStr += ' ~ ${_formatDate(stage.endDate!)}';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: stage.stageType.isExamDay ? themeColor : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${idx + 1}단계 ${stage.stageType.shortLabel}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: stage.stageType.isExamDay ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stage.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                                  onPressed: () => _editStage(idx),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                  onPressed: () => _removeStage(idx),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                    const SizedBox(height: 20),

                    // 5. 메인 캘린더 연동 토글
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF3B82F6)),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '메인 캘린더에 시험 일정 표시',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    '월간 캘린더 및 대시보드 디데이에 자동 연동',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: _showInMainCalendar,
                            activeTrackColor: const Color(0xFF3B82F6),
                            onChanged: (val) => setState(() => _showInMainCalendar = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 저장 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveExam,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          widget.existingExam != null ? '시험 수정 완료' : '시험 등록하기',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
