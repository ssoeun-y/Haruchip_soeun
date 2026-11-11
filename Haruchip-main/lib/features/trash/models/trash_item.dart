import 'package:flutter/material.dart';

/// 휴지통 엔티티 유형
enum TrashEntityType {
  plan('일정 / D-Day', '📅', Color(0xFF0284C7)),
  goal('목표 / 버킷리스트', '🎯', Color(0xFFD97706)),
  appointment('약속 / 플랜', '🤝', Color(0xFF4F46E5)),
  routine('루틴 / 주간 계획', '🔄', Color(0xFF059669)),
  diary('다이어리 / 기록', '📝', Color(0xFFDB2777)),
  settlement('모임 정산 영수증', '💰', Color(0xFF7C3AED)),
  notice('모임 공지사항', '📢', Color(0xFFDC2626)),
  vote('모임 투표', '🗳️', Color(0xFF0891B2)),
  event('모임 공유 일정', '🗓️', Color(0xFF2563EB)),
  room('모임 방', '👥', Color(0xFF0D9488)),
  category('카테고리', '🏷️', Color(0xFF475569)),
  exam('시험 일정', '📚', Color(0xFF4F46E5)),
  birthday('생일 친구', '🎂', Color(0xFFEC4899));

  const TrashEntityType(this.labelKo, this.emoji, this.color);

  final String labelKo;
  final String emoji;
  final Color color;

  String toJson() => name;

  static TrashEntityType fromJson(String? value) {
    return TrashEntityType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TrashEntityType.plan,
    );
  }
}

/// 30일 복구 보존 휴지통 아이템 모델
@immutable
class TrashItem {
  const TrashItem({
    required this.id,
    required this.entityType,
    required this.originalTitle,
    required this.deletedAt,
    required this.originalData,
    this.categoryKey,
    this.roomId,
    this.authorName,
  });

  final String id;
  final TrashEntityType entityType;
  final String originalTitle;
  final DateTime deletedAt;
  final Map<String, dynamic> originalData;
  final String? categoryKey;
  final String? roomId;
  final String? authorName;

  /// 최초 삭제일 기준 30일 보존 후 남은 일수 (0~30)
  int get daysRemaining {
    final now = DateTime.now();
    final diff = now.difference(deletedAt).inDays;
    final remaining = 30 - diff;
    return remaining < 0 ? 0 : (remaining > 30 ? 30 : remaining);
  }

  /// D-Day 라벨 (예: D-28, D-1, D-Day)
  String get daysRemainingLabel {
    final rem = daysRemaining;
    if (rem <= 0) return 'D-Day (오늘 영구 삭제 예정)';
    return '남은 복구 기간 D-$rem';
  }

  /// 남은 보관 일수 라벨 (ex. "28일 남음")
  String get remainingDaysText {
    final rem = daysRemaining;
    if (rem <= 0) return '오늘 만료 예정';
    return '$rem일 남음';
  }

  /// 30일 만료 여부 (영구 Purge 대상)
  bool get isExpired => daysRemaining <= 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType.toJson(),
        'originalTitle': originalTitle,
        'deletedAt': deletedAt.toIso8601String(),
        'originalData': originalData,
        'categoryKey': categoryKey,
        'roomId': roomId,
        'authorName': authorName,
      };

  factory TrashItem.fromJson(Map<String, dynamic> json) {
    return TrashItem(
      id: json['id'] as String? ?? 'trash-${DateTime.now().microsecondsSinceEpoch}',
      entityType: TrashEntityType.fromJson(json['entityType'] as String?),
      originalTitle: json['originalTitle'] as String? ?? '무제 항목',
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : DateTime.now(),
      originalData: json['originalData'] is Map
          ? Map<String, dynamic>.from(json['originalData'] as Map)
          : {},
      categoryKey: json['categoryKey'] as String?,
      roomId: json['roomId'] as String?,
      authorName: json['authorName'] as String?,
    );
  }
}
