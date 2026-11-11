import '../../onboarding/data/onboarding_categories.dart';
import '../../onboarding/models/onboarding_category.dart';

/// 카테고리 & 디데이 명세 §4 `ddayTitlePlaceholder`를 그대로 이식한 맵.
///
/// 명세 원문의 `CategoryType.project`는 이 저장소의 기존 `categoryKey`
/// (CLAUDE.md §4: exam|birthday|pet|plan|solo|military|couple)와 대조했을
/// 때 의미가 겹치는 게 `plan`("계획/업무/학업/시험/군대 공통" §2)이라
/// 별도 키를 만들지 않고 `plan`에 이식했다. `custom`은 아직 이 저장소에
/// 자유 생성 카테고리 키가 없어(§7 우선순위상 다음 단계) placeholder만
/// 미리 마련해 둔다. `solo`는 명세 §4에 없던 값이라 프로토타입 톤에 맞춰
/// 새로 하나 지었다 — 확정 카피는 아니다.
const Map<String, String> ddayTitlePlaceholder = {
  'custom': '예: 우리 가족 기념일, 버킷리스트, 여행',
  'couple': '예: 우리 100일, 여행 기념일',
  'birthday': '예: 엄마 생신, ○○이 생일',
  'military': '예: 전역까지, 첫 휴가',
  'exam': '예: 정보처리기사 필기, 토익',
  'baby': '예: 첫 뒤집기, 백일 사진',
  'pet': '예: 병원 예약, 산책',
  'plan': '예: 클라이언트 미팅, 친구와의 약속',
  'goal': '예: 올해 토익 900점, 유럽 배낭여행',
  'routine': '예: 매주 월/수 필라테스, 매일 독서 30분',
  'solo': '예: 나홀로 제주 여행, 바디프로필',
  'fandom': '예: 최애 컴백일, 콘서트 티켓팅, 팬미팅',
  'hobby': '예: 기타 연습, 러닝 크루, 독서',
  'travel': '예: 오사카 여행, 제주도 한 달 살기',
  'wedding': '예: 웨딩홀 투어, 스튜디오 촬영, 본식',
};

/// 전체 카테고리 타입 목록.
const List<OnboardingCategory> kCategoryTypes = kOnboardingCategories;

/// 디데이 추가 화면의 구글 캘린더 연동 토글 초깃값(카테고리별) — 디데이
/// 추가 화면 명세 §3 예시("시험/계획 카테고리는 기본 ON, 커플/생일은
/// 기본 OFF")를 그대로 반영했다. 문서 자체가 "추후 확정"이라고 명시해서
/// 여기 없는 categoryKey는 전부 기본 OFF로 취급한다(호출부가
/// `kDefaultGoogleCalendarSync[key] ?? false`로 읽는다).
const Map<String, bool> kDefaultGoogleCalendarSync = {
  'exam': true,
  'plan': true,
  'goal': true,
  'routine': true,
  'couple': false,
  'birthday': false,
};

/// [categoryKey]에 해당하는 [OnboardingCategory]를 찾는다. 못 찾으면
/// null(호출부가 'custom'류 기본값으로 대체).
OnboardingCategory? categoryTypeOf(String categoryKey) {
  for (final type in kCategoryTypes) {
    if (type.key == categoryKey) return type;
  }
  return null;
}

/// 카테고리별 고유 파스텔 Hex 색상 매핑 (빨간색 고정 버그 방지 및 실시간 동기화)
String getCategoryColorHex(String categoryKey) {
  return switch (categoryKey) {
    'couple' => '#FF8DA1', // 연핑크 (Pastel Pink)
    'solo' => '#C084FC', // 연보라 (Pastel Purple)
    'fandom' => '#FBBF24', // 파스텔 옐로우 (Pastel Yellow)
    'group' => '#34D399', // 파스텔 에메랄드 그린 (Pastel Emerald Green)
    'exam' => '#818CF8', // 파스텔 인디고/블루 (Pastel Indigo)
    'military' => '#A3E635', // 파스텔 카키/라임 (Pastel Khaki)
    'birthday' => '#F472B6', // 파스텔 로즈핑크 (Pastel Rose Pink)
    'baby' => '#FDE047', // 소프트 옐로우 (Soft Warm Yellow)
    'pet' => '#FB923C', // 파스텔 피치/오렌지 (Pastel Peach)
    'wedding' => '#FDA4AF', // 로맨틱 로즈/샴페인 (Romantic Rose Champagne)
    'hobby' => '#6EE7B7', // 파스텔 세이지/민트 (Pastel Sage/Mint)
    'travel' => '#38BDF8', // 파스텔 스카이 블루 (Pastel Sky Blue)
    'plan' => '#60A5FA', // 파스텔 블루 (Pastel Blue)
    _ => '#60A5FA',
  };
}
