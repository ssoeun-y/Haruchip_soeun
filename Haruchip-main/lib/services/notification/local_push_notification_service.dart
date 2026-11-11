import 'dart:async';
import 'dart:developer' as developer;

import '../../features/plan/models/plan_item.dart';

/// 예약된 로컬 알림 데이터 모델
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.planItemId,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.categoryKey,
    this.isDelivered = false,
  });

  final String id;
  final String planItemId;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String categoryKey;
  final bool isDelivered;

  ScheduledNotification copyWith({
    String? id,
    String? planItemId,
    String? title,
    String? body,
    DateTime? scheduledTime,
    String? categoryKey,
    bool? isDelivered,
  }) {
    return ScheduledNotification(
      id: id ?? this.id,
      planItemId: planItemId ?? this.planItemId,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      categoryKey: categoryKey ?? this.categoryKey,
      isDelivered: isDelivered ?? this.isDelivered,
    );
  }
}

/// 하루칩 로컬 푸시 알림 & 백그라운드 스케줄러 서비스
class LocalPushNotificationService {
  LocalPushNotificationService._();

  static final LocalPushNotificationService instance =
      LocalPushNotificationService._();

  final Map<String, ScheduledNotification> _scheduledMap = {};
  final Map<String, Timer> _activeTimers = {};
  final StreamController<ScheduledNotification> _notificationController =
      StreamController<ScheduledNotification>.broadcast();

  bool _isInitialized = false;

  /// 푸시 알림 발생 이벤트 스트림 (배너 UI 등에서 수신 가능)
  Stream<ScheduledNotification> get onNotificationTriggered =>
      _notificationController.stream;

  /// 현재 대기 중인 예약 알림 목록
  List<ScheduledNotification> get activeNotifications =>
      _scheduledMap.values.where((n) => !n.isDelivered).toList();

  /// 서비스 초기화
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = true;
    developer.log(
      'LocalPushNotificationService initialized successfully',
      name: 'LocalPushNotification',
    );
    return true;
  }

  /// [PlanItem]의 미리 알림([EventReminder]) 설정을 바탕으로 로컬 푸시 알림 등록
  Future<ScheduledNotification?> schedulePlanReminder(PlanItem item) async {
    // 기존 해당 일정의 알림이 있다면 선제적 취소 (수정 반영)
    cancelReminder(item.id);

    if (item.reminder == EventReminder.none) {
      return null;
    }

    // 일정 시작 일시 계산
    final hour = item.deadlineTime?.hour ?? (item.isAllDay ? 9 : 9);
    final minute = item.deadlineTime?.minute ?? 0;
    final eventStart = DateTime(
      item.date.year,
      item.date.month,
      item.date.day,
      hour,
      minute,
    );

    // 알림 발송 시점 계산
    final DateTime scheduledTime;
    if (item.reminder == EventReminder.before1d9am) {
      scheduledTime = DateTime(
        item.date.year,
        item.date.month,
        item.date.day - 1,
        9,
        0,
      );
    } else {
      scheduledTime = eventStart.subtract(
        Duration(minutes: item.reminder.minutesBefore),
      );
    }

    final now = DateTime.now();
    // 이미 지난 시점인 경우 알림 미등록 (단, 정시 알림이고 1분 미만 차이면 바로 발송 가능)
    if (scheduledTime.isBefore(now)) {
      developer.log(
        'Scheduled notification time ($scheduledTime) is in the past. Skipping.',
        name: 'LocalPushNotification',
      );
      return null;
    }

    final delay = scheduledTime.difference(now);
    final notifId = 'notif_${item.id}_${scheduledTime.millisecondsSinceEpoch}';

    final bodyText = switch (item.reminder) {
      EventReminder.onTime => '지금 시작되는 일정입니다.',
      EventReminder.before10m => '10분 후에 시작됩니다.',
      EventReminder.before30m => '30분 후에 시작됩니다.',
      EventReminder.before1h => '1시간 후에 시작됩니다.',
      EventReminder.before1d9am => '내일 예정된 일정입니다.',
      EventReminder.before3d => '3일 후에 예정된 일정입니다.',
      EventReminder.before1w => '1주일 후에 예정된 일정입니다.',
      EventReminder.none => '',
    };

    final scheduled = ScheduledNotification(
      id: notifId,
      planItemId: item.id,
      title: item.title,
      body: bodyText,
      scheduledTime: scheduledTime,
      categoryKey: item.categoryKey,
    );

    _scheduledMap[item.id] = scheduled;

    // 타이머 등록 (앱 구동 중 발송)
    _activeTimers[item.id] = Timer(delay, () {
      _triggerNotification(scheduled);
    });

    developer.log(
      'Scheduled push notification for "${item.title}" at $scheduledTime (in ${delay.inMinutes}m)',
      name: 'LocalPushNotification',
    );

    return scheduled;
  }

  /// 특정 일정의 알림 스케줄 취소
  void cancelReminder(String planItemId) {
    _activeTimers[planItemId]?.cancel();
    _activeTimers.remove(planItemId);
    _scheduledMap.remove(planItemId);
    developer.log(
      'Cancelled push notification for item $planItemId',
      name: 'LocalPushNotification',
    );
  }

  /// 즉시 배너 알림 발송 (테스트 및 즉시 알림용)
  void showImmediateNotification({
    required String title,
    required String body,
    String? categoryKey,
  }) {
    final notif = ScheduledNotification(
      id: 'immediate_${DateTime.now().millisecondsSinceEpoch}',
      planItemId: 'immediate',
      title: title,
      body: body,
      scheduledTime: DateTime.now(),
      categoryKey: categoryKey ?? 'plan',
      isDelivered: true,
    );
    _triggerNotification(notif);
  }

  void _triggerNotification(ScheduledNotification notif) {
    final delivered = notif.copyWith(isDelivered: true);
    _scheduledMap[notif.planItemId] = delivered;
    _activeTimers.remove(notif.planItemId);

    developer.log(
      '🔔 [BANNER PUSH] ${notif.title} - ${notif.body}',
      name: 'LocalPushNotification',
    );

    _notificationController.add(delivered);
  }

  /// 모든 알림 타이머 해제
  void clearAll() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _scheduledMap.clear();
  }
}
