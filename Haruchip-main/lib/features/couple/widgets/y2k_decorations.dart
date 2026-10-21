import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Y2K 바인더 링 스파인 (상단 중앙 나선형 링 효과)
class Y2KBinderSpine extends StatelessWidget {
  const Y2KBinderSpine({super.key, this.ringCount = 5});

  final int ringCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(ringCount, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 14,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFD1DC),
                Color(0xFFFFFFFF),
                Color(0xFFFF8DA1),
                Color(0xFFCC4E6B),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: const Color(0xFFFFB6C1), width: 0.8),
          ),
        );
      }),
    );
  }
}

/// Y2K 레이스 스티치 & 도트 다이어리 외곽 프레임
class Y2KDiaryContainer extends StatelessWidget {
  const Y2KDiaryContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF0), // 파스텔 옐로우 & 아이보리 톤
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFFF94B8), // 핑크 레이스 스티치 테두리
          width: 3.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF69B4).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            spreadRadius: -3.5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 배경 파스텔 깅엄/체크 패턴 배경 레이어
            Positioned.fill(
              child: CustomPaint(
                painter: _Y2KPlaidBackgroundPainter(),
              ),
            ),
            // 좌상단 & 우상단 리본 엠블럼
            const Positioned(
              top: 6,
              left: 8,
              child: Text('🎀', style: TextStyle(fontSize: 16)),
            ),
            const Positioned(
              top: 6,
              right: 8,
              child: Text('💖', style: TextStyle(fontSize: 16)),
            ),
            // 내부 실제 콘텐츠
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// 파스텔 깅엄/체크 & 도트 배경 페인터
class _Y2KPlaidBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFFFBE8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final stripePaint = Paint()
      ..color = const Color(0xFFFFE3EC).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    const step = 28.0;
    const stripeW = 10.0;

    // 세로 줄무늬
    for (double x = 0; x < size.width; x += step) {
      canvas.drawRect(Rect.fromLTWH(x, 0, stripeW, size.height), stripePaint);
    }
    // 가로 줄무늬
    for (double y = 0; y < size.height; y += step) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, stripeW), stripePaint);
    }

    // 도트 무늬
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    for (double x = step / 2; x < size.width; x += step) {
      for (double y = step / 2; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Y2K 3D 볼록 젤리 버튼
class Y2KJellyButton extends StatefulWidget {
  const Y2KJellyButton({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
    this.color = const Color(0xFFFF69B4),
    this.textColor = Colors.white,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final String label;
  final Widget? icon;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  State<Y2KJellyButton> createState() => _Y2KJellyButtonState();
}

class _Y2KJellyButtonState extends State<Y2KJellyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                HSLColor.fromColor(widget.color).withLightness((HSLColor.fromColor(widget.color).lightness + 0.15).clamp(0.0, 1.0)).toColor(),
                widget.color,
                HSLColor.fromColor(widget.color).withLightness((HSLColor.fromColor(widget.color).lightness - 0.12).clamp(0.0, 1.0)).toColor(),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4),
                blurRadius: _isPressed ? 2 : 8,
                offset: Offset(0, _isPressed ? 1 : 4),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 젤리 상단 하이라이트 글래스 반사광
              Positioned(
                top: 2,
                left: 8,
                right: 8,
                height: widget.height * 0.38,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.65),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(widget.height / 3),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      shadows: const [
                        Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Y2K 젤리 프로그레스 바 (당일 목표 달성률)
class Y2KJellyProgressBar extends StatelessWidget {
  const Y2KJellyProgressBar({
    super.key,
    required this.progress, // 0.0 ~ 1.0
    required this.completedCount,
    required this.totalCount,
  });

  final double progress;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFB6C1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF69B4).withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Text('🍓', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '오늘의 달성률',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF882046),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4081),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pct% ($completedCount/$totalCount)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE8E8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFC0CB)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth * progress.clamp(0.0, 1.0);
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutBack,
                      width: barWidth,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFF8DA1),
                            Color(0xFFFF4081),
                            Color(0xFFE91E63),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4081).withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    if (barWidth > 20)
                      Positioned(
                        top: 2,
                        left: 4,
                        width: barWidth - 8,
                        height: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 빈티지 줄노트 텍스트영역 배경 페인터
class VintageLinedPaper extends StatelessWidget {
  const VintageLinedPaper({
    super.key,
    required this.child,
    this.lineHeight = 28.0,
  });

  final Widget child;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFF8), // 부드러운 미색
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD1DC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _LinedPaperPainter(lineHeight: lineHeight),
        child: child,
      ),
    );
  }
}

class _LinedPaperPainter extends CustomPainter {
  _LinedPaperPainter({required this.lineHeight});

  final double lineHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFFFC0CB).withValues(alpha: 0.45)
      ..strokeWidth = 1.0;

    for (double y = lineHeight; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), linePaint);
    }

    // 좌측 빨간 여백선 (빈티지 노트 감성)
    final marginPaint = Paint()
      ..color = const Color(0xFFFF8DA1).withValues(alpha: 0.3)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(36, 6), Offset(36, size.height - 6), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
