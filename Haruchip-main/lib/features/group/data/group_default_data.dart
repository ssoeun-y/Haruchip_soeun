import '../models/group_category_item.dart';

final now = DateTime.now();

/// 기본 모임 카테고리 프리셋 목록
final List<GroupCategoryItem> kDefaultGroupCategories = [
  GroupCategoryItem(
    id: 'group-1',
    name: '고교 동창회',
    icon: '👥',
    foundationDate: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 449)),
    regularScheduleInfo: '매월 둘째 주 토요일',
    themeColorHex: '#FFF5F2',
    memo: '반가운 고등학교 친구들과의 정기 모임',
    createdAt: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 450)),
    memberCount: 14,
  ),
  GroupCategoryItem(
    id: 'group-2',
    name: '주말 풋살 클럽',
    icon: '⚽',
    foundationDate: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 120)),
    regularScheduleInfo: '매주 일요일 오전 10시',
    themeColorHex: '#FFF5F2',
    memo: '부상 없이 건강하고 즐겁게 차는 풋살 모임',
    createdAt: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 120)),
    memberCount: 18,
  ),
  GroupCategoryItem(
    id: 'group-3',
    name: '퇴근길 독서 토론',
    icon: '☕',
    foundationDate: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 210)),
    regularScheduleInfo: '격주 목요일 저녁 7시',
    themeColorHex: '#FFF5F2',
    memo: '한 달에 2권 깊이 있게 읽고 이야기 나누기',
    createdAt: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 210)),
    memberCount: 8,
  ),
];

/// 기본 모임 세부 D-Day 일정 샘플 데이터
final List<GroupMeetingScheduleItem> kDefaultGroupMeetingSchedules = [
  // 고교 동창회 (group-1)
  GroupMeetingScheduleItem(
    id: 'sched-grp-1',
    groupId: 'group-1',
    title: '11월 정기 정모 및 송년회 준비',
    dateTime: DateTime(now.year, now.month, now.day + 5, 18, 30),
    location: '강남역 11번 출구 제주애월흑돼지',
    isAttending: true,
    isRegular: true,
    recurringRule: 'monthlySecondSaturday',
    memo: '회비 3만원, 연말 송년 여행 장소 투표 예정',
    createdAt: now.subtract(const Duration(days: 5)),
  ),
  GroupMeetingScheduleItem(
    id: 'sched-grp-2',
    groupId: 'group-1',
    title: '급 번개 치맥 모임',
    dateTime: DateTime(now.year, now.month, now.day + 12, 19, 0),
    location: '사당역 5번 출구 생활맥주',
    isAttending: null,
    isRegular: false,
    memo: '시간 되는 친구들 가볍게 한잔!',
    createdAt: now.subtract(const Duration(days: 2)),
  ),
  GroupMeetingScheduleItem(
    id: 'sched-grp-past-1',
    groupId: 'group-1',
    title: '10월 가을 맞이 정기 모임',
    dateTime: DateTime(now.year, now.month, now.day - 25, 18, 0),
    location: '교대역 서초갈비',
    isAttending: true,
    isRegular: true,
    recurringRule: 'monthlySecondSaturday',
    memo: '12명 참석 완료, 2차 노래방까지 즐겁게 마무리',
    createdAt: now.subtract(const Duration(days: 35)),
  ),

  // 주말 풋살 클럽 (group-2)
  GroupMeetingScheduleItem(
    id: 'sched-grp-3',
    groupId: 'group-2',
    title: '이번 주 일요 풋살 매치 (FC 한강전)',
    dateTime: DateTime(now.year, now.month, now.day + 3, 10, 0),
    location: '잠실 유수지 풋살파크 A구역',
    isAttending: true,
    isRegular: true,
    recurringRule: 'weeklySunday',
    memo: '개인 풋살화 및 흰색/남색 유니폼 지참',
    createdAt: now.subtract(const Duration(days: 3)),
  ),

  // 퇴근길 독서 토론 (group-3)
  GroupMeetingScheduleItem(
    id: 'sched-grp-4',
    groupId: 'group-3',
    title: '도서 [데미안] 챕터 1~4 심층 토론',
    dateTime: DateTime(now.year, now.month, now.day + 8, 19, 0),
    location: '성수동 북카페 림 스터디룸',
    isAttending: false,
    isRegular: true,
    recurringRule: 'biweeklyThursday',
    memo: '인상 깊었던 한 줄 메모지 준비해오기',
    createdAt: now.subtract(const Duration(days: 1)),
  ),
];
