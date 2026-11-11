import 'package:flutter/material.dart';

/// 하루칩 디자인 토큰 — 색상.
///
/// 화면 코드에서 Color(0x...) 하드코딩 금지, 항상 이 파일의 토큰을 참조한다.
/// (CLAUDE.md §6: "색상은 항상 디자인 토큰 참조, 하드코딩 금지")
///
/// NOTE: 아래 값들은 정식 브랜드 가이드가 없는 상태에서 잡은 임시 팔레트다.
/// 브랜드 가이드가 확정되면 이 파일만 교체하면 되도록 색상은 전부 여기로 모은다.
///
/// NOTE: §6이 언급하는 `kFreeColorPresets`(D-day/캘린더 등록용 무료 프리셋 7개)는
/// 색상 피커 기능을 만들 때 추가한다 — 실제 브랜드 확정 색상이 필요해 이번
/// 카테고리 선택 화면 범위에서는 임의로 정하지 않았다.
class AppColors {
  AppColors._();

  // Base
  static const Color background = Color(0xFFFFFBF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5F0EC);
  static const Color border = Color(0xFFE7DFD8);

  // Text
  static const Color textPrimary = Color(0xFF2B2320);
  static const Color textSecondary = Color(0xFF8A7F78);
  static const Color textDisabled = Color(0xFFC7BEB8);

  // Brand
  static const Color primary = Color(0xFFFF7A59);
  static const Color primaryMuted = Color(0xFFFFE7DE);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // 카테고리 유형별 액센트 (§5: 감성형 / 실용형)
  static const Color emotionalAccent = Color(0xFFFF7A9C);
  static const Color emotionalAccentMuted = Color(0xFFFFE3EA);
  static const Color practicalAccent = Color(0xFF4E8CFF);
  static const Color practicalAccentMuted = Color(0xFFE4ECFF);

  static const Color danger = Color(0xFFE0523F);

  // --- 프로토타입 팔레트 (haruchip_app.html — CLAUDE.md §5/§6) ---
  // §5/§6 "모든 화면은 haruchip_app.html의 색상·톤을 따른다" 규칙에 따라
  // 그 파일이 쓰는 Tailwind yellow/amber/gray 스케일 값을 그대로 옮겨왔다.
  // 아직 이 팔레트로 옮겨가지 않은 기존 화면(로그인 등)은 위 코랄 계열
  // 토큰을 계속 쓴다 — 전면 리테마는 이번 범위 밖이라 별도로 진행한다.
  static const Color protoBackground = Color(0xFFFFFDF4);
  static const Color protoStepLabel = Color(0xFFD97706); // amber-600
  static const Color protoHeading = Color(0xFF111827); // gray-900
  static const Color protoSubtitle = Color(0xFF6B7280); // gray-500
  static const Color protoCardBg = Color(0xFFFFFFFF); // white
  static const Color protoCardBorder = Color(0xFFF3F4F6); // gray-100
  static const Color protoCardText = Color(0xFF4B5563); // gray-600
  static const Color protoCardSelectedBg = Color(0xFFFEFCE8); // yellow-50
  static const Color protoCardSelectedBorder = Color(0xFFFACC15); // yellow-400
  static const Color protoCardSelectedText = Color(0xFF78350F); // amber-900
  static const Color protoButtonBg = Color(0xFFFACC15); // yellow-400
  static const Color protoButtonText = Color(0xFF451A03); // amber-950

  // 대시보드 뷰모드 선택 화면(라디오형 카드)은 카테고리 카드와 선택 테두리
  // 색이 다르다 — haruchip_app.html에서 그 화면만 border-yellow-300을 쓴다.
  static const Color protoRadioSelectedBorder = Color(0xFFFDE68A); // yellow-300
  static const Color protoRadioAccent = Color(0xFFEAB308); // yellow-500 (라디오 채움 색)
  static const Color protoRadioUnselected = Color(0xFF9CA3AF); // gray-400 (라디오 테두리)

  // 커플 화면 전용 핑크 톤 — haruchip_app.html의 커플 카드/커플룸(pink-50~700)을
  // 그대로 옮겨왔다. 감성형 공통 토큰(emotionalAccent)과 별도로 두는 이유는
  // html 원본이 커플에만 이 정확한 pink 스케일을 쓰기 때문이다(§5/§6).
  static const Color protoCoupleBg = Color(0xFFFDF2F8); // pink-50
  static const Color protoCoupleBgMuted = Color(0xFFFCE7F3); // pink-100
  static const Color protoCoupleText = Color(0xFFDB2777); // pink-600
  static const Color protoCoupleTextStrong = Color(0xFFBE185D); // pink-700

  // --- 네추럴 미니멀 통일 프리셋 (커플 & 나만의 카테고리 & 취미 & 여행) ---
  // [커플]: 은은한 베이비 핑크
  static const Color coupleBg = Color(0xFFFFF0F3);
  static const Color coupleBorder = Color(0xFFFFCCD5);
  static const Color coupleText = Color(0xFF4A4A4A);

  // [나만의 카테고리]: 단정한 모던 웜그레이
  static const Color myCategoryBg = Color(0xFFF8F9FA);
  static const Color myCategoryBorder = Color(0xFFE9ECEF);
  static const Color myCategoryText = Color(0xFF343A40);

  // [취미]: 편안하고 차분한 소프트 세이지/올리브 파스텔
  static const Color hobbyBg = Color(0xFFF4F7F4);
  static const Color hobbyBorder = Color(0xFFDDE7DD);
  static const Color hobbyText = Color(0xFF354235);

  // [여행]: 설레고 청량한 파스텔 스카이 블루
  static const Color travelBg = Color(0xFFF0F8FF);
  static const Color travelBorder = Color(0xFFD6ECFF);
  static const Color travelText = Color(0xFF2C3E50);

  // [결혼 준비]: 로맨틱 로즈 샴페인 파스텔
  static const Color weddingBg = Color(0xFFFFF5F5);
  static const Color weddingBorder = Color(0xFFFED7D7);
  static const Color weddingText = Color(0xFF742A2A);
  static const Color weddingPrimary = Color(0xFFE53E3E);

  /// D-day/캘린더 등록 시 색상은 무료 프리셋 7개로 고정한다(CLAUDE.md §6).
  /// 프리셋 밖 커스텀 컬러피커는 프리미엄 유료 기능이라 이번 범위(카테고리
  /// 커스텀 1~4단계)에서는 만들지 않는다 — 카테고리 생성 폼은 이 7개
  /// 배열만 스와치로 노출하면 된다.
  ///
  /// haruchip_app.html이 쓰는 Tailwind 스케일(§5/§6 톤 재현 규칙)에서
  /// 채도 있는 대표색 7개를 뽑았다: 레드/오렌지/옐로/그린/블루/퍼플/핑크.
  static const List<Color> kFreeColorPresets = [
    Color(0xFFEF4444), // red-500
    Color(0xFFF97316), // orange-500
    Color(0xFFEAB308), // yellow-500 (protoRadioAccent와 동일 톤)
    Color(0xFF22C55E), // green-500
    Color(0xFF3B82F6), // blue-500
    Color(0xFFA855F7), // purple-500
    Color(0xFFEC4899), // pink-500
  ];
}
