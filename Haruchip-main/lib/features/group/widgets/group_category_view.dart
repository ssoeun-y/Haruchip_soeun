import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/group_category_item.dart';
import '../providers/group_category_provider.dart';
import 'add_group_modal.dart';
import 'add_group_meeting_modal.dart';

/// 모임(Group) 카테고리 메인 뷰: 복수 모임 관리 & D-Day 스케줄러 & 참여/불참 체크 & 지난 일정 아카이브
class GroupCategoryView extends ConsumerStatefulWidget {
  const GroupCategoryView({super.key});

  @override
  ConsumerState<GroupCategoryView> createState() => _GroupCategoryViewState();
}

class _GroupCategoryViewState extends ConsumerState<GroupCategoryView> {
  // false: 다가오는 모임 (D-Day), true: 지난 모임 기록 (아카이브)
  bool _showPastArchive = false;

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupListProvider);
    final selectedGroup = ref.watch(selectedGroupProvider);
    final selectedGroupId = ref.watch(selectedGroupIdProvider);
    final upcomingSchedules = ref.watch(upcomingSchedulesForSelectedGroupProvider);
    final pastSchedules = ref.watch(pastSchedulesForSelectedGroupProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 복수 모임 전환 미니 칩 바 & [+ 새 모임 추가] 액션
          _buildGroupSelectorBar(context, groups, selectedGroupId),
          const SizedBox(height: 12),

          // 2. 상단 대표 모임 카드 (파스텔 피치/코럴 규격 카드)
          if (selectedGroup != null)
            _buildTopGroupCard(context, selectedGroup)
          else
            _buildEmptyGroupCard(context),

          const SizedBox(height: 20),

          // 3. 다가오는 모임 vs 지난 모임 아카이브 탭 토글
          if (selectedGroup != null) ...[
            _buildSectionToggle(
              upcomingCount: upcomingSchedules.length,
              pastCount: pastSchedules.length,
            ),
            const SizedBox(height: 14),

            // 4. 모임 일정 리스트 (다가오는 D-Day vs 지난 기록)
            if (!_showPastArchive)
              _buildUpcomingMeetingList(context, selectedGroup, upcomingSchedules)
            else
              _buildPastArchiveList(context, selectedGroup, pastSchedules),
          ],

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  /// 1. 복수 모임 가로 선택 칩 바
  Widget _buildGroupSelectorBar(
    BuildContext context,
    List<GroupCategoryItem> groups,
    String? selectedGroupId,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final group in groups) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(group.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      group.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selectedGroupId == group.id
                            ? const Color(0xFF42302A)
                            : const Color(0xFF78716C),
                      ),
                    ),
                  ],
                ),
                selected: selectedGroupId == group.id,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(selectedGroupIdProvider.notifier).state = group.id;
                  }
                },
                selectedColor: const Color(0xFFFFE2D9),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: selectedGroupId == group.id
                        ? const Color(0xFFFFB39E)
                        : const Color(0xFFE7E5E4),
                    width: selectedGroupId == group.id ? 1.5 : 1,
                  ),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
            ),
          ],
          ActionChip(
            avatar: const Icon(Icons.add, size: 16, color: Color(0xFFE26D5C)),
            label: const Text(
              '새 모임 추가',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE26D5C),
              ),
            ),
            backgroundColor: const Color(0xFFFFF5F2),
            side: const BorderSide(color: Color(0xFFFFE2D9), width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => AddGroupModal.show(context),
          ),
        ],
      ),
    );
  }

  /// 2. 상단 대표 모임 카드 (파스텔 피치/코럴 테마: 배경 #FFF5F2, 테두리 #FFE2D9, 텍스트 #42302A)
  Widget _buildTopGroupCard(BuildContext context, GroupCategoryItem group) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE2D9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE26D5C).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 아바타 아이콘/사진 + 타이틀 & 편집/삭제 메뉴 + N일째 뱃지
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 좌측 아바타
              _buildAvatarWidget(group),
              const SizedBox(width: 14),

              // 중앙: 모임명 & 멤버 수
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            group.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF42302A),
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE2D9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${group.memberCount}명',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF78350F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '개설일: ${group.foundationDate.year}.${group.foundationDate.month.toString().padLeft(2, '0')}.${group.foundationDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8C6D62),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 우측 상단: 모임 관리 팝업 메뉴
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF8C6D62)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) {
                  if (value == 'edit') {
                    AddGroupModal.show(context, existingGroup: group);
                  } else if (value == 'delete') {
                    _confirmDeleteGroup(context, group);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: Color(0xFF42302A)),
                        SizedBox(width: 8),
                        Text('모임 정보 수정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('모임 삭제', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // N일째 카운터 & 정기 모임 주기 뱃지
          Row(
            children: [
              // 모임 N일째 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD7C9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB39E)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.celebration_rounded, size: 15, color: Color(0xFFC2410C)),
                    const SizedBox(width: 6),
                    Text(
                      group.daysCountText(),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF42302A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 정기 모임 주기 정보 칩 (예: 매월 둘째 주 토요일)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE2D9)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_repeat_rounded, size: 14, color: Color(0xFFE26D5C)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          group.regularScheduleInfo,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5E453D),
                          ),
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  /// 아바타 위젯 (사진 파일 vs 이모지)
  Widget _buildAvatarWidget(GroupCategoryItem group) {
    if (group.imagePath != null && group.imagePath!.isNotEmpty) {
      final file = File(group.imagePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.file(file, width: 56, height: 56, fit: BoxFit.cover),
        );
      }
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE2D9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE26D5C).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        group.icon,
        style: const TextStyle(fontSize: 28),
      ),
    );
  }

  /// 모임이 없을 때 노출되는 빈 카드
  Widget _buildEmptyGroupCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE2D9)),
      ),
      child: Column(
        children: [
          const Text('👥', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          const Text(
            '등록된 모임이 없습니다',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF42302A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '동창회, 동호회, 스터디 모임을 추가하고\nD-Day와 정기 모임 일정을 한눈에 관리해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF8C6D62), height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => AddGroupModal.show(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('첫 모임 등록하기', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE26D5C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. 다가오는 모임 vs 지난 모임 아카이브 탭 토글
  Widget _buildSectionToggle({
    required int upcomingCount,
    required int pastCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F4),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showPastArchive = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: !_showPastArchive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_showPastArchive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '다가오는 모임 D-Day ($upcomingCount)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: !_showPastArchive ? FontWeight.w800 : FontWeight.w600,
                    color: !_showPastArchive ? const Color(0xFF42302A) : const Color(0xFF78716C),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showPastArchive = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _showPastArchive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _showPastArchive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '지난 모임 기록 ($pastCount)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _showPastArchive ? FontWeight.w800 : FontWeight.w600,
                    color: _showPastArchive ? const Color(0xFF42302A) : const Color(0xFF78716C),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4-1. 다가오는 모임 일정 리스트 (D-Day 카드 & 참여/불참 원터치 토글)
  Widget _buildUpcomingMeetingList(
    BuildContext context,
    GroupCategoryItem group,
    List<GroupMeetingScheduleItem> schedules,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 헤더: 타이틀 + [+ 모임 일정 추가] 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '다가오는 모임 일정',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF292524),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE2D9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${schedules.length}건',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE26D5C),
                    ),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => AddGroupMeetingModal.show(context, groupId: group.id),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFFE26D5C)),
              label: const Text(
                '일정 추가',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE26D5C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (schedules.isEmpty)
          _buildEmptyMeetingPlaceholder(
            context,
            group,
            title: '예정된 모임 일정이 없습니다',
            subtitle: '새로운 정기 모임이나 번개 모임을 등록해보세요!',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, index) {
              final schedule = schedules[index];
              return _buildMeetingScheduleCard(context, schedule, isPast: false);
            },
          ),
      ],
    );
  }

  /// 4-2. 지난 모임 기록 (아카이브 리스트)
  Widget _buildPastArchiveList(
    BuildContext context,
    GroupCategoryItem group,
    List<GroupMeetingScheduleItem> pastSchedules,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '지난 모임 히스토리',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF292524),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '총 ${pastSchedules.length}건 완료',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF78716C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (pastSchedules.isEmpty)
          _buildEmptyMeetingPlaceholder(
            context,
            group,
            title: '지난 모임 기록이 없습니다',
            subtitle: '모임 날짜가 지나면 자동으로 여기에 아카이빙됩니다.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pastSchedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, index) {
              final schedule = pastSchedules[index];
              return _buildMeetingScheduleCard(context, schedule, isPast: true);
            },
          ),
      ],
    );
  }

  /// 모임 일정 카드 (D-Day, 일시, 장소, 정기 뱃지, 참여/불참 토글)
  Widget _buildMeetingScheduleCard(
    BuildContext context,
    GroupMeetingScheduleItem schedule, {
    required bool isPast,
  }) {
    final dDay = schedule.dDayText();
    final isToday = dDay == 'D-Day';

    return Container(
      decoration: BoxDecoration(
        color: isPast ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isToday
              ? const Color(0xFFE26D5C)
              : (isPast ? const Color(0xFFE7E5E4) : const Color(0xFFFFE2D9)),
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isPast ? 0.01 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: D-Day 뱃지 + 정기 모임 뱃지 + 더보기 메뉴
          Row(
            children: [
              // D-Day 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPast
                      ? const Color(0xFFE7E5E4)
                      : (isToday ? const Color(0xFFE26D5C) : const Color(0xFFFFE2D9)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dDay,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isPast
                        ? const Color(0xFF78716C)
                        : (isToday ? Colors.white : const Color(0xFFC2410C)),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              if (schedule.isRegular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE2D9)),
                  ),
                  child: const Text(
                    '정기 모임',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE26D5C),
                    ),
                  ),
                ),

              const Spacer(),

              // 편집/삭제 팝업
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 18, color: Color(0xFFA8A29E)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'edit') {
                    AddGroupMeetingModal.show(context, groupId: schedule.groupId, existingSchedule: schedule);
                  } else if (val == 'delete') {
                    ref.read(groupScheduleListProvider.notifier).deleteSchedule(schedule.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('일정 수정', style: TextStyle(fontSize: 12.5)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('일정 삭제', style: TextStyle(fontSize: 12.5, color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 제목
          Text(
            schedule.title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isPast ? const Color(0xFF78716C) : const Color(0xFF292524),
              decoration: isPast ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 6),

          // 일시
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: isPast ? const Color(0xFFA8A29E) : const Color(0xFFE26D5C)),
              const SizedBox(width: 5),
              Text(
                schedule.formattedDateTime,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isPast ? const Color(0xFFA8A29E) : const Color(0xFF57534E),
                ),
              ),
            ],
          ),

          // 장소 (있을 경우)
          if (schedule.location.isNotEmpty && schedule.location != '장소 미정') ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: isPast ? const Color(0xFFA8A29E) : const Color(0xFFE26D5C)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    schedule.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: isPast ? const Color(0xFFA8A29E) : const Color(0xFF78716C),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // 메모 (있을 경우)
          if (schedule.memo != null && schedule.memo!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              schedule.memo!,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFFA8A29E)),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF5F5F4)),
          const SizedBox(height: 10),

          // 하단: [참여 / 불참] 원터치 토글 바
          Row(
            children: [
              const Text(
                '참석 여부:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF78716C)),
              ),
              const SizedBox(width: 10),

              // [참여] 버튼
              _buildAttendanceButton(
                label: '참여',
                icon: Icons.check_circle_rounded,
                isSelected: schedule.isAttending == true,
                activeColor: const Color(0xFF10B981),
                onTap: () {
                  ref.read(groupScheduleListProvider.notifier).toggleAttendance(schedule.id, true);
                },
              ),
              const SizedBox(width: 8),

              // [불참] 버튼
              _buildAttendanceButton(
                label: '불참',
                icon: Icons.cancel_rounded,
                isSelected: schedule.isAttending == false,
                activeColor: const Color(0xFFEF4444),
                onTap: () {
                  ref.read(groupScheduleListProvider.notifier).toggleAttendance(schedule.id, false);
                },
              ),

              const Spacer(),

              // 참석 상태 텍스트
              Text(
                schedule.attendanceLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: schedule.isAttending == true
                      ? const Color(0xFF059669)
                      : (schedule.isAttending == false
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFA8A29E)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 참여 / 불참 토글 버튼
  Widget _buildAttendanceButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : const Color(0xFFF5F5F4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE7E5E4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? activeColor : const Color(0xFFA8A29E),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : const Color(0xFF78716C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 빈 일정 안내 플레이스홀더
  Widget _buildEmptyMeetingPlaceholder(
    BuildContext context,
    GroupCategoryItem group, {
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Column(
        children: [
          const Text('📅', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF44403C)),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFFA8A29E)),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => AddGroupMeetingModal.show(context, groupId: group.id),
            icon: const Icon(Icons.add, size: 15, color: Color(0xFFE26D5C)),
            label: const Text(
              '새 모임 일정 잡기',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFE26D5C)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFE2D9)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  /// 모임 삭제 확인 다이얼로그
  void _confirmDeleteGroup(BuildContext context, GroupCategoryItem group) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('모임 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '[${group.name}] 모임과 관련된 모든 일정을 삭제하시겠습니까?',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(groupListProvider.notifier).deleteGroup(group.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🗑️ [${group.name}] 모임이 삭제되었습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
