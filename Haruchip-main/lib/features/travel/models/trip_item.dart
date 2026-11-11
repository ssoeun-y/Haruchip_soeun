import 'package:flutter/material.dart';

/// 단일 여행 가방 싸기(체크리스트) 항목 모델
class PackingCheckItem {
  const PackingCheckItem({
    required this.id,
    required this.title,
    this.category = '기타',
    this.isChecked = false,
  });

  final String id;
  final String title;
  final String category;
  final bool isChecked;

  PackingCheckItem copyWith({
    String? id,
    String? title,
    String? category,
    bool? isChecked,
  }) {
    return PackingCheckItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'isChecked': isChecked,
  };

  factory PackingCheckItem.fromJson(Map<String, dynamic> json) => PackingCheckItem(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String? ?? '기타',
    isChecked: json['isChecked'] as bool? ?? false,
  );
}

/// 여행 일자별(Day 1, Day 2...) 세부 일정 항목 모델
class DayScheduleItem {
  const DayScheduleItem({
    required this.id,
    required this.dayNumber,
    this.date,
    this.time,
    required this.title,
    this.location,
    this.reservationCode,
    this.memo,
  });

  final String id;
  final int dayNumber;
  final DateTime? date;
  final String? time; // '09:30', '14:00'
  final String title;
  final String? location;
  final String? reservationCode;
  final String? memo;

  /// 당일 잔여 시간 카운트다운 라벨 생성 (ex: "탑승까지 02:40 남음")
  String? countdownLabel([DateTime? customNow]) {
    if (time == null) return null;
    final now = customNow ?? DateTime.now();

    final parts = time!.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    final targetDate = date ?? now;
    final targetDateTime = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);

    // 같은 날짜인지 확인
    final isSameDate = now.year == targetDate.year &&
        now.month == targetDate.month &&
        now.day == targetDate.day;

    if (!isSameDate) return null;

    final diff = targetDateTime.difference(now);
    if (diff.isNegative) {
      return '일정 진행 완료';
    }

    final hoursLeft = diff.inHours;
    final minutesLeft = diff.inMinutes % 60;
    final formattedTime = '${hoursLeft.toString().padLeft(2, '0')}:${minutesLeft.toString().padLeft(2, '0')}';

    if (title.contains('비행기') || title.contains('탑승') || title.contains('출국') || title.contains('항공')) {
      return '탑승까지 $formattedTime 남음';
    } else if (title.contains('체크인') || title.contains('호텔') || title.contains('숙소')) {
      return '체크인까지 $formattedTime 남음';
    }
    return '시작까지 $formattedTime 남음';
  }

  DayScheduleItem copyWith({
    String? id,
    int? dayNumber,
    DateTime? date,
    String? time,
    String? title,
    String? location,
    String? reservationCode,
    String? memo,
  }) {
    return DayScheduleItem(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      time: time ?? this.time,
      title: title ?? this.title,
      location: location ?? this.location,
      reservationCode: reservationCode ?? this.reservationCode,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayNumber': dayNumber,
    'date': date?.toIso8601String(),
    'time': time,
    'title': title,
    'location': location,
    'reservationCode': reservationCode,
    'memo': memo,
  };

  factory DayScheduleItem.fromJson(Map<String, dynamic> json) => DayScheduleItem(
    id: json['id'] as String,
    dayNumber: json['dayNumber'] as int? ?? 1,
    date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
    time: json['time'] as String?,
    title: json['title'] as String,
    location: json['location'] as String?,
    reservationCode: json['reservationCode'] as String?,
    memo: json['memo'] as String?,
  );
}

/// 단일 여행 모델 (보딩패스/티켓 스타일 렌더링에 필요한 정보 포함)
class TripItem {
  const TripItem({
    required this.id,
    required this.destination,
    this.emoji = '✈️',
    required this.startDate,
    required this.endDate,
    this.themeColorHex = '#2C3E50',
    this.memo,
    this.packingList = const [],
    this.daySchedules = const [],
  });

  final String id;
  final String destination;
  final String emoji;
  final DateTime startDate;
  final DateTime endDate;
  final String themeColorHex;
  final String? memo;
  final List<PackingCheckItem> packingList;
  final List<DayScheduleItem> daySchedules;

  /// 여행 일수 (ex. 2박 3일이면 3일)
  int get durationInDays {
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return e.difference(s).inDays + 1;
  }

  /// 현재 여행이 진행 중인지 여부
  bool isOngoing([DateTime? customNow]) {
    final now = customNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return !today.isBefore(s) && !today.isAfter(e);
  }

  /// 현재 진행 중일 때 몇 일차인지 계산 (1일차, 2일차...)
  int currentDayNumber([DateTime? customNow]) {
    final now = customNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    return today.difference(s).inDays + 1;
  }

  /// D-Day 뱃지 텍스트 (준비 중: D-N / 당일: D-Day / 여행 중: N일차 / 종료: D+N)
  String dDayBadge([DateTime? customNow]) {
    final now = customNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);

    if (today.isBefore(s)) {
      final diff = s.difference(today).inDays;
      return diff == 0 ? 'D-Day' : 'D-$diff';
    } else if (!today.isAfter(e)) {
      final dayNum = today.difference(s).inDays + 1;
      return '$dayNum일차';
    } else {
      final past = today.difference(e).inDays;
      return 'D+$past';
    }
  }

  /// 짐 싸기 완료 개수
  int get completedPackingCount => packingList.where((p) => p.isChecked).length;

  /// 짐 싸기 전체 개수
  int get totalPackingCount => packingList.length;

  /// 짐 싸기 완료율 (0.0 ~ 1.0)
  double get packingProgress =>
      totalPackingCount == 0 ? 0.0 : completedPackingCount / totalPackingCount;

  /// 짐 싸기 텍스트 (ex. "8/12 완료")
  String get packingProgressText => '$completedPackingCount/$totalPackingCount 완료';

  /// 여행 기간 포맷 (ex: "2026.11.15 ~ 2026.11.18")
  String get dateRangeText {
    final s = '${startDate.year}.${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')}';
    final e = '${endDate.year}.${endDate.month.toString().padLeft(2, '0')}.${endDate.day.toString().padLeft(2, '0')}';
    return '$s ~ $e';
  }

  Color get themeColor {
    try {
      final clean = themeColorHex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return const Color(0xFF2C3E50);
    }
  }

  TripItem copyWith({
    String? id,
    String? destination,
    String? emoji,
    DateTime? startDate,
    DateTime? endDate,
    String? themeColorHex,
    String? memo,
    List<PackingCheckItem>? packingList,
    List<DayScheduleItem>? daySchedules,
  }) {
    return TripItem(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      emoji: emoji ?? this.emoji,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      themeColorHex: themeColorHex ?? this.themeColorHex,
      memo: memo ?? this.memo,
      packingList: packingList ?? this.packingList,
      daySchedules: daySchedules ?? this.daySchedules,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'destination': destination,
    'emoji': emoji,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'themeColorHex': themeColorHex,
    'memo': memo,
    'packingList': packingList.map((p) => p.toJson()).toList(),
    'daySchedules': daySchedules.map((s) => s.toJson()).toList(),
  };

  factory TripItem.fromJson(Map<String, dynamic> json) => TripItem(
    id: json['id'] as String,
    destination: json['destination'] as String,
    emoji: json['emoji'] as String? ?? '✈️',
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse(json['endDate'] as String),
    themeColorHex: json['themeColorHex'] as String? ?? '#2C3E50',
    memo: json['memo'] as String?,
    packingList: (json['packingList'] as List<dynamic>?)
            ?.map((p) => PackingCheckItem.fromJson(p as Map<String, dynamic>))
            .toList() ??
        const [],
    daySchedules: (json['daySchedules'] as List<dynamic>?)
            ?.map((s) => DayScheduleItem.fromJson(s as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}
