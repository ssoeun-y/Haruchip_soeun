import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../trash/logic/trash_service.dart';
import '../../trash/models/trash_item.dart';
import '../../trash/providers/trash_provider.dart';

/// 30일 복구 보존 전역 휴지통 관리 화면
class TrashBinScreen extends ConsumerStatefulWidget {
  const TrashBinScreen({super.key});

  @override
  ConsumerState<TrashBinScreen> createState() => _TrashBinScreenState();
}

class _TrashBinScreenState extends ConsumerState<TrashBinScreen> {
  TrashEntityType? _selectedFilter;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmEmptyTrash() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('휴지통 비우기', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          '휴지통의 모든 항목을 영구 삭제하시겠습니까?\n영구 삭제된 항목은 다시 복구할 수 없습니다.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(trashBinProvider.notifier).emptyTrash();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🗑️ 휴지통을 완전히 비웠습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('영구 비우기'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(TrashItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('항목 영구 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '[${item.originalTitle}] 항목을 영구 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(trashBinProvider.notifier).permanentlyDelete(item.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🗑️ [${item.originalTitle}] 항목이 영구 삭제되었습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('영구 삭제'),
          ),
        ],
      ),
    );
  }

  void _restoreItem(TrashItem item) {
    // 원래 위치로 되돌리기에 성공했을 때만 휴지통에서 빠진다. 실패하면
    // (원래 카테고리/방이 없어졌거나 복구 미지원 유형) 휴지통에 그대로 둔다.
    final ok = ref.read(trashServiceProvider).restore(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '🎉 [${item.originalTitle}] 항목이 원래 위치로 복구되었습니다!'
            : '⚠️ [${item.originalTitle}] 원래 위치(카테고리/모임방)를 찾을 수 없어 복구하지 못했어요. 휴지통에 그대로 보관됩니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final allTrash = ref.watch(trashBinProvider);

    final filteredTrash = allTrash.where((item) {
      if (_selectedFilter != null && item.entityType != _selectedFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = item.originalTitle.toLowerCase().contains(query);
        final matchCat = item.categoryKey?.toLowerCase().contains(query) ?? false;
        return matchTitle || matchCat;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.protoHeading),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '🗑️ 휴지통 (30일 복구 보존)',
          style: AppTypography.cardLabel.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.protoHeading,
          ),
        ),
        actions: [
          if (allTrash.isNotEmpty)
            TextButton.icon(
              onPressed: _confirmEmptyTrash,
              icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Color(0xFFDC2626)),
              label: const Text(
                '휴지통 비우기',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 30일 보존 안내 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFEFF6FF),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '삭제된 항목은 30일 동안 안전하게 보존되며, 언제든 원래 위치로 즉시 복구할 수 있습니다.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          // 검색창
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: '삭제된 항목 검색 (제목, 카테고리)...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                isDense: true,
              ),
            ),
          ),

          // 필터 칩 리스트
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: Text('전체 (${allTrash.length})'),
                  selected: _selectedFilter == null,
                  onSelected: (sel) => setState(() => _selectedFilter = null),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF0F172A),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _selectedFilter == null ? Colors.white : const Color(0xFF475569),
                  ),
                  side: BorderSide(color: _selectedFilter == null ? Colors.transparent : const Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(width: 6),
                ...TrashEntityType.values.map((type) {
                  final count = allTrash.where((t) => t.entityType == type).length;
                  final isSelected = _selectedFilter == type;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text('${type.emoji} ${type.labelKo} ($count)'),
                      selected: isSelected,
                      onSelected: (sel) => setState(() => _selectedFilter = sel ? type : null),
                      backgroundColor: Colors.white,
                      selectedColor: type.color.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? type.color : const Color(0xFF475569),
                      ),
                      side: BorderSide(color: isSelected ? type.color : const Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 휴지통 목록
          Expanded(
            child: filteredTrash.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty ? '검색 결과가 없습니다.' : '휴지통이 깨끗하게 비어있습니다.',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '삭제된 항목이 여기에 30일간 보존됩니다.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                    itemCount: filteredTrash.length,
                    itemBuilder: (context, index) {
                      final item = filteredTrash[index];
                      final isUrgent = item.daysRemaining <= 7;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isUrgent ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Entity Badge & Remaining Days Countdown
                            // (Wrap은 내용 폭만큼만 차지 — 남은 기간 배지가 오른쪽 끝에 붙도록 가로를 채움)
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: item.entityType.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(item.entityType.emoji, style: const TextStyle(fontSize: 11)),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.entityType.labelKo,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: item.entityType.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isUrgent ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.daysRemainingLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ),
                            const SizedBox(height: 10),

                            // Original Title
                            Text(
                              item.originalTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Deletion Info
                            Text(
                              '삭제 일시: ${_formatDate(item.deletedAt)} · 30일 후 자동 영구 정리',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 14),

                            // Action Buttons: Restore vs Permanent Delete
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _restoreItem(item),
                                    icon: const Icon(Icons.restore_rounded, size: 15),
                                    label: const Text('복구하기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F172A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _confirmPermanentDelete(item),
                                  icon: const Icon(Icons.delete_forever_rounded, size: 15, color: Color(0xFFDC2626)),
                                  label: const Text(
                                    '영구 삭제',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    side: const BorderSide(color: Color(0xFFFECACA)),
                                  ),
                                ),
                              ],
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
  }
}
