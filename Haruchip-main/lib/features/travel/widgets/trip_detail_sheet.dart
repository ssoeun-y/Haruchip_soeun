import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/typography.dart';
import '../models/trip_item.dart';
import '../providers/travel_provider.dart';
import 'add_trip_modal.dart';

/// 단일 여행 세부 플래너 화면/바텀시트
/// (가방 싸기 체크리스트 + 일자별 Day 1, 2, 3... 타임라인)
class TripDetailSheet extends ConsumerStatefulWidget {
  const TripDetailSheet({
    super.key,
    required this.tripId,
  });

  final String tripId;

  static Future<void> show(BuildContext context, String tripId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TripDetailSheet(tripId: tripId),
    );
  }

  @override
  ConsumerState<TripDetailSheet> createState() => _TripDetailSheetState();
}

class _TripDetailSheetState extends ConsumerState<TripDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDayNumber = 1;
  final TextEditingController _customItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customItemController.dispose();
    super.dispose();
  }

  void _handleAddCustomPackingItem() {
    final text = _customItemController.text.trim();
    if (text.isEmpty) return;

    ref.read(travelTripListProvider.notifier).addPackingItem(widget.tripId, text);
    _customItemController.clear();
  }

  void _showCopyPackingDialog(List<TripItem> allTrips) {
    final otherTrips = allTrips.where((t) => t.id != widget.tripId).toList();
    if (otherTrips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('복사해 올 다른 여행이 없습니다.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.copy_rounded, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('체크리스트 복사해오기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이전에 다녀왔거나 준비했던 다른 여행의 짐 싸기 목록을 그대로 가져옵니다.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),
            for (final other in otherTrips)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: Text(other.emoji, style: const TextStyle(fontSize: 22)),
                title: Text(other.destination, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('${other.packingList.length}개 항목', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  ref.read(travelTripListProvider.notifier).copyPackingListFrom(widget.tripId, other.id);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('📦 [${other.destination}]의 체크리스트를 성공적으로 복사했습니다!')),
                  );
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('닫기', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog(TripItem trip) {
    final titleController = TextEditingController();
    final timeController = TextEditingController(text: '10:00');
    final locationController = TextEditingController();
    final reservationController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.add_location_alt_rounded, color: Color(0xFF0284C7)),
            const SizedBox(width: 8),
            Text('Day $_selectedDayNumber 일정 추가', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('일정 / 장소 명칭', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
              const SizedBox(height: 4),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ex. 간사이공항 착륙 & 라피트 탑승',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('시간 (HH:mm)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: timeController,
                          decoration: InputDecoration(
                            hintText: '09:30',
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('예약 번호 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: reservationController,
                          decoration: InputDecoration(
                            hintText: 'ex. OZ102',
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('위치 / 상세 메모 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
              const SizedBox(height: 4),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'ex. 1터미널 3번 게이트 / 난바역 1번 출구',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;

              final targetDate = trip.startDate.add(Duration(days: _selectedDayNumber - 1));
              final newItem = DayScheduleItem(
                id: 'sched-${DateTime.now().millisecondsSinceEpoch}',
                dayNumber: _selectedDayNumber,
                date: targetDate,
                time: timeController.text.trim().isEmpty ? null : timeController.text.trim(),
                title: title,
                location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                reservationCode: reservationController.text.trim().isEmpty ? null : reservationController.text.trim(),
              );

              ref.read(travelTripListProvider.notifier).addDaySchedule(trip.id, newItem);
              Navigator.of(dialogCtx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTrip(TripItem trip) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('여행 삭제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text('[${trip.destination}] 여행과 관련된 모든 짐 싸기 및 일정 데이터가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(travelTripListProvider.notifier).deleteTrip(trip.id);
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🗑️ [${trip.destination}] 여행이 삭제되었습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(travelTripListProvider);
    final trip = trips.firstWhere((t) => t.id == widget.tripId, orElse: () => trips.first);

    final dDayBadgeText = trip.dDayBadge();
    final durationDays = trip.durationInDays;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // 상단 드래그 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 보딩패스 스타일 상단 헤더 카드
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD6ECFF), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.06),
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
                    Row(
                      children: [
                        Text(trip.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 8),
                        Text(
                          trip.destination,
                          style: AppTypography.heading2.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            dDayBadgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF64748B)),
                          onSelected: (val) {
                            if (val == 'edit') {
                              AddTripModal.show(context, initialTrip: trip);
                            } else if (val == 'delete') {
                              _confirmDeleteTrip(trip);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'edit', child: Text('여행 정보 수정')),
                            const PopupMenuItem(value: 'delete', child: Text('여행 삭제', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.dateRangeText} (${durationDays - 1}박 $durationDays일)',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                if (trip.memo != null && trip.memo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    trip.memo!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ],
            ),
          ),

          // 2대 서브 탭: [가방 싸기 체크리스트] & [일자별 Day 타임라인]
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                ],
              ),
              labelColor: const Color(0xFF0284C7),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: '가방 싸기 (${trip.completedPackingCount}/${trip.totalPackingCount})'),
                Tab(text: '일자별 일정 (${trip.daySchedules.length})'),
              ],
            ),
          ),

          // 탭 바 본문
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. 가방 싸기 탭
                _buildPackingListTab(trip, trips),
                // 2. 일자별 Day 타임라인 탭
                _buildDayTimelineTab(trip),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1. 가방 싸기 체크리스트 탭 뷰
  Widget _buildPackingListTab(TripItem trip, List<TripItem> allTrips) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 진행률 카드
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('짐 싸기 달성률', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    Text(
                      '${(trip.packingProgress * 100).toInt()}% (${trip.packingProgressText})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: trip.packingProgress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 상단 액션 버튼들 (원터치 템플릿 불러오기 / 이전 여행 복사해오기)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(travelTripListProvider.notifier).loadDefaultPackingList(trip.id),
                  icon: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF0284C7)),
                  label: const Text('필수 템플릿 불러오기', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCopyPackingDialog(allTrips),
                  icon: const Icon(Icons.content_copy_rounded, size: 14, color: Color(0xFF475569)),
                  label: const Text('이전 여행 짐 복사', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 커스텀 짐 직접 추가 인라인 필드
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customItemController,
                  decoration: InputDecoration(
                    hintText: '직접 챙길 짐 추가 (ex. 카메라 충전기, 비타민)',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _handleAddCustomPackingItem(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _handleAddCustomPackingItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('추가', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 체크리스트 아이템들 (카테고리별 그룹)
          if (trip.packingList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Text('🎒', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text('아직 등록된 짐 싸기 항목이 없습니다.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  SizedBox(height: 4),
                  Text('상단의 [필수 템플릿 불러오기]를 눌러 기본 준비물을 채워보세요!', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            )
          else ...[
            for (final categoryGroup in _groupPackingByCategory(trip.packingList).entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text(
                  categoryGroup.key,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    for (final item in categoryGroup.value) ...[
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: Checkbox(
                          value: item.isChecked,
                          activeColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (_) {
                            ref.read(travelTripListProvider.notifier).togglePackingItem(trip.id, item.id);
                          },
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: item.isChecked ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                            decoration: item.isChecked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            ref.read(travelTripListProvider.notifier).removePackingItem(trip.id, item.id);
                          },
                        ),
                      ),
                      if (item != categoryGroup.value.last)
                        const Divider(height: 1, indent: 40, color: Color(0xFFF1F5F9)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Map<String, List<PackingCheckItem>> _groupPackingByCategory(List<PackingCheckItem> list) {
    final map = <String, List<PackingCheckItem>>{};
    for (final item in list) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  /// 2. 일자별 Day 타임라인 탭 뷰
  Widget _buildDayTimelineTab(TripItem trip) {
    final totalDays = trip.durationInDays;
    final daySchedules = trip.daySchedules
        .where((s) => s.dayNumber == _selectedDayNumber)
        .toList();

    final dayDate = trip.startDate.add(Duration(days: _selectedDayNumber - 1));
    final dateStr = '${dayDate.month}.${dayDate.day} (${['일', '월', '화', '수', '목', '금', '토'][dayDate.weekday % 7]})';

    return Column(
      children: [
        // 상단 가로 Day 탭 바 (Day 1, Day 2, Day 3 ...)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (int d = 1; d <= totalDays; d++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('Day $d', style: TextStyle(fontSize: 12, fontWeight: _selectedDayNumber == d ? FontWeight.bold : FontWeight.w600)),
                      selected: _selectedDayNumber == d,
                      selectedColor: const Color(0xFF0284C7),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(color: _selectedDayNumber == d ? Colors.white : const Color(0xFF475569)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: _selectedDayNumber == d ? const Color(0xFF0284C7) : Colors.transparent),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedDayNumber = d);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // 선택된 Day 상세 일정 리스트
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day $_selectedDayNumber 일정  ·  $dateStr',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddScheduleDialog(trip),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('일정 추가', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (daySchedules.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Text('🗺️', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text('Day $_selectedDayNumber에 등록된 일정이 없습니다.', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        const Text('[+ 일정 추가]를 눌러 항공편, 호텔, 방문 장소를 등록하세요!', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  )
                else
                  for (final item in daySchedules) ...[
                    _buildDayScheduleCard(trip, item),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayScheduleCard(TripItem trip, DayScheduleItem item) {
    final countdown = item.countdownLabel();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (item.time != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.time!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (item.reservationCode != null && item.reservationCode!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '예약: ${item.reservationCode}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                onPressed: () {
                  ref.read(travelTripListProvider.notifier).deleteDaySchedule(trip.id, item.id);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          if (item.location != null && item.location!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.location!,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (countdown != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⏱️', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(
                    countdown,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
