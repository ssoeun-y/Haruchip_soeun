import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../shared/widgets/common_date_time_picker.dart';
import '../models/trip_item.dart';
import '../providers/travel_provider.dart';

/// 새 여행 추가 / 여행 정보 수정 모달
class AddTripModal extends ConsumerStatefulWidget {
  const AddTripModal({
    super.key,
    this.initialTrip,
  });

  final TripItem? initialTrip;

  static Future<void> show(BuildContext context, {TripItem? initialTrip}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTripModal(initialTrip: initialTrip),
    );
  }

  @override
  ConsumerState<AddTripModal> createState() => _AddTripModalState();
}

class _AddTripModalState extends ConsumerState<AddTripModal> {
  late final TextEditingController _destinationController;
  late final TextEditingController _memoController;

  late String _selectedEmoji;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _selectedColorHex;

  final List<String> _emojiPresets = [
    '✈️', '🌴', '❄️', '🗼', '🌊', '🎡', '🏕️', '🚆', '🌸', '🏙️', '🏰', '⛰️'
  ];

  final List<String> _colorPresets = [
    '#2C3E50', // Classic Navy Blue
    '#0284C7', // Ocean Sky Blue
    '#0D9488', // Emerald Teal
    '#E11D48', // Coral Rose
    '#8B5CF6', // Soft Violet
    '#D97706', // Warm Sunset Amber
  ];

  @override
  void initState() {
    super.initState();
    final trip = widget.initialTrip;
    final now = DateTime.now();

    _destinationController = TextEditingController(text: trip?.destination ?? '');
    _memoController = TextEditingController(text: trip?.memo ?? '');
    _selectedEmoji = trip?.emoji ?? '✈️';
    _startDate = trip?.startDate ?? now.add(const Duration(days: 14));
    _endDate = trip?.endDate ?? now.add(const Duration(days: 17));
    _selectedColorHex = trip?.themeColorHex ?? '#2C3E50';
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showCommonDateRangePickerModal(
      context,
      initialStartDate: _startDate,
      initialEndDate: _endDate,
      isAllDay: true,
      showAllDayToggle: false,
      accentColor: const Color(0xFF0284C7),
      title: '여행 기간 설정',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _saveTrip() {
    final dest = _destinationController.text.trim();
    if (dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 여행지 명칭을 입력해 주세요.')),
      );
      return;
    }

    if (widget.initialTrip != null) {
      final updated = widget.initialTrip!.copyWith(
        destination: dest,
        emoji: _selectedEmoji,
        startDate: _startDate,
        endDate: _endDate,
        themeColorHex: _selectedColorHex,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      );
      ref.read(travelTripListProvider.notifier).updateTrip(updated);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✈️ [$dest] 여행 정보가 수정되었습니다.')),
      );
    } else {
      final newTrip = TripItem(
        id: 'trip-${DateTime.now().millisecondsSinceEpoch}',
        destination: dest,
        emoji: _selectedEmoji,
        startDate: _startDate,
        endDate: _endDate,
        themeColorHex: _selectedColorHex,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      );
      ref.read(travelTripListProvider.notifier).addTrip(newTrip);
      // 필수 짐싸기 템플릿 자동 로드
      ref.read(travelTripListProvider.notifier).loadDefaultPackingList(newTrip.id);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🎉 [$dest] 여행이 타임라인에 등록되었습니다!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final durationDays = _endDate.difference(_startDate).inDays + 1;
    final startStr = '${_startDate.year}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${_endDate.year}.${_endDate.month.toString().padLeft(2, '0')}.${_endDate.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialTrip != null ? '여행 정보 수정' : '새 여행 등록',
                  style: AppTypography.heading2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.protoHeading,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 대표 이모지 선택
            const Text('대표 이모지', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final emoji in _emojiPresets)
                    GestureDetector(
                      onTap: () => setState(() => _selectedEmoji = emoji),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedEmoji == emoji ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedEmoji == emoji ? const Color(0xFF0284C7) : const Color(0xFFE5E7EB),
                            width: _selectedEmoji == emoji ? 2 : 1,
                          ),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 여행지 명칭
            const Text('여행지 명칭', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
            const SizedBox(height: 6),
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                hintText: 'ex. 오사카 & 교토 투어, 제주도 힐링 여행',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 여행 기간 선택
            const Text('여행 기간 (출발일 ~ 도착일)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF0284C7)),
                        const SizedBox(width: 10),
                        Text(
                          '$startStr ~ $endStr',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${durationDays - 1}박 $durationDays일',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 테마 컬러
            const Text('티켓 테마 컬러', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final hex in _colorPresets)
                  GestureDetector(
                    onTap: () => setState(() => _selectedColorHex = hex),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF${hex.replaceAll('#', '')}')),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColorHex == hex ? Colors.black : Colors.white,
                          width: _selectedColorHex == hex ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: _selectedColorHex == hex
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // 한줄 메모
            const Text('여행 테마 / 한줄 메모 (선택)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
            const SizedBox(height: 6),
            TextField(
              controller: _memoController,
              decoration: InputDecoration(
                hintText: 'ex. 비에이 크리스마스 나무 & 료칸 온천 힐링',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 등록 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  widget.initialTrip != null ? '수정 완료' : '여행 타임라인에 추가',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
