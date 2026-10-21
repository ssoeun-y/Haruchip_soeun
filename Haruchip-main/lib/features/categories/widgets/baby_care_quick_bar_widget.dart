import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../controllers/baby_category_controller.dart';
import '../models/baby_profile.dart';

/// 아기 4대 케어 원터치 퀵 바 & 실시간 수유텀 카운트다운 위젯
class BabyCareQuickBarWidget extends StatelessWidget {
  const BabyCareQuickBarWidget({
    super.key,
    required this.profile,
    required this.onLogQuickCare,
    required this.onLogDetailedCare,
    required this.onOpenCareHistory,
  });

  final BabyProfile profile;
  final ValueChanged<BabyCareLogType> onLogQuickCare;
  final ValueChanged<BabyCareLogItem> onLogDetailedCare;
  final VoidCallback onOpenCareHistory;

  static const _controller = BabyCategoryController();

  BabyCareLogItem? _getLastLog(BabyCareLogType type) {
    final list = profile.careLogs.where((l) => l.type == type).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.isNotEmpty ? list.first : null;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showDetailedSheet(BuildContext context, BabyCareLogType type) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BabyCareDetailModal(
        type: type,
        onSave: onLogDetailedCare,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedingStatus = _controller.calculateNextFeeding(
      profile.careLogs,
      profile.feedingIntervalHours,
    );

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
          // 1. 헤더 & 실시간 수유텀 카운트다운 배너
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 4,
                children: [
                  const Text(
                    '⚡ 원터치 케어 타임로그',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.protoHeading,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '길게 눌러 상세 입력',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onOpenCareHistory,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '기록 (${profile.careLogs.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF0284C7),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 수유 텀 카운트다운 인디케이터
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: feedingStatus.isOverdue
                  ? const Color(0xFFFEF2F2)
                  : (feedingStatus.isDueNow
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFF0FDF4)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: feedingStatus.isOverdue
                    ? const Color(0xFFFECACA)
                    : (feedingStatus.isDueNow
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFBBF7D0)),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  feedingStatus.isOverdue
                      ? '⚠️'
                      : (feedingStatus.isDueNow ? '⏰' : '🍼'),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedingStatus.statusText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: feedingStatus.isOverdue
                              ? const Color(0xFFDC2626)
                              : (feedingStatus.isDueNow
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF16A34A)),
                        ),
                      ),
                      if (feedingStatus.lastFeedingTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '마지막 수유: ${_formatTime(feedingStatus.lastFeedingTime!)} (텀 ${profile.feedingIntervalHours}시간 기준)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. 4대 필수 케어 버튼 그리드
          Row(
            children: [
              _buildCareButton(
                context,
                type: BabyCareLogType.feeding,
                label: '수유',
                emoji: '🍼',
                bgColor: const Color(0xFFFFF7ED),
                textColor: const Color(0xFFEA580C),
                borderColor: const Color(0xFFFFEDD5),
              ),
              const SizedBox(width: 8),
              _buildCareButton(
                context,
                type: BabyCareLogType.babyFood,
                label: '이유식',
                emoji: '🥣',
                bgColor: const Color(0xFFFEFCE8),
                textColor: const Color(0xFFCA8A04),
                borderColor: const Color(0xFFFEF08A),
              ),
              const SizedBox(width: 8),
              _buildCareButton(
                context,
                type: BabyCareLogType.sleep,
                label: '수면',
                emoji: '💤',
                bgColor: const Color(0xFFF5F3FF),
                textColor: const Color(0xFF7C3AED),
                borderColor: const Color(0xFFDDD6FE),
              ),
              const SizedBox(width: 8),
              _buildCareButton(
                context,
                type: BabyCareLogType.diaper,
                label: '기저귀',
                emoji: '👶',
                bgColor: const Color(0xFFF0FDF4),
                textColor: const Color(0xFF16A34A),
                borderColor: const Color(0xFFDCFCE7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCareButton(
    BuildContext context, {
    required BabyCareLogType type,
    required String label,
    required String emoji,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
  }) {
    final lastLog = _getLastLog(type);

    return Expanded(
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => onLogQuickCare(type),
          onLongPress: () => _showDetailedSheet(context, type),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    lastLog != null ? _formatTime(lastLog.timestamp) : '기록없음',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: lastLog != null ? textColor : Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 상세 케어 기록 입력 모달 바텀시트
class _BabyCareDetailModal extends StatefulWidget {
  const _BabyCareDetailModal({
    required this.type,
    required this.onSave,
  });

  final BabyCareLogType type;
  final ValueChanged<BabyCareLogItem> onSave;

  @override
  State<_BabyCareDetailModal> createState() => _BabyCareDetailModalState();
}

class _BabyCareDetailModalState extends State<_BabyCareDetailModal> {
  late DateTime _timestamp;
  late TextEditingController _amountCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _memoCtrl;
  String? _selectedSubType;

  @override
  void initState() {
    super.initState();
    _timestamp = DateTime.now();
    _amountCtrl = TextEditingController();
    _durationCtrl = TextEditingController();
    _memoCtrl = TextEditingController();

    _selectedSubType = switch (widget.type) {
      BabyCareLogType.feeding => '분유',
      BabyCareLogType.babyFood => '중기',
      BabyCareLogType.sleep => '낮잠',
      BabyCareLogType.diaper => '소변',
    };
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _durationCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  List<String> get _subTypeOptions => switch (widget.type) {
        BabyCareLogType.feeding => ['분유', '모유', '유축', '혼합'],
        BabyCareLogType.babyFood => ['초기', '중기', '후기', '완료기'],
        BabyCareLogType.sleep => ['낮잠', '밤잠'],
        BabyCareLogType.diaper => ['소변', '대변', '대소변'],
      };

  void _submit() {
    final amountVal = double.tryParse(_amountCtrl.text.trim());
    final durationVal = int.tryParse(_durationCtrl.text.trim());
    final memoVal = _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim();

    final item = BabyCareLogItem(
      id: 'log-${DateTime.now().microsecondsSinceEpoch}',
      type: widget.type,
      timestamp: _timestamp,
      amount: amountVal,
      subType: _selectedSubType,
      durationMinutes: durationVal,
      memo: memoVal,
    );

    widget.onSave(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.75,
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
              Text(
                '${widget.type.emoji} ${widget.type.label} 상세 기록',
                style: AppTypography.heading2.copyWith(fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                // 1. 유형 선택 (소분류 칩)
                const Text(
                  '종류 선택',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final opt in _subTypeOptions)
                      ChoiceChip(
                        label: Text(opt),
                        selected: _selectedSubType == opt,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedSubType = opt);
                        },
                        selectedColor: const Color(0xFF0284C7),
                        labelStyle: TextStyle(
                          color: _selectedSubType == opt ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2. 용량 / 시간 입력
                if (widget.type == BabyCareLogType.feeding) ...[
                  const Text('수유량 (ml)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '예: 160',
                      suffixText: 'ml',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ] else if (widget.type == BabyCareLogType.babyFood) ...[
                  const Text('섭취량 (g)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '예: 120',
                      suffixText: 'g',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ] else if (widget.type == BabyCareLogType.sleep) ...[
                  const Text('수면 시간 (분)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '예: 90 (1시간 30분)',
                      suffixText: '분',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 3. 메모
                const Text('메모', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _memoCtrl,
                  decoration: InputDecoration(
                    hintText: '특이사항이나 상태를 적어주세요',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('기록 저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
