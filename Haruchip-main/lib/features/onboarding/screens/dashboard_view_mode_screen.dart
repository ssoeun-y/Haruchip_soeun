import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/typography.dart';
import '../data/dashboard_view_mode_options.dart';
import '../providers/dashboard_view_mode_provider.dart';
import '../widgets/dashboard_view_mode_card.dart';
import '../widgets/toss_funnel_components.dart';
import 'onboarding_complete_screen.dart';

/// 토스(Toss) 스타일 온보딩 퍼널 [Step 3: 대시보드 보기 방식 선택 (미리보기 연동)]
class DashboardViewModeScreen extends ConsumerWidget {
  const DashboardViewModeScreen({super.key, this.onNext});

  /// 다음 단계(완료화면)로 넘어갈 때 호출된다.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedKey = ref.watch(dashboardViewModeProvider);
    final canProceed = ref.watch(canProceedFromDashboardViewModeProvider);

    void handleSelect(String key) {
      ref.read(dashboardViewModeProvider.notifier).select(key);
    }

    void handleNext() {
      if (!canProceed) return;
      if (onNext != null) {
        onNext!();
        return;
      }
      Navigator.of(context).push(
        SlideFadePageRoute(page: const OnboardingCompleteScreen()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            TossStepIndicator(
              currentStep: 3,
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
                      '대시보드를 어떤 스타일로 볼까요?',
                      style: AppTypography.heading1.copyWith(
                        color: const Color(0xFF191F28),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '나에게 가장 보기 편한 방식을 골라보세요. 설정에서 언제든 변경할 수 있어요.',
                      style: AppTypography.bodyMuted.copyWith(
                        color: const Color(0xFF8B95A1),
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final option in kDashboardViewModeOptions) ...[
                      DashboardViewModeCard(
                        option: option,
                        selected: selectedKey == option.key,
                        onTap: () => handleSelect(option.key),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 16),

                    // 실시간 목업 (미리보기 박스)
                    _buildInteractiveMockupBox(selectedKey),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            GlassFloatingButton(
              label: canProceed ? '다음으로' : '뷰모드를 선택해주세요',
              enabled: canProceed,
              onPressed: handleNext,
            ),
          ],
        ),
      ),
    );
  }

  /// 실시간 목업 미리보기 박스 위젯
  Widget _buildInteractiveMockupBox(String? selectedKey) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E8EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.phone_iphone_rounded,
                  size: 16,
                  color: Color(0xFF3182F6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedKey == 'box'
                      ? '실시간 미리보기 : 칩 모아보기 뷰'
                      : '실시간 미리보기 : 타임라인 뷰',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333D4B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: selectedKey == 'box'
                ? _buildChipsMockup()
                : _buildTimelineMockup(),
          ),
        ],
      ),
    );
  }

  /// 1) 타임라인 뷰 실시간 목업
  Widget _buildTimelineMockup() {
    return Column(
      key: const ValueKey('timeline_mockup'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineNode(
          badgeText: 'D-DAY',
          badgeColor: const Color(0xFFFF7A9C),
          title: '우리 사랑한 지 520일째 ❤️',
          subtext: '처음 만난 날부터 함께 걸어온 소중한 시간',
          isLast: false,
        ),
        _buildTimelineNode(
          badgeText: 'D-14',
          badgeColor: const Color(0xFF60A5FA),
          title: '정보처리기사 실기 시험 📚',
          subtext: '목표 달성을 위한 카운트다운',
          isLast: false,
        ),
        _buildTimelineNode(
          badgeText: 'D-45',
          badgeColor: const Color(0xFF34D399),
          title: '정기 휴가 출발 🏖️',
          subtext: '복무율 68.4% 달성 기념 휴가',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineNode({
    required String badgeText,
    required Color badgeColor,
    required String title,
    required String subtext,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE5E8EB),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF2F4F6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF191F28),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtext,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8B95A1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2) 칩 모아보기 뷰 실시간 목업
  Widget _buildChipsMockup() {
    return GridView.count(
      key: const ValueKey('chips_mockup'),
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.45,
      children: [
        _buildMiniChip(
          emoji: '❤️',
          title: '우리 사랑한 지',
          dDay: 'D+520',
          bgColor: const Color(0xFFFFF0F3),
          borderColor: const Color(0xFFFFCCD5),
          textColor: const Color(0xFF4A4A4A),
        ),
        _buildMiniChip(
          emoji: '📚',
          title: '시험 / 자격증',
          dDay: 'D-14',
          bgColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFDBEAFE),
          textColor: const Color(0xFF1E3A8A),
        ),
        _buildMiniChip(
          emoji: '🎖️',
          title: '군대 복무율',
          dDay: '68.4%',
          bgColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF14532D),
        ),
        _buildMiniChip(
          emoji: '👶',
          title: '아기 성장',
          dDay: '12개월차',
          bgColor: const Color(0xFFFEFCE8),
          borderColor: const Color(0xFFFEF08A),
          textColor: const Color(0xFF713F12),
        ),
      ],
    );
  }

  Widget _buildMiniChip({
    required String emoji,
    required String title,
    required String dDay,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            dDay,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
