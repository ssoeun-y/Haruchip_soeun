import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../controllers/baby_category_controller.dart';
import '../data/baby_health_database.dart';
import '../models/baby_profile.dart';

/// 국가 표준 필수 예방접종 타임라인 위젯 (KCDCA 표준일정표 기반 디데이 & 완료 체크리스트)
class BabyVaccineTimelineWidget extends StatefulWidget {
  const BabyVaccineTimelineWidget({
    super.key,
    required this.profile,
    required this.onToggleVaccine,
    required this.onUpdateVaccine,
  });

  final BabyProfile profile;
  final ValueChanged<VaccineDose> onToggleVaccine;
  final ValueChanged<VaccineDose> onUpdateVaccine;

  @override
  State<BabyVaccineTimelineWidget> createState() => _BabyVaccineTimelineWidgetState();
}

class _BabyVaccineTimelineWidgetState extends State<BabyVaccineTimelineWidget> {
  int _tabIndex = 0; // 0: 전체, 1: 0~6개월, 2: 12~36개월, 3: 만 4~12세, 4: 미접종(대기)
  static const _controller = BabyCategoryController();

  List<VaccineDose> get _effectiveDoses {
    final existing = widget.profile.vaccineDoses;
    if (existing.isNotEmpty) return existing;
    return kDefaultVaccineDoses;
  }

  List<VaccineDose> get _filteredDoses {
    final all = _effectiveDoses;
    return switch (_tabIndex) {
      1 => all.where((d) => d.recommendedAgeMonths <= 6).toList(),
      2 => all.where((d) => d.recommendedAgeMonths >= 12 && d.recommendedAgeMonths <= 36).toList(),
      3 => all.where((d) => d.recommendedAgeMonths >= 48).toList(),
      4 => all.where((d) => !d.isCompleted).toList(),
      _ => all,
    };
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _calculateDdayBadge(DateTime targetDate, bool isCompleted) {
    if (isCompleted) return '접종완료';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final diff = target.difference(today).inDays;

    if (diff > 0) return 'D-$diff';
    if (diff == 0) return 'D-Day';
    return 'D+${-diff}';
  }

  @override
  Widget build(BuildContext context) {
    final allDoses = _effectiveDoses;
    final completedCount = allDoses.where((d) => d.isCompleted).length;
    final totalCount = allDoses.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final filtered = _filteredDoses;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 & 진행률
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Text('💉', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '국가 표준 필수 예방접종',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.protoHeading,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$completedCount / $totalCount 완료 (${(progress * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
            ),
          ),

          const SizedBox(height: 14),

          // 2. 필터 탭 (전체, 0~6개월, 12~36개월, 만 4~12세, 미접종)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTab(0, '전체 ($totalCount)'),
                const SizedBox(width: 6),
                _buildTab(1, '0~6개월'),
                const SizedBox(width: 6),
                _buildTab(2, '12~36개월'),
                const SizedBox(width: 6),
                _buildTab(3, '만 4~12세'),
                const SizedBox(width: 6),
                _buildTab(4, '미접종 (${totalCount - completedCount})'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. 접종 목록
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text(
                '해당 조건의 예방접종 항목이 없습니다.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final dose = filtered[index];
                final targetDate = _controller.calculateVaccineTargetDate(
                  widget.profile.birthDate,
                  dose.recommendedAgeMonths,
                );
                final badgeText = _calculateDdayBadge(targetDate, dose.isCompleted);
                final isDdayOrPast = !dose.isCompleted && targetDate.isBefore(DateTime.now());

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: dose.isCompleted
                        ? const Color(0xFFF8FAFC)
                        : (isDdayOrPast ? const Color(0xFFFFFBEB) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: dose.isCompleted
                          ? const Color(0xFFE2E8F0)
                          : (isDdayOrPast ? const Color(0xFFFDE68A) : const Color(0xFFF1F5F9)),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // 체크박스
                      Checkbox(
                        value: dose.isCompleted,
                        activeColor: const Color(0xFF0284C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        onChanged: (_) => widget.onToggleVaccine(dose),
                      ),
                      const SizedBox(width: 4),

                      // 백신 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 2,
                              children: [
                                Text(
                                  dose.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: dose.isCompleted ? Colors.grey.shade600 : AppColors.protoHeading,
                                    decoration: dose.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    dose.recommendedAgeLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              dose.isCompleted && dose.completedDate != null
                                  ? '접종일: ${_formatDate(dose.completedDate!)}'
                                  : '권장 예정일: ${_formatDate(targetDate)} (${dose.disease})',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: dose.isCompleted ? Colors.grey.shade500 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 디데이 뱃지
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: dose.isCompleted
                              ? const Color(0xFFE2E8F0)
                              : (isDdayOrPast ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: dose.isCompleted
                                ? const Color(0xFF64748B)
                                : (isDdayOrPast ? const Color(0xFFD97706) : const Color(0xFF0369A1)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _tabIndex == index;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
