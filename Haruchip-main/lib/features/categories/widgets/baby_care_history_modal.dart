import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../models/baby_profile.dart';

/// 아기 케어 타임로그 전체 히스토리 모달
Future<List<BabyCareLogItem>?> showBabyCareHistoryModal(
  BuildContext context, {
  required List<BabyCareLogItem> careLogs,
}) {
  return showModalBottomSheet<List<BabyCareLogItem>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BabyCareHistorySheet(initialLogs: careLogs),
  );
}

class _BabyCareHistorySheet extends StatefulWidget {
  const _BabyCareHistorySheet({required this.initialLogs});

  final List<BabyCareLogItem> initialLogs;

  @override
  State<_BabyCareHistorySheet> createState() => _BabyCareHistorySheetState();
}

class _BabyCareHistorySheetState extends State<_BabyCareHistorySheet> {
  late List<BabyCareLogItem> _logs;

  @override
  void initState() {
    super.initState();
    _logs = List.from(widget.initialLogs);
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  String _weekdayKo(int weekday) {
    return switch (weekday) {
      DateTime.monday => '월',
      DateTime.tuesday => '화',
      DateTime.wednesday => '수',
      DateTime.thursday => '목',
      DateTime.friday => '금',
      DateTime.saturday => '토',
      _ => '일',
    };
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return '[${_formatDate(date)} 오늘]';
    } else if (date == yesterday) {
      return '[${_formatDate(date)} 어제]';
    } else {
      return '[${_formatDate(date)} (${_weekdayKo(date.weekday)})]';
    }
  }

  Future<void> _deleteLog(BabyCareLogItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('기록 삭제', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Text(
          '${item.type.emoji} ${item.type.label} (${_formatTime(item.timestamp)}) 기록을 삭제하시겠습니까?',
          style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _logs.removeWhere((l) => l.id == item.id);
      });
    }
  }

  Map<DateTime, List<BabyCareLogItem>> _groupLogsByDate() {
    final map = <DateTime, List<BabyCareLogItem>>{};
    for (final item in _logs) {
      final dateKey = DateTime(item.timestamp.year, item.timestamp.month, item.timestamp.day);
      map.putIfAbsent(dateKey, () => []).add(item);
    }
    // Sort items within each day chronologically (시간순)
    for (final list in map.values) {
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final grouped = _groupLogsByDate();
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a)); // Newest dates first

    return Container(
      height: mediaQuery.size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                children: [
                  const Flexible(
                    child: Text(
                    '📋 케어 타임로그 히스토리',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.protoHeading,
                    ),
                  ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '총 ${_logs.length}건',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ),
                ],
              ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(_logs),
              ),
            ],
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      '기록된 케어 로그가 없습니다.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedDates.length,
                    itemBuilder: (context, dateIndex) {
                      final date = sortedDates[dateIndex];
                      final dayLogs = grouped[date] ?? [];
                      final dateHeader = _getDateHeader(date);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. 날짜별 그룹핑 헤더
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateHeader,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Text(
                                    '${dayLogs.length}개의 기록',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 2. 날짜 아래 시간순 나열 카드 목록
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dayLogs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (context, logIndex) {
                                final item = dayLogs[logIndex];
                                final infoList = <String>[];
                                if (item.subType != null && item.subType!.isNotEmpty) {
                                  infoList.add(item.subType!);
                                }
                                if (item.amount != null) {
                                  infoList.add(item.type == BabyCareLogType.feeding
                                      ? '${item.amount!.toInt()}ml'
                                      : '${item.amount!.toInt()}g');
                                }
                                if (item.durationMinutes != null) {
                                  infoList.add('${item.durationMinutes}분');
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // 시간 뱃지 (가독성 높은 모노톤 박스)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Text(
                                          _formatTime(item.timestamp),
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // 이모지 & 항목 내용
                                      Text(item.type.emoji, style: const TextStyle(fontSize: 20)),
                                      const SizedBox(width: 8),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  item.type.label,
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.protoHeading,
                                                  ),
                                                ),
                                                if (infoList.isNotEmpty) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFE0F2FE),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      infoList.join(' · '),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF0369A1),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (item.memo != null && item.memo!.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                '💬 ${item.memo}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // 삭제 버튼
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                                        tooltip: '삭제',
                                        onPressed: () => _deleteLog(item),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_logs),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
