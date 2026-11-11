import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../home/screens/main_shell_screen.dart';
import 'app_permission_screen.dart';

/// 앱 시작 스플래시 화면 (자동 전환)
///
/// 요구사항 명세:
/// - 로고 에셋(달력 아이콘)을 중앙에 배치
///   * 상단: 하루칩 로고 (미니멀 소프트 섀도우)
///   * 중앙 타이틀: HaruChip
///   * 서브 텍스트: "하루의 소중한 조각들을 담아봐요"
/// - 별도의 '시작하기' 터치 버튼 없이, 1.8초~2.0초 간 부드러운 페이드인/아웃 후
///   자동으로 화면 전환:
///   * 기존 로그인 세션 유지 유저 -> 메인 대시보드([MainShellScreen])로 즉시 진입
///   * 최초 진입 또는 미인증 유저 -> 온보딩 1단계([AppPermissionScreen])로 매끄럽게 연결
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onNext,
    this.isLoggedIn,
  });

  /// 다음 단계로 넘어갈 때 호출되는 콜백 (주로 테스트 환경)
  final VoidCallback? onNext;

  /// 기존 로그인 세션 유지 여부
  final bool? isLoggedIn;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // 1.9초 전체 주기: 페이드인 (0~600ms) -> 유지 (600~1500ms) -> 페이드아웃 (1500~1900ms)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 45.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 20.0,
      ),
    ]).animate(_animController);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60.0,
      ),
    ]).animate(_animController);

    _animController.forward();

    // 1.9초 후 자동으로 다음 온보딩 퍼널 단계로 이동
    _navigationTimer = Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      _proceedToNext();
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _proceedToNext() {
    if (widget.onNext != null) {
      widget.onNext!();
      return;
    }
    final loggedIn = widget.isLoggedIn ??
        (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null);

    final Widget targetScreen = loggedIn
        ? const MainShellScreen()
        : const AppPermissionScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBEB), Color(0xFFFFFDF9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 상단: 하루칩 로고 (미니멀 소프트 섀도우)
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.16),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 에셋 로딩 예외 시 미니멀 폴백 아이콘 노출
                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFDF00), Color(0xFFFFB300)],
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Text('🗓️', style: TextStyle(fontSize: 48)),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 중앙 타이틀: HaruChip
                  const Text(
                    'HaruChip',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 서브 텍스트: "하루의 소중한 조각들을 담아봐요"
                  const Text(
                    '하루의 소중한 조각들을 담아봐요',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
