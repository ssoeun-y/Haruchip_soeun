import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../categories/models/category_model.dart';
import '../../categories/providers/category_provider.dart';
import '../../categories/screens/category_detail_screen.dart';
import '../../categories/screens/couple_category_detail_screen.dart';
import '../../couple/providers/couple_provider.dart';
import '../../onboarding/providers/dashboard_view_mode_provider.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/add_category_dashboard_card.dart';
import '../widgets/add_category_dashboard_modal.dart';
import '../widgets/category_summary_dashboard_card.dart';
import '../widgets/dashboard_view_mode_toggle.dart';
import 'trash_bin_screen.dart';

/// 메인 셸의 "대시보드" 탭 — 카테고리별 핵심 디데이 요약 뷰 (Summary Hub)
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isEditMode = false;

  void _navigateToCategoryDetail(CategoryModel category) {
    if (category.categoryKey == 'couple') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CoupleCategoryDetailScreen(category: category),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(category: category),
        ),
      );
    }
  }

  void _hideCategoryWithFeedback(CategoryModel category) {
    ref.read(categoryListProvider.notifier).hideCategory(category.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ [${category.name}] 카테고리가 대시보드에서 숨겨졌습니다. (설정 > 숨김 보관함에서 언제든 복구 가능)'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCategoryActionSheet(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Text(category.icon, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                      ),
                      Text(
                        '카테고리 카드 관리 옵션',
                        style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF007AFF)),
              title: const Text('카테고리 상세 보기', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.of(ctx).pop();
                _navigateToCategoryDetail(category);
              },
            ),
            const Divider(height: 12, color: Color(0xFFF3F4F6)),
            ListTile(
              leading: const Icon(Icons.sort_rounded, size: 18, color: Color(0xFF8B5CF6)),
              title: const Text('대시보드 순서 편집 모드 시작', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() => _isEditMode = true);
              },
            ),
            const Divider(height: 12, color: Color(0xFFF3F4F6)),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined, size: 18, color: Color(0xFFE11D48)),
              title: const Text('대시보드에서 숨기기', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFE11D48))),
              subtitle: const Text('데이터는 100% 영구 보존되며, 홈에서만 감춰집니다.', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.of(ctx).pop();
                _hideCategoryWithFeedback(category);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(resolvedDashboardViewModeProvider);
    final totalDays = ref.watch(totalDaysTogetherProvider);
    final visibleCategories = ref.watch(visibleCategoriesProvider);
    final allPlanItems = ref.watch(planListProvider);

    // 임박 D-Day 필터링 (가장 빠른 3개 일정)
    final upcomingItems = allPlanItems
        .where((i) => i.displayMode != DdayDisplayMode.daysCount)
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 심플·감성 대시보드 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '하루칩',
                        style: AppTypography.heading1.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.protoHeading,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '한눈에 보는 나의 디데이 요약',
                        style: AppTypography.caption.copyWith(
                          fontSize: 13,
                          color: AppColors.protoSubtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.protoHeading),
                        tooltip: '휴지통 (30일 복구 보존)',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TrashBinScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 22, color: AppColors.protoHeading),
                        tooltip: '환경 설정 및 백업',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. 임박한 주요 일정 브리핑 바 (간결한 상단 칩)
              if (upcomingItems.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final item in upcomingItems) ...[
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          color: AppColors.protoHeading,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF007AFF),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          dDayLabel(item.date),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. 뷰 모드 토글 & 순서 편집 버튼 툴바
              // 좁은 폰에서는 [순서 편집] 버튼이 다음 줄로. (Wrap은 내용 폭만큼만 차지하므로
              // 넓을 때 버튼이 오른쪽 끝에 붙도록 가로를 채운다)
              SizedBox(
                width: double.infinity,
                child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 0,
                runSpacing: 8,
                children: [
                  DashboardViewModeToggle(
                    selectedKey: viewMode,
                    onSelect: (key) =>
                        ref.read(dashboardViewModeProvider.notifier).select(key),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _isEditMode = !_isEditMode);
                    },
                    icon: Icon(
                      _isEditMode ? Icons.check_circle_rounded : Icons.sort_rounded,
                      size: 16,
                      color: _isEditMode ? const Color(0xFF10B981) : AppColors.protoHeading,
                    ),
                    label: Text(
                      _isEditMode ? '편집 완료' : '순서 편집',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: _isEditMode ? const Color(0xFF10B981) : AppColors.protoHeading,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      backgroundColor: _isEditMode ? const Color(0xFFECFDF5) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _isEditMode ? const Color(0xFFA7F3D0) : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ),
              const SizedBox(height: 16),

              // 4. 카테고리별 표준 요약 카드 그리드/리스트
              if (viewMode == 'box') ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: visibleCategories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == visibleCategories.length) {
                      return AddCategoryDashboardCard(
                        onTap: () => showAddCategoryDashboardModal(context),
                      );
                    }
                    final category = visibleCategories[index];
                    final items = ref.watch(planItemsByCategoryProvider(category.categoryKey));
                    final countUpItems = items.where((i) => i.displayMode == DdayDisplayMode.daysCount).toList();
                    final countDownItems = items.where((i) => i.displayMode != DdayDisplayMode.daysCount).toList();

                    String? customCountUp;
                    if (category.categoryKey == 'couple') {
                      customCountUp = '만난 지 D+$totalDays일째';
                    }

                    return CategorySummaryDashboardCard(
                      key: ValueKey(category.id),
                      category: category,
                      countUpItems: countUpItems,
                      countDownItems: countDownItems,
                      customCountUpText: customCountUp,
                      isEditMode: _isEditMode,
                      isWideList: false,
                      onTap: _isEditMode ? null : () => _navigateToCategoryDetail(category),
                      onLongPress: () => _showCategoryActionSheet(category),
                      onHide: () => _hideCategoryWithFeedback(category),
                    );
                  },
                ),
              ] else ...[
                // 세로 리스트형 (순서 편집 모드 지원)
                if (_isEditMode)
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleCategories.length,
                    // ignore: deprecated_member_use
                    onReorder: (oldIndex, newIndex) {
                      ref.read(categoryListProvider.notifier).reorderCategories(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final category = visibleCategories[index];
                      final items = ref.watch(planItemsByCategoryProvider(category.categoryKey));
                      final countUpItems = items.where((i) => i.displayMode == DdayDisplayMode.daysCount).toList();
                      final countDownItems = items.where((i) => i.displayMode != DdayDisplayMode.daysCount).toList();

                      String? customCountUp;
                      if (category.categoryKey == 'couple') {
                        customCountUp = '만난 지 D+$totalDays일째';
                      }

                      return Container(
                        key: ValueKey(category.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: CategorySummaryDashboardCard(
                          category: category,
                          countUpItems: countUpItems,
                          countDownItems: countDownItems,
                          customCountUpText: customCountUp,
                          isEditMode: true,
                          isWideList: true,
                          onTap: null,
                          onLongPress: () => _showCategoryActionSheet(category),
                          onHide: () => _hideCategoryWithFeedback(category),
                        ),
                      );
                    },
                  )
                else
                  Column(
                    children: [
                      for (final category in visibleCategories) ...[
                        Builder(builder: (context) {
                          final items = ref.watch(planItemsByCategoryProvider(category.categoryKey));
                          final countUpItems = items.where((i) => i.displayMode == DdayDisplayMode.daysCount).toList();
                          final countDownItems = items.where((i) => i.displayMode != DdayDisplayMode.daysCount).toList();

                          String? customCountUp;
                          if (category.categoryKey == 'couple') {
                            customCountUp = '만난 지 D+$totalDays일째';
                          }

                          return CategorySummaryDashboardCard(
                            category: category,
                            countUpItems: countUpItems,
                            countDownItems: countDownItems,
                            customCountUpText: customCountUp,
                            isEditMode: false,
                            isWideList: true,
                            onTap: () => _navigateToCategoryDetail(category),
                            onLongPress: () => _showCategoryActionSheet(category),
                            onHide: () => _hideCategoryWithFeedback(category),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                      AddCategoryDashboardCard(
                        onTap: () => showAddCategoryDashboardModal(context),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
