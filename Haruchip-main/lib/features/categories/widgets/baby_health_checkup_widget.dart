import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../data/baby_health_database.dart';
import '../models/baby_profile.dart';

/// 영유아 건강검진 (1~8차) & 신체 성장 기록 (키/몸무게/머리둘레) 위젯
class BabyHealthCheckupWidget extends StatelessWidget {
  const BabyHealthCheckupWidget({
    super.key,
    required this.profile,
    required this.onToggleCheckup,
    required this.onOpenAddGrowthRecord,
  });

  final BabyProfile profile;
  final ValueChanged<HealthCheckupDose> onToggleCheckup;
  final VoidCallback onOpenAddGrowthRecord;

  List<HealthCheckupDose> get _effectiveDoses {
    final existing = profile.checkupDoses;
    if (existing.isNotEmpty) return existing;
    return kDefaultHealthCheckupDoses;
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final doses = _effectiveDoses;
    final growthRecords = profile.growthRecords;

    final completedCount = doses.where((d) => d.isCompleted).length;

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
          // 1. 헤더 (1~8차 건강검진)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Text('🩺', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '국가 영유아 건강검진 (1~8차)',
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
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$completedCount / ${doses.length} 완료',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. 검진 차수 리스트
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: doses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final dose = doses[index];
              final startDate = profile.birthDate.add(Duration(days: dose.startDays));
              final endDate = profile.birthDate.add(Duration(days: dose.endDays));

              final isPeriodActive = !today.isBefore(startDate) && !today.isAfter(endDate);
              final isUpcoming = today.isBefore(startDate);

              String badgeText;
              Color badgeBg;
              Color badgeTextClr;

              if (dose.isCompleted) {
                badgeText = '검진 완료';
                badgeBg = const Color(0xFFE2E8F0);
                badgeTextClr = const Color(0xFF64748B);
              } else if (isPeriodActive) {
                final daysLeft = endDate.difference(today).inDays;
                badgeText = '마감 D-$daysLeft (검진기간)';
                badgeBg = const Color(0xFFFEF2F2);
                badgeTextClr = const Color(0xFFDC2626);
              } else if (isUpcoming) {
                final startLeft = startDate.difference(today).inDays;
                badgeText = 'D-$startLeft 시작';
                badgeBg = const Color(0xFFF1F5F9);
                badgeTextClr = const Color(0xFF64748B);
              } else {
                badgeText = '기간 경과';
                badgeBg = const Color(0xFFF1F5F9);
                badgeTextClr = Colors.grey;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: dose.isCompleted
                      ? const Color(0xFFF8FAFC)
                      : (isPeriodActive ? const Color(0xFFFFF7ED) : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isPeriodActive && !dose.isCompleted
                        ? const Color(0xFFFDBA74)
                        : (dose.isCompleted ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
                    width: isPeriodActive && !dose.isCompleted ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: dose.isCompleted,
                      activeColor: const Color(0xFFD97706),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      onChanged: (_) => onToggleCheckup(dose),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${dose.stage}차 검진',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: dose.isCompleted ? Colors.grey.shade600 : AppColors.protoHeading,
                                  decoration: dose.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${dose.periodLabel})',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '검진 기간: ${_formatDate(startDate)} ~ ${_formatDate(endDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: dose.isCompleted ? Colors.grey.shade500 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: badgeTextClr,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // 3. 신체 성장 기록 섹션
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Text('📏', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '신체 성장 기록 (키/몸무게/머리둘레)',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.protoHeading,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onOpenAddGrowthRecord,
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('기록 추가', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (growthRecords.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                '아직 등록된 신체 측정 기록이 없습니다.\n상단의 [기록 추가] 버튼을 눌러보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: growthRecords.length > 3 ? 3 : growthRecords.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final sorted = List<GrowthRecord>.from(growthRecords)
                  ..sort((a, b) => b.date.compareTo(a.date));
                final record = sorted[index];

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _formatDate(record.date),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const Spacer(),
                      if (record.heightCm != null)
                        Text(
                          '키 ${record.heightCm}cm  ',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                        ),
                      if (record.weightKg != null)
                        Text(
                          '몸무게 ${record.weightKg}kg  ',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                        ),
                      if (record.headCircumferenceCm != null)
                        Text(
                          '머리둘레 ${record.headCircumferenceCm}cm',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
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
}
