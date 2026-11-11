import 'package:flutter/foundation.dart';
import '../data/baby_health_database.dart';
import '../models/baby_profile.dart';

/// 아기 성장 마일스톤 정보
@immutable
class BabyMilestoneInfo {
  const BabyMilestoneInfo({
    required this.targetDays,
    required this.label,
    required this.targetDate,
    required this.daysLeft,
    required this.description,
    required this.isReached,
    this.checklist = const [],
  });

  final int targetDays;
  final String label;
  final DateTime targetDate;
  final int daysLeft;
  final String description;
  final bool isReached;
  final List<String> checklist;
}

/// 수유 텀 카운트다운 상태
@immutable
class BabyFeedingCountdownStatus {
  const BabyFeedingCountdownStatus({
    required this.lastFeedingTime,
    required this.nextFeedingTime,
    required this.statusText,
    required this.isOverdue,
    required this.isDueNow,
    required this.remainingMinutes,
  });

  final DateTime? lastFeedingTime;
  final DateTime? nextFeedingTime;
  final String statusText;
  final bool isOverdue;
  final bool isDueNow;
  final int remainingMinutes;
}

/// 아기 카테고리 컨트롤러 (타임로그, 예방접종, 건강검진, 성장 마일스톤 연산 엔진)
class BabyCategoryController {
  const BabyCategoryController();

  /// 1. '태어난 지 N일째' 계산 (출생 당일 = 1일째)
  String formatBabyDaysCount(DateTime birthDate, [DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);

    final totalDays = today.difference(birth).inDays + 1;
    if (totalDays <= 0) {
      final daysUntil = birth.difference(today).inDays;
      return '출생 예정 (D-$daysUntil)';
    }
    return '태어난 지 $totalDays일째';
  }

  /// 2. '생후 N개월 N일차 (N주 N일)' 상세 월령 텍스트 생성
  /// 예: '생후 4개월 5일차 (18주 2일)'
  String formatBabyAgeDetailed(DateTime birthDate, [DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);

    final totalDays = today.difference(birth).inDays + 1;
    if (totalDays <= 0) return '출생 전';

    var months = (today.year - birth.year) * 12 + (today.month - birth.month);
    if (today.day < birth.day) months -= 1;
    if (months < 0) months = 0;

    // Anchor date calculation
    var anchorYear = birth.year;
    var anchorMonth = birth.month + months;
    while (anchorMonth > 12) {
      anchorYear += 1;
      anchorMonth -= 12;
    }
    // Handle days overflow in target month
    final daysInMonth = DateTime(anchorYear, anchorMonth + 1, 0).day;
    final safeAnchorDay = birth.day > daysInMonth ? daysInMonth : birth.day;
    final anchorDate = DateTime(anchorYear, anchorMonth, safeAnchorDay);

    final remainderDays = today.difference(anchorDate).inDays;
    final totalElapsedDays = totalDays - 1; // 0-indexed for weeks
    final weeks = totalElapsedDays ~/ 7;
    final remainderWeekDays = totalElapsedDays % 7;

    return '생후 $months개월 ${remainderDays < 0 ? 0 : remainderDays}일차 ($weeks주 $remainderWeekDays일)';
  }

  /// 3. 실시간 수유텀 카운트다운 연산
  BabyFeedingCountdownStatus calculateNextFeeding(
    List<BabyCareLogItem> logs,
    int feedingIntervalHours, [
    DateTime? relativeTo,
  ]) {
    final now = relativeTo ?? DateTime.now();
    final feedingLogs = logs
        .where((l) => l.type == BabyCareLogType.feeding)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (feedingLogs.isEmpty) {
      return const BabyFeedingCountdownStatus(
        lastFeedingTime: null,
        nextFeedingTime: null,
        statusText: '수유 기록 없음',
        isOverdue: false,
        isDueNow: false,
        remainingMinutes: 0,
      );
    }

    final last = feedingLogs.first;
    final interval = feedingIntervalHours > 0 ? feedingIntervalHours : 3;
    final nextTime = last.timestamp.add(Duration(hours: interval));
    final diff = nextTime.difference(now);
    final diffMinutes = diff.inMinutes;

    if (diffMinutes > 10) {
      final hours = diffMinutes ~/ 60;
      final mins = diffMinutes % 60;
      final timeStr = hours > 0 ? '$hours시간 $mins분 전' : '$mins분 전';
      return BabyFeedingCountdownStatus(
        lastFeedingTime: last.timestamp,
        nextFeedingTime: nextTime,
        statusText: '다음 수유까지 $timeStr',
        isOverdue: false,
        isDueNow: false,
        remainingMinutes: diffMinutes,
      );
    } else if (diffMinutes >= -10) {
      return BabyFeedingCountdownStatus(
        lastFeedingTime: last.timestamp,
        nextFeedingTime: nextTime,
        statusText: '수유 시간 도래 (D-0)',
        isOverdue: false,
        isDueNow: true,
        remainingMinutes: diffMinutes,
      );
    } else {
      final overdueMinutes = diffMinutes.abs();
      final hours = overdueMinutes ~/ 60;
      final mins = overdueMinutes % 60;
      final overdueStr = hours > 0 ? '$hours시간 $mins분' : '$mins분';
      return BabyFeedingCountdownStatus(
        lastFeedingTime: last.timestamp,
        nextFeedingTime: nextTime,
        statusText: '수유 텀 $overdueStr 초과 ⚠️',
        isOverdue: true,
        isDueNow: false,
        remainingMinutes: diffMinutes,
      );
    }
  }

  /// 4. 예방접종 권장 예정일 및 D-Day 계산
  DateTime calculateVaccineTargetDate(DateTime birthDate, int recommendedAgeMonths) {
    if (recommendedAgeMonths == 0) {
      return birthDate;
    }
    var targetYear = birthDate.year;
    var targetMonth = birthDate.month + recommendedAgeMonths;
    while (targetMonth > 12) {
      targetYear += 1;
      targetMonth -= 12;
    }
    final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final safeDay = birthDate.day > daysInMonth ? daysInMonth : birthDate.day;
    return DateTime(targetYear, targetMonth, safeDay);
  }

  /// 질병관리청(KCDA) 표준 가이드라인에 맞춘 세부 백신별 권장일자 산출
  DateTime calculateVaccineDoseTargetDate(DateTime birthDate, VaccineDose dose) {
    if (dose.id == 'vac-bcg-1') {
      // BCG: 생후 4주 이내 (28일)
      return birthDate.add(const Duration(days: 28));
    }
    if (dose.id == 'vac-hepb-1') {
      // B형간염 1차: 출생 당일 (24시간 이내)
      return birthDate;
    }
    return calculateVaccineTargetDate(birthDate, dose.recommendedAgeMonths);
  }

  /// 5. 성장 마일스톤 D-Day 리스트 생성
  List<BabyMilestoneInfo> getGrowthMilestones(DateTime birthDate, [DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);

    final totalDays = today.difference(birth).inDays + 1;
    final result = <BabyMilestoneInfo>[];

    for (final milestone in kBabyGrowthMilestones) {
      final targetDate = birth.add(Duration(days: milestone.days - 1));
      final daysLeft = milestone.days - totalDays;

      result.add(
        BabyMilestoneInfo(
          targetDays: milestone.days,
          label: milestone.label,
          targetDate: targetDate,
          daysLeft: daysLeft < 0 ? 0 : daysLeft,
          description: milestone.description,
          isReached: totalDays >= milestone.days,
        ),
      );
    }

    return result;
  }
}
