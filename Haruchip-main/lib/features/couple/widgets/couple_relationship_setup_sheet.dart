import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/couple_relationship.dart';
import '../providers/couple_provider.dart';

/// 커플 "만난 날 및 재회 설정" 시트 — 커플 상세 화면과 온보딩/카테고리
/// 추가 흐름이 함께 쓴다. "설정 완료"를 누르면 [coupleProvider]에 저장하고
/// true, 닫으면 false.
Future<bool> showCoupleRelationshipSetupSheet(BuildContext context, WidgetRef ref) async {
  final couple = ref.read(coupleProvider);
  DateTime tempStartDate = couple.startDate;
  List<ReunionPeriod> tempReunions = couple.reunions.map((r) => r.copyWith()).toList();

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final mediaQuery = MediaQuery.of(context);
          // Calculate total days preview
          final now = DateTime.now();
          final totalElapsed = DateTime(now.year, now.month, now.day)
              .difference(DateTime(tempStartDate.year, tempStartDate.month, tempStartDate.day))
              .inDays;
          final breakupDays = tempReunions.fold<int>(0, (sum, r) => sum + r.length.inDays);
          final previewDays = (totalElapsed - breakupDays).clamp(0, 99999);

          return Container(
            height: mediaQuery.size.height * 0.88,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          '만난 날 및 재회 설정',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Calculated Preview Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFD4C2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite, color: Color(0xFFFF7A59), size: 28),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('현재 연애 일수', style: TextStyle(fontSize: 12, color: Color(0xFF8A7F78))),
                                Text(
                                  '${previewDays + 1}일째',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFFF7A59)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section 1: 처음 만난 날
                      const Text('처음 만난 날 (시작일)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showHaruDatePicker(
                            context,
                            initialDate: tempStartDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() => tempStartDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${tempStartDate.year}.${tempStartDate.month.toString().padLeft(2, '0')}.${tempStartDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF007AFF)),
                              ),
                              const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF007AFF)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Section 2: 재회 및 이별 기간 목록
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              '이별 / 재회 이력',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setModalState(() {
                                tempReunions.add(
                                  ReunionPeriod(
                                    breakupDate: tempStartDate.add(const Duration(days: 100)),
                                    reuniteDate: tempStartDate.add(const Duration(days: 130)),
                                  ),
                                );
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF007AFF)),
                            label: const Text('+ 재회 추가', style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '이별했던 기간만큼 총 연애 일수에서 정확히 제외됩니다.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      if (tempReunions.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: const Text('등록된 이별/재회 기간이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        )
                      else
                        for (int i = 0; i < tempReunions.length; i++)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9FB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE5E5EA)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('기간 #${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3A3A3C))),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444), size: 18),
                                      onPressed: () {
                                        setModalState(() {
                                          tempReunions.removeAt(i);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // Breakup date button
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showHaruDatePicker(
                                            context,
                                            initialDate: tempReunions[i].breakupDate,
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime(2100),
                                          );
                                          if (picked != null) {
                                            setModalState(() {
                                              tempReunions[i] = tempReunions[i].copyWith(breakupDate: picked);
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFD1D1D6)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('이별일', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              Text(
                                                '${tempReunions[i].breakupDate.year}.${tempReunions[i].breakupDate.month.toString().padLeft(2, '0')}.${tempReunions[i].breakupDate.day.toString().padLeft(2, '0')}',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6),
                                      child: Text('~', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    // Reunite date button
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showHaruDatePicker(
                                            context,
                                            initialDate: tempReunions[i].reuniteDate ?? tempReunions[i].breakupDate.add(const Duration(days: 30)),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime(2100),
                                          );
                                          if (picked != null) {
                                            setModalState(() {
                                              tempReunions[i] = tempReunions[i].copyWith(reuniteDate: picked);
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFD1D1D6)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('재회일', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              Text(
                                                tempReunions[i].reuniteDate != null
                                                    ? '${tempReunions[i].reuniteDate!.year}.${tempReunions[i].reuniteDate!.month.toString().padLeft(2, '0')}.${tempReunions[i].reuniteDate!.day.toString().padLeft(2, '0')}'
                                                    : '미재회 (현재 이별 중)',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
                // Bottom Submit Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        ref.read(coupleProvider.notifier).updateRelationship(
                              startDate: tempStartDate,
                              reunions: tempReunions,
                            );
                        Navigator.pop(ctx, true);
                      },
                      child: const Text(
                        '설정 완료',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  return saved == true;
}
