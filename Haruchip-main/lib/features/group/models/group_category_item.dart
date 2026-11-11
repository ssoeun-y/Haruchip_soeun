import 'package:flutter/material.dart';

/// 모임(Group) 카테고리 개별 모임 데이터 모델
@immutable
class GroupCategoryItem {
  const GroupCategoryItem({
    required this.id,
    required this.name,
    this.icon = '👥',
    this.imagePath,
    required this.foundationDate,
    this.regularScheduleInfo = '매월 둘째 주 토요일',
    this.themeColorHex = '#FFF5F2',
    this.memo,
    required this.createdAt,
    this.memberCount = 1,
  });

  final String id;
  final String name;
  final String icon;
  final String? imagePath;
  final DateTime foundationDate;
  final String regularScheduleInfo;
  final String themeColorHex;
  final String? memo;
  final DateTime createdAt;
  final int memberCount;

  /// 모임 결성일 기준 경과 일수 (결성일을 1일째로 계산)
  int daysSinceFoundation([DateTime? now]) {
    final current = now ?? DateTime.now();
    final start = DateTime(foundationDate.year, foundationDate.month, foundationDate.day);
    final today = DateTime(current.year, current.month, current.day);
    final diff = today.difference(start).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }

  /// N일째 라벨 (ex. "모임 450일째")
  String daysCountText([DateTime? now]) {
    final days = daysSinceFoundation(now);
    return '모임 $days일째';
  }

  /// 포맷된 결성일 문자열 (ex. "2025.08.10 결성")
  String get formattedFoundationDate {
    final y = foundationDate.year;
    final m = foundationDate.month.toString().padLeft(2, '0');
    final d = foundationDate.day.toString().padLeft(2, '0');
    return '$y.$m.$d 결성';
  }

  GroupCategoryItem copyWith({
    String? id,
    String? name,
    String? icon,
    String? imagePath,
    DateTime? foundationDate,
    String? regularScheduleInfo,
    String? themeColorHex,
    String? memo,
    DateTime? createdAt,
    int? memberCount,
  }) {
    return GroupCategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      imagePath: imagePath ?? this.imagePath,
      foundationDate: foundationDate ?? this.foundationDate,
      regularScheduleInfo: regularScheduleInfo ?? this.regularScheduleInfo,
      themeColorHex: themeColorHex ?? this.themeColorHex,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'imagePath': imagePath,
      'foundationDate': foundationDate.toIso8601String(),
      'regularScheduleInfo': regularScheduleInfo,
      'themeColorHex': themeColorHex,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
      'memberCount': memberCount,
    };
  }

  factory GroupCategoryItem.fromJson(Map<String, dynamic> json) {
    return GroupCategoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: (json['icon'] as String?) ?? '👥',
      imagePath: json['imagePath'] as String?,
      foundationDate: DateTime.parse(json['foundationDate'] as String),
      regularScheduleInfo: (json['regularScheduleInfo'] as String?) ?? '매월 둘째 주 토요일',
      themeColorHex: (json['themeColorHex'] as String?) ?? '#FFF5F2',
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      memberCount: (json['memberCount'] as int?) ?? 1,
    );
  }
}

/// 모임 세부 D-Day 일정 (정기 / 번개 모임) 데이터 모델
@immutable
class GroupMeetingScheduleItem {
  const GroupMeetingScheduleItem({
    required this.id,
    required this.groupId,
    required this.title,
    required this.dateTime,
    this.location = '장소 미정',
    this.isAttending,
    this.isRegular = true,
    this.recurringRule,
    this.memo,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String title;
  final DateTime dateTime;
  final String location;
  /// true: 참석, false: 불참, null: 미정
  final bool? isAttending;
  final bool isRegular;
  final String? recurringRule;
  final String? memo;
  final DateTime createdAt;

  /// 일정이 완전히 지난 과거 일정인지 여부
  bool get isPassed {
    return dateTime.isBefore(DateTime.now());
  }

  /// D-Day 카운트 (미래는 양수, 오늘은 0, 과거는 음수)
  int dDayCount([DateTime? now]) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return target.difference(today).inDays;
  }

  /// D-Day 라벨 텍스트 (ex. "D-Day", "D-7", "D+3")
  String dDayText([DateTime? now]) {
    final days = dDayCount(now);
    if (days == 0) return 'D-Day';
    if (days > 0) return 'D-$days';
    return 'D+${days.abs()}';
  }

  /// 포맷된 일시 문자열 (ex. "2026.11.14 (토) 오후 6:00")
  String get formattedDateTime {
    final y = dateTime.year;
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayStr = weekdays[dateTime.weekday - 1];

    final isPm = dateTime.hour >= 12;
    final hour12 = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final min = dateTime.minute.toString().padLeft(2, '0');
    final amPm = isPm ? '오후' : '오전';

    return '$y.$m.$d ($weekdayStr) $amPm $hour12:$min';
  }

  /// 참석 상태 라벨 (ex. "참여 예정", "불참", "미정")
  String get attendanceLabel {
    if (isAttending == true) return '참여 예정';
    if (isAttending == false) return '불참';
    return '미정';
  }

  GroupMeetingScheduleItem copyWith({
    String? id,
    String? groupId,
    String? title,
    DateTime? dateTime,
    String? location,
    bool? isAttending,
    bool clearAttendance = false,
    bool? isRegular,
    String? recurringRule,
    String? memo,
    DateTime? createdAt,
  }) {
    return GroupMeetingScheduleItem(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      isAttending: clearAttendance ? null : (isAttending ?? this.isAttending),
      isRegular: isRegular ?? this.isRegular,
      recurringRule: recurringRule ?? this.recurringRule,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'isAttending': isAttending,
      'isRegular': isRegular,
      'recurringRule': recurringRule,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GroupMeetingScheduleItem.fromJson(Map<String, dynamic> json) {
    return GroupMeetingScheduleItem(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      title: json['title'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      location: (json['location'] as String?) ?? '장소 미정',
      isAttending: json['isAttending'] as bool?,
      isRegular: (json['isRegular'] as bool?) ?? true,
      recurringRule: json['recurringRule'] as String?,
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
