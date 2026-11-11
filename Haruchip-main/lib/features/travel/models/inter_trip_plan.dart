/// 여행 사이사이 계획(인터벌 마일스톤) 모델
/// (ex: 호텔 잔금 결제, 환전 신청, 여권 만료일 확인 및 재발급 등)
class InterTripPlan {
  const InterTripPlan({
    required this.id,
    required this.title,
    required this.date,
    this.time,
    this.isCompleted = false,
    this.beforeTripId,
    this.afterTripId,
    this.memo,
  });

  final String id;
  final String title;
  final DateTime date;
  final String? time; // '10:00'
  final bool isCompleted;
  final String? beforeTripId;
  final String? afterTripId;
  final String? memo;

  /// D-Day 라벨 계산 (D-Day, D-N, D+N)
  String dDayLabel([DateTime? customNow]) {
    final now = customNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${-diff}';
  }

  /// 날짜 포맷 (ex: "12.01 (화)")
  String get formattedDate {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final wd = weekdays[date.weekday % 7];
    return '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ($wd)';
  }

  InterTripPlan copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? time,
    bool? isCompleted,
    String? beforeTripId,
    String? afterTripId,
    String? memo,
  }) {
    return InterTripPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
      beforeTripId: beforeTripId ?? this.beforeTripId,
      afterTripId: afterTripId ?? this.afterTripId,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'time': time,
    'isCompleted': isCompleted,
    'beforeTripId': beforeTripId,
    'afterTripId': afterTripId,
    'memo': memo,
  };

  factory InterTripPlan.fromJson(Map<String, dynamic> json) => InterTripPlan(
    id: json['id'] as String,
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    time: json['time'] as String?,
    isCompleted: json['isCompleted'] as bool? ?? false,
    beforeTripId: json['beforeTripId'] as String?,
    afterTripId: json['afterTripId'] as String?,
    memo: json['memo'] as String?,
  );
}
