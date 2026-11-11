import '../models/hobby_item.dart';

/// 기본 취미 아이콘 프리셋
const List<String> kHobbyIconPresets = [
  '🎸', // 기타/악기
  '🏃', // 러닝/조깅
  '☕', // 커피/카페
  '🎨', // 드로잉/미술
  '📚', // 독서/북클럽
  '🧗', // 클라이밍
  '🍳', // 베이킹/요리
  '📷', // 필름카메라/사진
  '🎹', // 피아노/건반
  '🌱', // 식물/가드닝
  '🏊', // 수영
  '🚴', // 자전거/라이딩
  '🧘', // 요가/필라테스
  '🧶', // 뜨개질/공예
  '🎬', // 영화/연극 관람
  '🏸', // 배드민턴/테니스
];

/// 초기 기본 취미 데이터 (시작일 기준 N일째 계산 지원)
List<HobbyItem> getInitialHobbies() {
  return [
    HobbyItem(
      id: 'hobby-guitar',
      name: '기타 연습',
      icon: '🎸',
      startDate: DateTime(2026, 6, 14),
      colorHex: '#354235',
      memo: '매일 코드 30분씩 연습하기',
      createdAt: DateTime(2026, 6, 14),
    ),
    HobbyItem(
      id: 'hobby-running',
      name: '주말 러닝',
      icon: '🏃',
      startDate: DateTime(2026, 8, 1),
      colorHex: '#2E4C38',
      memo: '가볍게 5km부터 천천히 페이스 올리기',
      createdAt: DateTime(2026, 8, 1),
    ),
    HobbyItem(
      id: 'hobby-coffee',
      name: '핸드드립 커피',
      icon: '☕',
      startDate: DateTime(2026, 9, 20),
      colorHex: '#4A3B32',
      memo: '다양한 원두 산지 노트 기록',
      createdAt: DateTime(2026, 9, 20),
    ),
  ];
}

/// 초기 취미 세부 일정 데이터 (D-Day 스케줄러)
List<HobbyScheduleItem> getInitialHobbySchedules() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return [
    // 기타 연습 일정
    HobbyScheduleItem(
      id: 'sched-guitar-1',
      hobbyId: 'hobby-guitar',
      title: '기타 줄 갈기 & 프렛 청소',
      date: today.add(const Duration(days: 6, hours: 14)),
      hasTime: true,
      location: '낙원상가 기타스토리',
      memo: '엘릭서 010 스트링 교체 및 레몬오일 도포',
      isCompleted: false,
      createdAt: now,
    ),
    HobbyScheduleItem(
      id: 'sched-guitar-2',
      hobbyId: 'hobby-guitar',
      title: '합주실 정기 밴드 세션',
      date: today.add(const Duration(days: 12, hours: 19, minutes: 30)),
      hasTime: true,
      location: '홍대 사운드스튜디오 A룸',
      memo: '자작곡 인트로 및 2번 곡 솔로 맞춰보기',
      isCompleted: false,
      createdAt: now,
    ),

    // 주말 러닝 일정
    HobbyScheduleItem(
      id: 'sched-running-1',
      hobbyId: 'hobby-running',
      title: '한강 10km 정기 러닝',
      date: today.add(const Duration(days: 4, hours: 7, minutes: 30)),
      hasTime: true,
      location: '반포 한강공원 달빛광장',
      memo: '페이스 5:30 유지, 수분 보충 젤 챙기기',
      isCompleted: false,
      createdAt: now,
    ),

    // 핸드드립 커피 일정
    HobbyScheduleItem(
      id: 'sched-coffee-1',
      hobbyId: 'hobby-coffee',
      title: '에티오피아 원두 커핑 & 로스팅 클래스',
      date: today.add(const Duration(days: 15, hours: 14)),
      hasTime: true,
      location: '성수동 블루포트 랩',
      memo: '추출 도구 칼리타 웨이브 지참',
      isCompleted: false,
      createdAt: now,
    ),
  ];
}
