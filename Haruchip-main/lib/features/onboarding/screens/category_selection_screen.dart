import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/typography.dart';
import '../../categories/data/category_types.dart';
import '../../categories/logic/category_content_flow.dart';
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

    Future<void> handleNext() async {
      if (!canProceed) return;

      // 고른 카테고리마다 내용(커플: 만난 날, 일정: 첫 일정, 반려동물: 아이 정보 …)을
      // 입력·저장해야 추가된다. 빈 카테고리로 시작하지 않는다.
      final notifier = ref.read(categoryListProvider.notifier);
      final types = kOnboardingCategories.where((c) => selectedKeys.contains(c.key));
      for (final type in types) {
        final alreadyHas = ref.read(categoryListProvider).any((c) => c.categoryKey == type.key);
        if (alreadyHas) continue;
        while (true) {
          final draft = notifier.newDraft(
            categoryKey: type.key,
            name: type.labelKo,
            emoji: type.emoji,
            colorHex: getCategoryColorHex(type.key),
          );
          final added = await collectContentAndAddCategory(context, ref, draft);
          if (added || !context.mounted) break;
          final retry = await _askRetryOrSkip(context, type.labelKo);
          if (!context.mounted) return;
          if (!retry) {
            ref.read(categorySelectionProvider.notifier).toggle(type.key);
            break;
          }
        }
        if (!context.mounted) return;
      }
      // 전부 뺐으면 이 화면에 머문다 (최소 1개 선택 안내가 다시 보인다).
      if (ref.read(categoryListProvider).isEmpty) return;

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

/// 내용 입력창을 저장 없이 닫았을 때: 다시 입력(true) / 이 카테고리 빼기(false).
Future<bool> _askRetryOrSkip(BuildContext context, String label) async {
  final retry = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("'$label' 내용을 입력해주세요"),
      content: const Text('내용을 입력하고 저장해야 이 카테고리로 시작할 수 있어요.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('이 카테고리 빼기'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3182F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('다시 입력하기'),
        ),
      ],
    ),
  );
  return retry ?? true;
}
