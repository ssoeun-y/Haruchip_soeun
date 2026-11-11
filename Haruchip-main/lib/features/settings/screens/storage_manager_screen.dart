import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../trash/models/trash_item.dart';
import '../../trash/providers/trash_provider.dart';

/// 카테고리별 저장공간 사용량 항목 모델
class CategoryStorageItem {
  const CategoryStorageItem({
    required this.categoryKey,
    required this.name,
    required this.icon,
    required this.color,
    required this.baseSizeMb,
    required this.itemCount,
    required this.photoCount,
  });

  final String categoryKey;
  final String name;
  final String icon;
  final Color color;
  final double baseSizeMb;
  final int itemCount;
  final int photoCount;

  CategoryStorageItem copyWith({
    String? categoryKey,
    String? name,
    String? icon,
    Color? color,
    double? baseSizeMb,
    int? itemCount,
    int? photoCount,
  }) {
    return CategoryStorageItem(
      categoryKey: categoryKey ?? this.categoryKey,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      baseSizeMb: baseSizeMb ?? this.baseSizeMb,
      itemCount: itemCount ?? this.itemCount,
      photoCount: photoCount ?? this.photoCount,
    );
  }
}

/// 지난 일정/기록 아카이브 항목 모델 (정리 모달용)
class ArchiveRecordItem {
  ArchiveRecordItem({
    required this.id,
    required this.title,
    required this.date,
    required this.sizeKb,
    this.hasPhoto = false,
  });

  final String id;
  final String title;
  final DateTime date;
  final int sizeKb;
  final bool hasPhoto;
}

/// 카카오톡 스타일 저장공간 관리 화면
///
/// 1. 상단 게이지 바: "기록 데이터 18.4 MB / 여유 공간 충분"
/// 2. 용량 초과 경고: "저장공간이 부족해요. 지난 기록을 정리해주세요" 배너
/// 3. 카테고리별 저장공간 목록: [아기 기록: 4.2 MB], [결혼 기록: 6.1 MB], [모임 기록: 2.5 MB] 등
/// 4. 카테고리 정리 상세 뷰: 체크박스 '선택 삭제' 및 '지난 기록 일괄 삭제'
class StorageManagerScreen extends ConsumerStatefulWidget {
  const StorageManagerScreen({super.key});

  @override
  ConsumerState<StorageManagerScreen> createState() => _StorageManagerScreenState();
}

class _StorageManagerScreenState extends ConsumerState<StorageManagerScreen> {
  // 모의 캐시 데이터 크기 (MB)
  double _cacheSizeMb = 1.6;

  // 카테고리별 기본 데이터 목록 (동적 증감)
  late List<CategoryStorageItem> _categoryStorageList;

  // 임의 초과 시뮬레이션 플래그
  bool _isNearCapacity = false;

  @override
  void initState() {
    super.initState();
    _initStorageData();
  }

  void _initStorageData() {
    _categoryStorageList = [
      const CategoryStorageItem(
        categoryKey: 'wedding',
        name: '결혼 기록',
        icon: '💍',
        color: Color(0xFFE53E3E),
        baseSizeMb: 6.1,
        itemCount: 42,
        photoCount: 16,
      ),
      const CategoryStorageItem(
        categoryKey: 'baby',
        name: '아기 기록',
        icon: '🍼',
        color: Color(0xFFF59E0B),
        baseSizeMb: 4.2,
        itemCount: 38,
        photoCount: 12,
      ),
      const CategoryStorageItem(
        categoryKey: 'travel',
        name: '여행 기록',
        icon: '✈️',
        color: Color(0xFF0284C7),
        baseSizeMb: 3.8,
        itemCount: 26,
        photoCount: 19,
      ),
      const CategoryStorageItem(
        categoryKey: 'couple',
        name: '커플 기록',
        icon: '💑',
        color: Color(0xFFEC4899),
        baseSizeMb: 3.2,
        itemCount: 31,
        photoCount: 14,
      ),
      const CategoryStorageItem(
        categoryKey: 'group',
        name: '모임 기록',
        icon: '👥',
        color: Color(0xFFE26D5C),
        baseSizeMb: 2.5,
        itemCount: 19,
        photoCount: 8,
      ),
      const CategoryStorageItem(
        categoryKey: 'hobby',
        name: '취미 기록',
        icon: '🎨',
        color: Color(0xFF10B981),
        baseSizeMb: 1.8,
        itemCount: 15,
        photoCount: 5,
      ),
      const CategoryStorageItem(
        categoryKey: 'other',
        name: '기타 및 시험/군대',
        icon: '📦',
        color: Color(0xFF64748B),
        baseSizeMb: 1.4,
        itemCount: 12,
        photoCount: 2,
      ),
    ];
  }

  /// 전체 사용량 (MB)
  double get _totalUsedMb {
    final catTotal = _categoryStorageList.fold<double>(0.0, (acc, item) => acc + item.baseSizeMb);
    return double.parse((catTotal + _cacheSizeMb).toStringAsFixed(1));
  }

  /// 캐시 비우기
  void _clearCache() {
    setState(() {
      _cacheSizeMb = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧹 임시 캐시 데이터가 완전히 삭제되었습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 특정 카테고리 상세 정리 모달 오픈
  void _openCategoryCleanupModal(CategoryStorageItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryCleanupSheet(
        item: item,
        onCleanedUp: (removedMb, removedCount) {
          setState(() {
            final idx = _categoryStorageList.indexWhere((c) => c.categoryKey == item.categoryKey);
            if (idx != -1) {
              final old = _categoryStorageList[idx];
              final newSize = (old.baseSizeMb - removedMb).clamp(0.1, 999.0);
              final newCount = (old.itemCount - removedCount).clamp(0, 999);
              _categoryStorageList[idx] = old.copyWith(
                baseSizeMb: double.parse(newSize.toStringAsFixed(1)),
                itemCount: newCount,
              );
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalUsed = _totalUsedMb;
    // 50MB 기준 80% 이상이거나 테스트 플래그 시 경고
    final isWarning = _isNearCapacity || totalUsed >= 40.0;
    final progress = (totalUsed / 50.0).clamp(0.0, 1.0);

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
          '저장공간 관리',
          style: AppTypography.cardLabel.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.protoHeading,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '용량 부족 시뮬레이션',
            icon: Icon(
              _isNearCapacity ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
              color: _isNearCapacity ? const Color(0xFFDC2626) : const Color(0xFF64748B),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isNearCapacity = !_isNearCapacity;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 상단 게이지 바 카드
            _buildTopGaugeCard(totalUsed, progress, isWarning),
            const SizedBox(height: 14),

            // 2. 용량 초과 경고 배너
            if (isWarning) ...[
              _buildCapacityWarningBanner(),
              const SizedBox(height: 14),
            ],

            // 3. 임시 캐시 정리 바
            _buildCacheCleanCard(),
            const SizedBox(height: 20),

            // 4. 카테고리별 저장공간 사용 목록
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '카테고리별 저장공간',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '총 ${_categoryStorageList.length}개 카테고리',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categoryStorageList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final item = _categoryStorageList[index];
                return _buildCategoryStorageTile(item);
              },
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  /// 1. 상단 게이지 바 카드 (기록 데이터 18.4 MB / 여유 공간 충분)
  Widget _buildTopGaugeCard(double totalUsed, double progress, bool isWarning) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWarning ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '기록 데이터 ${totalUsed.toStringAsFixed(1)} MB',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isWarning ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isWarning ? const Color(0xFFFCA5A5) : const Color(0xFFBBF7D0),
                  ),
                ),
                child: Text(
                  isWarning ? '정리 권장' : '여유 공간 충분',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isWarning ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '텍스트, 사진, D-Day 히스토리 및 캐시가 안전하게 저장되어 있습니다.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
          ),
          const SizedBox(height: 18),

          // 세그먼트 게이지 바
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isWarning ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '사용 중: ${totalUsed.toStringAsFixed(1)} MB',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const Text(
                '권장 한도: 50.0 MB',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. 저장공간 부족 배너 (명세 일치 문구)
  Widget _buildCapacityWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '저장공간이 부족해요. 지난 기록을 정리해주세요',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF991B1B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '지난 모임/여행/기념일 기록을 정리하면 쾌적하게 사용할 수 있습니다.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // 가장 용량이 큰 카테고리 정리 유도
              if (_categoryStorageList.isNotEmpty) {
                _openCategoryCleanupModal(_categoryStorageList.first);
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('정리하기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// 3. 임시 캐시 정리 카드
  Widget _buildCacheCleanCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cached_rounded, size: 20, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '임시 캐시 파일',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_cacheSizeMb.toStringAsFixed(1)} MB',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  '삭제해도 개인 일정 및 D-Day 데이터는 안전하게 보존됩니다.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          if (_cacheSizeMb > 0)
            OutlinedButton(
              onPressed: _clearCache,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('비우기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            ),
        ],
      ),
    );
  }

  /// 4. 카테고리별 저장공간 타일 (예: [아기 기록: 4.2 MB], [결혼 기록: 6.1 MB], [모임 기록: 2.5 MB])
  Widget _buildCategoryStorageTile(CategoryStorageItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openCategoryCleanupModal(item),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(item.icon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.baseSizeMb} MB',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '기록 ${item.itemCount}건 · 첨부 사진 ${item.photoCount}장',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 카테고리 정리 상세 모달 (체크박스 '선택 삭제' 및 '지난 기록 일괄 삭제')
class _CategoryCleanupSheet extends ConsumerStatefulWidget {
  const _CategoryCleanupSheet({
    required this.item,
    required this.onCleanedUp,
  });

  final CategoryStorageItem item;
  final void Function(double removedMb, int removedCount) onCleanedUp;

  @override
  ConsumerState<_CategoryCleanupSheet> createState() => _CategoryCleanupSheetState();
}

class _CategoryCleanupSheetState extends ConsumerState<_CategoryCleanupSheet> {
  late List<ArchiveRecordItem> _records;
  final Set<String> _selectedRecordIds = {};

  @override
  void initState() {
    super.initState();
    _initRecords();
  }

  void _initRecords() {
    final now = DateTime.now();
    _records = [
      ArchiveRecordItem(
        id: 'rec-1',
        title: '${widget.item.name} 지난 이벤트 #1',
        date: now.subtract(const Duration(days: 45)),
        sizeKb: 620,
        hasPhoto: true,
      ),
      ArchiveRecordItem(
        id: 'rec-2',
        title: '${widget.item.name} 히스토리 기록 #2',
        date: now.subtract(const Duration(days: 90)),
        sizeKb: 480,
        hasPhoto: true,
      ),
      ArchiveRecordItem(
        id: 'rec-3',
        title: '${widget.item.name} 과거 정산 및 체크리스트',
        date: now.subtract(const Duration(days: 120)),
        sizeKb: 180,
        hasPhoto: false,
      ),
      ArchiveRecordItem(
        id: 'rec-4',
        title: '${widget.item.name} 오래된 메모 및 D-Day',
        date: now.subtract(const Duration(days: 180)),
        sizeKb: 240,
        hasPhoto: false,
      ),
    ];
  }

  /// 선택 삭제 수행 (휴지통 연동)
  void _deleteSelected() {
    if (_selectedRecordIds.isEmpty) return;

    final selectedRecords = _records.where((r) => _selectedRecordIds.contains(r.id)).toList();
    final count = selectedRecords.length;
    final totalKb = selectedRecords.fold<int>(0, (sum, r) => sum + r.sizeKb);
    final mb = totalKb / 1024.0;

    for (final rec in selectedRecords) {
      ref.read(trashBinProvider.notifier).moveToTrash(
        TrashItem(
          id: 'trash-${rec.id}',
          entityType: TrashEntityType.plan,
          originalTitle: rec.title,
          deletedAt: DateTime.now(),
          originalData: {
            'id': rec.id,
            'title': rec.title,
            'date': rec.date.toIso8601String(),
            'categoryKey': widget.item.categoryKey,
          },
          categoryKey: widget.item.categoryKey,
        ),
      );
    }

    setState(() {
      _records.removeWhere((r) => _selectedRecordIds.contains(r.id));
      _selectedRecordIds.clear();
    });

    widget.onCleanedUp(mb, count);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🗑️ $count개 지난 기록이 휴지통으로 이동되었습니다. (30일 보관)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 지난 기록 일괄 삭제 수행
  void _deleteAllPastRecords() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('지난 기록 일괄 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '[${widget.item.name}]의 모든 지난 기록(${_records.length}건)을 정리하시겠습니까?\n삭제된 데이터는 30일 동안 휴지통에서 복구할 수 있습니다.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final count = _records.length;
              final totalKb = _records.fold<int>(0, (sum, r) => sum + r.sizeKb);
              final mb = totalKb / 1024.0;

              for (final rec in _records) {
                ref.read(trashBinProvider.notifier).moveToTrash(
                  TrashItem(
                    id: 'trash-${rec.id}',
                    entityType: TrashEntityType.plan,
                    originalTitle: rec.title,
                    deletedAt: DateTime.now(),
                    originalData: {
                      'id': rec.id,
                      'title': rec.title,
                      'date': rec.date.toIso8601String(),
                      'categoryKey': widget.item.categoryKey,
                    },
                    categoryKey: widget.item.categoryKey,
                  ),
                );
              }

              setState(() {
                _records.clear();
                _selectedRecordIds.clear();
              });

              widget.onCleanedUp(mb, count);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 [${widget.item.name}]의 지난 기록 $count건이 모두 정리되었습니다!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('일괄 삭제'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 드래그 핸들
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(widget.item.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  '${widget.item.name} 정리',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 상단 일괄 정리 액션 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '지난 기록 (${_records.length}건)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
                if (_records.isNotEmpty)
                  TextButton.icon(
                    onPressed: _deleteAllPastRecords,
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Color(0xFFDC2626)),
                    label: const Text(
                      '지난 기록 일괄 삭제',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                    ),
                  ),
              ],
            ),
          ),

          // 기록 리스트
          Expanded(
            child: _records.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('✨', style: TextStyle(fontSize: 36)),
                        SizedBox(height: 10),
                        Text(
                          '정리할 지난 기록이 없습니다.',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: _records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final record = _records[index];
                      final isSelected = _selectedRecordIds.contains(record.id);

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedRecordIds.add(record.id);
                                } else {
                                  _selectedRecordIds.remove(record.id);
                                }
                              });
                            },
                            title: Text(
                              record.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                '${_formatDate(record.date)} · ${record.sizeKb} KB ${record.hasPhoto ? "· 📷 사진 포함" : ""}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 하단: '선택 삭제' 액션 버튼 바
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedRecordIds.isNotEmpty ? _deleteSelected : null,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(
                    _selectedRecordIds.isNotEmpty
                        ? '${_selectedRecordIds.length}개 선택 삭제 (휴지통 이동)'
                        : '정리할 항목을 선택해주세요',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
