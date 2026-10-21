import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/appointment_model.dart';
import 'add_appointment_modal.dart';

/// 일정 / 약속 노션 & 애플 리마인더 감성 카테고리 뷰
class AppointmentCategoryView extends StatefulWidget {
  const AppointmentCategoryView({
    super.key,
    required this.appointments,
    required this.onAppointmentsChanged,
    required this.onOpenAddModal,
  });

  final List<AppointmentItem> appointments;
  final ValueChanged<List<AppointmentItem>> onAppointmentsChanged;
  final VoidCallback onOpenAddModal;

  @override
  State<AppointmentCategoryView> createState() => _AppointmentCategoryViewState();
}

class _AppointmentCategoryViewState extends State<AppointmentCategoryView> {
  // Set of appointment ids whose subtasks accordion is expanded
  final Set<String> _expandedSubTaskIds = {};

  List<AppointmentItem> _getSortedAppointments() {
    final list = List<AppointmentItem>.from(widget.appointments);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    list.sort((a, b) {
      final targetA = DateTime(a.date.year, a.date.month, a.date.day);
      final targetB = DateTime(b.date.year, b.date.month, b.date.day);
      final isPastA = targetA.isBefore(today);
      final isPastB = targetB.isBefore(today);

      if (isPastA != isPastB) {
        return isPastA ? 1 : -1;
      }

      final dateComp = a.date.compareTo(b.date);
      if (dateComp != 0) return dateComp;

      if (a.time != null && b.time != null) {
        final aMinutes = a.time!.hour * 60 + a.time!.minute;
        final bMinutes = b.time!.hour * 60 + b.time!.minute;
        return aMinutes.compareTo(bMinutes);
      }
      return 0;
    });

    return list;
  }

  void _toggleSubTask(AppointmentItem appointment, int index) {
    final updatedSubTasks = List<SubTaskItem>.from(appointment.subTasks);
    final current = updatedSubTasks[index];
    updatedSubTasks[index] = current.copyWith(isDone: !current.isDone);

    final updated = appointment.copyWith(subTasks: updatedSubTasks);
    final newList = widget.appointments.map((a) => a.id == appointment.id ? updated : a).toList();
    widget.onAppointmentsChanged(newList);
  }

  Future<void> _editAppointment(AppointmentItem appointment) async {
    final updated = await showAddAppointmentModal(
      context,
      existingAppointment: appointment,
      allowDelete: true,
      onDelete: () {
        final newList = widget.appointments.where((a) => a.id != appointment.id).toList();
        widget.onAppointmentsChanged(newList);
      },
    );
    if (updated != null) {
      final newList = widget.appointments.map((a) => a.id == appointment.id ? updated : a).toList();
      widget.onAppointmentsChanged(newList);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedList = _getSortedAppointments();

    if (sortedList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_note_outlined, size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            const Text('예정된 일정 및 약속이 없습니다', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: widget.onOpenAddModal,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('새 일정 등록하기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final appointment = sortedList[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentItem appointment) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(appointment.date.year, appointment.date.month, appointment.date.day);
    final isToday = target.isAtSameMomentAs(today);
    final isPast = target.isBefore(today);

    final isExpanded = _expandedSubTaskIds.contains(appointment.id);
    final doneSubTaskCount = appointment.subTasks.where((s) => s.isDone).length;
    final totalSubTaskCount = appointment.subTasks.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          width: isToday ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 메인 약속 카드 정보
          InkWell(
            onTap: () => _editAppointment(appointment),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단: 일시 (When) + 실시간 D-Day/카운트다운 뱃지
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: isToday ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                '${appointment.formattedDate} · ${appointment.formattedTime}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                  color: isToday ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF0F172A)
                              : (isPast ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          appointment.realtimeCountdownLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isToday
                                ? Colors.white
                                : (isPast ? const Color(0xFF94A3B8) : const Color(0xFF2563EB)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 제목 (What)
                  Text(
                    appointment.title,
                    style: AppTypography.heading2.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isPast ? const Color(0xFF94A3B8) : AppColors.protoHeading,
                    ),
                  ),

                  // 장소 (Where)
                  if (appointment.location != null && appointment.location!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointment.location!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // 함께하는 사람 (With)
                  if (appointment.withPeople.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: appointment.withPeople.map((person) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline, size: 11, color: Color(0xFF64748B)),
                              const SizedBox(width: 3),
                              Text(
                                person,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 하위 할 일 (Sub-tasks) 아코디언 바
          if (appointment.subTasks.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedSubTaskIds.remove(appointment.id);
                  } else {
                    _expandedSubTaskIds.add(appointment.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.checklist_rounded, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '준비물 / 할 일 ($doneSubTaskCount / $totalSubTaskCount)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: List.generate(appointment.subTasks.length, (sIdx) {
                    final sub = appointment.subTasks[sIdx];
                    return GestureDetector(
                      onTap: () => _toggleSubTask(appointment, sIdx),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: sub.isDone ? const Color(0xFF0F172A) : Colors.transparent,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: sub.isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                  width: 1.5,
                                ),
                              ),
                              child: sub.isDone
                                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sub.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: sub.isDone ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                                  decoration: sub.isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
