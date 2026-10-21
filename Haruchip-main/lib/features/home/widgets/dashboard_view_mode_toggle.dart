import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';

/// 대시보드 "나의 주요 디데이" 라벨 + 세로형/박스형 토글 pill —
/// CLAUDE.md §8(대시보드: 뷰모드 전환).
///
/// haruchip_app.html 301~307줄 마크업을 그대로 재현한다(§5/§6):
/// 좌측 스파클 아이콘 + 라벨, 우측 회색 pill 안에 "세로형"/"박스형" 두
/// 버튼. 현재 선택된 값은 [selectedKey]
/// (`resolvedDashboardViewModeProvider`가 넘겨준 'vertical'|'box')로
/// 받고, 탭하면 [onSelect]로 키를 올려보낸다 — 실제 상태 갱신은
/// [DashboardScreen]에서 `dashboardViewModeProvider.notifier.select(key)`를
/// 호출해 처리한다.
class DashboardViewModeToggle extends StatelessWidget {
  const DashboardViewModeToggle({
    super.key,
    required this.selectedKey,
    required this.onSelect,
  });

  final String selectedKey;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    // 내용 폭만큼만 차지 (대시보드에서 오른쪽 [순서 편집] 버튼과 한 줄에 놓이도록),
    // 아주 좁은 폰·큰 글씨에서는 라벨과 토글이 두 줄로.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0, // 원래 배치와 동일 (라벨과 토글 사이 간격 없음)
      runSpacing: 6,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: AppColors.protoStepLabel,
            ),
            const SizedBox(width: 6),
            Text(
              '나의 주요 디데이',
              style: AppTypography.cardLabel.copyWith(
                color: AppColors.protoHeading,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            // 원본 bg-gray-100(#F3F4F6)과 정확히 같은 값 — protoCardBorder.
            color: AppColors.protoCardBorder,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleButton(
                label: '세로형',
                selected: selectedKey == 'vertical',
                onTap: () => onSelect('vertical'),
              ),
              _ToggleButton(
                label: '박스형',
                selected: selectedKey == 'box',
                onTap: () => onSelect('box'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.protoCardBg : null,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? AppColors.protoHeading : AppColors.protoSubtitle,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
