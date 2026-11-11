import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';

/// 2D 플랫 라인 및 레트로 픽셀/미니멀 심볼 프리셋
const List<String> kMinimalEmoticonPresets = [
  '❤️', // 하트
  '💍', // 반지
  '💌', // 편지
  '📔', // 다이어리
  '🎨', // 팔레트 (취미)
  '🎸', // 기타 (취미)
  '🎮', // 게임기 (취미)
  '✈️', // 비행기 (여행)
  '🧳', // 캐리어 (여행)
  '🌴', // 야자수 (여행)
  '🗺️', // 지도 (여행)
  '📅', // 달력
  '🌱', // 새싹
  '⭐', // 별
  '🎀', // 리본
  '☕', // 커피
  '🎯', // 타겟
  '🐾', // 발자국
  '🧸', // 곰인형
];

/// 아기 카테고리 카드 폼 팩터와 1:1 일치하는 커플 & 나만의 카테고리 상단 통일 카드
///
/// 레이아웃 구성:
/// - 좌측: 원형 프로필 아바타 (펜슬 수정 버튼)
/// - 우측 상단: 카테고리명/닉네임 + 대표 심볼 (깔끔한 2D 플랫 라인 / 픽셀 이모티콘)
/// - 우측 중앙: 핵심 D-Day 일수 (ex. "사랑한 지 520일째", "목표 D-45")
/// - 하단: 라운드 서브 배지(재회 기간 제외 정보, 시작일) + [섹션 관리] 버튼
class UnifiedCategoryTopCard extends StatelessWidget {
  const UnifiedCategoryTopCard({
    super.key,
    required this.categoryKey,
    required this.title,
    required this.symbol,
    required this.coreDDayText,
    this.startDateText,
    this.reunionOrExtraBadge,
    this.photoUrl,
    this.fallbackEmoji,
    this.onEditAvatar,
    this.onManageSection,
    this.onHideCard,
    this.manageSectionText = '섹션 관리',
    this.onTapCard,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
  });

  final String categoryKey;
  final String title;
  final String symbol;
  final String coreDDayText;
  final String? startDateText;
  final String? reunionOrExtraBadge;
  final String? photoUrl;
  final String? fallbackEmoji;
  final VoidCallback? onEditAvatar;
  final VoidCallback? onManageSection;
  final VoidCallback? onHideCard;
  final String manageSectionText;
  final VoidCallback? onTapCard;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;

  bool get _isCouple => categoryKey == 'couple';

  Color get _resolvedBg {
    if (backgroundColor != null) return backgroundColor!;
    if (categoryKey == 'couple') return AppColors.coupleBg;
    if (categoryKey == 'hobby') return AppColors.hobbyBg;
    if (categoryKey == 'travel') return AppColors.travelBg;
    if (categoryKey == 'wedding') return AppColors.weddingBg;
    return AppColors.myCategoryBg;
  }

  Color get _resolvedBorder {
    if (borderColor != null) return borderColor!;
    if (categoryKey == 'couple') return AppColors.coupleBorder;
    if (categoryKey == 'hobby') return AppColors.hobbyBorder;
    if (categoryKey == 'travel') return AppColors.travelBorder;
    if (categoryKey == 'wedding') return AppColors.weddingBorder;
    return AppColors.myCategoryBorder;
  }

  Color get _resolvedText {
    if (textColor != null) return textColor!;
    if (categoryKey == 'couple') return AppColors.coupleText;
    if (categoryKey == 'hobby') return AppColors.hobbyText;
    if (categoryKey == 'travel') return AppColors.travelText;
    if (categoryKey == 'wedding') return AppColors.weddingText;
    return AppColors.myCategoryText;
  }

  String get _resolvedFallbackEmoji {
    if (fallbackEmoji != null) return fallbackEmoji!;
    if (categoryKey == 'couple') return '❤️';
    if (categoryKey == 'hobby') return '🎨';
    if (categoryKey == 'travel') return '✈️';
    if (categoryKey == 'wedding') return '💍';
    return '📔';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _resolvedBg;
    final bColor = _resolvedBorder;
    final tColor = _resolvedText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: bColor, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. 좌측: 원형 프로필 아바타 (펜슬 수정 버튼 포함)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: bColor, width: 1.5),
                      color: Colors.white,
                    ),
                    child: photoUrl != null && photoUrl!.isNotEmpty
                        ? CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(photoUrl!),
                          )
                        : CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Text(
                              _resolvedFallbackEmoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                  ),
                  if (onEditAvatar != null)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: InkWell(
                        onTap: onEditAvatar,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(4.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: bColor, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 11,
                            color: tColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // 2. 우측 정보 영역 (상단 타이틀/심볼 + 중앙 핵심 D-Day)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 우측 상단: 카테고리명/닉네임 + 대표 심볼
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTypography.cardLabel.copyWith(
                              color: tColor.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          symbol,
                          style: const TextStyle(fontSize: 15),
                        ),
                        if (onHideCard != null) ...[
                          const Spacer(),
                          InkWell(
                            onTap: onHideCard,
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_off_outlined, size: 13, color: Color(0xFF94A3B8)),
                                  SizedBox(width: 3),
                                  Text(
                                    '카드 숨기기',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 우측 중앙: 핵심 D-Day 일수
                    Text(
                      coreDDayText,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: tColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0x14000000)),
          const SizedBox(height: 12),

          // 3. 하단: 라운드 서브 배지(재회 기간 제외 정보, 시작일) + [섹션 관리] 버튼
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (startDateText != null && startDateText!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: bColor, width: 1.0),
                        ),
                        child: Text(
                          startDateText!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: tColor.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    if (reunionOrExtraBadge != null && reunionOrExtraBadge!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: bColor, width: 1.0),
                        ),
                        child: Text(
                          reunionOrExtraBadge!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _isCouple ? const Color(0xFFE11D48) : tColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onManageSection != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onManageSection,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: bColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 13,
                          color: tColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          manageSectionText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: tColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
