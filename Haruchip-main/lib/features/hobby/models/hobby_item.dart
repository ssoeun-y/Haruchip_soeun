/// 단일 취미 데이터 모델
class HobbyItem {
  const HobbyItem({
    required this.id,
    required this.name,
    this.icon = '🎨',
    this.imagePath,
    required this.startDate,
    this.colorHex = '#354235',
    this.memo,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String icon;
  final String? imagePath;
  final DateTime startDate;
  final String colorHex;
  final String? memo;
  final DateTime createdAt;

  /// 시작일 기준 지속 일수 (시작일을 1일째로 계산)
  int daysSinceStart([DateTime? now]) {
    final current = now ?? DateTime.now();
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime(current.year, current.month, current.day);
    return today.difference(start).inDays + 1;
  }

  /// 지속 일수 라벨 (ex. "시작한 지 142일째")
  String daysSinceStartText([DateTime? now]) {
    final days = daysSinceStart(now);
    if (days <= 0) return '오늘 시작';
    return '시작한 지 $days일째';
  }

  /// 깔끔한 시작 날짜 1줄 포맷 (ex. "2026.06.14 시작")
  String get formattedStartDate {
    final y = startDate.year;
    final m = startDate.month.toString().padLeft(2, '0');
    final d = startDate.day.toString().padLeft(2, '0');
    return '$y.$m.$d 시작';
  }

  HobbyItem copyWith({
    String? id,
    String? name,
    String? icon,
    String? imagePath,
    DateTime? startDate,
    String? colorHex,
    String? memo,
    DateTime? createdAt,
  }) {
    return HobbyItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      imagePath: imagePath ?? this.imagePath,
      startDate: startDate ?? this.startDate,
      colorHex: colorHex ?? this.colorHex,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'imagePath': imagePath,
      'startDate': startDate.toIso8601String(),
      'colorHex': colorHex,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HobbyItem.fromJson(Map<String, dynamic> json) {
    return HobbyItem(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: (json['icon'] as String?) ?? '🎨',
      imagePath: json['imagePath'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      colorHex: (json['colorHex'] as String?) ?? '#354235',
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// 취미 세부 일정 데이터 모델
class HobbyScheduleItem {
  const HobbyScheduleItem({
    required this.id,
    required this.hobbyId,
    required this.title,
    required this.date,
    this.hasTime = true,
    this.location,
    this.memo,
    this.isCompleted = false,
    required this.createdAt,
  });

  final String id;
  final String hobbyId;
  final String title;
  final DateTime date;
  final bool hasTime;
  final String? location;
  final String? memo;
  final bool isCompleted;
  final DateTime createdAt;

  /// 오늘 날짜 기준 경과 여부 판별
  bool isPast([DateTime? now]) {
    final current = now ?? DateTime.now();
    if (hasTime) {
      return date.isBefore(current);
    }
    final today = DateTime(current.year, current.month, current.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }

  /// D-Day 뱃지 텍스트 (ex. D-6, 03:15 남음, 오늘 D-Day, D+1)
  String dDayBadge([DateTime? now]) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    final diffDays = targetDay.difference(today).inDays;

    if (diffDays > 0) {
      return 'D-$diffDays';
    } else if (diffDays == 0) {
      if (hasTime && date.isAfter(current)) {
        final rem = date.difference(current);
        final hours = rem.inHours;
        final mins = rem.inMinutes % 60;
        return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} 남음';
      }
      return '오늘 D-Day';
    } else {
      return 'D+${-diffDays}';
    }
  }

  /// 포맷팅된 일시 텍스트 (ex. "2026.11.08 14:00")
  String get formattedDateTime {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    if (hasTime) {
      final hh = date.hour.toString().padLeft(2, '0');
      final mm = date.minute.toString().padLeft(2, '0');
      return '$y.$m.$d $hh:$mm';
    }
    return '$y.$m.$d';
  }

  HobbyScheduleItem copyWith({
    String? id,
    String? hobbyId,
    String? title,
    DateTime? date,
    bool? hasTime,
    String? location,
    String? memo,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return HobbyScheduleItem(
      id: id ?? this.id,
      hobbyId: hobbyId ?? this.hobbyId,
      title: title ?? this.title,
      date: date ?? this.date,
      hasTime: hasTime ?? this.hasTime,
      location: location ?? this.location,
      memo: memo ?? this.memo,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hobbyId': hobbyId,
      'title': title,
      'date': date.toIso8601String(),
      'hasTime': hasTime,
      'location': location,
      'memo': memo,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HobbyScheduleItem.fromJson(Map<String, dynamic> json) {
    return HobbyScheduleItem(
      id: json['id'] as String,
      hobbyId: json['hobbyId'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      hasTime: (json['hasTime'] as bool?) ?? true,
      location: json['location'] as String?,
      memo: json['memo'] as String?,
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
