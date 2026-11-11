import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hobby_item.dart';
import '../providers/hobby_provider.dart';
import 'add_hobby_modal.dart';
import 'add_hobby_schedule_modal.dart';

/// 취미(Hobby) 카테고리 메인 뷰: 복수 취미 지속일수 & D-Day 스케줄러
class HobbyCategoryView extends ConsumerWidget {
  const HobbyCategoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hobbies = ref.watch(hobbyListProvider);
    final selectedHobby = ref.watch(selectedHobbyProvider);
    final selectedHobbyId = ref.watch(selectedHobbyIdProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 복수 취미 전환 미니 칩 바 & [+ 새 취미 추가] 액션
          _buildHobbySelectorBar(context, ref, hobbies, selectedHobbyId),
          const SizedBox(height: 12),

          // 2. 상단 대표 취미 요약 카드 (소프트 세이지 톤 규격 카드)
          if (selectedHobby != null)
            _buildTopHobbyCard(context, ref, selectedHobby)
          else
            _buildEmptyHobbyCard(context),

          const SizedBox(height: 24),

          // 3. 세부 D-Day 리스트 (취미 일정 스케줄러)
          if (selectedHobby != null)
            _buildScheduleSection(context, ref, selectedHobby),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  /// 1. 복수 취미 가로 선택 칩 바
  Widget _buildHobbySelectorBar(
    BuildContext context,
    WidgetRef ref,
    List<HobbyItem> hobbies,
    String? selectedHobbyId,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final hobby in hobbies) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(hobby.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      hobby.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: hobby.id == selectedHobbyId
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: hobby.id == selectedHobbyId
                            ? const Color(0xFF354235)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                selected: hobby.id == selectedHobbyId,
                selectedColor: const Color(0xFFDDE7DD),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: hobby.id == selectedHobbyId
                        ? const Color(0xFF354235)
                        : const Color(0xFFE5E7EB),
                    width: hobby.id == selectedHobbyId ? 1.5 : 1,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    ref.read(selectedHobbyIdProvider.notifier).state = hobby.id;
                  }
                },
              ),
            ),
          ],

          // [+ 새 취미 추가] 칩
          ActionChip(
            avatar: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF354235)),
            label: const Text(
              '새 취미',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF354235),
              ),
            ),
            backgroundColor: const Color(0xFFF4F7F4),
            side: const BorderSide(color: Color(0xFFDDE7DD)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => AddHobbyModal.show(context),
          ),
        ],
      ),
    );
  }

  /// 2. 상단 취미 대표 카드 (파스텔 소프트 세이지 테마 & Y2K 도트 뱃지)
  Widget _buildTopHobbyCard(
    BuildContext context,
    WidgetRef ref,
    HobbyItem hobby,
  ) {
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F4), // 소프트 세이지 배경
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE7DD), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 행: 취미 이름 + 편집 버튼 + 새 취미 추가 버튼
          Row(
            children: [
              Expanded(
                child: Text(
                  hobby.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF354235),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF5A6E5A)),
                tooltip: '취미 수정',
                onPressed: () => AddHobbyModal.show(context, initialHobby: hobby),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => AddHobbyModal.show(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDDE7DD)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: Color(0xFF354235)),
                      SizedBox(width: 4),
                      Text(
                        '취미 추가',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF354235),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // 중앙/하단 행: 좌측 원형 아바타 + 우측 지속일수(Y2K 도트 뱃지) & 시작일
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // [좌측 원형 아바타]: 취미 대표 이모지 또는 직접 등록한 사진
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDDE7DD), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: hobby.imagePath != null
                    ? ClipOval(
                        child: Image.file(
                          File(hobby.imagePath!),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(hobby.icon, style: const TextStyle(fontSize: 36)),
              ),
              const SizedBox(width: 16),

              // [우측 정보]: Y2K 도트 뱃지(지속일수) & 시작일 1줄 표기
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Y2K 도트 뱃지: "시작한 지 142일째"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF354235),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            offset: Offset(0, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF86EFAC), // 비비드 네온 그린 도트
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hobby.daysSinceStartText(now),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 서브 칩: "2026.06.14 시작" (군더더기 없는 미니멀 표기)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDDE7DD)),
                      ),
                      child: Text(
                        hobby.formattedStartDate,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5E4B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  /// 빈 상태 취미 카드
  Widget _buildEmptyHobbyCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE7DD), width: 1.5),
      ),
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎨', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text(
            '등록된 취미가 없어요',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF354235)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => AddHobbyModal.show(context),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('취미 등록하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF354235),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. 세부 D-Day 리스트 (취미 일정 스케줄러)
  Widget _buildScheduleSection(
    BuildContext context,
    WidgetRef ref,
    HobbyItem hobby,
  ) {
    final schedules = ref.watch(schedulesForHobbyProvider(hobby.id));
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '다가오는 취미 일정',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE7DD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${schedules.where((s) => !s.isCompleted && !s.isPast(now)).length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF354235),
                    ),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => AddHobbyScheduleModal.show(context, hobbyId: hobby.id),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF354235)),
              label: const Text(
                '일정 추가',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF354235),
                ),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 일정 목록 렌더링
        if (schedules.isEmpty)
          _buildEmptyScheduleBox(context, hobby.id)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = schedules[index];
              return _buildScheduleCard(context, ref, item, now);
            },
          ),
      ],
    );
  }

  /// 단일 취미 일정 카드
  Widget _buildScheduleCard(
    BuildContext context,
    WidgetRef ref,
    HobbyScheduleItem item,
    DateTime now,
  ) {
    final isPast = item.isPast(now);
    final isDone = item.isCompleted || isPast;
    final dDayText = item.dDayBadge(now);

    return InkWell(
      onTap: () => AddHobbyScheduleModal.show(
        context,
        hobbyId: item.hobbyId,
        initialSchedule: item,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFFAFAFA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? const Color(0xFFE5E7EB) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isDone
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // [좌측]: 심플 완료 체크박스
            InkWell(
              onTap: () {
                ref.read(hobbyScheduleListProvider.notifier).toggleSchedule(item.id);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: item.isCompleted ? const Color(0xFF354235) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: item.isCompleted ? const Color(0xFF354235) : const Color(0xFFD1D5DB),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: item.isCompleted
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // [중앙]: 일정명 + 일시 + 장소
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: item.isCompleted
                          ? Colors.grey.shade400
                          : (isPast ? Colors.grey.shade600 : const Color(0xFF1F2937)),
                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        item.formattedDateTime,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDone ? Colors.grey.shade400 : const Color(0xFF6B7280),
                        ),
                      ),
                      if (item.location != null && item.location!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '📍 ${item.location!}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDone ? Colors.grey.shade400 : const Color(0xFF4B5E4B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // [우측]: D-Day 뱃지 (ex. D-6, 03:15 남음)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.isCompleted
                    ? Colors.grey.shade100
                    : (dDayText.contains('남음')
                        ? const Color(0xFFFEF3C7) // 임박 강조
                        : const Color(0xFFF4F7F4)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: item.isCompleted
                      ? Colors.grey.shade300
                      : (dDayText.contains('남음')
                          ? const Color(0xFFFCD34D)
                          : const Color(0xFFDDE7DD)),
                ),
              ),
              child: Text(
                item.isCompleted ? '완료' : dDayText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: item.isCompleted
                      ? Colors.grey.shade400
                      : (dDayText.contains('남음')
                          ? const Color(0xFFB45309)
                          : const Color(0xFF354235)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 빈 일정 박스
  Widget _buildEmptyScheduleBox(BuildContext context, String hobbyId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.event_available_rounded, size: 36, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 10),
          const Text(
            '등록된 다음 일정이 없어요',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 4),
          const Text(
            '[+ 취미 일정 추가]로 다가올 일정을 계획해 보세요!',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => AddHobbyScheduleModal.show(context, hobbyId: hobbyId),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('취미 일정 등록'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF354235),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
