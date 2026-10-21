import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../models/appointment_model.dart';
import '../models/goal_model.dart';

/// 3대 전문 카테고리 [기록(아카이브) 보관함] 모달
Future<void> showProfessionalArchiveModal(
  BuildContext context, {
  required List<GoalItem> goals,
  required List<AppointmentItem> appointments,
  required ValueChanged<List<GoalItem>> onGoalsChanged,
  required ValueChanged<List<AppointmentItem>> onAppointmentsChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ProfessionalArchiveModal(
      goals: goals,
      appointments: appointments,
      onGoalsChanged: onGoalsChanged,
      onAppointmentsChanged: onAppointmentsChanged,
    ),
  );
}

class _ProfessionalArchiveModal extends StatefulWidget {
  const _ProfessionalArchiveModal({
    required this.goals,
    required this.appointments,
    required this.onGoalsChanged,
    required this.onAppointmentsChanged,
  });

  final List<GoalItem> goals;
  final List<AppointmentItem> appointments;
  final ValueChanged<List<GoalItem>> onGoalsChanged;
  final ValueChanged<List<AppointmentItem>> onAppointmentsChanged;

  @override
  State<_ProfessionalArchiveModal> createState() => _ProfessionalArchiveModalState();
}

class _ProfessionalArchiveModalState extends State<_ProfessionalArchiveModal> {
  final TextEditingController _searchController = TextEditingController();
  int _tabIndex = 0; // 0=전체, 1=달성 목표, 2=지난 일정
  String? _selectedYearFilter; // null = 전체, '2026', '2025'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GoalItem> _getArchivedGoals() {
    return widget.goals.where((g) => g.isCompleted || g.status == GoalStatus.completed).toList();
  }

  List<AppointmentItem> _getPastAppointments() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.appointments.where((a) {
      final aDate = DateTime(a.date.year, a.date.month, a.date.day);
      return a.isArchived || aDate.isBefore(today);
    }).toList();
  }

  void _restoreGoal(GoalItem goal) {
    final updated = goal.copyWith(
      isCompleted: false,
      status: GoalStatus.inProgress,
      completedAt: null,
    );
    final newList = widget.goals.map((g) => g.id == goal.id ? updated : g).toList();
    widget.onGoalsChanged(newList);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✨ '${goal.title}' 목표가 진행 중으로 복원되었습니다.")),
    );
  }

  void _deleteGoal(GoalItem goal) {
    final newList = widget.goals.where((g) => g.id != goal.id).toList();
    widget.onGoalsChanged(newList);
    setState(() {});
  }

  void _deleteAppointment(AppointmentItem appt) {
    final newList = widget.appointments.where((a) => a.id != appt.id).toList();
    widget.onAppointmentsChanged(newList);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    final archivedGoals = _getArchivedGoals().where((g) {
      final matchesQuery = query.isEmpty || g.title.toLowerCase().contains(query);
      final itemYear = (g.completedAt ?? g.deadline ?? DateTime.now()).year.toString();
      final matchesYear = _selectedYearFilter == null || itemYear == _selectedYearFilter;
      return matchesQuery && matchesYear;
    }).toList();

    final pastAppointments = _getPastAppointments().where((a) {
      final matchesQuery = query.isEmpty ||
          a.title.toLowerCase().contains(query) ||
          (a.location != null && a.location!.toLowerCase().contains(query));
      final itemYear = a.date.year.toString();
      final matchesYear = _selectedYearFilter == null || itemYear == _selectedYearFilter;
      return matchesQuery && matchesYear;
    }).toList();

    // Sort descending by date (latest first)
    archivedGoals.sort((a, b) {
      final dateA = a.completedAt ?? a.deadline ?? DateTime(2000);
      final dateB = b.completedAt ?? b.deadline ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    pastAppointments.sort((a, b) => b.date.compareTo(a.date));

    final availableYears = <String>{
      for (final g in _getArchivedGoals()) (g.completedAt ?? g.deadline ?? DateTime.now()).year.toString(),
      for (final a in _getPastAppointments()) a.date.year.toString(),
      DateTime.now().year.toString(),
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Text('🗄️', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '기록 보관함 (Archive)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppColors.protoSubtitle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Search Bar & Year Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  // Search Box
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '과거 달성 기록 및 약속 검색...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Year Filter Chips & Tab Filter
                  Row(
                    children: [
                      // All Years
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: const Text('전체 연도', style: TextStyle(fontSize: 11)),
                          selected: _selectedYearFilter == null,
                          onSelected: (_) => setState(() => _selectedYearFilter = null),
                          selectedColor: const Color(0xFF0F172A),
                          labelStyle: TextStyle(
                            color: _selectedYearFilter == null ? Colors.white : const Color(0xFF334155),
                            fontWeight: _selectedYearFilter == null ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      for (final yr in availableYears)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('$yr년', style: const TextStyle(fontSize: 11)),
                            selected: _selectedYearFilter == yr,
                            onSelected: (_) => setState(() => _selectedYearFilter = yr),
                            selectedColor: const Color(0xFF0F172A),
                            labelStyle: TextStyle(
                              color: _selectedYearFilter == yr ? Colors.white : const Color(0xFF334155),
                              fontWeight: _selectedYearFilter == yr ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Tab bar: [전체] | [달성 완료 목표] | [지난 일정]
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildTabButton(0, '전체 (${archivedGoals.length + pastAppointments.length})'),
                  _buildTabButton(1, '달성 목표 (${archivedGoals.length})'),
                  _buildTabButton(2, '지난 일정 (${pastAppointments.length})'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // List Content
            Expanded(
              child: (_tabIndex == 0 && archivedGoals.isEmpty && pastAppointments.isEmpty) ||
                      (_tabIndex == 1 && archivedGoals.isEmpty) ||
                      (_tabIndex == 2 && pastAppointments.isEmpty)
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('보관된 기록이 없습니다', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        if (_tabIndex == 0 || _tabIndex == 1) ...[
                          if (archivedGoals.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('🎯 달성 완료한 목표', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ),
                            for (final goal in archivedGoals)
                              _buildArchivedGoalTile(goal),
                          ],
                        ],
                        if (_tabIndex == 0 || _tabIndex == 2) ...[
                          if (pastAppointments.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('📅 지난 일정 및 약속', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ),
                            for (final appt in pastAppointments)
                              _buildPastAppointmentTile(appt),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 3,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArchivedGoalTile(GoalItem goal) {
    final dateStr = goal.completedAt != null
        ? '${goal.completedAt!.year}.${goal.completedAt!.month.toString().padLeft(2, '0')}.${goal.completedAt!.day.toString().padLeft(2, '0')} 달성'
        : '달성 완료';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF16A34A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _restoreGoal(goal),
            child: const Text('복원', style: TextStyle(fontSize: 12, color: Color(0xFF007AFF), fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
            onPressed: () => _deleteGoal(goal),
          ),
        ],
      ),
    );
  }

  Widget _buildPastAppointmentTile(AppointmentItem appt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 20, color: Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${appt.formattedDate} · ${appt.formattedTime}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
            onPressed: () => _deleteAppointment(appt),
          ),
        ],
      ),
    );
  }
}
