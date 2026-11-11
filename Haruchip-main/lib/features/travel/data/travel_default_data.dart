import '../models/inter_trip_plan.dart';
import '../models/trip_item.dart';

/// 기본 가방 싸기(체크리스트) 마스터 템플릿 항목들
final List<PackingCheckItem> kDefaultPackingTemplates = [
  // 필수 서류
  const PackingCheckItem(id: 'pack-tpl-1', title: '여권 (유효기간 6개월 이상)', category: '필수 서류'),
  const PackingCheckItem(id: 'pack-tpl-2', title: '항공권 e-티켓 & 탑승권', category: '필수 서류'),
  const PackingCheckItem(id: 'pack-tpl-3', title: '해외 결제 카드 (트래블로그/월렛)', category: '필수 서류'),
  const PackingCheckItem(id: 'pack-tpl-4', title: '현지 화폐 현금 & 바우처', category: '필수 서류'),
  const PackingCheckItem(id: 'pack-tpl-5', title: '해외 여행자 보험 증서', category: '필수 서류'),

  // 전자기기
  const PackingCheckItem(id: 'pack-tpl-6', title: '스마트폰 고속 충전기 & 케이블', category: '전자기기'),
  const PackingCheckItem(id: 'pack-tpl-7', title: '대용량 보조배터리 (기내 수하물)', category: '전자기기'),
  const PackingCheckItem(id: 'pack-tpl-8', title: '국가별 멀티 변환 플러그(돼지코)', category: '전자기기'),
  const PackingCheckItem(id: 'pack-tpl-9', title: 'eSIM 등록 or 포켓 와이파이', category: '전자기기'),
  const PackingCheckItem(id: 'pack-tpl-10', title: '무선 이어폰 / 헤드셋', category: '전자기기'),

  // 의류 & 잡화
  const PackingCheckItem(id: 'pack-tpl-11', title: '일자별 옷 & 여벌 옷', category: '의류 & 잡화'),
  const PackingCheckItem(id: 'pack-tpl-12', title: '속옷 & 양말 (여유분 포함)', category: '의류 & 잡화'),
  const PackingCheckItem(id: 'pack-tpl-13', title: '잠옷 & 실내용 편한 복장', category: '의류 & 잡화'),
  const PackingCheckItem(id: 'pack-tpl-14', title: '편한 운동화 & 슬리퍼', category: '의류 & 잡화'),
  const PackingCheckItem(id: 'pack-tpl-15', title: '자외선 차단 선글라스 & 모자', category: '의류 & 잡화'),
  const PackingCheckItem(id: 'pack-tpl-16', title: '초경량 3단 접이식 우산', category: '의류 & 잡화'),

  // 위생 & 상비약
  const PackingCheckItem(id: 'pack-tpl-17', title: '세면도구 & 칫솔/치약', category: '위생 & 상비약'),
  const PackingCheckItem(id: 'pack-tpl-18', title: '스킨케어 & 선크림', category: '위생 & 상비약'),
  const PackingCheckItem(id: 'pack-tpl-19', title: '상비약 (소화제, 두통약, 감기약, 지사제)', category: '위생 & 상비약'),
  const PackingCheckItem(id: 'pack-tpl-20', title: '밴드 & 인공눈물', category: '위생 & 상비약'),
];

/// 초기 복수 여행 샘플 데이터 (시간 순 타임라인 로드맵)
List<TripItem> getInitialMockTrips() {
  final now = DateTime.now();

  return [
    TripItem(
      id: 'trip-jeju',
      destination: '제주도 힐링 여행',
      emoji: '🌴',
      startDate: now.add(const Duration(days: 5)),
      endDate: now.add(const Duration(days: 7)),
      themeColorHex: '#0284C7', // Ocean Blue
      memo: '한라산 둘레길 트래킹 & 흑돼지 맛집 탐방',
      packingList: [
        const PackingCheckItem(id: 'p-jeju-1', title: '신분증 & 운전면허증', category: '필수 서류', isChecked: true),
        const PackingCheckItem(id: 'p-jeju-2', title: '모바일 탑승권 발급', category: '필수 서류', isChecked: true),
        const PackingCheckItem(id: 'p-jeju-3', title: '보조배터리 & 충전기', category: '전자기기', isChecked: true),
        const PackingCheckItem(id: 'p-jeju-4', title: '트래킹화 & 편한 양말', category: '의류 & 잡화', isChecked: false),
        const PackingCheckItem(id: 'p-jeju-5', title: '선크림 & 썬글라스', category: '위생 & 상비약', isChecked: false),
      ],
      daySchedules: [
        DayScheduleItem(
          id: 'ds-jeju-1',
          dayNumber: 1,
          date: now.add(const Duration(days: 5)),
          time: '08:30',
          title: '김포공항 출발 (제주항공 7C113)',
          location: '김포공항 국내선 3층',
          reservationCode: '7C113-A882',
        ),
        DayScheduleItem(
          id: 'ds-jeju-2',
          dayNumber: 1,
          date: now.add(const Duration(days: 5)),
          time: '11:00',
          title: '제주 렌터카 인수 & 해안도로 드라이브',
          location: '제주공항 렌터카 셔틀 5구역',
          reservationCode: 'RENT-9941',
        ),
        DayScheduleItem(
          id: 'ds-jeju-3',
          dayNumber: 2,
          date: now.add(const Duration(days: 6)),
          time: '14:00',
          title: '서귀포 바다전망 카페 & 흑돼지 디너',
          location: '서귀포시 중문관광로',
        ),
      ],
    ),
    TripItem(
      id: 'trip-osaka',
      destination: '오사카 & 교토 단풍 투어',
      emoji: '✈️',
      startDate: now.add(const Duration(days: 35)),
      endDate: now.add(const Duration(days: 39)),
      themeColorHex: '#2C3E50', // Classic Sky Navy
      memo: '유니버설 스튜디오 익스프레스 & 도톤보리 타코야키',
      packingList: [
        const PackingCheckItem(id: 'p-osaka-1', title: '여권 (유효기간 6개월 이상)', category: '필수 서류', isChecked: true),
        const PackingCheckItem(id: 'p-osaka-2', title: '간사이공항 피치항공 e-티켓', category: '필수 서류', isChecked: true),
        const PackingCheckItem(id: 'p-osaka-3', title: '110V 돼지코 어댑터 2개', category: '전자기기', isChecked: false),
        const PackingCheckItem(id: 'p-osaka-4', title: '트래블로그 카드 엔화 충전', category: '필수 서류', isChecked: true),
        const PackingCheckItem(id: 'p-osaka-5', title: 'USJ 익스프레스 패스 QR', category: '필수 서류', isChecked: false),
        const PackingCheckItem(id: 'p-osaka-6', title: '휴족시간 & 소화제', category: '위생 & 상비약', isChecked: false),
      ],
      daySchedules: [
        DayScheduleItem(
          id: 'ds-osaka-1',
          dayNumber: 1,
          date: now.add(const Duration(days: 35)),
          time: '09:10',
          title: '인천공항 T1 출국 탑승',
          location: '인천공항 제1여객터미널 28번 게이트',
          reservationCode: 'MM028',
        ),
        DayScheduleItem(
          id: 'ds-osaka-2',
          dayNumber: 1,
          date: now.add(const Duration(days: 35)),
          time: '15:00',
          title: '난바 오리엔탈 호텔 체크인',
          location: '오사카 주오구 센니치마에',
          reservationCode: 'BK-OSK-771',
        ),
        DayScheduleItem(
          id: 'ds-osaka-3',
          dayNumber: 2,
          date: now.add(const Duration(days: 36)),
          time: '08:00',
          title: '유니버설 스튜디오 재팬 (USJ) 오픈런',
          location: 'USJ 오사카 코노하나구',
          reservationCode: 'EXP4-NINTENDO',
        ),
      ],
    ),
    TripItem(
      id: 'trip-sapporo',
      destination: '삿포로 & 오타루 눈꽃 축제',
      emoji: '❄️',
      startDate: now.add(const Duration(days: 80)),
      endDate: now.add(const Duration(days: 84)),
      themeColorHex: '#0D9488', // Emerald Teal
      memo: '비에이 크리스마스 나무 & 조잔케이 료칸 온천',
      packingList: [
        const PackingCheckItem(id: 'p-sap-1', title: '방수 방한화 & 아이젠', category: '의류 & 잡화', isChecked: false),
        const PackingCheckItem(id: 'p-sap-2', title: '방한 장갑 & 넥워머', category: '의류 & 잡화', isChecked: false),
        const PackingCheckItem(id: 'p-sap-3', title: '붙이는 핫팩 & 발바닥 핫팩', category: '위생 & 상비약', isChecked: false),
        const PackingCheckItem(id: 'p-sap-4', title: '료칸 숙박 바우처 출력', category: '필수 서류', isChecked: false),
      ],
      daySchedules: [
        DayScheduleItem(
          id: 'ds-sap-1',
          dayNumber: 1,
          date: now.add(const Duration(days: 80)),
          time: '10:45',
          title: '신치토세 공항 도착 & JR 쾌속 에어포트',
          location: '신치토세 공항 국제선 청사',
          reservationCode: 'OZ174',
        ),
      ],
    ),
  ];
}

/// 초기 여행 사이사이 계획(Inter-Trip Plans) 샘플 데이터
List<InterTripPlan> getInitialMockInterPlans() {
  final now = DateTime.now();

  return [
    InterTripPlan(
      id: 'plan-inter-1',
      title: '오사카 특급 라피트 열차 왕복권 예매',
      date: now.add(const Duration(days: 15)),
      time: '14:00',
      isCompleted: true,
      beforeTripId: 'trip-jeju',
      afterTripId: 'trip-osaka',
      memo: '클룩 모바일 바우처 할인 쿠폰 적용',
    ),
    InterTripPlan(
      id: 'plan-inter-2',
      title: '엔화(JPY) 우대 환전 신청 (트래블로그)',
      date: now.add(const Duration(days: 22)),
      time: '11:00',
      isCompleted: false,
      beforeTripId: 'trip-jeju',
      afterTripId: 'trip-osaka',
      memo: '환율 900원 초반대 알림 설정 확인',
    ),
    InterTripPlan(
      id: 'plan-inter-3',
      title: '삿포로 조잔케이 온천 료칸 잔금 결제',
      date: now.add(const Duration(days: 50)),
      time: '10:00',
      isCompleted: false,
      beforeTripId: 'trip-osaka',
      afterTripId: 'trip-sapporo',
      memo: '가이세키 석식 포함 예약 확정 메일 보관',
    ),
    InterTripPlan(
      id: 'plan-inter-4',
      title: '비에이 투어 버스 1인 잔여 좌석 예약',
      date: now.add(const Duration(days: 62)),
      time: '16:00',
      isCompleted: false,
      beforeTripId: 'trip-osaka',
      afterTripId: 'trip-sapporo',
      memo: '청의 호수 & 흰수염 폭포 코스',
    ),
  ];
}
