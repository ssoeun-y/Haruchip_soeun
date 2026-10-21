import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
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
    _logs = List.from(widget.initialLogs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  String _formatDateTime(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m.$d $h:$min';
  }

  void _deleteLog(int index) {
    setState(() {
      _logs.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

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
                child: Text(
                  '📋 케어 타임로그 히스토리 (${_logs.length})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading2.copyWith(fontSize: 18),
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
                : ListView.separated(
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _logs[index];
                      final infoList = <String>[];
                      if (item.subType != null) infoList.add(item.subType!);
                      if (item.amount != null) {
                        infoList.add(item.type == BabyCareLogType.feeding
                            ? '${item.amount!.toInt()}ml'
                            : '${item.amount!.toInt()}g');
                      }
                      if (item.durationMinutes != null) {
                        infoList.add('${item.durationMinutes}분');
                      }
                      if (item.memo != null && item.memo!.isNotEmpty) {
                        infoList.add('"${item.memo}"');
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Text(item.type.emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.type.label,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.protoHeading,
                                        ),
                                      ),
                                      if (infoList.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${infoList.join(', ')})',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF0284C7),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _formatDateTime(item.timestamp),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                              onPressed: () => _deleteLog(index),
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
