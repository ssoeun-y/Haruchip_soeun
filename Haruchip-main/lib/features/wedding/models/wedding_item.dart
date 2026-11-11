import 'package:flutter/material.dart' show TimeOfDay;

/// 결혼 준비 6대 주요 진행 단계
enum WeddingStage {
  hallAndPlanner('상견례 및 웨딩홀/플래너', '🏛️', 1),
  studimeAndRing('스드메 및 웨딩밴드', '💍', 2),
  studioShoot('스튜디오 촬영 및 셀렉', '📸', 3),
  houseAndLiving('신혼집 및 혼수/가전/가구', '🛋️', 4),
  invitationAndGuest('청첩장 및 하객 준비', '💌', 5),
  finalCheckAndCeremony('본식 최종 점검 및 예식', '👰', 6);

  const WeddingStage(this.labelKo, this.emoji, this.order);

  final String labelKo;
  final String emoji;
  final int order;
}

/// 단일 결혼 준비 체크리스트 항목 모델 (1:1 개별 분리)
class WeddingItem {
  WeddingItem({
    required this.id,
    required this.orderIndex,
    required this.title,
    required this.standardOffsetDays,
    required this.stage,
    this.targetDate,
    this.deadlineTime,
    this.isCompleted = false,
    this.completedAt,
    this.location = '',
    this.memo = '',
    this.budget,
    this.actualCost,
    this.isWeekdayPreferred = false,
    this.weekdayNotice,
    this.syncedPlanId,
  });

  final String id;
  final int orderIndex;
  final String title;
  final int standardOffsetDays;
  final WeddingStage stage;
  final DateTime? targetDate;
  final TimeOfDay? deadlineTime;
  final bool isCompleted;
  final DateTime? completedAt;
  final String location;
  final String memo;
  final int? budget;
  final int? actualCost;
  final bool isWeekdayPreferred;
  final String? weekdayNotice;
  final String? syncedPlanId;

  WeddingItem copyWith({
    String? id,
    int? orderIndex,
    String? title,
    int? standardOffsetDays,
    WeddingStage? stage,
    DateTime? targetDate,
    TimeOfDay? deadlineTime,
    bool? isCompleted,
    DateTime? completedAt,
    String? location,
    String? memo,
    int? budget,
    int? actualCost,
    bool? isWeekdayPreferred,
    String? weekdayNotice,
    String? syncedPlanId,
    bool clearDate = false,
    bool clearTime = false,
  }) {
    return WeddingItem(
      id: id ?? this.id,
      orderIndex: orderIndex ?? this.orderIndex,
      title: title ?? this.title,
      standardOffsetDays: standardOffsetDays ?? this.standardOffsetDays,
      stage: stage ?? this.stage,
      targetDate: clearDate ? null : (targetDate ?? this.targetDate),
      deadlineTime: clearTime ? null : (deadlineTime ?? this.deadlineTime),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      location: location ?? this.location,
      memo: memo ?? this.memo,
      budget: budget ?? this.budget,
      actualCost: actualCost ?? this.actualCost,
      isWeekdayPreferred: isWeekdayPreferred ?? this.isWeekdayPreferred,
      weekdayNotice: weekdayNotice ?? this.weekdayNotice,
      syncedPlanId: syncedPlanId ?? this.syncedPlanId,
    );
  }

  /// 실시간 D-Day 및 당일 시간 잔여 카운트다운 텍스트 계산
  String dDayLabel({DateTime? relativeNow}) {
    if (targetDate == null) return '날짜 미정';

    final now = relativeNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate!.year, targetDate!.month, targetDate!.day);

    final diffDays = target.difference(today).inDays;

    if (diffDays > 0) {
      return 'D-$diffDays';
    } else if (diffDays < 0) {
      return 'D+${diffDays.abs()}';
    } else {
      // 당일 도달 시 실시간 잔여 시간 계산
      if (deadlineTime != null) {
        final targetDateTime = DateTime(
          target.year,
          target.month,
          target.day,
          deadlineTime!.hour,
          deadlineTime!.minute,
        );
        final diffMinutes = targetDateTime.difference(now).inMinutes;

        if (diffMinutes > 0) {
          final hours = diffMinutes ~/ 60;
          final mins = diffMinutes % 60;
          if (hours > 0) {
            return 'D-Day (${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} 남음)';
          } else {
            return 'D-Day ($mins분 남음)';
          }
        } else {
          return '시간 경과 (완료 체크 권장)';
        }
      }
      return 'D-Day';
    }
  }

  /// 포맷된 날짜/시간 문자열 (ex. "2026.05.16 14:00" 또는 "2026.05.16")
  String get formattedDateTime {
    if (targetDate == null) return '일정 미지정';
    final dateStr =
        '${targetDate!.year}.${targetDate!.month.toString().padLeft(2, '0')}.${targetDate!.day.toString().padLeft(2, '0')}';
    if (deadlineTime != null) {
      final hourStr = deadlineTime!.hour.toString().padLeft(2, '0');
      final minuteStr = deadlineTime!.minute.toString().padLeft(2, '0');
      return '$dateStr $hourStr:$minuteStr';
    }
    return dateStr;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderIndex': orderIndex,
      'title': title,
      'standardOffsetDays': standardOffsetDays,
      'stage': stage.name,
      'targetDate': targetDate?.toIso8601String(),
      'deadlineTime': deadlineTime != null
          ? {'hour': deadlineTime!.hour, 'minute': deadlineTime!.minute}
          : null,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'location': location,
      'memo': memo,
      'budget': budget,
      'actualCost': actualCost,
      'isWeekdayPreferred': isWeekdayPreferred,
      'weekdayNotice': weekdayNotice,
      'syncedPlanId': syncedPlanId,
    };
  }

  factory WeddingItem.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parsedTime;
    if (json['deadlineTime'] != null) {
      final map = Map<String, dynamic>.from(json['deadlineTime'] as Map);
      parsedTime = TimeOfDay(
        hour: map['hour'] as int? ?? 0,
        minute: map['minute'] as int? ?? 0,
      );
    }

    return WeddingItem(
      id: json['id'] as String,
      orderIndex: json['orderIndex'] as int? ?? 1,
      title: json['title'] as String,
      standardOffsetDays: json['standardOffsetDays'] as int? ?? 0,
      stage: WeddingStage.values.firstWhere(
        (s) => s.name == json['stage'],
        orElse: () => WeddingStage.hallAndPlanner,
      ),
      targetDate: json['targetDate'] != null
          ? DateTime.tryParse(json['targetDate'] as String)
          : null,
      deadlineTime: parsedTime,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      location: json['location'] as String? ?? '',
      memo: json['memo'] as String? ?? '',
      budget: json['budget'] as int?,
      actualCost: json['actualCost'] as int?,
      isWeekdayPreferred: json['isWeekdayPreferred'] as bool? ?? false,
      weekdayNotice: json['weekdayNotice'] as String?,
      syncedPlanId: json['syncedPlanId'] as String?,
    );
  }
}
