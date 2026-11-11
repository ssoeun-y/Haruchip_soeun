import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../models/wedding_item.dart';
import '../providers/wedding_provider.dart';
import 'wedding_budget_section_widget.dart';
import 'wedding_item_edit_modal.dart';
import 'wedding_template_manager_modal.dart';

/// 결혼 준비 전용 카테고리 뷰 위젯
/// - 상단 배너/거대 프로필 제거
/// - [+ 항목/일정 추가] -> 57개 템플릿 +/- 매니저 모달
/// - 가독성 극대화 준비 항목 카드 (#순번, 일시, 장소, 체크박스, 연필 편집)
/// - 하단 독립 예산 & 지출 정리표 섹션
class WeddingCategoryView extends ConsumerStatefulWidget {
  const WeddingCategoryView({super.key});

  @override
  ConsumerState<WeddingCategoryView> createState() => _WeddingCategoryViewState();
}

class _WeddingCategoryViewState extends ConsumerState<WeddingCategoryView> {
  WeddingStage? _selectedStageFilter;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(weddingListProvider);

    final filteredItems = _selectedStageFilter == null
        ? items
        : items.where((i) => i.stage == _selectedStageFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 체크리스트 섹션 상단 헤더 & [+ 항목/일정 추가] 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Text('📋', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '준비 항목 체크리스트 (${items.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.protoHeading,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => WeddingTemplateManagerModal.show(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                '항목/일정 추가',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. 단계 필터 탭
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildStageChip(null, '전체 (${items.length})'),
              for (final stage in WeddingStage.values)
                _buildStageChip(
                  stage,
                  '${stage.emoji} ${stage.labelKo} (${items.where((i) => i.stage == stage).length})',
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. 준비 항목 카드 리스트 (가독성 극대화: 내용, 일시, 장소 한눈에 보기)
        if (filteredItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Text('💍', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 10),
                const Text(
                  '선택된 결혼 준비 일정이 없습니다.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '상단의 [+ 항목/일정 추가] 버튼을 눌러\n57개 표준 템플릿에서 원하는 일정을 담아보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8), height: 1.4),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => WeddingTemplateManagerModal.show(context),
                  icon: const Icon(Icons.playlist_add_rounded, size: 18),
                  label: const Text('57개 템플릿에서 일정 담기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53E3E),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          )
        else
          for (final item in filteredItems) ...[
            _buildRefinedItemCard(item),
          ],

        const SizedBox(height: 28),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 24),

        // 4. 하단 독립된 [결혼 예산 & 지출 정리표] 섹션
        const WeddingBudgetSectionWidget(),
        const SizedBox(height: 20),
      ],
    );
  }

  /// 준비 항목 카드 UI (가독성 극대화)
  Widget _buildRefinedItemCard(WeddingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isCompleted ? const Color(0xFFE2E8F0) : const Color(0xFFFED7D7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // [좌측]: 완료 체크박스
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: InkWell(
              onTap: () => ref.read(weddingListProvider.notifier).toggleItemCompletion(item.id),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: item.isCompleted ? const Color(0xFFE53E3E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: item.isCompleted ? const Color(0xFFE53E3E) : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: item.isCompleted
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // [중앙]: 상단 (#순번 태그 + 항목명) / 하단 (📅 일시 + 📍 장소)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [중앙 상단]: #순번 태그 + 항목명
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Text(
                        '#${item.orderIndex.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE53E3E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: item.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // [중앙 하단]: 일시 및 장소 (한눈에 확인)
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    // 📅 일시
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📅 ', style: TextStyle(fontSize: 12.5)),
                        Text(
                          item.targetDate != null
                              ? '${item.formattedDateTime} (${item.dDayLabel()})'
                              : '일정 미지정',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: item.targetDate != null
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    // 📍 장소
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📍 ', style: TextStyle(fontSize: 12.5)),
                        Text(
                          item.location.isNotEmpty ? item.location : '장소 미지정',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: item.location.isNotEmpty
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // [우측]: 편집(연필) 아이콘 (탭 시 날짜/시간/장소/메모 수정)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
            tooltip: '일정 및 장소 수정',
            padding: const EdgeInsets.only(left: 4),
            constraints: const BoxConstraints(),
            onPressed: () => WeddingItemEditModal.show(context, item),
          ),
        ],
      ),
    );
  }

  Widget _buildStageChip(WeddingStage? stage, String label) {
    final isSelected = _selectedStageFilter == stage;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFFE53E3E),
        backgroundColor: Colors.white,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? const Color(0xFFE53E3E) : const Color(0xFFE2E8F0),
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
