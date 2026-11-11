import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/app_permissions.dart';
import '../providers/app_permissions_provider.dart';
import '../widgets/toss_funnel_components.dart';
import 'category_selection_screen.dart';
import 'login_screen.dart';

/// 토스(Toss) 스타일 온보딩 퍼널 [Step 1: 앱 접근 권한 안내]
class AppPermissionScreen extends ConsumerWidget {
  const AppPermissionScreen({
    super.key,
    this.onNext,
    this.isSettingsMode = false,
  });

  final VoidCallback? onNext;
  final bool isSettingsMode;

  void _handleContinue(BuildContext context) {
    if (onNext != null) {
      onNext!();
      return;
    }
    if (isSettingsMode) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).push(
      SlideFadePageRoute(page: const CategorySelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(appPermissionsProvider);
    final notifier = ref.read(appPermissionsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            if (!isSettingsMode)
              TossStepIndicator(
                currentStep: 1,
                totalSteps: 3,
                onBack: () => Navigator.maybePop(context),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF333D4B),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '앱 접근 권한 관리',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.protoHeading,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '하루칩을 더 편리하게 쓰기 위해\n접근 권한이 필요해요',
                      style: AppTypography.heading1.copyWith(
                        color: const Color(0xFF191F28),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '선택 권한은 허용하지 않아도 해당 기능 외 기본 서비스를 계속 이용하실 수 있어요.',
                      style: AppTypography.bodyMuted.copyWith(
                        color: const Color(0xFF8B95A1),
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 전체 동의하기 카드
                    InkWell(
                      onTap: () => notifier.toggleAll(),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: permissions.allAgreed
                              ? const Color(0xFFE8F3FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: permissions.allAgreed
                                ? const Color(0xFF3182F6)
                                : const Color(0xFFE5E8EB),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: permissions.allAgreed
                                    ? const Color(0xFF3182F6)
                                    : const Color(0xFFF2F4F6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                size: 16,
                                color: permissions.allAgreed
                                    ? Colors.white
                                    : const Color(0xFFB0B8C1),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                '전체 동의하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF191F28),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '선택 항목 포함',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7684),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFE5E8EB)),
                    const SizedBox(height: 16),

                    // 개별 권한 항목 리스트
                    for (final item in kAppPermissionItems) ...[
                      _buildPermissionRow(
                        item: item,
                        isEnabled: permissions.isEnabled(item.key),
                        onToggle: () => notifier.toggle(item.key),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (!isSettingsMode) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            '이미 계정이 있으신가요? 로그인하기',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF6B7684),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            GlassFloatingButton(
              label: isSettingsMode ? '설정 완료' : '동의하고 계속하기',
              onPressed: () => _handleContinue(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow({
    required PermissionItemInfo item,
    required bool isEnabled,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? const Color(0xFF3182F6).withValues(alpha: 0.35)
                : const Color(0xFFF2F4F6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isEnabled
                    ? const Color(0xFFE8F3FF)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.icon,
                size: 20,
                color: isEnabled
                    ? const Color(0xFF3182F6)
                    : const Color(0xFF6B7684),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.isRequired ? '필수' : '선택',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: item.isRequired
                                ? const Color(0xFFE0523F)
                                : const Color(0xFF6B7684),
                          ),
                        ),
                      ),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF191F28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF8B95A1),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isEnabled,
              activeColor: const Color(0xFF3182F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              onChanged: (_) => onToggle(),
            ),
          ],
        ),
      ),
    );
  }
}
