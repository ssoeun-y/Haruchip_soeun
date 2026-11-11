import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../../services/auth/apple_auth_service.dart';
import '../../../services/auth/google_auth_service.dart';
import 'category_selection_screen.dart';

/// 온보딩 플로우의 "로그인" 단계.
///
/// 전체 온보딩 순서(CLAUDE.md §8):
/// 스플래시 → 권한요청 → **로그인** → 카테고리 선택(다중) → 대시보드
/// 뷰모드 → 완료화면 → 메인셸
///
/// 이 화면은 그중 로그인 단계만 담당한다. 구글/애플은 `lib/services/auth/*`의
/// 실제 OAuth 로직(도메인 담당)에 연결돼 있다. 카카오는 CLAUDE.md §1대로
/// 보안 담당이 별도 연동하기 전까지 다음 단계로만 넘어가는 UI 스텁이다.
/// [onNext]를 넘기면 그 콜백을 대신 호출하고, 넘기지 않으면 다음 단계인
/// [CategorySelectionScreen]으로 실제 이동한다.
///
/// 로그인은 Firebase의 기본 동작대로 앱을 재실행해도 유지된다 — 앱 시작
/// 지점(`main.dart`의 `AuthGate`)이 `FirebaseAuth.instance.currentUser`를
/// 확인해서 이미 로그인된 사용자는 스플래시/로그인 화면을 건너뛰고 바로
/// [CategorySelectionScreen]으로 진입한다.
///
/// NOTE(§5/§6): haruchip_app.html 온보딩엔 로그인 화면이 별도로 존재하지
/// 않는다(인트로 → 카테고리선택 → 뷰모드선택 → 완료 4개뿐). 그래서 이
/// 화면은 "정확한 마크업 재현"이 아니라 같은 색상 토큰·컴포넌트 톤만
/// 맞춘 것이다 — 원본에 없는 상단 진행바/스텝 라벨은 만들지 않는다.
///
/// 이전에는 화면 하단에 대시보드가 없던 시절 커플/캘린더/계획 화면을
/// 바로 확인할 수 있는 "개발자용 바로가기" 임시 섹션이 있었다. 이제
/// 메인 셸(대시보드/캘린더/일정·정산방/우리의방 4탭)이 생겨서 더 이상
/// 필요하지 않아 제거했다 — 각 화면은 온보딩 완료 후 메인 셸의 탭으로
/// 정식 진입한다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onNext});

  /// 다음 단계(카테고리 선택)로 넘어갈 때 호출된다.
  final VoidCallback? onNext;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  bool get _isAnyLoading => _isGoogleLoading || _isAppleLoading;

  void _goToNextStep() {
    if (widget.onNext != null) {
      widget.onNext!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CategorySelectionScreen()),
    );
  }

  /// 카카오 로그인은 아직 실제 OAuth 연동 전 UI 스텁 — 다음 단계로만
  /// 넘어간다. (실제 로직은 보안 담당이 `lib/services/auth/*`에서 별도 구현)
  void _handleKakaoStubLogin() {
    if (_isAnyLoading) return;
    _goToNextStep();
  }

  Future<void> _handleGoogleLogin() async {
    if (_isAnyLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      await GoogleAuthService.instance.signIn();
      if (!mounted) return;
      _goToNextStep();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // 사용자가 계정 선택 창에서 취소 — 조용히 무시.
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인에 실패했습니다: ${e.description ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인에 실패했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleAppleLogin() async {
    if (_isAnyLoading) return;
    setState(() => _isAppleLoading = true);
    try {
      await AppleAuthService.instance.signIn();
      if (!mounted) return;
      _goToNextStep();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        // 사용자가 애플 로그인 시트에서 취소 — 조용히 무시.
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('애플 로그인에 실패했습니다: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('애플 로그인에 실패했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '하루칩에\n로그인해주세요',
                style: AppTypography.heading1.copyWith(
                  color: AppColors.protoHeading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '간편 로그인으로 시작하고, 다음 단계에서 관심있는 카테고리를 골라주세요.',
                style: AppTypography.bodyMuted.copyWith(
                  color: AppColors.protoSubtitle,
                ),
              ),
              const SizedBox(height: 32),
              _LoginButton(
                icon: Icons.chat_bubble_rounded,
                label: '카카오로 시작하기',
                onPressed: _isAnyLoading ? null : _handleKakaoStubLogin,
              ),
              const SizedBox(height: 12),
              _LoginButton(
                icon: Icons.apple_rounded,
                label: _isAppleLoading ? '애플 로그인 중...' : '애플로 시작하기',
                onPressed: _isAnyLoading ? null : _handleAppleLogin,
              ),
              const SizedBox(height: 12),
              _LoginButton(
                icon: Icons.g_mobiledata_rounded,
                label: _isGoogleLoading ? '구글 로그인 중...' : '구글로 시작하기',
                onPressed: _isAnyLoading ? null : _handleGoogleLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.protoCardBg,
          foregroundColor: AppColors.protoHeading,
          side: const BorderSide(color: AppColors.protoCardBorder, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: AppColors.protoHeading),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.button.copyWith(
                color: AppColors.protoHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
