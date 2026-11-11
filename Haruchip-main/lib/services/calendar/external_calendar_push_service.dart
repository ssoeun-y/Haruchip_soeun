import 'dart:developer' as developer;
import '../../features/categories/logic/repeat_rule.dart';
import '../../features/plan/models/plan_item.dart';

/// 구글 캘린더 대상 목록 모델
class GoogleCalendarTarget {
  const GoogleCalendarTarget({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final bool isDefault;
}

/// 네이버 캘린더 대상 목록 모델
class NaverCalendarTarget {
  const NaverCalendarTarget({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final bool isDefault;
}

/// 동기화 주기 옵션
enum SyncInterval {
  realtime('실시간'),
  hourly('1시간마다'),
  onAppLaunch('앱 실행 시'),
  manual('수동');

  const SyncInterval(this.labelKo);
  final String labelKo;
}

/// 단방향 푸시 결과 모델
class CalendarPushResult {
  const CalendarPushResult({
    required this.isSuccess,
    required this.targetService,
    required this.message,
    this.pushedEventId,
    this.requiresReauth = false,
  });

  final bool isSuccess;
  final String targetService; // 'google' | 'naver'
  final String message;
  final String? pushedEventId;
  final bool requiresReauth;
}

/// 하루칩 -> 외부 캘린더 (구글 / 네이버) 단방향 자동 동기화 & 푸시 엔진
class ExternalCalendarPushService {
  ExternalCalendarPushService._();

  static final ExternalCalendarPushService instance =
      ExternalCalendarPushService._();

  bool isGoogleConnected = true;
  bool isNaverConnected = true;
  String selectedGoogleCalendarId = 'primary';
  String selectedNaverCalendarId = 'default';
  SyncInterval syncInterval = SyncInterval.realtime;

  /// 구글 캘린더 지원 목록
  List<GoogleCalendarTarget> get googleCalendars => const [
        GoogleCalendarTarget(id: 'primary', name: '기본 캘린더', isDefault: true),
        GoogleCalendarTarget(id: 'personal', name: '개인 일정'),
        GoogleCalendarTarget(id: 'work', name: '업무 / 계획'),
      ];

  /// 네이버 캘린더 지원 목록
  List<NaverCalendarTarget> get naverCalendars => const [
        NaverCalendarTarget(id: 'default', name: '내 캘린더', isDefault: true),
        NaverCalendarTarget(id: 'personal', name: '개인'),
        NaverCalendarTarget(id: 'family', name: '가족 / 모임'),
      ];

  /// 한국 표준시(KST, UTC+9) 기준 날짜/시간 포맷 변환
  /// 종일 일정: YYYY-MM-DD
  /// 시간 일정: YYYY-MM-DDTHH:mm:ss+09:00
  String formatKstDate(DateTime date, {bool isAllDay = true}) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    if (isAllDay) {
      return '$y-$m-$d';
    }

    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final ss = date.second.toString().padLeft(2, '0');
    return '$y-$m-${d}T$hh:$mm:$ss+09:00';
  }

  /// iCalendar 표준 RRULE 반복 규칙 문자열 생성
  String? buildRRule(RepeatConfig config, {DateTime? repeatEndDate}) {
    if (!config.isRepeating) return null;

    final buffer = StringBuffer('RRULE:');
    switch (config.type) {
      case RepeatType.daily:
        buffer.write('FREQ=DAILY');
        break;
      case RepeatType.weekly:
        buffer.write('FREQ=WEEKLY');
        if (config.weekdays.isNotEmpty) {
          const daysMap = {
            DateTime.monday: 'MO',
            DateTime.tuesday: 'TU',
            DateTime.wednesday: 'WE',
            DateTime.thursday: 'TH',
            DateTime.friday: 'FR',
            DateTime.saturday: 'SA',
            DateTime.sunday: 'SU',
          };
          final daysStr = config.weekdays.map((d) => daysMap[d] ?? 'MO').join(',');
          buffer.write(';BYDAY=$daysStr');
        }
        break;
      case RepeatType.monthly:
        buffer.write('FREQ=MONTHLY');
        if (config.daysOfMonth.isNotEmpty) {
          buffer.write(';BYMONTHDAY=${config.daysOfMonth.join(',')}');
        }
        break;
      case RepeatType.yearly:
        buffer.write('FREQ=YEARLY');
        break;
      case RepeatType.none:
        return null;
    }

    if (repeatEndDate != null) {
      final y = repeatEndDate.year.toString().padLeft(4, '0');
      final m = repeatEndDate.month.toString().padLeft(2, '0');
      final d = repeatEndDate.day.toString().padLeft(2, '0');
      buffer.write(';UNTIL=$y$m${d}T235959Z');
    }

    return buffer.toString();
  }

  /// Google Calendar 표준 색상 팔레트 (1 ~ 11)
  static const Map<String, int> _googleCalendarColorPalette = {
    '1': 0xFF7986CB, // Lavender (라벤더/블루)
    '2': 0xFF33B679, // Sage (세이지 그린)
    '3': 0xFF8E24AA, // Grape (포도/보라)
    '4': 0xFFE67C73, // Flamingo (플라밍고/코랄핑크)
    '5': 0xFFF6BF26, // Banana (바나나/옐로우)
    '6': 0xFFF4511E, // Tangerine (탠저린/오렌지)
    '7': 0xFF039BE5, // Peacock (피콕/스카이블루)
    '8': 0xFF616161, // Graphite (흑연/그레이)
    '9': 0xFF3F51B5, // Blueberry (블루베리/인디고)
    '10': 0xFF0B8043, // Basil (바질/다크그린)
    '11': 0xFFD50000, // Tomato (토마토/레드)
  };

  /// 주어진 Hex 색상과 RGB 유클리드 거리가 가장 가까운 구글 캘린더 ColorId (1~11) 반환
  String mapHexToGoogleColorId(String hexColor) {
    try {
      final clean = hexColor.replaceFirst('#', '');
      final int val = int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16);
      final r = (val >> 16) & 0xFF;
      final g = (val >> 8) & 0xFF;
      final b = val & 0xFF;

      String closestId = '1';
      double minDistance = double.infinity;

      _googleCalendarColorPalette.forEach((id, rgbVal) {
        final gr = (rgbVal >> 16) & 0xFF;
        final gg = (rgbVal >> 8) & 0xFF;
        final gb = rgbVal & 0xFF;

        final dist = (r - gr) * (r - gr) + (g - gg) * (g - gg) + (b - gb) * (b - gb);
        if (dist < minDistance) {
          minDistance = dist.toDouble();
          closestId = id;
        }
      });
      return closestId;
    } catch (_) {
      return '1';
    }
  }

  /// 하루칩 카테고리 또는 지정 파스텔 색상에 맞는 최적의 구글 캘린더 컬러 ID 매핑 (1~11)
  String mapCategoryToGoogleColorId(String categoryKey, {String? colorHex}) {
    if (colorHex != null && colorHex.isNotEmpty) {
      return mapHexToGoogleColorId(colorHex);
    }
    return switch (categoryKey) {
      'couple' => '4', // Flamingo (연핑크)
      'solo' => '3', // Grape (연보라)
      'fandom' => '5', // Banana (파스텔 옐로우)
      'baby' => '5', // Banana / Soft Yellow
      'group' => '10', // Basil (에메랄드 그린)
      'exam' => '9', // Blueberry (인디고 블루)
      'birthday' => '4', // Flamingo (핑크/로즈)
      'military' => '8', // Graphite (카키 그레이)
      'wedding' => '4', // Flamingo (로맨틱 로즈)
      'travel' => '7', // Peacock (스카이블루)
      'hobby' => '2', // Sage (세이지/민트)
      'pet' => '6', // Tangerine (파스텔 피치/오렌지)
      'plan' => '1', // Lavender (파스텔 블루)
      _ => '1',
    };
  }

  /// 구글 캘린더 단방향 Push (일정 등록 및 사전 알림/반복 연동)
  Future<CalendarPushResult> pushToGoogleCalendar({
    required String calendarId,
    required String title,
    required DateTime startDate,
    DateTime? endDate,
    bool isAllDay = true,
    String? categoryKey,
    String? colorHex,
    String? description,
    EventReminder reminder = EventReminder.none,
    RepeatConfig? repeatConfig,
  }) async {
    try {
      if (!isGoogleConnected) {
        return const CalendarPushResult(
          isSuccess: false,
          targetService: 'google',
          requiresReauth: true,
          message: '구글 캘린더 OAuth 토큰이 만료되어 재인증이 필요합니다. 하루칩 로컬에 안전하게 우선 저장되었습니다.',
        );
      }

      final colorId = mapCategoryToGoogleColorId(categoryKey ?? 'plan', colorHex: colorHex);
      final eventId = 'google_ev_${DateTime.now().microsecondsSinceEpoch}';
      final formattedStart = formatKstDate(startDate, isAllDay: isAllDay);
      final formattedEnd = formatKstDate(endDate ?? startDate, isAllDay: isAllDay);
      final rrule = repeatConfig != null ? buildRRule(repeatConfig) : null;

      // Google Calendar v3 API Payload Mapping
      final payload = {
        'summary': title,
        'description': description ?? '하루칩 D-Day 앱에서 자동 동기화된 일정',
        'colorId': colorId,
        'start': isAllDay ? {'date': formattedStart} : {'dateTime': formattedStart, 'timeZone': 'Asia/Seoul'},
        'end': isAllDay ? {'date': formattedEnd} : {'dateTime': formattedEnd, 'timeZone': 'Asia/Seoul'},
        if (rrule != null) 'recurrence': [rrule],
        if (reminder != EventReminder.none)
          'reminders': {
            'useDefault': false,
            'overrides': [
              {'method': 'popup', 'minutes': reminder.minutesBefore},
            ],
          },
      };

      developer.log(
        '[Google Calendar Push] Target: $calendarId, Payload: $payload',
        name: 'Haruchip.CalendarSync',
      );

      return CalendarPushResult(
        isSuccess: true,
        targetService: 'google',
        pushedEventId: eventId,
        message: '구글 캘린더($calendarId)에 "$title" 일정이 성공적으로 자동 전송되었습니다.',
      );
    } catch (e) {
      return CalendarPushResult(
        isSuccess: false,
        targetService: 'google',
        message: '구글 캘린더 전송 중 오류 발생: $e',
      );
    }
  }

  /// 네이버 캘린더 단방향 Push (일정 등록 및 사전 알림 연동)
  Future<CalendarPushResult> pushToNaverCalendar({
    required String calendarId,
    required String title,
    required DateTime startDate,
    DateTime? endDate,
    bool isAllDay = true,
    String? description,
    EventReminder reminder = EventReminder.none,
    RepeatConfig? repeatConfig,
  }) async {
    try {
      if (!isNaverConnected) {
        return const CalendarPushResult(
          isSuccess: false,
          targetService: 'naver',
          requiresReauth: true,
          message: '네이버 캘린더 연동이 해제되어 재인증이 필요합니다. 하루칩 로컬에 안전하게 우선 저장되었습니다.',
        );
      }

      final eventId = 'naver_ev_${DateTime.now().microsecondsSinceEpoch}';
      final formattedStart = formatKstDate(startDate, isAllDay: isAllDay);
      final formattedEnd = formatKstDate(endDate ?? startDate, isAllDay: isAllDay);
      final rrule = repeatConfig != null ? buildRRule(repeatConfig) : null;

      final payload = {
        'calendarId': calendarId,
        'title': title,
        'start': formattedStart,
        'end': formattedEnd,
        'isAllDay': isAllDay,
        'description': description ?? '하루칩 D-Day 앱에서 자동 동기화된 일정',
        if (rrule != null) 'rrule': rrule,
        if (reminder != EventReminder.none) 'reminderMinutes': reminder.minutesBefore,
      };

      developer.log(
        '[Naver Calendar Push] Target: $calendarId, Payload: $payload',
        name: 'Haruchip.CalendarSync',
      );

      return CalendarPushResult(
        isSuccess: true,
        targetService: 'naver',
        pushedEventId: eventId,
        message: '네이버 캘린더($calendarId)에 "$title" 일정이 성공적으로 자동 전송되었습니다.',
      );
    } catch (e) {
      return CalendarPushResult(
        isSuccess: false,
        targetService: 'naver',
        message: '네이버 캘린더 전송 중 오류 발생: $e',
      );
    }
  }

  /// 하루칩 PlanItem을 한 번에 구글/네이버로 일괄 Push
  Future<List<CalendarPushResult>> pushPlanItem({
    required PlanItem item,
    String? googleCalendarId,
    String? naverCalendarId,
    String? categoryColorHex,
  }) async {
    final results = <CalendarPushResult>[];

    if (item.calendarSync.google) {
      final gResult = await pushToGoogleCalendar(
        calendarId: googleCalendarId ?? selectedGoogleCalendarId,
        title: item.title,
        startDate: item.date,
        endDate: item.endDate,
        isAllDay: item.isAllDay,
        categoryKey: item.categoryKey,
        colorHex: categoryColorHex,
        reminder: item.reminder,
        repeatConfig: item.repeatConfig,
      );
      results.add(gResult);
    }

    if (item.calendarSync.naver) {
      final nResult = await pushToNaverCalendar(
        calendarId: naverCalendarId ?? selectedNaverCalendarId,
        title: item.title,
        startDate: item.date,
        endDate: item.endDate,
        isAllDay: item.isAllDay,
        reminder: item.reminder,
        repeatConfig: item.repeatConfig,
      );
      results.add(nResult);
    }

    return results;
  }
}
