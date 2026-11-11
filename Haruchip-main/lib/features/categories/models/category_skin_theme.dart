import 'package:flutter/material.dart';

/// Y2K 블로그형 스킨/테마 패턴 유형
enum SkinPatternType {
  none,
  dot,
  grid,
  pixelHeart,
  diagonalStripes;

  String toJson() {
    switch (this) {
      case SkinPatternType.none:
        return 'none';
      case SkinPatternType.dot:
        return 'dot';
      case SkinPatternType.grid:
        return 'grid';
      case SkinPatternType.pixelHeart:
        return 'pixel_heart';
      case SkinPatternType.diagonalStripes:
        return 'diagonal_stripes';
    }
  }

  static SkinPatternType fromJson(String? value) {
    switch (value) {
      case 'dot':
        return SkinPatternType.dot;
      case 'grid':
        return SkinPatternType.grid;
      case 'pixel_heart':
      case 'pixelHeart':
        return SkinPatternType.pixelHeart;
      case 'diagonal_stripes':
      case 'diagonalStripes':
        return SkinPatternType.diagonalStripes;
      case 'none':
      default:
        return SkinPatternType.none;
    }
  }

  String get labelKo {
    switch (this) {
      case SkinPatternType.none:
        return '없음';
      case SkinPatternType.dot:
        return '픽셀 도트';
      case SkinPatternType.grid:
        return '모눈 격자';
      case SkinPatternType.pixelHeart:
        return '픽셀 하트';
      case SkinPatternType.diagonalStripes:
        return '대각 스트라이프';
    }
  }
}

/// Y2K 블로그형 스킨 테두리(보더) 스타일
enum SkinBorderStyle {
  none,
  solid,
  dotted,
  dashed,
  retroDouble,
  window98Bevel;

  String toJson() {
    switch (this) {
      case SkinBorderStyle.none:
        return 'none';
      case SkinBorderStyle.solid:
        return 'solid';
      case SkinBorderStyle.dotted:
        return 'dotted';
      case SkinBorderStyle.dashed:
        return 'dashed';
      case SkinBorderStyle.retroDouble:
        return 'retro_double';
      case SkinBorderStyle.window98Bevel:
        return 'window98_bevel';
    }
  }

  static SkinBorderStyle fromJson(String? value) {
    switch (value) {
      case 'solid':
        return SkinBorderStyle.solid;
      case 'dotted':
        return SkinBorderStyle.dotted;
      case 'dashed':
        return SkinBorderStyle.dashed;
      case 'retro_double':
      case 'retroDouble':
        return SkinBorderStyle.retroDouble;
      case 'window98_bevel':
      case 'window98Bevel':
        return SkinBorderStyle.window98Bevel;
      case 'none':
      default:
        return SkinBorderStyle.none;
    }
  }

  String get labelKo {
    switch (this) {
      case SkinBorderStyle.none:
        return '테두리 없음';
      case SkinBorderStyle.solid:
        return '실선';
      case SkinBorderStyle.dotted:
        return '도트 점선';
      case SkinBorderStyle.dashed:
        return '대시 점선';
      case SkinBorderStyle.retroDouble:
        return '레트로 이중선';
      case SkinBorderStyle.window98Bevel:
        return '윈도우98 입체 음영';
    }
  }
}

/// DB 영속성 및 확장을 고려한 독립 테마 데이터 모델
@immutable
class CategorySkinTheme {
  const CategorySkinTheme({
    required this.id,
    required this.name,
    this.backgroundColor = '#FFF0F5',
    this.patternType = 'none',
    this.patternColor = '#FFFFFF',
    this.patternOpacity = 0.20,
    this.borderStyle = 'solid',
    this.borderColor = '#FF85A2',
    this.borderWidth = 1.5,
    this.borderRadius = 16.0,
    this.accentEmoji = '💖',
    this.textColor = '#111827',
  });

  /// 스킨 고유 식별자
  final String id;

  /// 스킨 표시 이름 (예: 사이버 핑크 2000)
  final String name;

  /// 전체/카드 배경색 HEX (예: '#FFF0F5')
  final String backgroundColor;

  /// 패턴 유형 문자열 ('none', 'dot', 'grid', 'pixel_heart', 'diagonal_stripes')
  final String patternType;

  /// 패턴 자체의 색상 HEX (배경색과 분리 가능)
  final String patternColor;

  /// 패턴 불투명도 (기본 0.15~0.25, 텍스트 가독성 안전 마진)
  final double patternOpacity;

  /// 테두리 스타일 문자열 ('none', 'solid', 'dotted', 'dashed', 'retro_double', 'window98_bevel')
  final String borderStyle;

  /// 테두리 선 색상 HEX
  final String borderColor;

  /// 테두리 선 굵기 (px)
  final double borderWidth;

  /// 모서리 둥글기 (0: 직각 레트로, 8~24: 둥근 모서리)
  final double borderRadius;

  /// 대표 강조 이모지/아이콘
  final String accentEmoji;

  /// 텍스트 색상 HEX
  final String textColor;

  SkinPatternType get patternTypeEnum => SkinPatternType.fromJson(patternType);
  SkinBorderStyle get borderStyleEnum => SkinBorderStyle.fromJson(borderStyle);

  CategorySkinTheme copyWith({
    String? id,
    String? name,
    String? backgroundColor,
    String? patternType,
    String? patternColor,
    double? patternOpacity,
    String? borderStyle,
    String? borderColor,
    double? borderWidth,
    double? borderRadius,
    String? accentEmoji,
    String? textColor,
  }) {
    return CategorySkinTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      patternType: patternType ?? this.patternType,
      patternColor: patternColor ?? this.patternColor,
      patternOpacity: patternOpacity ?? this.patternOpacity,
      borderStyle: borderStyle ?? this.borderStyle,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      accentEmoji: accentEmoji ?? this.accentEmoji,
      textColor: textColor ?? this.textColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'backgroundColor': backgroundColor,
        'patternType': patternType,
        'patternColor': patternColor,
        'patternOpacity': patternOpacity,
        'borderStyle': borderStyle,
        'borderColor': borderColor,
        'borderWidth': borderWidth,
        'borderRadius': borderRadius,
        'accentEmoji': accentEmoji,
        'textColor': textColor,
      };

  factory CategorySkinTheme.fromJson(Map<String, dynamic> json) {
    return CategorySkinTheme(
      id: json['id'] as String? ?? 'custom_skin',
      name: json['name'] as String? ?? '사용자 커스텀 스킨',
      backgroundColor: json['backgroundColor'] as String? ?? '#FFF0F5',
      patternType: json['patternType'] as String? ?? 'none',
      patternColor: json['patternColor'] as String? ?? '#FFFFFF',
      patternOpacity: (json['patternOpacity'] as num?)?.toDouble() ?? 0.20,
      borderStyle: json['borderStyle'] as String? ?? 'solid',
      borderColor: json['borderColor'] as String? ?? '#FF85A2',
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 1.5,
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 16.0,
      accentEmoji: json['accentEmoji'] as String? ?? '💖',
      textColor: json['textColor'] as String? ?? '#111827',
    );
  }
}

/// Y2K 무드의 큐레이션 기본 프리셋 5종
class Y2kSkinPresets {
  const Y2kSkinPresets._();

  /// 1. [사이버 핑크 2000]: 딸기우유 핑크 배경 + 픽셀 화이트 도트 + 핑크 테두리
  static const cyberPink2000 = CategorySkinTheme(
    id: 'cyber_pink_2000',
    name: '사이버 핑크 2000',
    backgroundColor: '#FFE8F0',
    patternType: 'dot',
    patternColor: '#FFFFFF',
    patternOpacity: 0.35,
    borderStyle: 'solid',
    borderColor: '#FF85A2',
    borderWidth: 2.0,
    borderRadius: 18.0,
    accentEmoji: '💖',
    textColor: '#9C1A45',
  );

  /// 2. [윈도우 픽셀 클래식]: 레트로 그레이시 블루 + 직각 입체 보더 + 네이비 타이틀
  static const windowsPixelClassic = CategorySkinTheme(
    id: 'windows_pixel_classic',
    name: '윈도우 픽셀 클래식',
    backgroundColor: '#C5CBD9',
    patternType: 'none',
    patternColor: '#FFFFFF',
    patternOpacity: 0.20,
    borderStyle: 'window98_bevel',
    borderColor: '#808080',
    borderWidth: 3.0,
    borderRadius: 0.0,
    accentEmoji: '💻',
    textColor: '#000080',
  );

  /// 3. [밀크 옐로우 다이어리]: 크림 옐로우 배경 + 잔잔한 체크 격자 + 브라운 점선 테두리
  static const milkYellowDiary = CategorySkinTheme(
    id: 'milk_yellow_diary',
    name: '밀크 옐로우 다이어리',
    backgroundColor: '#FFF9E6',
    patternType: 'grid',
    patternColor: '#E6D5AC',
    patternOpacity: 0.35,
    borderStyle: 'dashed',
    borderColor: '#8C6D52',
    borderWidth: 1.8,
    borderRadius: 14.0,
    accentEmoji: '📖',
    textColor: '#5D4037',
  );

  /// 4. [민트 소다 레트로]: 파스텔 민트 + 민트그린 하트 패턴 + 모던 라인
  static const mintSodaRetro = CategorySkinTheme(
    id: 'mint_soda_retro',
    name: '민트 소다 레트로',
    backgroundColor: '#E0F7F6',
    patternType: 'pixel_heart',
    patternColor: '#80CBC4',
    patternOpacity: 0.30,
    borderStyle: 'retro_double',
    borderColor: '#00897B',
    borderWidth: 3.0,
    borderRadius: 18.0,
    accentEmoji: '🫧',
    textColor: '#004D40',
  );

  /// 5. [클린 미니멀]: 선 없음(Border None) + 배경 파스텔 단색만 깔끔하게 적용
  static const cleanMinimal = CategorySkinTheme(
    id: 'clean_minimal',
    name: '클린 미니멀',
    backgroundColor: '#F8FAFC',
    patternType: 'none',
    patternColor: '#CBD5E1',
    patternOpacity: 0.15,
    borderStyle: 'none',
    borderColor: '#E2E8F0',
    borderWidth: 0.0,
    borderRadius: 20.0,
    accentEmoji: '✨',
    textColor: '#1E293B',
  );

  /// 6. [스트라이프 레트로]: 사선 스트라이프 + 도트 점선 테두리
  static const stripeRetro = CategorySkinTheme(
    id: 'stripe_retro',
    name: '스트라이프 레트로',
    backgroundColor: '#FFF0F5',
    patternType: 'diagonal_stripes',
    patternColor: '#F8BBD0',
    patternOpacity: 0.28,
    borderStyle: 'dotted',
    borderColor: '#EC407A',
    borderWidth: 2.0,
    borderRadius: 16.0,
    accentEmoji: '🎀',
    textColor: '#880E4F',
  );

  static const List<CategorySkinTheme> all = [
    cyberPink2000,
    windowsPixelClassic,
    milkYellowDiary,
    mintSodaRetro,
    cleanMinimal,
    stripeRetro,
  ];
}
