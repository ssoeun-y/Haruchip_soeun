import 'package:flutter/material.dart';

import '../../../design_system/typography.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/baby_profile.dart';

/// 아기 신체 계측 기록 추가 모달
Future<GrowthRecord?> showBabyGrowthRecordModal(
  BuildContext context, {
  GrowthRecord? existingRecord,
}) {
  return showModalBottomSheet<GrowthRecord>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BabyGrowthRecordSheet(existingRecord: existingRecord),
  );
}

class _BabyGrowthRecordSheet extends StatefulWidget {
  const _BabyGrowthRecordSheet({this.existingRecord});

  final GrowthRecord? existingRecord;

  @override
  State<_BabyGrowthRecordSheet> createState() => _BabyGrowthRecordSheetState();
}

class _BabyGrowthRecordSheetState extends State<_BabyGrowthRecordSheet> {
  late DateTime _date;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _headCtrl;
  late TextEditingController _memoCtrl;

  @override
  void initState() {
    super.initState();
    final rec = widget.existingRecord;
    _date = rec?.date ?? DateTime.now();
    _heightCtrl = TextEditingController(text: rec?.heightCm?.toString() ?? '');
    _weightCtrl = TextEditingController(text: rec?.weightKg?.toString() ?? '');
    _headCtrl = TextEditingController(text: rec?.headCircumferenceCm?.toString() ?? '');
    _memoCtrl = TextEditingController(text: rec?.memo ?? '');
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _headCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  void _save() {
    final height = double.tryParse(_heightCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());
    final head = double.tryParse(_headCtrl.text.trim());
    final memo = _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim();

    if (height == null && weight == null && head == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('키, 몸무게, 머리둘레 중 하나 이상을 입력해주세요.')),
      );
      return;
    }

    final record = GrowthRecord(
      id: widget.existingRecord?.id ?? 'growth-${DateTime.now().microsecondsSinceEpoch}',
      date: _date,
      heightCm: height,
      weightKg: weight,
      headCircumferenceCm: head,
      memo: memo,
    );

    Navigator.of(context).pop(record);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.78,
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
                  '📏 신체 계측 성장 기록',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading2.copyWith(fontSize: 18),
                ),
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
                // 1. 측정 날짜
                const Text('측정 날짜', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showHaruDatePicker(
                      context,
                      initialDate: _date,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _date = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(_date),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0284C7)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 2. 키, 몸무게, 머리둘레
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('키 (cm)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _heightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '68.5',
                              suffixText: 'cm',
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('몸무게 (kg)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '7.8',
                              suffixText: 'kg',
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
                  ],
                ),

                const SizedBox(height: 18),

                const Text('머리둘레 (cm)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _headCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '43.2',
                    suffixText: 'cm',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 3. 메모
                const Text('메모', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _memoCtrl,
                  decoration: InputDecoration(
                    hintText: '병원 검진 메모나 특이사항을 적어주세요',
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
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
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
