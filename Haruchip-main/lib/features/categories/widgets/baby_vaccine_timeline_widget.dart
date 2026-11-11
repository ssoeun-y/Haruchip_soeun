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
  int _tabIndex = 0; // 0: 미접종, 1: 완료, 2: 전체, 3: 0~6개월, 4: 12~36개월, 5: 만 4~12세
  static const _controller = BabyCategoryController();

  List<VaccineDose> get _effectiveDoses {
    final existing = widget.profile.vaccineDoses;
    if (existing.isNotEmpty) return existing;
    return kDefaultVaccineDoses;
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _calculateDdayBadge(DateTime targetDate, bool isCompleted) {
    if (isCompleted) return '접종 완료';
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
    final uncompletedCount = totalCount - completedCount;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    // Filter by tab
    List<VaccineDose> filtered;
    switch (_tabIndex) {
      case 0: // 미접종
        filtered = allDoses.where((d) => !d.isCompleted).toList();
        break;
      case 1: // 완료
        filtered = allDoses.where((d) => d.isCompleted).toList();
        break;
      case 2: // 전체
        filtered = List.from(allDoses);
        break;
      case 3: // 0~6개월
        filtered = allDoses.where((d) => d.recommendedAgeMonths <= 6).toList();
        break;
      case 4: // 12~36개월
        filtered = allDoses.where((d) => d.recommendedAgeMonths >= 12 && d.recommendedAgeMonths <= 36).toList();
        break;
      case 5: // 만 4~12세
        filtered = allDoses.where((d) => d.recommendedAgeMonths >= 48).toList();
        break;
      default:
        filtered = List.from(allDoses);
    }

    // Sort: If showing mixed tabs (전체 or age tabs), keep uncompleted first, completed after
    if (_tabIndex != 0 && _tabIndex != 1) {
      filtered.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        final dateA = _controller.calculateVaccineDoseTargetDate(widget.profile.birthDate, a);
        final dateB = _controller.calculateVaccineDoseTargetDate(widget.profile.birthDate, b);
        return dateA.compareTo(dateB);
      });
    } else if (_tabIndex == 0) {
      filtered.sort((a, b) {
        final dateA = _controller.calculateVaccineDoseTargetDate(widget.profile.birthDate, a);
        final dateB = _controller.calculateVaccineDoseTargetDate(widget.profile.birthDate, b);
        return dateA.compareTo(dateB);
      });
    }

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

          // 2. 필터 탭 (미접종, 완료, 전체, 0~6개월, 12~36개월, 만 4~12세)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTab(0, '미접종 ($uncompletedCount)'),
                const SizedBox(width: 6),
                _buildTab(1, '접종 완료 ($completedCount)'),
                const SizedBox(width: 6),
                _buildTab(2, '전체 ($totalCount)'),
                const SizedBox(width: 6),
                _buildTab(3, '0~6개월'),
                const SizedBox(width: 6),
                _buildTab(4, '12~36개월'),
                const SizedBox(width: 6),
                _buildTab(5, '만 4~12세'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. 접종 목록
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                _tabIndex == 0
                    ? '🎉 모든 권장 필수 예방접종을 완료했습니다!'
                    : (_tabIndex == 1 ? '아직 접종 완료된 항목이 없습니다.' : '해당 조건의 예방접종 항목이 없습니다.'),
                style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
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
                final targetDate = _controller.calculateVaccineDoseTargetDate(
                  widget.profile.birthDate,
                  dose,
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
                          ? const Color(0xFFCBD5E1)
                          : (isDdayOrPast ? const Color(0xFFFDE68A) : const Color(0xFFF1F5F9)),
                      width: dose.isCompleted ? 1.2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // 체크박스 (완료/미접종 토글)
                      Checkbox(
                        value: dose.isCompleted,
                        activeColor: const Color(0xFF059669),
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
                              spacing: 6,
                              runSpacing: 2,
                              children: [
                                // Wrap 안에서는 Flexible을 쓸 수 없다 — Wrap이 이미 폭을 넘으면 줄바꿈한다.
                                Text(
                                  dose.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: dose.isCompleted ? Colors.grey.shade600 : AppColors.protoHeading,
                                    decoration: dose.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
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
                                  ? '접종일: ${_formatDate(dose.completedDate!)} (${dose.disease})'
                                  : '권장 예정일: ${_formatDate(targetDate)} (${dose.disease})',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: dose.isCompleted ? Colors.grey.shade500 : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '출처: 질병관리청 국가표준 필수예방접종 가이드라인',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 완료 도장 그래픽 또는 디데이 뱃지
                      if (dose.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                              SizedBox(width: 3),
                              Text(
                                '접종 완료',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDdayOrPast ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDdayOrPast ? const Color(0xFFD97706) : const Color(0xFF0369A1),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 12),
          // 공식 안내 가이드라인 안내
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '출처: 질병관리청(KCDA) 예방접종도우미 표준 예방접종 일정표 기준',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
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
