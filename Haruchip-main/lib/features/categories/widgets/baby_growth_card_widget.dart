import 'dart:io';
import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../controllers/baby_category_controller.dart';
import '../models/baby_profile.dart';

/// 아기 성장 메인 카드 위젯
/// (원형 프로필 사진, 태어난 지 N일째, 상세 월령 N개월 N일차(N주 N일), 성별/혈액형/출생시간 뱃지)
class BabyGrowthCardWidget extends StatelessWidget {
  const BabyGrowthCardWidget({
    super.key,
    required this.profile,
    required this.onTapEdit,
    this.onTapManageSections,
  });

  final BabyProfile profile;
  final VoidCallback onTapEdit;
  final VoidCallback? onTapManageSections;

  static const _controller = BabyCategoryController();

  ImageProvider? _getAvatarImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return NetworkImage(url);
    final file = File(url);
    if (file.existsSync()) return FileImage(file);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final daysCountText = _controller.formatBabyDaysCount(profile.birthDate);
    final detailedAgeText = _controller.formatBabyAgeDetailed(profile.birthDate);
    final avatarImage = _getAvatarImage(profile.photoUrl);

    final isBoy = profile.gender == BabyGender.boy;
    final isGirl = profile.gender == BabyGender.girl;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isBoy
              ? const Color(0xFFBAE6FD)
              : (isGirl ? const Color(0xFFFBCFE8) : const Color(0xFFFED7AA)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapEdit,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. 원형 프로필 아바타
                    Stack(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isBoy
                                  ? const Color(0xFF38BDF8)
                                  : (isGirl ? const Color(0xFFF472B6) : const Color(0xFFFB923C)),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isBoy
                                        ? const Color(0xFF38BDF8)
                                        : (isGirl ? const Color(0xFFF472B6) : const Color(0xFFFB923C)))
                                    .withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: avatarImage != null
                                ? Image(
                                    image: avatarImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Text('👶', style: TextStyle(fontSize: 32)),
                                    ),
                                  )
                                : const Center(
                                    child: Text('👶', style: TextStyle(fontSize: 32)),
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // 2. 아기 이름 & 태어난 지 N일째
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  profile.name,
                                  style: AppTypography.heading2.copyWith(
                                    color: AppColors.protoHeading,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            daysCountText,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: isBoy
                                  ? const Color(0xFF0284C7)
                                  : (isGirl ? const Color(0xFFDB2777) : const Color(0xFFEA580C)),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 3. 상세 월령 배너 (생후 N개월 N일차 / N주 N일)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isBoy
                        ? const Color(0xFFE0F2FE)
                        : (isGirl ? const Color(0xFFFCE7F3) : const Color(0xFFFFEDD5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isBoy ? '🩵' : (isGirl ? '🩷' : '✨'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          detailedAgeText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isBoy
                                ? const Color(0xFF0369A1)
                                : (isGirl ? const Color(0xFFBE185D) : const Color(0xFFC2410C)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 4. 세부 정보 뱃지들 (성별, 혈액형, 출생시간, 수유텀)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (profile.gender != BabyGender.none)
                      _buildInfoBadge(
                        label: profile.gender.label,
                        bgColor: isBoy ? const Color(0xFFF0F9FF) : const Color(0xFFFFF1F2),
                        textColor: isBoy ? const Color(0xFF0284C7) : const Color(0xFFE11D48),
                        borderColor: isBoy ? const Color(0xFFBAE6FD) : const Color(0xFFFECDD3),
                      ),
                    if (profile.bloodType != null && profile.bloodType!.isNotEmpty)
                      _buildInfoBadge(
                        label: '${profile.bloodType}형',
                        bgColor: const Color(0xFFF8FAFC),
                        textColor: const Color(0xFF475569),
                        borderColor: const Color(0xFFE2E8F0),
                      ),
                    if (profile.birthTime != null && profile.birthTime!.isNotEmpty)
                      _buildInfoBadge(
                        label: '⏰ ${profile.birthTime} 출생',
                        bgColor: const Color(0xFFF8FAFC),
                        textColor: const Color(0xFF475569),
                        borderColor: const Color(0xFFE2E8F0),
                      ),
                    _buildInfoBadge(
                      label: '🍼 수유텀 ${profile.feedingIntervalHours}시간',
                      bgColor: const Color(0xFFFFFBEB),
                      textColor: const Color(0xFFB45309),
                      borderColor: const Color(0xFFFDE68A),
                    ),
                    if (onTapManageSections != null)
                      GestureDetector(
                        onTap: onTapManageSections,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF93C5FD), width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune_rounded, size: 12, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text(
                                '섹션 관리',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge({
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
