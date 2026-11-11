import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../couple/models/couple_relationship.dart';
import '../../couple/providers/couple_provider.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../shared/widgets/add_event_bottom_sheet.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../widgets/category_edit_modal.dart';
import '../widgets/unified_category_top_card.dart';

class CoupleCategoryDetailScreen extends ConsumerStatefulWidget {
  const CoupleCategoryDetailScreen({
    super.key,
    required this.category,
  });

  final CategoryModel category;

  @override
  ConsumerState<CoupleCategoryDetailScreen> createState() => _CoupleCategoryDetailScreenState();
}

class _CoupleCategoryDetailScreenState extends ConsumerState<CoupleCategoryDetailScreen> {
  late CategoryModel _category;
  bool _isTitleEditing = false;
  late TextEditingController _titleController;

  // Edit / Reordering mode for 'N일째' items
  bool _isReorderingMode = false;
  List<PlanItem> _customCountUpOrder = [];

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _titleController = TextEditingController(text: _category.name);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _checkOnboarding() {
    final couple = ref.read(coupleProvider);
    // If it's the mock date or not initialized
    if (couple.startDate.year == 2024 && couple.startDate.month == 5 && couple.startDate.day == 14) {
      _showRelationshipSetupModal();
    }
  }

  Future<void> _showRelationshipSetupModal() async {
    final couple = ref.read(coupleProvider);
    DateTime tempStartDate = couple.startDate;
    List<ReunionPeriod> tempReunions = couple.reunions.map((r) => r.copyWith()).toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final mediaQuery = MediaQuery.of(context);
            // Calculate total days preview
            final now = DateTime.now();
            final totalElapsed = DateTime(now.year, now.month, now.day)
                .difference(DateTime(tempStartDate.year, tempStartDate.month, tempStartDate.day))
                .inDays;
            final breakupDays = tempReunions.fold<int>(0, (sum, r) => sum + r.length.inDays);
            final previewDays = (totalElapsed - breakupDays).clamp(0, 99999);

            return Container(
              height: mediaQuery.size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '만난 날 및 재회 설정',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Calculated Preview Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFD4C2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite, color: Color(0xFFFF7A59), size: 28),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('현재 연애 일수', style: TextStyle(fontSize: 12, color: Color(0xFF8A7F78))),
                                  Text(
                                    '${previewDays + 1}일째',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFFF7A59)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section 1: 처음 만난 날
                        const Text('처음 만난 날 (시작일)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showHaruDatePicker(
                              context,
                              initialDate: tempStartDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setModalState(() => tempStartDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${tempStartDate.year}.${tempStartDate.month.toString().padLeft(2, '0')}.${tempStartDate.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF007AFF)),
                                ),
                                const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF007AFF)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Section 2: 재회 및 이별 기간 목록
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '이별 / 재회 이력',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  tempReunions.add(
                                    ReunionPeriod(
                                      breakupDate: tempStartDate.add(const Duration(days: 100)),
                                      reuniteDate: tempStartDate.add(const Duration(days: 130)),
                                    ),
                                  );
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF007AFF)),
                              label: const Text('+ 재회 추가', style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '이별했던 기간만큼 총 연애 일수에서 정확히 제외됩니다.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),

                        if (tempReunions.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEEEEEE)),
                            ),
                            child: const Text('등록된 이별/재회 기간이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          )
                        else
                          for (int i = 0; i < tempReunions.length; i++)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9FB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE5E5EA)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('기간 #${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3A3A3C))),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444), size: 18),
                                        onPressed: () {
                                          setModalState(() {
                                            tempReunions.removeAt(i);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // Breakup date button
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            final picked = await showHaruDatePicker(
                                              context,
                                              initialDate: tempReunions[i].breakupDate,
                                              firstDate: DateTime(1900),
                                              lastDate: DateTime(2100),
                                            );
                                            if (picked != null) {
                                              setModalState(() {
                                                tempReunions[i] = tempReunions[i].copyWith(breakupDate: picked);
                                              });
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFD1D1D6)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('이별일', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                Text(
                                                  '${tempReunions[i].breakupDate.year}.${tempReunions[i].breakupDate.month.toString().padLeft(2, '0')}.${tempReunions[i].breakupDate.day.toString().padLeft(2, '0')}',
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6),
                                        child: Text('~', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                      // Reunite date button
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            final picked = await showHaruDatePicker(
                                              context,
                                              initialDate: tempReunions[i].reuniteDate ?? tempReunions[i].breakupDate.add(const Duration(days: 30)),
                                              firstDate: DateTime(1900),
                                              lastDate: DateTime(2100),
                                            );
                                            if (picked != null) {
                                              setModalState(() {
                                                tempReunions[i] = tempReunions[i].copyWith(reuniteDate: picked);
                                              });
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFD1D1D6)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('재회일', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                Text(
                                                  tempReunions[i].reuniteDate != null
                                                      ? '${tempReunions[i].reuniteDate!.year}.${tempReunions[i].reuniteDate!.month.toString().padLeft(2, '0')}.${tempReunions[i].reuniteDate!.day.toString().padLeft(2, '0')}'
                                                      : '미재회 (현재 이별 중)',
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                  // Bottom Submit Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          ref.read(coupleProvider.notifier).updateRelationship(
                                startDate: tempStartDate,
                                reunions: tempReunions,
                              );
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          '설정 완료',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openEditModal() async {
    final updated = await showCategoryEditModal(
      context,
      category: _category,
    );

    if (updated != null && mounted) {
      setState(() {
        _category = updated;
      });
      ref.read(categoryListProvider.notifier).updateCategory(updated);
    }
  }

  void _saveTitle() {
    setState(() => _isTitleEditing = false);
    final updated = _category.copyWith(name: _titleController.text.trim());
    setState(() => _category = updated);
    ref.read(categoryListProvider.notifier).updateCategory(updated);
  }

  @override
  Widget build(BuildContext context) {
    final couple = ref.watch(coupleProvider);
    final totalDays = ref.watch(totalDaysTogetherProvider);
    final anniversaries = ref.watch(upcomingAnniversariesProvider);
    final customItems = ref.watch(planItemsByCategoryProvider(_category.categoryKey));

    final bgConfig = _category.background;
    final hasImage = bgConfig.type == BackgroundType.image && bgConfig.imageUrl != null;

    // Filter count-up items (N일째)
    final countUpItems = customItems.where((item) => item.displayMode == DdayDisplayMode.daysCount).toList();
    if (_customCountUpOrder.length != countUpItems.length) {
      _customCountUpOrder = List.from(countUpItems);
    }

    // Filter countdown items (D-Day & Milestones)
    final countDownItems = customItems.where((item) => item.displayMode != DdayDisplayMode.daysCount).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: AppColors.protoHeading),
        title: Row(
          children: [
            Text(_category.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            if (_isTitleEditing)
              Expanded(
                child: TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: AppTypography.heading2.copyWith(color: AppColors.protoHeading),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _saveTitle(),
                ),
              )
            else
              GestureDetector(
                onTap: () => setState(() => _isTitleEditing = true),
                child: Text(
                  _category.name,
                  style: AppTypography.heading2.copyWith(color: AppColors.protoHeading),
                ),
              ),
          ],
        ),
        actions: [
          if (_isTitleEditing)
            IconButton(
              icon: const Icon(Icons.check, color: Color(0xFF3B82F6)),
              onPressed: _saveTitle,
            )
          else ...[
            TextButton.icon(
              onPressed: _openEditModal,
              icon: const Icon(Icons.palette_outlined, size: 18, color: AppColors.protoHeading),
              label: Text('꾸미기', style: AppTypography.caption.copyWith(color: AppColors.protoHeading, fontWeight: FontWeight.bold)),
            ),
            // Header Action: '+ 항목 추가' button text
            TextButton.icon(
              onPressed: () => showAddEventBottomSheet(
                context,
                categoryKey: _category.categoryKey,
              ),
              icon: const Icon(Icons.add, size: 18, color: Color(0xFF007AFF)),
              label: const Text(
                '항목 추가',
                style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ]
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Custom Main Card (아기 카드와 1:1 통일된 네추럴 미니멀 폼 팩터)
                  Builder(
                    builder: (context) {
                      final breakupDays = couple.reunions.fold<int>(0, (sum, r) => sum + r.length.inDays);
                      final startDateStr = '시작일: ${couple.startDate.year}.${couple.startDate.month.toString().padLeft(2, '0')}.${couple.startDate.day.toString().padLeft(2, '0')}';
                      final reunionStr = breakupDays > 0 ? '재회 기간 제외: $breakupDays일' : '연애 진행 중 ing';

                      return UnifiedCategoryTopCard(
                        categoryKey: 'couple',
                        title: _category.name.isNotEmpty ? _category.name : '우리 사랑한 지',
                        symbol: '❤️',
                        coreDDayText: '사랑한 지 ${totalDays + 1}일째',
                        startDateText: startDateStr,
                        reunionOrExtraBadge: reunionStr,
                        photoUrl: hasImage ? bgConfig.imageUrl : null,
                        fallbackEmoji: '❤️',
                        onEditAvatar: () async {
                          final updated = await showCategoryEditModal(context, category: _category);
                          if (updated != null) {
                            setState(() => _category = updated);
                            ref.read(categoryListProvider.notifier).updateCategory(updated);
                          }
                        },
                        onManageSection: _showRelationshipSetupModal,
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // 2. Zone A: 'N일째 리스트' (Count-up List)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, size: 18, color: AppColors.protoHeading),
                          const SizedBox(width: 6),
                          Text(
                            'N일째 리스트',
                            style: AppTypography.cardLabel.copyWith(color: AppColors.protoHeading, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _customCountUpOrder = List.from(countUpItems);
                            _isReorderingMode = true;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '편집',
                          style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Base Initial Meeting Date Item
                  _buildCountUpCard(
                    title: '처음 만난 날',
                    subtext: '${couple.startDate.year}.${couple.startDate.month.toString().padLeft(2, '0')}.${couple.startDate.day.toString().padLeft(2, '0')}',
                    dDayLabel: '${totalDays + 1}일째',
                    onTap: _showRelationshipSetupModal,
                  ),

                  // Custom Count-up Items
                  for (final item in _customCountUpOrder)
                    _buildCountUpCard(
                      title: item.title,
                      subtext: '${item.date.year}.${item.date.month.toString().padLeft(2, '0')}.${item.date.day.toString().padLeft(2, '0')}',
                      dDayLabel: '${DateTime.now().difference(item.date).inDays + 1}일째',
                      onTap: () => showAddEventBottomSheet(
                        context,
                        categoryKey: _category.categoryKey,
                        existingItem: item,
                      ),
                    ),

                  const SizedBox(height: 28),

                  // 3. Zone B: '세부 D-Day 리스트' (Countdown List)
                  Row(
                    children: [
                      const Icon(Icons.event_note_rounded, size: 18, color: AppColors.protoHeading),
                      const SizedBox(width: 6),
                      Text(
                        '세부 D-Day 리스트',
                        style: AppTypography.cardLabel.copyWith(color: AppColors.protoHeading, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._buildCountDownItems(countDownItems, anniversaries),
                ],
              ),
            ),
          ),

          // Reordering Modal Overlay for Zone A
          if (_isReorderingMode)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Notification
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'N일째 항목 순서 변경',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '💡 상단 2개 항목만 메인 화면에 우선 표시됩니다.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF007AFF), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reorderable list
                        Expanded(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: ReorderableListView(
                              // ignore: deprecated_member_use
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (oldIndex < newIndex) newIndex -= 1;
                                  final item = _customCountUpOrder.removeAt(oldIndex);
                                  _customCountUpOrder.insert(newIndex, item);
                                });
                              },
                              children: [
                                for (int i = 0; i < _customCountUpOrder.length; i++)
                                  Container(
                                    key: ValueKey(_customCountUpOrder[i].id),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: i < 2
                                          ? Border.all(color: const Color(0xFF007AFF), width: 2)
                                          : Border.all(color: const Color(0xFFE5E5EA)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: i < 2 ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${i + 1}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: i < 2 ? Colors.white : const Color(0xFF8E8E93),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _customCountUpOrder[i].title,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                                          ),
                                        ),
                                        const Icon(Icons.drag_handle_rounded, color: Color(0xFF8E8E93)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            setState(() {
                              _isReorderingMode = false;
                            });
                          },
                          child: const Text('수정 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountUpCard({
    required String title,
    required String subtext,
    required String dDayLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE4D8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      color: AppColors.protoHeading,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtext,
                    style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                dDayLabel,
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCountDownItems(List<PlanItem> customItems, List<AnniversaryMilestone> autoAnniv) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<_CountDownListItem> merged = [];

    for (final item in customItems) {
      final itemDate = DateTime(item.date.year, item.date.month, item.date.day);
      final isPast = itemDate.isBefore(today);
      final diff = itemDate.difference(today).inDays;
      merged.add(_CountDownListItem(
        title: item.title,
        subtext: '${item.date.year}.${item.date.month.toString().padLeft(2, '0')}.${item.date.day.toString().padLeft(2, '0')}',
        date: item.date,
        isPast: isPast,
        dDayLabel: diff == 0 ? 'D-Day' : (diff > 0 ? 'D-$diff' : 'D+${-diff}'),
        isCoupleSpecial: false,
        rawItem: item,
      ));
    }

    for (final anniv in autoAnniv) {
      final diff = anniv.date.difference(today).inDays;
      merged.add(_CountDownListItem(
        title: anniv.label,
        subtext: '${anniv.date.year}.${anniv.date.month.toString().padLeft(2, '0')}.${anniv.date.day.toString().padLeft(2, '0')}',
        date: anniv.date,
        isPast: false,
        dDayLabel: diff == 0 ? 'D-Day' : 'D-$diff',
        isCoupleSpecial: true,
      ));
    }

    merged.sort((a, b) {
      if (!a.isPast && !b.isPast) return a.date.compareTo(b.date);
      if (a.isPast && b.isPast) return b.date.compareTo(a.date);
      return a.isPast ? 1 : -1;
    });

    return merged.map((m) {
      return GestureDetector(
        onTap: () {
          if (m.rawItem != null) {
            showAddEventBottomSheet(
              context,
              categoryKey: _category.categoryKey,
              existingItem: m.rawItem,
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECE4D8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          m.title,
                          style: AppTypography.body.copyWith(
                            color: AppColors.protoHeading,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        if (m.isCoupleSpecial) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFFF7F50)),
                        ]
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      m.subtext,
                      style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: m.dDayLabel.startsWith('D+') ? const Color(0xFFFFEAEA) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  m.dDayLabel,
                  style: TextStyle(
                    color: m.dDayLabel.startsWith('D+') ? const Color(0xFFEF4444) : const Color(0xFF007AFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _CountDownListItem {
  _CountDownListItem({
    required this.title,
    required this.subtext,
    required this.date,
    required this.isPast,
    required this.dDayLabel,
    required this.isCoupleSpecial,
    this.rawItem,
  });

  final String title;
  final String subtext;
  final DateTime date;
  final bool isPast;
  final String dDayLabel;
  final bool isCoupleSpecial;
  final PlanItem? rawItem;
}
