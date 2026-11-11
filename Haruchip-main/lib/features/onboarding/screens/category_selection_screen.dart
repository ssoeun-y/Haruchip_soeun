import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/typography.dart';
import '../../categories/providers/category_provider.dart';
import '../data/onboarding_categories.dart';
import '../providers/category_selection_provider.dart';
import '../widgets/category_selection_card.dart';
import '../widgets/toss_funnel_components.dart';
import 'dashboard_view_mode_screen.dart';

/// 토스(Toss) 스타일 온보딩 퍼널 [Step 2: 관심 카테고리 다중 선택]
class CategorySelectionScreen extends ConsumerWidget {
  const CategorySelectionScreen({super.key, this.onNext});

  /// 다음 단계(대시보드 뷰모드 선택)로 넘어갈 때 호출된다.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedKeys = ref.watch(categorySelectionProvider);
    final canProceed = ref.watch(canProceedFromCategorySelectionProvider);

    void handleToggle(String key) {
      ref.read(categorySelectionProvider.notifier).toggle(key);
    }

    void handleNext() {
      if (!canProceed) return;

      final types = kOnboardingCategories
          .where((c) => selectedKeys.contains(c.key))
          .map((c) => (key: c.key, labelKo: c.labelKo, emoji: c.emoji));
      ref.read(categoryListProvider.notifier).seedFromKeys(types);

      if (onNext != null) {
        onNext!();
        return;
      }
      Navigator.of(context).push(
        SlideFadePageRoute(page: const DashboardViewModeScreen()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            TossStepIndicator(
              currentStep: 2,
              totalSteps: 3,
              onBack: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '관심 있는 카테고리를 골라주세요',
                      style: AppTypography.heading1.copyWith(
                        color: const Color(0xFF191F28),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '나에게 필요한 카테고리를 선택하세요 (중복 선택 가능)',
                      style: AppTypography.bodyMuted.copyWith(
                        color: const Color(0xFF8B95A1),
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 폭 비례(1.22)로만 높이를 잡으면 좁은 폰·큰 글씨에서 카드 내용이 넘친다 —
                    // 넓은 폰에서는 기존 비율 그대로, 좁으면 내용에 필요한 최소 높이를 보장한다.
                    LayoutBuilder(builder: (context, constraints) {
                      final cellWidth = (constraints.maxWidth - 12) / 2;
                      final minHeight =
                          92 + MediaQuery.textScalerOf(context).scale(40);
                      final cellHeight =
                          (cellWidth / 1.22) > minHeight ? cellWidth / 1.22 : minHeight;
                      return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: cellWidth / cellHeight,
                      children: [
                        for (final category in kOnboardingCategories)
                          CategorySelectionCard(
                            category: category,
                            selected: selectedKeys.contains(category.key),
                            onTap: () => handleToggle(category.key),
                          ),
                      ],
                    );
                    }),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            GlassFloatingButton(
              label: canProceed ? '다음으로' : '카테고리를 1개 이상 선택해주세요',
              enabled: canProceed,
              onPressed: handleNext,
            ),
          ],
        ),
      ),
    );
  }
}
