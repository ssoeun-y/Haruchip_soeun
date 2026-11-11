import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../trash/logic/trash_service.dart';
import '../../trash/models/trash_item.dart';
import '../../trash/providers/trash_provider.dart';

/// 30일 보관 및 자동 영구 삭제 전역 휴지통 관리 화면
class TrashBinScreen extends ConsumerStatefulWidget {
  const TrashBinScreen({super.key});

  @override
  ConsumerState<TrashBinScreen> createState() => _TrashBinScreenState();
}

class _TrashBinScreenState extends ConsumerState<TrashBinScreen> {
  TrashEntityType? _selectedFilter;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // 다중 선택 상태 (체크박스 선택된 TrashItem.id 집합)
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 전체 휴지통 비우기
  void _confirmEmptyTrash() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('휴지통 비우기', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          '영구 삭제 시 복원이 불가능합니다. 계속하시겠습니까?\n휴지통의 모든 항목이 즉시 영구 삭제됩니다.',
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
              setState(() {
                _selectedIds.clear();
                _isSelectionMode = false;
              });
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

  /// 단일 항목 완전 삭제 (필수 확인 다이얼로그)
  void _confirmPermanentDelete(TrashItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('항목 영구 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '영구 삭제 시 복원이 불가능합니다. 계속하시겠습니까?\n[${item.originalTitle}] 항목을 영구 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다.',
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
              setState(() {
                _selectedIds.remove(item.id);
              });
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

  /// 다중 선택 항목 완전 삭제
  void _confirmPermanentDeleteSelected() {
    if (_selectedIds.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('선택 항목 완전 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '영구 삭제 시 복원이 불가능합니다. 계속하시겠습니까?\n선택한 ${_selectedIds.length}개 항목이 영구 삭제됩니다.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final count = _selectedIds.length;
              ref.read(trashBinProvider.notifier).permanentlyDeleteMultiple(_selectedIds);
              setState(() {
                _selectedIds.clear();
                _isSelectionMode = false;
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🗑️ 선택한 $count개 항목이 영구 삭제되었습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('완전 삭제'),
          ),
        ],
      ),
    );
  }

  /// 단일 항목 복원
  void _restoreItem(TrashItem item) {
    // 원래 위치로 되돌리기에 성공했을 때만 휴지통에서 빠진다. 실패하면
    // (원래 카테고리/방이 없어졌거나 복구 미지원 유형) 휴지통에 그대로 둔다.
    final ok = ref.read(trashServiceProvider).restore(item);
    setState(() {
      _selectedIds.remove(item.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '🎉 [${item.originalTitle}] 항목이 원래 위치로 복구되었습니다!'
            : '⚠️ [${item.originalTitle}] 원래 위치(카테고리/모임방)를 찾을 수 없어 복구하지 못했어요. 휴지통에 그대로 보관됩니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 다중 선택 항목 일괄 복원
  void _restoreSelected() {
    if (_selectedIds.isEmpty) return;

    final allTrash = ref.read(trashBinProvider);
    final toRestore = allTrash.where((item) => _selectedIds.contains(item.id)).toList();

    // 되돌린 항목만 휴지통에서 빠진다 — 실패한 항목은 그대로 남아 데이터가 사라지지 않는다.
    final service = ref.read(trashServiceProvider);
    var count = 0;
    for (final item in toRestore) {
      if (service.restore(item)) count++;
    }
    final failed = toRestore.length - count;

    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failed == 0
            ? '🎉 선택한 $count개 항목이 원래 위치로 복구되었습니다!'
            : '$count개 항목을 복구했어요. $failed개는 원래 위치를 찾을 수 없어 휴지통에 보관됩니다.'),
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
          _isSelectionMode ? '${_selectedIds.length}개 선택됨' : '🗑️ 휴지통',
          style: AppTypography.cardLabel.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.protoHeading,
          ),
        ),
        actions: [
          if (allTrash.isNotEmpty) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = !_isSelectionMode;
                  if (!_isSelectionMode) {
                    _selectedIds.clear();
                  }
                });
              },
              child: Text(
                _isSelectionMode ? '선택 취소' : '선택 관리',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            IconButton(
              tooltip: '휴지통 비우기',
              onPressed: _confirmEmptyTrash,
              icon: const Icon(Icons.delete_sweep_rounded, size: 20, color: Color(0xFFDC2626)),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // 30일 보관 및 자동 영구 삭제 안내 배너 (명세 일치 문구)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              border: Border(bottom: BorderSide(color: Color(0xFFDBEAFE))),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '삭제된 항목은 30일 동안 보관되며, 30일이 지나면 영구 삭제됩니다. (30일 동안 안전하게 보존)',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
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

          // 다중 선택 시 전체 선택/해제 토글 바
          if (_isSelectionMode && filteredTrash.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectedIds.length == filteredTrash.length && filteredTrash.isNotEmpty,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.addAll(filteredTrash.map((e) => e.id));
                        } else {
                          _selectedIds.clear();
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  const Text(
                    '전체 선택',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const Spacer(),
                  Text(
                    '${_selectedIds.length} / ${filteredTrash.length}개 선택',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 6),

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
                          _searchQuery.isNotEmpty ? '검색 결과가 없습니다.' : '휴지통이 비어있습니다.',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '삭제된 항목은 30일 동안 보관 후 영구 삭제됩니다.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filteredTrash.length,
                    itemBuilder: (context, index) {
                      final item = filteredTrash[index];
                      final isUrgent = item.daysRemaining <= 7;
                      final isSelected = _selectedIds.contains(item.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : (isUrgent ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                            width: isSelected ? 1.8 : 1.0,
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
                            // 상단: 체크박스(선택모드 시) + 엔티티 뱃지 + [남은 보관 일수 (ex. 28일 남음)]
                            Row(
                              children: [
                                if (_isSelectionMode) ...[
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedIds.add(item.id);
                                        } else {
                                          _selectedIds.remove(item.id);
                                        }
                                      });
                                    },
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Container(
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
                                      Flexible(
                                        child: Text(
                                          item.entityType.labelKo,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: item.entityType.color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ),
                                const SizedBox(width: 8),
                                const Spacer(),
                                // [남은 보관 일수 (ex. 28일 남음)] 라벨
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isUrgent ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isUrgent ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 12,
                                        color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.daysRemaining}일 남음',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 삭제된 항목/이벤트명
                            Text(
                              item.originalTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // 삭제 일시 및 30일 보관 안내
                            Text(
                              '삭제 일시: ${_formatDate(item.deletedAt)} · 30일 보관 후 영구 삭제',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),

                            // 단일 아이템 조작 액션 (선택 모드가 아닐 때 노출)
                            if (!_isSelectionMode) ...[
                              const SizedBox(height: 14),
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
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 다중 선택 모드 플로팅 하단 바 ([복원하기] / [완전 삭제])
      bottomNavigationBar: _isSelectionMode && _selectedIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _restoreSelected,
                        icon: const Icon(Icons.restore_rounded, size: 16),
                        label: Text(
                          '${_selectedIds.length}개 복원하기',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _confirmPermanentDeleteSelected,
                        icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Color(0xFFDC2626)),
                        label: Text(
                          '${_selectedIds.length}개 완전 삭제',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
