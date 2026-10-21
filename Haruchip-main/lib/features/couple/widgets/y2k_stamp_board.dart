import 'package:flutter/material.dart';

/// 6칸 Y2K 플래시 감성 칭찬 도장판
class Y2KStampBoard extends StatelessWidget {
  const Y2KStampBoard({
    super.key,
    required this.stampCount,
    this.maxStamps = 6,
  });

  final int stampCount;
  final int maxStamps;

  static const List<({String icon, String label})> kStampTypes = [
    (icon: '💮', label: '참잘했어요'),
    (icon: '💖', label: '보석하트'),
    (icon: '👑', label: '왕관'),
    (icon: '⭐', label: '반짝이별'),
    (icon: '🍓', label: '상큼딸기'),
    (icon: '💯', label: '백점만점'),
  ];

  String get _encourageMessage {
    if (stampCount == 0) return '오늘의 할 일을 완료하고 칭찬 도장을 모아보세요! 🍓';
    if (stampCount <= 2) return '시작이 반이야! 차근차근 잘하고 있어요 💖';
    if (stampCount < 6) return '오늘도 대단해요! 목표까지 얼마 안 남았어요 ⭐';
    return '오늘도 최고야! 6개 도장 완성 참 잘했어요 🎉';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFB6C1), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4081).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    Text('💮', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '참 잘했어요 칭찬 도장판',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Color(0xFF882046),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFC0CB)),
                ),
                child: Text(
                  '$stampCount / $maxStamps 도장',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFFD81B60),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _encourageMessage,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFAD1457),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // 6칸 도장 슬롯 그리드 (3열 x 2행)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: maxStamps,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final isStamped = index < stampCount;
              final stampInfo = kStampTypes[index % kStampTypes.length];

              return _StampSlot(
                index: index + 1,
                isStamped: isStamped,
                icon: stampInfo.icon,
                label: stampInfo.label,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StampSlot extends StatelessWidget {
  const _StampSlot({
    required this.index,
    required this.isStamped,
    required this.icon,
    required this.label,
  });

  final int index;
  final bool isStamped;
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      decoration: BoxDecoration(
        color: isStamped ? const Color(0xFFFFF0F5) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStamped ? const Color(0xFFFF4081) : const Color(0xFFE0E0E0),
          width: isStamped ? 2.0 : 1.2,
          style: isStamped ? BorderStyle.solid : BorderStyle.solid,
        ),
        boxShadow: isStamped
            ? [
                BoxShadow(
                  color: const Color(0xFFFF4081).withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!isStamped)
            Text(
              '$index',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.withValues(alpha: 0.4),
              ),
            ),
          if (isStamped)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.2, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.bounceOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD81B60),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
