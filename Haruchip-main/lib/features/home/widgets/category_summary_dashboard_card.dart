import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../categories/controllers/baby_category_controller.dart';
import '../../categories/logic/repeat_rule.dart';
import '../../categories/models/baby_profile.dart';
import '../../categories/models/category_model.dart';
import '../../categories/models/solo_profile.dart';
import '../../couple/providers/couple_provider.dart';
import '../../military/providers/military_provider.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart' show dDayLabel;

/// 카테고리별 감성 소프트 파스텔 테마 팔레트 (10~30대 타깃 톤온톤 디자인)
class CategoryThemePalette {
  const CategoryThemePalette({
    required this.bg,
    required this.border,
    required this.chipBg,
    required this.primary,
    required this.text,
  });

  final Color bg;
  final Color border;
  final Color chipBg;
  final Color primary;
  final Color text;

  static CategoryThemePalette forCategoryKey(String key) {
    switch (key) {
      case 'couple':
        return const CategoryThemePalette(
          bg: Color(0xFFFFF1F2),
          border: Color(0xFFFFE4E6),
          chipBg: Color(0xFFFFE4E6),
          primary: Color(0xFFE11D48),
          text: Color(0xFF881337),
        );
      case 'military':
        return const CategoryThemePalette(
          bg: Color(0xFFF0FDF4),
          border: Color(0xFFDCFCE7),
          chipBg: Color(0xFFDCFCE7),
          primary: Color(0xFF16A34A),
          text: Color(0xFF14532D),
        );
      case 'baby':
        return const CategoryThemePalette(
          bg: Color(0xFFFEFCE8),
          border: Color(0xFFFEF08A),
          chipBg: Color(0xFFFEF08A),
          primary: Color(0xFFCA8A04),
          text: Color(0xFF713F12),
        );
      case 'pet':
        return const CategoryThemePalette(
          bg: Color(0xFFFFF8F1),
          border: Color(0xFFFFEDD5),
          chipBg: Color(0xFFFFEDD5),
          primary: Color(0xFFEA580C),
          text: Color(0xFF7C2D12),
        );
      case 'solo':
        return const CategoryThemePalette(
          bg: Color(0xFFFAF5FF),
          border: Color(0xFFF3E8FF),
          chipBg: Color(0xFFF3E8FF),
          primary: Color(0xFF9333EA),
          text: Color(0xFF581C87),
        );
      case 'fandom':
        return const CategoryThemePalette(
          bg: Color(0xFFFFFDF0),
          border: Color(0xFFFEF3C7),
          chipBg: Color(0xFFFEF3C7),
          primary: Color(0xFFD97706),
          text: Color(0xFF78350F),
        );
      case 'exam':
      case 'study':
        return const CategoryThemePalette(
          bg: Color(0xFFEFF6FF),
          border: Color(0xFFDBEAFE),
          chipBg: Color(0xFFDBEAFE),
          primary: Color(0xFF2563EB),
          text: Color(0xFF1E3A8A),
        );
      case 'birthday':
        return const CategoryThemePalette(
          bg: Color(0xFFFDF2F8),
          border: Color(0xFFFCE7F3),
          chipBg: Color(0xFFFCE7F3),
          primary: Color(0xFFDB2777),
          text: Color(0xFF831843),
        );
      case 'goal':
        return const CategoryThemePalette(
          bg: Color(0xFFF0FDF4),
          border: Color(0xFFDCFCE7),
          chipBg: Color(0xFFDCFCE7),
          primary: Color(0xFF16A34A),
          text: Color(0xFF14532D),
        );
      case 'routine':
        return const CategoryThemePalette(
          bg: Color(0xFFF0F9FF),
          border: Color(0xFFE0F2FE),
          chipBg: Color(0xFFE0F2FE),
          primary: Color(0xFF0284C7),
          text: Color(0xFF075985),
        );
      case 'plan':
      default:
        return const CategoryThemePalette(
          bg: Color(0xFFF8FAFC),
          border: Color(0xFFE2E8F0),
          chipBg: Color(0xFFE2E8F0),
          primary: Color(0xFF475569),
          text: Color(0xFF0F172A),
        );
    }
  }
}

/// 홈/대시보드 메인 표준 카테고리 요약 카드
class CategorySummaryDashboardCard extends ConsumerWidget {
  const CategorySummaryDashboardCard({
    super.key,
    required this.category,
    required this.countUpItems,
    required this.countDownItems,
    this.customCountUpText,
    this.onTap,
    this.onLongPress,
    this.onHide,
    this.isEditMode = false,
    this.isWideList = false,
  });

  final CategoryModel category;
  final List<PlanItem> countUpItems;
  final List<PlanItem> countDownItems;
  final String? customCountUpText;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onHide;
  final bool isEditMode;
  final bool isWideList;

  String _formatDaysCount(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays + 1;
    return diff > 0 ? '$diff일째' : 'D-Day';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = CategoryThemePalette.forCategoryKey(category.categoryKey);
    final key = category.categoryKey;

    return InkWell(
      onTap: isEditMode ? null : onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEditMode ? palette.primary : palette.border,
            width: isEditMode ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: isEditMode ? 0.12 : 0.04),
              blurRadius: isEditMode ? 14 : 10,
              offset: isEditMode ? const Offset(0, 4) : const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 헤더: 아이콘 + 카테고리 이름 + 바로가기 화살표 / 편집 모드 숨김 & 핸들
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.chipBg,
                    shape: BoxShape.circle,
                  ),
                  child: Text(category.icon, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.name,
                    style: AppTypography.cardLabel.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: palette.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isEditMode) ...[
                  if (onHide != null)
                    IconButton(
                      icon: const Icon(Icons.visibility_off_outlined, size: 20, color: Color(0xFF6B7280)),
                      tooltip: '대시보드에서 숨기기',
                      onPressed: onHide,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.drag_handle_rounded, size: 22, color: Color(0xFF9CA3AF)),
                ] else ...[
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: palette.primary.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // 2. 카테고리별 특화 맞춤 요약 UI
            if (key == 'military')
              _buildMilitaryBody(context, ref, palette)
            else if (key == 'couple')
              _buildCoupleBody(context, ref, palette)
            else if (key == 'baby')
              _buildBabyBody(context, ref, palette)
            else if (key == 'exam' || key == 'study')
              _buildExamBody(context, ref, palette)
            else if (key == 'solo')
              _buildSoloBody(context, ref, palette)
            else if (key == 'routine')
              _buildRoutineBody(context, ref, palette)
            else
              _buildStandardBody(palette),
          ],
        ),
      ),
    );
  }

  /// 1. 커플 카테고리 특화 요약 (함께한 지 N일째 + 가장 임박한 기념일 D-Day 2개)
  Widget _buildCoupleBody(
    BuildContext context,
    WidgetRef ref,
    CategoryThemePalette palette,
  ) {
    final totalDays = ref.watch(totalDaysTogetherProvider);
    final countUpLabel = '함께한 지 D+$totalDays일째';
    final topDdays = countDownItems.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: palette.chipBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            countUpLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: palette.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (topDdays.isNotEmpty)
          for (final item in topDdays) ...[
            _buildDdayRow(item.title, dDayLabel(item.date), palette),
          ]
        else
          Text(
            '등록된 기념일 일정이 없어요',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  /// 2. 군대 카테고리 특화 요약
  Widget _buildMilitaryBody(
    BuildContext context,
    WidgetRef ref,
    CategoryThemePalette palette,
  ) {
    final progress = ref.watch(militaryProgressProvider);
    final dischargeDday = ref.watch(militaryDischargeDdayProvider);
    final leaveDday = ref.watch(militaryLeaveDdayProvider);
    final currentRank = ref.watch(militaryCurrentRankProvider);
    final nextRankMilestone = ref.watch(militaryNextRankMilestoneProvider);
    final nextRankDday = ref.watch(militaryNextRankDdayProvider);
    final remainingVacationDays = ref.watch(militaryRemainingVacationDaysProvider);
    final progressPercent = (progress * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '복무율 $progressPercent%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.primary),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '전역 $dischargeDday',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: palette.text),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: palette.chipBg,
            valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMiniTag('🎖️', nextRankMilestone == null ? '${currentRank.labelKo} (진급 완료)' : '${nextRankMilestone.rank.labelKo} $nextRankDday', palette),
              const SizedBox(width: 6),
              _buildMiniTag('🏖️', leaveDday != null ? '휴가 $leaveDday' : '휴가 미설정', palette),
              const SizedBox(width: 6),
              _buildMiniTag('⏳', '남은 휴가 $remainingVacationDays일', palette),
            ],
          ),
        ),
      ],
    );
  }

  /// 3. 아기 카테고리 특화 요약 (태어난 지 N일째 / 개월수 롤링 + 다음 예방접종/검진 D-Day 2개)
  Widget _buildBabyBody(
    BuildContext context,
    WidgetRef ref,
    CategoryThemePalette palette,
  ) {
    BabyProfile? babyProfile;
    if (category.metadata?['babyProfile'] != null) {
      try {
        babyProfile = BabyProfile.fromJson(Map<String, dynamic>.from(category.metadata!['babyProfile'] as Map));
      } catch (_) {}
    }
    final topDdays = countDownItems.take(2).toList();
    const babyController = BabyCategoryController();

    String daysCountText = '태어난 지 1일째';
    String detailedAge = '생후 1개월차';
    if (babyProfile != null) {
      daysCountText = babyController.formatBabyDaysCount(babyProfile.birthDate);
      detailedAge = babyController.formatBabyAgeDetailed(babyProfile.birthDate);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: palette.chipBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                daysCountText,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: palette.primary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: palette.border),
              ),
              child: Text(
                detailedAge,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.text),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (topDdays.isNotEmpty)
          for (final item in topDdays) ...[
            _buildDdayRow(item.title, dDayLabel(item.date), palette),
          ]
        else
          Text(
            '등록된 접종/검진 일정이 없어요',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  /// 4. 시험/자격증 카테고리 특화 요약 (가장 먼저 닥쳐오는 세부 단계 2개)
  Widget _buildExamBody(
    BuildContext context,
    WidgetRef ref,
    CategoryThemePalette palette,
  ) {
    final topDdays = countDownItems.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (countDownItems.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: palette.chipBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '준비 중인 시험 일정 ${countDownItems.length}개',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: palette.primary),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (topDdays.isNotEmpty)
          for (final item in topDdays) ...[
            _buildDdayRow(item.title, dDayLabel(item.date), palette),
          ]
        else
          Text(
            '등록된 시험 일정이 없어요',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  /// 5. 솔로 카테고리 특화 요약 (나에게 집중한 지 N일째 + 자기계발/설렘 D-Day 2개)
  Widget _buildSoloBody(
    BuildContext context,
    WidgetRef ref,
    CategoryThemePalette palette,
  ) {
    SoloProfile? soloProfile;
    if (category.metadata?['soloProfile'] != null) {
      try {
        soloProfile = SoloProfile.fromJson(Map<String, dynamic>.from(category.metadata!['soloProfile'] as Map));
      } catch (_) {}
    }
    final daysSinceStart = soloProfile?.daysCount() ?? (countUpItems.isNotEmpty ? DateTime.now().difference(countUpItems.first.date).inDays : 1);
    final countUpLabel = '나에게 집중한 지 D+$daysSinceStart일째';
    final topDdays = countDownItems.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: palette.chipBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            countUpLabel,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: palette.primary),
          ),
        ),
        const SizedBox(height: 10),
        if (topDdays.isNotEmpty)
          for (final item in topDdays) ...[
            _buildDdayRow(item.title, dDayLabel(item.date), palette),
          ]
        else
          Text(
            '등록된 플랜이 없어요',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  /// 6. 루틴 / 주간 계획표 특화 요약 (다가오는 루틴 일정 스마트 계산 및 뱃지)
  Widget _buildRoutineBody(
    BuildContext context,
    WidgetRef ref,
    CategoryThemePalette palette,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allItems = [...countDownItems, ...countUpItems];

    // Calculate upcoming occurrences for each routine item
    final upcomingList = <({PlanItem item, DateTime targetDateTime, String timeLabel, String badgeText})>[];

    for (final item in allItems) {
      final hour = item.deadlineTime?.hour ?? 0;
      final minute = item.deadlineTime?.minute ?? 0;
      final timeStr = item.deadlineTime != null
          ? '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'
          : '';

      DateTime? nextDate;
      if (item.repeatConfig.type == RepeatType.daily) {
        final candidate = DateTime(today.year, today.month, today.day, hour, minute);
        if (candidate.isAfter(now) || (hour == 0 && minute == 0 && !candidate.isBefore(today))) {
          nextDate = candidate;
        } else {
          nextDate = candidate.add(const Duration(days: 1));
        }
      } else if (item.repeatConfig.type == RepeatType.weekly && item.repeatConfig.weekdays.isNotEmpty) {
        for (int i = 0; i <= 7; i++) {
          final checkDate = today.add(Duration(days: i));
          final checkWd = checkDate.weekday % 7; // 0 for Sunday
          if (item.repeatConfig.weekdays.contains(checkWd) || item.repeatConfig.weekdays.contains(checkDate.weekday)) {
            final cand = DateTime(checkDate.year, checkDate.month, checkDate.day, hour, minute);
            if (cand.isAfter(now) || i > 0) {
              nextDate = cand;
              break;
            }
          }
        }
      }

      nextDate ??= DateTime(item.date.year, item.date.month, item.date.day, hour, minute);

      final diffDays = DateTime(nextDate.year, nextDate.month, nextDate.day).difference(today).inDays;
      String timeLabel;
      String badgeText;

      const weekdaysKo = ['일', '월', '화', '수', '목', '금', '토'];
      final weekdayKo = weekdaysKo[nextDate.weekday % 7];

      if (diffDays == 0) {
        timeLabel = timeStr.isNotEmpty ? '오늘 $timeStr' : '오늘';
        final diffMinutes = nextDate.difference(now).inMinutes;
        if (diffMinutes > 0 && diffMinutes < 60) {
          badgeText = '$diffMinutes분 전';
        } else if (diffMinutes >= 60 && diffMinutes <= 1440) {
          final diffHours = (diffMinutes / 60).floor();
          badgeText = '$diffHours시간 전';
        } else {
          badgeText = '오늘';
        }
      } else if (diffDays == 1) {
        timeLabel = timeStr.isNotEmpty ? '내일 $timeStr' : '내일';
        badgeText = '내일';
      } else {
        timeLabel = timeStr.isNotEmpty ? '$weekdayKo요일 $timeStr' : '$weekdayKo요일';
        badgeText = diffDays > 0 ? 'D-$diffDays' : dDayLabel(item.date);
      }

      upcomingList.add((
        item: item,
        targetDateTime: nextDate,
        timeLabel: timeLabel,
        badgeText: badgeText,
      ));
    }

    upcomingList.sort((a, b) => a.targetDateTime.compareTo(b.targetDateTime));

    final displayList = upcomingList.take(2).toList();
    final todayCount = upcomingList.where((e) {
      return DateTime(e.targetDateTime.year, e.targetDateTime.month, e.targetDateTime.day) == today;
    }).length;

    final topPillText = todayCount > 0 ? '오늘 예정된 루틴 $todayCount개' : '다가오는 루틴 일정';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: palette.chipBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            topPillText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: palette.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (displayList.isNotEmpty)
          for (final entry in displayList) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border.withValues(alpha: 0.8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.item.title,
                          style: AppTypography.caption.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.protoHeading,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (entry.timeLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            entry.timeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: palette.text.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      entry.badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]
        else
          Text(
            '등록된 루틴 일정이 없어요',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  /// 공통 표준 바디 (덕질, 반려동물, 목표, 일정 등)
  Widget _buildStandardBody(CategoryThemePalette palette) {
    final topCountUpPills = <Widget>[];

    if (customCountUpText != null && customCountUpText!.isNotEmpty) {
      topCountUpPills.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: palette.chipBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            customCountUpText!,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: palette.primary),
          ),
        ),
      );
    }

    for (final item in countUpItems.take(2)) {
      if (customCountUpText != null && countUpItems.length == 1) continue;
      topCountUpPills.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: palette.chipBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${item.title} ${_formatDaysCount(item.date)}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: palette.primary),
          ),
        ),
      );
      if (topCountUpPills.length >= 2) break;
    }

    final topDDayItems = countDownItems.take(2).toList();
    final hasNoData = topCountUpPills.isEmpty && topDDayItems.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topCountUpPills.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: topCountUpPills,
          ),
          if (topDDayItems.isNotEmpty) const SizedBox(height: 10),
        ],
        if (topDDayItems.isNotEmpty) ...[
          for (final item in topDDayItems) ...[
            _buildDdayRow(item.title, dDayLabel(item.date), palette),
          ],
        ] else if (hasNoData) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '등록된 디데이 일정이 없어요',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDdayRow(String title, String dDayText, CategoryThemePalette palette) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.caption.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.protoHeading,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: palette.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              dDayText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String emoji, String text, CategoryThemePalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: palette.text),
          ),
        ],
      ),
    );
  }
}
