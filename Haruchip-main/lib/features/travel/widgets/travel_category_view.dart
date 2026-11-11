import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../models/inter_trip_plan.dart';
import '../models/trip_item.dart';
import '../providers/travel_provider.dart';
import 'add_inter_plan_modal.dart';
import 'add_trip_modal.dart';
import 'trip_detail_sheet.dart';

/// '여행' 카테고리 메인 뷰
/// (상단 요약 카드 + 복수 여행 세로 타임라인 로드맵 + 여행 사이사이 인서트 플랜)
class TravelCategoryView extends ConsumerWidget {
  const TravelCategoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(travelTripListProvider);
    final interPlans = ref.watch(interTripPlanListProvider);
    final nextTrip = ref.watch(nextTripProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 상단 요약 카드 (파스텔 스카이 블루 #F0F8FF / #D6ECFF / #2C3E50)
        _buildTopSummaryCard(context, nextTrip),
        const SizedBox(height: 20),

        // 2. 타임라인 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Text('🗺️', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '여행 로드맵 타임라인',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '총 ${trips.length}개 여행 등록됨',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 3. 세로 타임라인 로드맵 (Trip Nodes & Between-Trips Inserts)
        if (trips.isEmpty)
          _buildEmptyState(context)
        else
          _buildVerticalTimeline(context, ref, trips, interPlans),
      ],
    );
  }

  /// 1. 상단 요약 카드
  Widget _buildTopSummaryCard(BuildContext context, TripItem? nextTrip) {
    String statusTitle;
    String statusSubtitle;
    String dDayBadgeText;

    if (nextTrip != null) {
      final isOngoing = nextTrip.isOngoing();
      if (isOngoing) {
        statusTitle = '${nextTrip.destination} ${nextTrip.currentDayNumber()}일차';
        statusSubtitle = '현재 설레는 여행이 진행 중입니다! 즐거운 추억 만드세요 ✨';
        dDayBadgeText = '${nextTrip.currentDayNumber()}일차';
      } else {
        final dday = nextTrip.dDayBadge();
        statusTitle = '다음 여행: ${nextTrip.emoji} ${nextTrip.destination} $dday';
        statusSubtitle = '여행 기간: ${nextTrip.dateRangeText} (${nextTrip.durationInDays - 1}박 ${nextTrip.durationInDays}일)';
        dDayBadgeText = dday;
      }
    } else {
      statusTitle = '다음 여행을 계획해 보세요';
      statusSubtitle = '새로운 여행지를 등록하고 보딩패스 타임라인을 만들어보세요!';
      dDayBadgeText = 'D-Day 설정';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF), // 파스텔 스카이 블루 배경
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6ECFF), width: 1.5), // 소프트 스카이 테두리
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.05),
            blurRadius: 12,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6ECFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✈️', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      dDayBadgeText,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),
              // 우측 상단 [+ 새 여행 추가] 액션 버튼
              ElevatedButton.icon(
                onPressed: () => AddTripModal.show(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('새 여행 추가', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            statusTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2C3E50), // 텍스트: #2C3E50
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusSubtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5A738E),
            ),
          ),
        ],
      ),
    );
  }

  /// 빈 상태 뷰
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Text('🏖️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text(
            '아직 등록된 여행 일정이 없습니다',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          const Text(
            '첫 여행을 등록하고 세로 타임라인과 가방 싸기 체크리스트를 시작해보세요!',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => AddTripModal.show(context),
            icon: const Icon(Icons.flight_takeoff_rounded, size: 18),
            label: const Text('첫 번째 여행 등록하기', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. 세로 타임라인 로드맵 (보딩패스 노드 + 사이 계획 인서트)
  Widget _buildVerticalTimeline(
    BuildContext context,
    WidgetRef ref,
    List<TripItem> trips,
    List<InterTripPlan> interPlans,
  ) {
    return Column(
      children: [
        for (int i = 0; i < trips.length; i++) ...[
          // (1) 여행 노드 (보딩패스 스타일 티켓 카드)
          _buildTripNodeCard(context, trips[i]),

          // (2) 여행 사이사이 계획 인서트 (마지막 노드가 아닐 때, 혹은 각 여행 사이 공백 구간)
          if (i < trips.length - 1) ...[
            _buildInterTripInterval(
              context,
              ref,
              beforeTrip: trips[i],
              afterTrip: trips[i + 1],
              allInterPlans: interPlans,
            ),
          ] else ...[
            // 마지막 여행 이후의 사전 준비 인서트
            _buildInterTripInterval(
              context,
              ref,
              beforeTrip: trips[i],
              afterTrip: null,
              allInterPlans: interPlans,
            ),
          ],
        ],
      ],
    );
  }

  /// 보딩패스/티켓 스타일 여행 노드 카드
  Widget _buildTripNodeCard(BuildContext context, TripItem trip) {
    final dDayBadgeText = trip.dDayBadge();
    final durationDays = trip.durationInDays;

    return InkWell(
      onTap: () => TripDetailSheet.show(context, trip.id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD6ECFF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: trip.themeColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 티켓 헤더 바
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFFF0F8FF),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(trip.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              trip.destination,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: trip.isOngoing() ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        dDayBadgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 티켓 절취선 데코레이션 (좌우 반원 홈)
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.protoBackground,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Flex(
                            direction: Axis.horizontal,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              (constraints.constrainWidth() / 8).floor(),
                              (_) => const SizedBox(
                                width: 4,
                                height: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.protoBackground,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
                    ),
                  ),
                ],
              ),

              // 티켓 본문 정보 (기간, 짐 싸기 진행률 바)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${trip.dateRangeText} (${durationDays - 1}박 $durationDays일)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Row(
                          children: [
                            Text(
                              '상세 플래너',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0284C7)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 짐 싸기 진행률 미니 프로그레스 바
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text('🎒', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 4),
                            Text(
                              '짐 싸기 진행률',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                        Text(
                          trip.packingProgressText,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: trip.packingProgress,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 여행 사이사이 계획 인서트 (Interval Section with dashed line)
  Widget _buildInterTripInterval(
    BuildContext context,
    WidgetRef ref, {
    required TripItem beforeTrip,
    TripItem? afterTrip,
    required List<InterTripPlan> allInterPlans,
  }) {
    // 여행 A와 여행 B 사이의 계획들 필터링
    final relevantPlans = allInterPlans.where((p) {
      if (p.beforeTripId == beforeTrip.id) return true;
      if (afterTrip != null && p.afterTripId == afterTrip.id) return true;
      // 날짜 기준 필터
      if (afterTrip != null) {
        return p.date.isAfter(beforeTrip.endDate) && p.date.isBefore(afterTrip.startDate);
      }
      return p.date.isAfter(beforeTrip.endDate);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          // 수직 점선 타임라인
          Center(
            child: Container(
              width: 2,
              height: 20,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Color(0xFF94A3B8),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
            ),
          ),

          // 사이 계획 카드 및 [+ 사이 계획 추가] 액션 박스
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.alt_route_rounded, size: 16, color: Color(0xFF0284C7)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              afterTrip != null
                                  ? '${beforeTrip.destination} ~ ${afterTrip.destination} 사이 준비'
                                  : '다음 여행을 위한 사전 준비',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        AddInterPlanModal.show(
                          context,
                          beforeTripId: beforeTrip.id,
                          afterTripId: afterTrip?.id,
                          suggestedDate: beforeTrip.endDate.add(const Duration(days: 7)),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded, size: 14, color: Color(0xFF0284C7)),
                            Text(
                              '사이 계획 추가',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (relevantPlans.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final plan in relevantPlans) ...[
                    _buildInterPlanRow(context, ref, plan),
                    const SizedBox(height: 6),
                  ],
                ],
              ],
            ),
          ),

          // 하단 수직 점선
          Center(
            child: Container(
              width: 2,
              height: 20,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Color(0xFF94A3B8),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 개별 사이 계획 행
  Widget _buildInterPlanRow(BuildContext context, WidgetRef ref, InterTripPlan plan) {
    final dDayText = plan.dDayLabel();

    return InkWell(
      onTap: () {
        AddInterPlanModal.show(context, initialPlan: plan);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Checkbox(
              value: plan.isCompleted,
              activeColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (_) {
                ref.read(interTripPlanListProvider.notifier).togglePlan(plan.id);
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: plan.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                      decoration: plan.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    plan.time != null ? '${plan.formattedDate} · ${plan.time}' : plan.formattedDate,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                dDayText,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF94A3B8)),
              onPressed: () {
                ref.read(interTripPlanListProvider.notifier).deletePlan(plan.id);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
