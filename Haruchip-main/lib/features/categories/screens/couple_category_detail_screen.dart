import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../couple/models/couple_relationship.dart';
import '../../couple/providers/couple_provider.dart';
import '../../couple/widgets/couple_relationship_setup_sheet.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../shared/widgets/add_event_bottom_sheet.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../widgets/category_edit_modal.dart';

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

  Future<void> _showRelationshipSetupModal() =>
      showCoupleRelationshipSetupSheet(context, ref);

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
    final singleColor = bgConfig.colorValues.isNotEmpty ? colorFromHex(bgConfig.colorValues.first) : AppColors.protoCardBg;

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
                  // 1. Top Custom Main Card
                  GestureDetector(
                    onTap: _showRelationshipSetupModal,
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: bgConfig.type == BackgroundType.singleColor ? singleColor : null,
                        gradient: bgConfig.type == BackgroundType.gradient && bgConfig.colorValues.length >= 2
                            ? LinearGradient(colors: bgConfig.colorValues.map((h) => colorFromHex(h)).toList())
                            : null,
                        image: hasImage
                            ? DecorationImage(
                                image: bgConfig.imageUrl!.startsWith('http')
                                    ? NetworkImage(bgConfig.imageUrl!) as ImageProvider
                                    : AssetImage(bgConfig.imageUrl!),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.2), BlendMode.darken),
                              )
                            : null,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, cardConstraints) {
                          final cWidth = cardConstraints.maxWidth;
                          final cHeight = cardConstraints.maxHeight;
                          final typo = _category.typography;
                          final customTextColor = colorFromHex(typo.textColor);

                          return Stack(
                            children: [
                              Align(
                                alignment: typo.position.alignment,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Opacity(
                                    opacity: typo.opacity,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: switch (typo.position) {
                                        TextPositionPreset.topLeft || TextPositionPreset.bottomLeft => CrossAxisAlignment.start,
                                        TextPositionPreset.topRight || TextPositionPreset.bottomRight => CrossAxisAlignment.end,
                                        _ => CrossAxisAlignment.center,
                                      },
                                      children: [
                                        Text(
                                          '${totalDays + 1}일째',
                                          style: TextStyle(
                                            fontFamily: typo.fontFamily,
                                            fontSize: 34,
                                            fontWeight: FontWeight.w800,
                                            color: hasImage ? Colors.white : customTextColor,
                                            shadows: hasImage ? const [Shadow(color: Colors.black45, blurRadius: 4)] : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                              '${couple.startDate.year}.${couple.startDate.month.toString().padLeft(2, '0')}.${couple.startDate.day.toString().padLeft(2, '0')} ~ ing',
                                              style: TextStyle(
                                                fontFamily: typo.fontFamily,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: hasImage ? Colors.white70 : customTextColor.withValues(alpha: 0.8),
                                                shadows: hasImage ? const [Shadow(color: Colors.black45, blurRadius: 2)] : null,
                                              ),
                                            ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.edit_calendar, size: 14, color: hasImage ? Colors.white70 : customTextColor.withValues(alpha: 0.8)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (bgConfig.decorations != null)
                                for (final sticker in bgConfig.decorations!)
                                  Positioned(
                                    left: sticker.x * cWidth,
                                    top: sticker.y * cHeight,
                                    child: Transform.rotate(
                                      angle: sticker.rotation,
                                      child: Transform.scale(
                                        scale: sticker.scale,
                                        child: sticker.isText
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.85),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  sticker.stickerType,
                                                  style: TextStyle(
                                                    fontSize: sticker.fontSize ?? 14,
                                                    color: sticker.textColor != null ? colorFromHex(sticker.textColor!) : Colors.black87,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )
                                            : Text(sticker.stickerType, style: const TextStyle(fontSize: 32)),
                                      ),
                                    ),
                                  ),
                            ],
                          );
                        },
                      ),
                    ),
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
