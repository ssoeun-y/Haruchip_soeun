import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../categories/controllers/baby_category_controller.dart';
import '../../categories/logic/repeat_rule.dart';
import '../../categories/models/baby_profile.dart';
import '../../categories/models/category.dart';
import '../../categories/models/solo_profile.dart';
import '../../categories/widgets/skin_theme_card_container.dart';
import '../../couple/providers/couple_provider.dart';
import '../../hobby/providers/hobby_provider.dart';
import '../../military/providers/military_provider.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart' show dDayLabel;
import '../../travel/providers/travel_provider.dart';
import '../../wedding/providers/wedding_provider.dart';

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
          bg: Color(0xFFFFF0F3),
          border: Color(0xFFFFCCD5),
          chipBg: Color(0xFFFFCCD5),
          primary: Color(0xFFFF7A9C),
          text: Color(0xFF4A4A4A),
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
      case 'custom':
        return const CategoryThemePalette(
          bg: Color(0xFFF8F9FA),
          border: Color(0xFFE9ECEF),
          chipBg: Color(0xFFE9ECEF),
          primary: Color(0xFF6C757D),
          text: Color(0xFF343A40),
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
      case 'hobby':
        return const CategoryThemePalette(
          bg: Color(0xFFF4F7F4),
          border: Color(0xFFDDE7DD),
          chipBg: Color(0xFFDDE7DD),
          primary: Color(0xFF354235),
          text: Color(0xFF354235),
        );
      case 'travel':
        return const CategoryThemePalette(
          bg: Color(0xFFF0F8FF),
          border: Color(0xFFD6ECFF),
          chipBg: Color(0xFFD6ECFF),
          primary: Color(0xFF2C3E50),
          text: Color(0xFF2C3E50),
        );
      case 'wedding':
        return const CategoryThemePalette(
          bg: Color(0xFFFFF5F5),
          border: Color(0xFFFED7D7),
          chipBg: Color(0xFFFED7D7),
          primary: Color(0xFFE53E3E),
          text: Color(0xFF742A2A),
        );
      case 'plan':
      default:
        return const CategoryThemePalette(
          bg: Color(0xFFF8F9FA),
          border: Color(0xFFE9ECEF),
          chipBg: Color(0xFFE9ECEF),
          primary: Color(0xFF495057),
          text: Color(0xFF343A40),
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
    final skinTheme = category.skinTheme;
    final defaultPalette = CategoryThemePalette.forCategoryKey(category.categoryKey);
    final palette = skinTheme != null
        ? CategoryThemePalette(
            bg: colorFromHex(skinTheme.backgroundColor),
            border: colorFromHex(skinTheme.borderColor),
            chipBg: colorFromHex(skinTheme.patternColor).withValues(alpha: 0.28),
            primary: colorFromHex(skinTheme.borderColor),
            text: colorFromHex(skinTheme.textColor),
          )
        : defaultPalette;

    final key = category.categoryKey;
    final displayIcon = skinTheme?.accentEmoji.isNotEmpty == true ? skinTheme!.accentEmoji : category.icon;

    final cardContent = Column(
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
              child: Text(displayIcon, style: const TextStyle(fontSize: 16)),
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
        else if (key == 'hobby')
          _buildHobbyBody(context, ref, palette)
        else if (key == 'travel')
          _buildTravelBody(context, ref, palette)
        else if (key == 'wedding')
          _buildWeddingBody(context, ref, palette)
        else
          _buildStandardBody(palette),
      ],
    );

    if (skinTheme != null) {
      return InkWell(
        onTap: isEditMode ? null : onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(skinTheme.borderRadius),
        child: SkinThemeCardContainer(
          theme: skinTheme,
          padding: const EdgeInsets.all(16),
          child: cardContent,
        ),
      );
    }

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
        child: cardContent,
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

  /// 7. 취미 카테고리 특화 요약 (시작일 기준 N일째 또는 가장 가까운 일정 D-Day)
  Widget _buildHobbyBody(
    BuildContext context,
    WidgetRef ref,
    CategoryThemePalette palette,
  ) {
    // 하위 호환성: 레거시 테스트에서 metadata['completedCount']를 명시한 경우
    final legacyCompletedCount = category.metadata?['completedCount'] as int?;
    if (legacyCompletedCount != null) {
      final now = DateTime.now();
      final topCountUp = countUpItems.isNotEmpty ? countUpItems.first : null;
      final topCountDown = countDownItems.isNotEmpty ? countDownItems.first : null;

      final String mainDdayText;
      if (topCountDown != null) {
        mainDdayText = '${topCountDown.title} ${dDayLabel(topCountDown.date)}';
      } else if (topCountUp != null) {
        final days = now.difference(topCountUp.date).inDays + 1;
        mainDdayText = '${category.name} 시작한 지 $days일째';
      } else {
        mainDdayText = '${category.name} 진행 중';
      }

      final topDdays = countDownItems.take(2).toList();
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
                  mainDdayText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: palette.primary,
                  ),
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
                  '이번 달 $legacyCompletedCount회 완료',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
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
              '등록된 목표 일정이 없어요',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
        ],
      );
    }

    final now = DateTime.now();
    final nextScheduleData = ref.watch(nextHobbyScheduleProvider);
    final longestHobby = ref.watch(longestRunningHobbyProvider);

    final String chipText;
    final String? subChipText;
    final String? scheduleRowTitle;
    final String? scheduleRowBadge;

    if (nextScheduleData != null) {
      chipText = '${nextScheduleData.hobby.icon} ${nextScheduleData.schedule.title} ${nextScheduleData.schedule.dDayBadge(now)}';
      subChipText = '${nextScheduleData.hobby.name} ${nextScheduleData.hobby.daysSinceStartText(now)}';
      scheduleRowTitle = nextScheduleData.schedule.location != null
          ? '${nextScheduleData.schedule.title} (📍 ${nextScheduleData.schedule.location})'
          : nextScheduleData.schedule.title;
      scheduleRowBadge = nextScheduleData.schedule.dDayBadge(now);
    } else if (longestHobby != null) {
      chipText = '${longestHobby.icon} ${longestHobby.name} ${longestHobby.daysSinceStartText(now)}';
      subChipText = longestHobby.formattedStartDate;
      scheduleRowTitle = null;
      scheduleRowBadge = null;
    } else {
      chipText = '${category.name} 진행 중';
      subChipText = null;
      scheduleRowTitle = null;
      scheduleRowBadge = null;
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
                chipText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: palette.primary,
                ),
              ),
            ),
            if (subChipText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  subChipText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (scheduleRowTitle != null && scheduleRowBadge != null)
          _buildDdayRow(scheduleRowTitle, scheduleRowBadge, palette)
        else
          Text(
            '등록된 다음 취미 일정이 없어요',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  /// 8. 여행 카테고리 특화 요약 (현재 진행 중이거나 가장 가까운 여행 1개 우선 노출 & 짐 싸기 진행률)
  Widget _buildTravelBody(
    BuildContext context,
    WidgetRef ref,
    CategoryThemePalette palette,
  ) {
    final hasMetadataStartDate = category.metadata?['startDate'] != null;
    final nextTrip = ref.watch(nextTripProvider);

    if (!hasMetadataStartDate && nextTrip != null) {
      final isOngoing = nextTrip.isOngoing();
      final String travelStatusText;
      if (isOngoing) {
        travelStatusText = '${nextTrip.destination} ${nextTrip.currentDayNumber()}일차';
      } else {
        travelStatusText = '다음 여행: ${nextTrip.emoji} ${nextTrip.destination} ${nextTrip.dDayBadge()}';
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
                  travelStatusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: palette.primary,
                  ),
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
                  nextTrip.dateRangeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildMiniTag('🎒', '짐 싸기 ${nextTrip.packingProgressText} (${(nextTrip.packingProgress * 100).toInt()}%)', palette),
          if (nextTrip.daySchedules.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildDdayRow(nextTrip.daySchedules.first.title, 'Day 1', palette),
          ],
        ],
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? startDate;
    DateTime? endDate;

    if (category.metadata?['startDate'] != null) {
      try {
        startDate = DateTime.parse(category.metadata!['startDate'] as String);
      } catch (_) {}
    }
    if (category.metadata?['endDate'] != null) {
      try {
        endDate = DateTime.parse(category.metadata!['endDate'] as String);
      } catch (_) {}
    }

    if (startDate == null && countDownItems.isNotEmpty) {
      startDate = countDownItems.first.date;
    }
    if (startDate == null && countUpItems.isNotEmpty) {
      startDate = countUpItems.first.date;
    }

    final String travelStatusText;
    if (startDate != null) {
      final sDate = DateTime(startDate.year, startDate.month, startDate.day);
      final eDate = endDate != null
          ? DateTime(endDate.year, endDate.month, endDate.day)
          : sDate.add(const Duration(days: 3));

      if (today.isBefore(sDate)) {
        final diff = sDate.difference(today).inDays;
        travelStatusText = diff == 0 ? '오늘 출발 D-Day' : '출발 D-$diff';
      } else if (!today.isAfter(eDate)) {
        final currentDay = today.difference(sDate).inDays + 1;
        travelStatusText = '여행 $currentDay일차';
      } else {
        final pastDays = today.difference(eDate).inDays;
        travelStatusText = '다녀온 지 $pastDays일째';
      }
    } else {
      travelStatusText = '설레는 여행 준비 중';
    }

    final String periodText;
    if (startDate != null) {
      final s = '${startDate.year}.${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')}';
      if (endDate != null) {
        final e = '${endDate.year}.${endDate.month.toString().padLeft(2, '0')}.${endDate.day.toString().padLeft(2, '0')}';
        periodText = '$s ~ $e';
      } else {
        periodText = '$s 출발';
      }
    } else {
      periodText = '여행 일정 미정';
    }

    final topDdays = countDownItems.take(2).toList();

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
                travelStatusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: palette.primary,
                ),
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
                periodText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
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
            '등록된 세부 일정이 없어요',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  /// 9. 결혼 준비 카테고리 특화 요약 (본식 D-N일, 57개 개별 항목 체크리스트 달성률 프로그레스 바, 최우선 임박 일정)
  Widget _buildWeddingBody(
    BuildContext context,
    WidgetRef ref,
    CategoryThemePalette palette,
  ) {
    final weddingDate = ref.watch(weddingDateProvider);
    final stats = ref.watch(weddingStatsProvider);
    final items = ref.watch(weddingListProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final String mainDdayText;
    if (weddingDate != null) {
      final wDate = DateTime(weddingDate.year, weddingDate.month, weddingDate.day);
      if (today.isBefore(wDate)) {
        final diff = wDate.difference(today).inDays;
        mainDdayText = '본식 D-$diff';
      } else if (today.isAtSameMomentAs(wDate)) {
        mainDdayText = '오늘 본식 D-Day';
      } else {
        final past = today.difference(wDate).inDays;
        mainDdayText = '결혼한 지 $past일째';
      }
    } else {
      mainDdayText = '예식일 설정하기';
    }

    // Upcoming uncompleted items with targetDate
    final upcomingItems = items
        .where((i) => !i.isCompleted && i.targetDate != null)
        .toList()
      ..sort((a, b) => a.targetDate!.compareTo(b.targetDate!));

    final displayItems = upcomingItems.isNotEmpty
        ? upcomingItems.take(2).toList()
        : items.where((i) => !i.isCompleted).take(2).toList();

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
                mainDdayText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: palette.primary,
                ),
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
                '${stats.completed}/${stats.total} 완료 (${(stats.ratio * 100).toInt()}%)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: stats.ratio,
            backgroundColor: palette.border,
            valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 10),
        if (displayItems.isNotEmpty)
          for (final item in displayItems) ...[
            _buildDdayRow(
              item.title,
              item.targetDate != null ? item.dDayLabel() : '미정',
              palette,
            ),
          ]
        else
          Text(
            '모든 결혼 준비를 마쳤어요 🎉',
            style: TextStyle(
              fontSize: 12,
              color: palette.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
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
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: palette.text),
            ),
          ),
        ],
      ),
    );
  }
}
