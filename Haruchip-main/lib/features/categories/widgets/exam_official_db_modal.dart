import 'package:flutter/material.dart';
import '../../../design_system/typography.dart';
import '../data/official_exam_database.dart';
import '../models/category.dart';
import '../models/exam_model.dart';

/// 공식 시험일정 데이터베이스 검색 및 1초 원클릭 로드 모달
Future<ExamProfile?> showExamOfficialDbModal(BuildContext context) {
  return showModalBottomSheet<ExamProfile>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ExamOfficialDbModalContent(),
  );
}

class _ExamOfficialDbModalContent extends StatefulWidget {
  const _ExamOfficialDbModalContent();

  @override
  State<_ExamOfficialDbModalContent> createState() => _ExamOfficialDbModalContentState();
}

class _ExamOfficialDbModalContentState extends State<_ExamOfficialDbModalContent> {
  final _searchController = TextEditingController();
  String _selectedTab = '전체';
  String _searchQuery = '';

  // 각 프리셋별 선택된 회차 인덱스 맵 (presetId -> roundIndex)
  final Map<String, int> _selectedRoundMap = {};

  final List<String> _tabs = [
    '전체',
    '어학/상시',
    '국가기술자격',
    '공무원/공기업',
    '입시/수능',
    '학교시험',
  ];

  @override
  void initState() {
    super.initState();
    // 기본 회차 index 0 설정
    for (final preset in kOfficialExamPresets) {
      _selectedRoundMap[preset.id] = 0;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OfficialExamPreset> get _filteredPresets {
    return kOfficialExamPresets.where((preset) {
      final matchesTab = _selectedTab == '전체' || preset.groupCategory == _selectedTab;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          preset.title.toLowerCase().contains(query) ||
          preset.description.toLowerCase().contains(query) ||
          preset.groupCategory.toLowerCase().contains(query);
      return matchesTab && matchesSearch;
    }).toList();
  }

  void _selectAndReturnPreset(OfficialExamPreset preset) {
    final roundIndex = _selectedRoundMap[preset.id] ?? 0;
    final selectedRound = preset.rounds[roundIndex];

    final id = 'exam-${DateTime.now().microsecondsSinceEpoch}';
    final examTitle = '${preset.title} (${selectedRound.roundName})';

    // ExamProfile 생성
    if (preset.type == ExamType.midterm || preset.type == ExamType.finalExam) {
      // 학교 시험 모드인 경우 템플릿 과목 생성
      final baseDate = selectedRound.stages.isNotEmpty
          ? selectedRound.stages.first.startDate
          : DateTime.now().add(const Duration(days: 14));

      final templateSubjects = [
        ExamSubjectItem(
          id: '$id-sub1',
          subjectName: '국어',
          examDate: baseDate,
          period: 1,
          startTime: '09:00',
          endTime: '10:00',
          classroom: '지정 고사장',
          checklist: ['컴퓨터용 사인펜', '수정테이프', '필기도구'],
        ),
        ExamSubjectItem(
          id: '$id-sub2',
          subjectName: '수학',
          examDate: baseDate,
          period: 2,
          startTime: '10:30',
          endTime: '11:40',
          classroom: '지정 고사장',
          checklist: ['컴퓨터용 사인펜', '수정테이프', '자/계산기'],
        ),
        ExamSubjectItem(
          id: '$id-sub3',
          subjectName: '영어',
          examDate: baseDate.add(const Duration(days: 1)),
          period: 1,
          startTime: '09:00',
          endTime: '10:00',
          classroom: '지정 고사장',
          checklist: ['컴퓨터용 사인펜', '수정테이프'],
        ),
      ];

      final profile = ExamProfile(
        id: id,
        title: examTitle,
        type: preset.type,
        categoryName: preset.groupCategory,
        colorHex: preset.colorHex,
        stages: selectedRound.stages,
        subjects: templateSubjects,
        showInMainCalendar: true,
        createdAt: DateTime.now(),
      );
      Navigator.of(context).pop(profile);
    } else {
      // 자격증/공인시험 파이프라인
      final profile = ExamProfile(
        id: id,
        title: examTitle,
        type: preset.type,
        categoryName: preset.groupCategory,
        colorHex: preset.colorHex,
        stages: selectedRound.stages,
        showInMainCalendar: true,
        createdAt: DateTime.now(),
      );
      Navigator.of(context).pop(profile);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPresets;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
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
              // 드래그 핸들 & 헤더
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
                    Expanded(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('📚', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '공식 시험일정 불러오기',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.heading2.copyWith(
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '매년 회차별 공식 일정을 원클릭으로 일괄 등록합니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // 검색 바
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: '시험명 또는 자격증 검색 (토익, 정보처리기사, 수능...)',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                    ),
                  ),
                ),
              ),

              // 카테고리 탭 리스트
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: _tabs.map((tab) {
                    final isSelected = _selectedTab == tab;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(tab),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedTab = tab);
                        },
                        selectedColor: const Color(0xFF0F172A),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),

              // 시험 프리셋 목록
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔍', style: TextStyle(fontSize: 36)),
                            const SizedBox(height: 10),
                            const Text(
                              '검색된 공식 시험 일정이 없습니다.',
                              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '직접 시험 일정을 등록할 수 있습니다.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final preset = filtered[index];
                          final selectedRoundIdx = _selectedRoundMap[preset.id] ?? 0;
                          final activeRound = preset.rounds[selectedRoundIdx.clamp(0, preset.rounds.length - 1)];
                          final themeColor = colorFromHex(preset.colorHex);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 상단 배지 & 시험명
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: themeColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(preset.type.emoji, style: const TextStyle(fontSize: 20)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  preset.groupCategory,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${activeRound.stages.length}단계 플로우',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: themeColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            preset.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            preset.description,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // 회차(Round) 선택 칩 리스트 (회차가 여러 개인 경우)
                                if (preset.rounds.length > 1) ...[
                                  const Text(
                                    '📅 회차 선택',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: preset.rounds.asMap().entries.map((entry) {
                                        final rIdx = entry.key;
                                        final rItem = entry.value;
                                        final isRoundSelected = rIdx == selectedRoundIdx;

                                        return Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _selectedRoundMap[preset.id] = rIdx;
                                              });
                                            },
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isRoundSelected
                                                    ? themeColor.withValues(alpha: 0.15)
                                                    : const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isRoundSelected ? themeColor : const Color(0xFFE2E8F0),
                                                  width: isRoundSelected ? 1.5 : 1,
                                                ),
                                              ),
                                              child: Text(
                                                rItem.roundName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isRoundSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isRoundSelected ? themeColor : const Color(0xFF475569),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // 단계별 일정 프리뷰 타임라인
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFF1F5F9)),
                                  ),
                                  child: Column(
                                    children: activeRound.stages.asMap().entries.map((stageEntry) {
                                      final sIdx = stageEntry.key;
                                      final stage = stageEntry.value;
                                      final isLast = sIdx == activeRound.stages.length - 1;

                                      String dateStr = _formatDate(stage.startDate);
                                      if (stage.endDate != null) {
                                        dateStr += ' ~ ${_formatDate(stage.endDate!)}';
                                      }

                                      return Padding(
                                        padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: stage.stageType.isExamDay
                                                    ? themeColor
                                                    : const Color(0xFFE2E8F0),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                stage.stageType.shortLabel,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: stage.stageType.isExamDay ? Colors.white : const Color(0xFF475569),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                stage.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: stage.stageType.isExamDay ? FontWeight.bold : FontWeight.w500,
                                                  color: const Color(0xFF1E293B),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // 날짜는 자르지 않고, 좁으면 두 줄로
                                            Flexible(
                                              child: Text(
                                              dateStr,
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: stage.stageType.isExamDay ? themeColor : const Color(0xFF64748B),
                                              ),
                                            ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // 원클릭 등록 버튼
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _selectAndReturnPreset(preset),
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
                                    label: Text(
                                      '${preset.title} (${activeRound.roundName}) 등록',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
