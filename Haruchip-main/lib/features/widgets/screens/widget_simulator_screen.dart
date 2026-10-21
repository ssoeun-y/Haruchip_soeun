import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../couple/providers/couple_provider.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';

/// 모바일 OS 표준 위젯 규격 (잠금화면, 2x2, 4x2) 시뮬레이터 & 미리보기 화면
class WidgetSimulatorScreen extends ConsumerStatefulWidget {
  const WidgetSimulatorScreen({super.key});

  @override
  ConsumerState<WidgetSimulatorScreen> createState() => _WidgetSimulatorScreenState();
}

class _WidgetSimulatorScreenState extends ConsumerState<WidgetSimulatorScreen> {
  int _selectedTabIndex = 0; // 0: 잠금화면, 1: 2x2 위젯, 2: 4x2 위젯

  @override
  Widget build(BuildContext context) {
    final allPlanItems = ref.watch(planListProvider);
    final totalDaysTogether = ref.watch(totalDaysTogetherProvider);

    final upcomingItems = allPlanItems
        .where((i) => i.displayMode != DdayDisplayMode.daysCount)
        .take(4)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.protoHeading),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '모바일 위젯 시뮬레이터',
          style: AppTypography.cardLabel.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.protoHeading,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 위젯 탭 선택기
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTab('🔒 잠금화면 (1x1)', 0),
                  _buildTab('🖼️ 홈 2x2 (감성형)', 1),
                  _buildTab('📊 홈 4x2 (캘린더)', 2),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 선택된 위젯 라이브 렌더링
            Center(
              child: _selectedTabIndex == 0
                  ? _buildLockScreenWidget(upcomingItems)
                  : (_selectedTabIndex == 1
                      ? _buildHome2x2Widget(totalDaysTogether, upcomingItems)
                      : _buildHome4x2Widget(upcomingItems)),
            ),
            const SizedBox(height: 32),

            // 위젯 가이드 및 설치 방법 안내
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '스마트폰 홈/잠금화면에 위젯 추가하는 법',
                          style: AppTypography.cardLabel.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.protoHeading,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGuideStep('1', '스마트폰 홈 화면 또는 잠금화면의 빈 공간을 길게 꾹 누릅니다.'),
                  _buildGuideStep('2', '좌상단 [+] 버튼 또는 [위젯] 메뉴를 선택합니다.'),
                  _buildGuideStep('3', '앱 목록에서 [하루칩]을 검색하고 원하는 크기의 위젯을 추가합니다.'),
                  _buildGuideStep('4', '디데이와 카운트업이 실시간 자동 갱신됩니다.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          margin: const EdgeInsets.all(3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? AppColors.protoHeading : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  /// 1. 잠금화면 미니 위젯 (Inline / Circular / Rectangular)
  Widget _buildLockScreenWidget(List<PlanItem> upcomingItems) {
    final topItem = upcomingItems.isNotEmpty
        ? upcomingItems.first
        : PlanItem(id: 'mock', title: '커플 1000일', date: DateTime.now().add(const Duration(days: 12)), categoryKey: 'couple');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '10월 7일 수요일',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text(
            '09:41',
            style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w300, letterSpacing: -1),
          ),
          const SizedBox(height: 16),

          // 잠금화면 Inline 텍스트 위젯
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💍', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                // 실제 잠금화면 한 줄 위젯처럼 길면 말줄임
                Flexible(
                  child: Text(
                    '${topItem.title} ${dDayLabel(topItem.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 직사각형(Rectangular) & 원형(Circular) 모노톤 위젯
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rectangular 위젯
              Container(
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      topItem.title,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dDayLabel(topItem.date),
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Circular 위젯
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                // 원형 위젯은 크기가 고정이라 큰 글씨 설정에서도 원 안에 맞춰 줄인다.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('D-Day', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
                    Text(
                      dDayLabel(topItem.date).replaceAll('D-', ''),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. 홈 화면 2x2 위젯 (사진 / 감성형)
  Widget _buildHome2x2Widget(int totalDays, List<PlanItem> upcomingItems) {
    return Container(
      width: 170,
      height: 170,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFE4E6), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE4E6),
                  shape: BoxShape.circle,
                ),
                child: const Text('❤️', style: TextStyle(fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '커플 위젯',
                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '우리 함께한 지',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF881337), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 1),
              Text(
                'D+$totalDays일',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE11D48),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Row(
            children: [
              Icon(Icons.cake_outlined, size: 12, color: Color(0xFF881337)),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '다음 1000일 기념일까지',
                  style: TextStyle(fontSize: 10, color: Color(0xFF881337), fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. 홈 화면 4x2 위젯 (스마트 캘린더 & D-Day 그리드형)
  Widget _buildHome4x2Widget(List<PlanItem> upcomingItems) {
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      height: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // 좌측: 오늘 날짜 미니 달력 & 당일 일정
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${now.month}월',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF007AFF)),
                    ),
                    Text(
                      '${now.day}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppColors.protoHeading,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF007AFF)),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '오늘 등록된 일정 2건',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(width: 12),

          // 우측: 가장 임박한 D-Day 4개 2x2 그리드 라벨 칩
          Expanded(
            flex: 6,
            child: upcomingItems.isEmpty
                ? const Center(
                    child: Text('등록된 D-Day 없음', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final item in upcomingItems.take(3)) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.protoHeading,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  dDayLabel(item.date),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF007AFF),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: AppColors.protoHeading, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
