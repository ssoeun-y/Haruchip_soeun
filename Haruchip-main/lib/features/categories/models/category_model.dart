import 'package:flutter/material.dart';

import 'category_skin_theme.dart';

/// 배경 유형
enum BackgroundType {
  singleColor,
  gradient,
  image;

  String toJson() => name;

  static BackgroundType fromJson(String value) {
    return BackgroundType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BackgroundType.singleColor,
    );
  }
}

/// 텍스트 위치 프리셋 (5방향)
enum TextPositionPreset {
  center,
  topLeft,
  bottomLeft,
  topRight,
  bottomRight;

  String toJson() => name;

  static TextPositionPreset fromJson(String value) {
    return TextPositionPreset.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TextPositionPreset.center,
    );
  }

  Alignment get alignment => switch (this) {
        TextPositionPreset.center => Alignment.center,
        TextPositionPreset.topLeft => Alignment.topLeft,
        TextPositionPreset.bottomLeft => Alignment.bottomLeft,
        TextPositionPreset.topRight => Alignment.topRight,
        TextPositionPreset.bottomRight => Alignment.bottomRight,
      };

  String get labelKo => switch (this) {
        TextPositionPreset.center => '중앙',
        TextPositionPreset.topLeft => '좌측 상단',
        TextPositionPreset.bottomLeft => '좌측 하단',
        TextPositionPreset.topRight => '우측 상단',
        TextPositionPreset.bottomRight => '우측 하단',
      };
}

/// 스티커 / 효과 배치 정보
@immutable
class StickerConfig {
  const StickerConfig({
    required this.id,
    required this.stickerType,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.isText = false,
    this.textColor,
    this.fontSize,
    this.fontFamily,
    this.isPro = false,
  });

  final String id;
  final String stickerType;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final bool isText;
  final String? textColor;
  final double? fontSize;
  final String? fontFamily;
  final bool isPro;

  StickerConfig copyWith({
    String? id,
    String? stickerType,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    bool? isText,
    String? textColor,
    double? fontSize,
    String? fontFamily,
    bool? isPro,
  }) {
    return StickerConfig(
      id: id ?? this.id,
      stickerType: stickerType ?? this.stickerType,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      isText: isText ?? this.isText,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      isPro: isPro ?? this.isPro,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stickerType': stickerType,
        'x': x,
        'y': y,
        'scale': scale,
        'rotation': rotation,
        'isText': isText,
        'textColor': textColor,
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'isPro': isPro,
      };

  factory StickerConfig.fromJson(Map<String, dynamic> json) {
    return StickerConfig(
      id: json['id'] as String? ?? '',
      stickerType: json['stickerType'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      isText: json['isText'] as bool? ?? false,
      textColor: json['textColor'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      fontFamily: json['fontFamily'] as String?,
      isPro: json['isPro'] as bool? ?? false,
    );
  }
}

/// 카테고리 타이포그래피 설정
@immutable
class TypographyConfig {
  const TypographyConfig({
    this.fontFamily = 'Pretendard',
    this.textColor = '#111111',
    this.fontSize = 14.0,
    this.opacity = 1.0,
    this.position = TextPositionPreset.center,
  });

  final String fontFamily;
  final String textColor; // Hex string (e.g. #111111)
  final double fontSize;
  final double opacity; // 0.0 ~ 1.0
  final TextPositionPreset position;

  TypographyConfig copyWith({
    String? fontFamily,
    String? textColor,
    double? fontSize,
    double? opacity,
    TextPositionPreset? position,
  }) {
    return TypographyConfig(
      fontFamily: fontFamily ?? this.fontFamily,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontFamily': fontFamily,
        'textColor': textColor,
        'fontSize': fontSize,
        'opacity': opacity,
        'position': position.toJson(),
      };

  factory TypographyConfig.fromJson(Map<String, dynamic> json) {
    return TypographyConfig(
      fontFamily: json['fontFamily'] as String? ?? 'Pretendard',
      textColor: json['textColor'] as String? ?? '#111111',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      position: TextPositionPreset.fromJson(json['position'] as String? ?? 'center'),
    );
  }
}

/// 카테고리 배경 설정
@immutable
class BackgroundConfig {
  const BackgroundConfig({
    this.type = BackgroundType.singleColor,
    this.colorValues = const ['#FFF0F5'],
    this.imageUrl,
    this.decorations,
  });

  final BackgroundType type;
  final List<String> colorValues; // Hex color list
  final String? imageUrl;
  final List<StickerConfig>? decorations;

  BackgroundConfig copyWith({
    BackgroundType? type,
    List<String>? colorValues,
    String? imageUrl,
    List<StickerConfig>? decorations,
  }) {
    return BackgroundConfig(
      type: type ?? this.type,
      colorValues: colorValues ?? this.colorValues,
      imageUrl: imageUrl ?? this.imageUrl,
      decorations: decorations ?? this.decorations,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.toJson(),
        'colorValues': colorValues,
        'imageUrl': imageUrl,
        'decorations': decorations?.map((d) => d.toJson()).toList(),
      };

  factory BackgroundConfig.fromJson(Map<String, dynamic> json) {
    return BackgroundConfig(
      type: BackgroundType.fromJson(json['type'] as String? ?? ''),
      colorValues: (json['colorValues'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['#FFF0F5'],
      imageUrl: json['imageUrl'] as String?,
      decorations: (json['decorations'] as List<dynamic>?)
          ?.map((e) => StickerConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 하루칩 확장 카테고리 데이터 모델 (CategoryModel)
@immutable
class CategoryModel {
  CategoryModel({
    required this.id,
    required this.categoryKey,
    required this.name,
    String? icon,
    String? emoji,
    required this.createdAt,
    this.typography = const TypographyConfig(),
    BackgroundConfig? background,
    String? colorHex,
    String? backgroundImageUrl,
    this.metadata,
    this.isDashboardHidden = false,
    this.hiddenAt,
  })  : icon = icon ?? emoji ?? '📌',
        background = background ??
            BackgroundConfig(
              type: backgroundImageUrl != null
                  ? BackgroundType.image
                  : BackgroundType.singleColor,
              colorValues: [colorHex ?? '#FFF0F5'],
              imageUrl: backgroundImageUrl,
            );

  final String id;
  final String categoryKey;
  final String name;
  final String icon; // 이모지 또는 아이콘 코드
  final DateTime createdAt;
  final TypographyConfig typography;
  final BackgroundConfig background;
  final Map<String, dynamic>? metadata;
  final bool isDashboardHidden;
  final DateTime? hiddenAt;

  /// 기존 호환용 게터
  String get emoji => icon;
  String get colorHex => background.colorValues.isNotEmpty
      ? background.colorValues.first
      : '#FFF0F5';
  String? get backgroundImageUrl => background.imageUrl;
  bool get showVisualCard => metadata?['showVisualCard'] as bool? ?? true;

  /// Y2K 블로그형 스킨/테마 게터
  CategorySkinTheme? get skinTheme {
    final raw = metadata?['skinTheme'];
    if (raw is Map<String, dynamic>) {
      return CategorySkinTheme.fromJson(raw);
    } else if (raw is Map) {
      return CategorySkinTheme.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  CategoryModel copyWith({
    String? id,
    String? categoryKey,
    String? name,
    String? icon,
    String? emoji,
    DateTime? createdAt,
    TypographyConfig? typography,
    BackgroundConfig? background,
    String? colorHex,
    String? backgroundImageUrl,
    Map<String, dynamic>? metadata,
    bool? isDashboardHidden,
    DateTime? hiddenAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      categoryKey: categoryKey ?? this.categoryKey,
      name: name ?? this.name,
      icon: icon ?? emoji ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      typography: typography ?? this.typography,
      background: background ??
          (colorHex != null || backgroundImageUrl != null
              ? BackgroundConfig(
                  type: backgroundImageUrl != null
                      ? BackgroundType.image
                      : BackgroundType.singleColor,
                  colorValues: [colorHex ?? this.colorHex],
                  imageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
                )
              : this.background),
      metadata: metadata ?? this.metadata,
      isDashboardHidden: isDashboardHidden ?? this.isDashboardHidden,
      hiddenAt: hiddenAt ?? this.hiddenAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryKey': categoryKey,
        'name': name,
        'icon': icon,
        'createdAt': createdAt.toIso8601String(),
        'typography': typography.toJson(),
        'background': background.toJson(),
        if (metadata != null) 'metadata': metadata,
        'isDashboardHidden': isDashboardHidden,
        if (hiddenAt != null) 'hiddenAt': hiddenAt!.toIso8601String(),
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final colorHex = json['colorHex'] as String?;
    final bgImage = json['backgroundImageUrl'] as String?;
    final bgJson = json['background'] as Map<String, dynamic>?;

    BackgroundConfig bgConfig;
    if (bgJson != null) {
      bgConfig = BackgroundConfig.fromJson(bgJson);
    } else {
      bgConfig = BackgroundConfig(
        type: bgImage != null ? BackgroundType.image : BackgroundType.singleColor,
        colorValues: colorHex != null ? [colorHex] : const ['#FFF0F5'],
        imageUrl: bgImage,
      );
    }

    return CategoryModel(
      id: json['id'] as String? ?? '',
      categoryKey: json['categoryKey'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? json['emoji'] as String? ?? '📌',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      typography: json['typography'] != null
          ? TypographyConfig.fromJson(json['typography'] as Map<String, dynamic>)
          : const TypographyConfig(),
      background: bgConfig,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isDashboardHidden: json['isDashboardHidden'] as bool? ?? false,
      hiddenAt: json['hiddenAt'] != null
          ? DateTime.parse(json['hiddenAt'] as String)
          : null,
    );
  }
}

/// 하위 호환성을 위한 Type Alias
typedef Category = CategoryModel;
