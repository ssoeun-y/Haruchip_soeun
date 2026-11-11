import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/typography.dart';
import '../models/onboarding_category.dart';

/// 온보딩 카테고리 선택 카드 (햅틱 피드백 & 파스텔 하이라이트 테두리)
class CategorySelectionCard extends StatelessWidget {
  const CategorySelectionCard({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final OnboardingCategory category;
  final bool selected;
  final VoidCallback onTap;

  void _handleTap() {
    HapticFeedback.lightImpact();
    onTap();
  }

  Color _getPastelHighlightColor() {
    switch (category.key) {
      case 'couple':
        return const Color(0xFFFF7A9C);
      case 'wedding':
        return const Color(0xFFFF9EAA);
      case 'baby':
        return const Color(0xFFFBBF24);
      case 'military':
        return const Color(0xFF34D399);
      case 'exam':
        return const Color(0xFF60A5FA);
      case 'meeting':
        return const Color(0xFF818CF8);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor = _getPastelHighlightColor();

    return Semantics(
      button: true,
      selected: selected,
      label: '${category.labelKo} 카테고리',
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? highlightColor.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? highlightColor
                  : const Color(0xFFF2F4F6),
              width: selected ? 2.0 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: highlightColor.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? highlightColor.withValues(alpha: 0.15)
                      : const Color(0xFFF9FAFB),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                category.labelKo,
                textAlign: TextAlign.center,
                style: AppTypography.cardLabel.copyWith(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF191F28)
                      : const Color(0xFF4B5563),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
