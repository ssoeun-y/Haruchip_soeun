import 'package:flutter/material.dart';

import '../models/dashboard_view_mode_option.dart';

/// 온보딩 대시보드 보기 방식 선택 라디오 카드
class DashboardViewModeCard extends StatelessWidget {
  const DashboardViewModeCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final DashboardViewModeOption option;
  final bool selected;
  final VoidCallback onTap;

  String get _displayTitle {
    if (option.key == 'vertical') {
      return '[타임라인 뷰]';
    } else {
      return '[칩 모아보기 뷰]';
    }
  }

  String get _displayDescription {
    if (option.key == 'vertical') {
      return '날짜순으로 D-Day가 순차 정렬되는 깔끔한 타임라인';
    } else {
      return '카테고리별 대표 칩과 핵심 상태가 한눈에 들어오는 대시보드';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.labelKo} 뷰모드',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF0F7FF)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF3182F6)
                  : const Color(0xFFE5E8EB),
              width: selected ? 2.0 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF3182F6).withValues(alpha: 0.12),
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
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? const Color(0xFF3182F6) : Colors.transparent,
                  border: Border.all(
                    color: selected ? const Color(0xFF3182F6) : const Color(0xFFB0B8C1),
                    width: selected ? 6 : 2,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _displayTitle,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: selected ? const Color(0xFF3182F6) : const Color(0xFF191F28),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 기존 테스트 및 이전 라벨 하위 호환 매칭용 뱃지
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            option.labelKo,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7684),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayDescription,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF8B95A1),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
