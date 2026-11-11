import 'dart:async';
import 'package:flutter/material.dart';

import '../../home/screens/main_shell_screen.dart';

/// 토스(Toss) 스타일 온보딩 퍼널 [Step 4: 완료 인터랙션]
///
/// 요구사항 명세:
/// - 마지막 단계 완료 시 별도 팝업 확인창 없이, 화면 중앙에 "설정이 완료되었어요!" 문구와
///   체크 애니메이션이 0.8초간 표시된 후 매끄럽게 메인 대시보드로 전환(Transition).
class OnboardingCompleteScreen extends StatefulWidget {
  const OnboardingCompleteScreen({super.key, this.onFinish});

  /// 온보딩을 마칠 때 호출된다 (주로 테스트 환경).
  final VoidCallback? onFinish;

  @override
  State<OnboardingCompleteScreen> createState() =>
      _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends State<OnboardingCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkAnimController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _checkProgress;
  Timer? _autoTransitionTimer;
  bool _isTransitioned = false;

  @override
  void initState() {
    super.initState();

    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _checkAnimController,
      curve: Curves.elasticOut,
    );

    _checkProgress = CurvedAnimation(
      parent: _checkAnimController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );

    _checkAnimController.forward();

    // 0.8초 후 자동으로 메인 대시보드([MainShellScreen])로 부드럽게 화면 전환
    _autoTransitionTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (widget.onFinish != null) {
        widget.onFinish!();
      }
      setState(() => _isTransitioned = true);
    });
  }

  @override
  void dispose() {
    _autoTransitionTimer?.cancel();
    _checkAnimController.dispose();
    super.dispose();
  }

  void _handleFinish() {
    if (widget.onFinish != null) {
      widget.onFinish!();
      return;
    }
    setState(() => _isTransitioned = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isTransitioned) {
      return const PopScope(
        canPop: false,
        child: MainShellScreen(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3182F6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3182F6).withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _checkProgress,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(40, 40),
                            painter: _CheckmarkPainter(progress: _checkProgress.value),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  '설정이 완료되었어요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF191F28),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '소중한 날들을 더 빛나게,\n하루칩과 함께 시작해요 ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8B95A1),
                    height: 1.45,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: _handleFinish,
                  child: const Text(
                    '지금 바로 시작하기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3182F6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 부드러운 체크마크 드로잉 페인터
class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final p1 = Offset(size.width * 0.22, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.74);
    final p3 = Offset(size.width * 0.78, size.height * 0.30);

    path.moveTo(p1.dx, p1.dy);

    if (progress <= 0.5) {
      final t = progress / 0.5;
      final current = Offset.lerp(p1, p2, t)!;
      path.lineTo(current.dx, current.dy);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = (progress - 0.5) / 0.5;
      final current = Offset.lerp(p2, p3, t)!;
      path.lineTo(current.dx, current.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
