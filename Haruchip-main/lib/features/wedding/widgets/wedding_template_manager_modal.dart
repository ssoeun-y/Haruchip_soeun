import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../data/wedding_standard_items.dart';
import '../models/wedding_item.dart';
import '../providers/wedding_provider.dart';

/// 57개 마스터 템플릿 (+/-) 선택 및 나만의 새 항목 추가 바텀시트 모달
class WeddingTemplateManagerModal extends ConsumerStatefulWidget {
  const WeddingTemplateManagerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WeddingTemplateManagerModal(),
    );
  }

  @override
  ConsumerState<WeddingTemplateManagerModal> createState() =>
      _WeddingTemplateManagerModalState();
}

class _WeddingTemplateManagerModalState
    extends ConsumerState<WeddingTemplateManagerModal> {
  late final List<WeddingItem> _allTemplates;
  late final Set<String> _selectedIds;
  final List<WeddingItem> _newCustomItems = [];

  final TextEditingController _customTitleController = TextEditingController();
  WeddingStage? _selectedStageFilter;

  @override
  void initState() {
    super.initState();
    _allTemplates = createDefaultWeddingMasterItems();
    final currentItems = ref.read(weddingListProvider);
    _selectedIds = currentItems.map((i) => i.id).toSet();
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    super.dispose();
  }

  void _toggleTemplate(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _addCustomItem() {
    final title = _customTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요.')),
      );
      return;
    }

    final currentCount = _selectedIds.length + _newCustomItems.length;
    final customItem = WeddingItem(
      id: 'wedding-custom-${DateTime.now().microsecondsSinceEpoch}',
      orderIndex: currentCount + 1,
      title: title,
      standardOffsetDays: 30,
      stage: _selectedStageFilter ?? WeddingStage.finalCheckAndCeremony,
    );

    setState(() {
      _newCustomItems.add(customItem);
      _customTitleController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ "$title" 항목이 추가 목록에 담겼습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _applySelection() {
    ref.read(weddingListProvider.notifier).syncSelectedTemplates(
          _selectedIds,
          _newCustomItems,
        );

    Navigator.pop(context);

    final total = _selectedIds.length + _newCustomItems.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('총 $total개의 결혼 준비 일정이 메인 리스트에 반영되었습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = _selectedStageFilter == null
        ? _allTemplates
        : _allTemplates.where((i) => i.stage == _selectedStageFilter).toList();

    final totalSelected = _selectedIds.length + _newCustomItems.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // 상단 고정 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 드래그 바
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '결혼 준비 항목 매니저',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.protoHeading,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '57개 템플릿에서 원하는 일정만 담아보세요',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 나만의 새 항목 직접 추가 인풋 필드
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customTitleController,
                        decoration: InputDecoration(
                          hintText: '나만의 새 항목 직접 입력 (예: 청모 식당 예약)',
                          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
                          ),
                        ),
                        onSubmitted: (_) => _addCustomItem(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addCustomItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('직접 추가', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 단계별 필터 칩
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(null, '전체 (57)'),
                      for (final stage in WeddingStage.values)
                        _buildFilterChip(stage, '${stage.emoji} ${stage.labelKo}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 57개 마스터 템플릿 스크롤 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              itemCount: filteredTemplates.length + _newCustomItems.length,
              itemBuilder: (context, index) {
                // 신규 직접 추가된 항목 먼저 표시 (상단)
                if (index < _newCustomItems.length) {
                  final custom = _newCustomItems[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Color(0xFFE11D48)),
                          onPressed: () {
                            setState(() => _newCustomItems.removeAt(index));
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                custom.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF881337),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '✨ 사용자 직접 추가 항목',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFFE53E3E)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final template = filteredTemplates[index - _newCustomItems.length];
                final isSelected = _selectedIds.contains(template.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF5F5) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFED7D7) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // [+] / [-] 토글 버튼
                      InkWell(
                        onTap: () => _toggleTemplate(template.id),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE53E3E) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFE53E3E) : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            isSelected ? Icons.remove_rounded : Icons.add_rounded,
                            size: 20,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 항목 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '#${template.orderIndex.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? const Color(0xFFE53E3E) : const Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    template.title,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  '${template.stage.emoji} ${template.stage.labelKo}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                const Text(' · ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                Text(
                                  template.standardOffsetDays == 0 ? '본식 당일' : 'T-${template.standardOffsetDays}일 추천',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 상태 태그
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFF1F2) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          isSelected ? '선택됨' : '미선택',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFFE53E3E) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 하단 고정 액션 바
          Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('선택된 항목', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                    Text(
                      '$totalSelected개 선택됨',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applySelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53E3E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      '선택한 $totalSelected개 일정 추가/반영하기',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(WeddingStage? stage, String label) {
    final isSelected = _selectedStageFilter == stage;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFFE53E3E),
        backgroundColor: const Color(0xFFF1F5F9),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? const Color(0xFFE53E3E) : Colors.transparent,
          ),
        ),
        onSelected: (val) {
          setState(() {
            _selectedStageFilter = val ? stage : null;
          });
        },
      ),
    );
  }
}
