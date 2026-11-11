import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../couple/models/couple_relationship.dart';

/// 대시보드 커플 카드 — CLAUDE.md §8(대시보드 카테고리 카드 · 커플룸
/// 전용), §7-1/§7-2(총 연애일수, 기념일 자동계산).
///
/// haruchip_app.html 312~330줄 "COUPLE CARD" 마크업을 그대로 재현한다
/// (§5/§6): 핑크 그라디언트 배경 + ❤️ 아이콘 + "우리 사랑한 지" + D+일수
/// 배지 + 하단 "다가오는 기념일" 안내 줄 + "캘린더 연동" 버튼.
///
/// [totalDays]는 `totalDaysTogetherProvider`, [nextAnniversary]는
/// `upcomingAnniversariesProvider`의 첫 항목을 그대로 넘겨받는다(둘 다
/// 로직 담당자가 이미 구현한 provider — 이 위젯은 표시만 담당).
///
/// 카드 전체를 탭하면 [onTap](2부에서 "우리의방" 탭으로 실제 전환하는
/// 연결이 완성될 자리 — 지금은 [DashboardScreen]에서 스낵바 스텁으로
/// 연결)이 호출되고, "캘린더 연동" 버튼은 중첩 [InkWell]로 별도의
/// [onSyncCalendar] 콜백을 받아 카드 탭과 분리된다(html의
/// `event.stopPropagation()`과 동일한 효과 — Flutter는 안쪽 제스처가
/// 제스처 아레나에서 먼저 승리해 바깥 InkWell로 전파되지 않는다).
class CoupleDashboardCard extends StatelessWidget {
  const CoupleDashboardCard({
    super.key,
    required this.totalDays,
    required this.nextAnniversary,
    required this.onTap,
    required this.onSyncCalendar,
  });

  final int totalDays;
  final AnniversaryMilestone? nextAnniversary;
  final VoidCallback onTap;
  final VoidCallback onSyncCalendar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.coupleBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.coupleBorder, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.protoCoupleBgMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('❤️', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '우리 사랑한 지',
                        style: AppTypography.cardLabel.copyWith(
                          color: AppColors.protoHeading,
                        ),
                      ),
                      Text(
                        '커플 디데이 & 방',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.protoCoupleText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.protoCoupleBgMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'D+$totalDays',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.protoCoupleText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.protoCardBg.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.protoCoupleBg,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      nextAnniversary == null
                          ? '다가오는 기념일이 아직 없어요'
                          : '✨ 다가오는 기념일: ${nextAnniversary!.label} '
                              '(D-${nextAnniversary!.dDay})',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoCardText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onSyncCalendar,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.protoCardSelectedBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '캘린더 연동',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.protoStepLabel,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
