import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../calendar/providers/schedule_room_provider.dart';

/// 전 카테고리 공통 캘린더 & 모임 연동 옵션 위젯
class EventSyncOptionsSection extends ConsumerWidget {
  const EventSyncOptionsSection({
    super.key,
    required this.syncGoogle,
    required this.onSyncGoogleChanged,
    required this.syncNaver,
    required this.onSyncNaverChanged,
    required this.syncRoom,
    required this.onSyncRoomChanged,
    required this.selectedRoomIds,
    required this.onToggleRoomId,
    this.showInCalendar,
    this.onShowInCalendarChanged,
    this.showInCalendarLabel = '하루칩 캘린더에 표시',
    this.showInCalendarSubLabel = '메인 캘린더 화면에 일정을 표시합니다',
  });

  final bool syncGoogle;
  final ValueChanged<bool> onSyncGoogleChanged;
  final bool syncNaver;
  final ValueChanged<bool> onSyncNaverChanged;
  final bool syncRoom;
  final ValueChanged<bool> onSyncRoomChanged;
  final List<String> selectedRoomIds;
  final ValueChanged<String> onToggleRoomId;

  final bool? showInCalendar;
  final ValueChanged<bool>? onShowInCalendarChanged;
  final String showInCalendarLabel;
  final String showInCalendarSubLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(scheduleRoomsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '캘린더 & 모임 연동 설정',
          style: AppTypography.caption.copyWith(
            color: AppColors.protoSubtitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          // 배경색 있는 컨테이너 안의 SwitchListTile 잉크가 보이도록 투명 Material 한 겹.
          child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              // 1. 하루칩 캘린더에 표시 (옵션)
              if (showInCalendar != null && onShowInCalendarChanged != null) ...[
                SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  title: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0F172A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              showInCalendarLabel,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              showInCalendarSubLabel,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  value: showInCalendar!,
                  activeTrackColor: const Color(0xFF0F172A),
                  onChanged: onShowInCalendarChanged,
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
              ],

              // 2. 구글 캘린더 연동
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                title: const Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF4285F4)),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '구글 캘린더에 등록',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
                value: syncGoogle,
                activeTrackColor: const Color(0xFF4285F4),
                onChanged: onSyncGoogleChanged,
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // 3. 네이버 캘린더 연동
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                title: const Row(
                  children: [
                    Icon(Icons.event_note_rounded, size: 16, color: Color(0xFF03C75A)),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '네이버 캘린더에 등록',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
                value: syncNaver,
                activeTrackColor: const Color(0xFF03C75A),
                onChanged: onSyncNaverChanged,
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // 4. 참여 중인 모임 방 연동
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                title: const Row(
                  children: [
                    Icon(Icons.groups_outlined, size: 16, color: Color(0xFF6366F1)),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '참여 중인 모임에 등록',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
                value: syncRoom,
                activeTrackColor: const Color(0xFF6366F1),
                onChanged: onSyncRoomChanged,
              ),

              if (syncRoom) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '일정을 공유할 모임 방을 선택하세요:',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      if (rooms.isEmpty)
                        const Text(
                          '참여 중인 모임 방이 없습니다.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: rooms.map((r) {
                            final isSelected = selectedRoomIds.contains(r.id);
                            return FilterChip(
                              label: Text(
                                '${r.categoryTag} ${r.name}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFF6366F1),
                              backgroundColor: const Color(0xFFF1F5F9),
                              checkmarkColor: Colors.white,
                              onSelected: (_) => onToggleRoomId(r.id),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          ),
        ),
      ],
    );
  }
}
