import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../shared/widgets/common_date_time_picker.dart';
import '../data/hobby_default_data.dart';
import '../models/hobby_item.dart';
import '../providers/hobby_provider.dart';

/// 새 취미 등록 및 기존 취미 수정 모달 바텀시트
class AddHobbyModal extends ConsumerStatefulWidget {
  const AddHobbyModal({
    super.key,
    this.initialHobby,
  });

  final HobbyItem? initialHobby;

  static Future<void> show(
    BuildContext context, {
    HobbyItem? initialHobby,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddHobbyModal(initialHobby: initialHobby),
    );
  }

  @override
  ConsumerState<AddHobbyModal> createState() => _AddHobbyModalState();
}

class _AddHobbyModalState extends ConsumerState<AddHobbyModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _memoController;
  late String _selectedIcon;
  late DateTime _selectedStartDate;

  @override
  void initState() {
    super.initState();
    final hobby = widget.initialHobby;
    _nameController = TextEditingController(text: hobby?.name ?? '');
    _memoController = TextEditingController(text: hobby?.memo ?? '');
    _selectedIcon = hobby?.icon ?? '🎸';
    _selectedStartDate = hobby?.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.disposenatural();
    _memoController.dispose();
    super.dispose();
  }

  void _onPickStartDate() async {
    final picked = await showCommonDatePickerModal(
      context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(1980),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      accentColor: const Color(0xFF354235),
      title: '취미 시작일 선택',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedStartDate = picked;
      });
    }
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('취미 이름을 입력해 주세요.')),
      );
      return;
    }

    final isEdit = widget.initialHobby != null;
    final hobbyId = widget.initialHobby?.id ?? 'hobby-${DateTime.now().millisecondsSinceEpoch}';

    final newHobby = HobbyItem(
      id: hobbyId,
      name: name,
      icon: _selectedIcon,
      startDate: _selectedStartDate,
      memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      colorHex: '#354235',
      createdAt: widget.initialHobby?.createdAt ?? DateTime.now(),
    );

    if (isEdit) {
      ref.read(hobbyListProvider.notifier).updateHobby(newHobby);
    } else {
      ref.read(hobbyListProvider.notifier).addHobby(newHobby);
      ref.read(selectedHobbyIdProvider.notifier).state = hobbyId;
    }

    Navigator.pop(context);
  }

  void _onDelete() {
    if (widget.initialHobby == null) return;
    ref.read(hobbyListProvider.notifier).deleteHobby(widget.initialHobby!.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialHobby != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 상단 타이틀 & 닫기
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? '취미 수정하기' : '새 취미 등록',
                  style: AppTypography.heading2.copyWith(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 대표 아이콘 선택기
            const Text(
              '대표 아이콘 선택',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final icon in kHobbyIconPresets) ...[
                    GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _selectedIcon == icon
                              ? const Color(0xFFDDE7DD)
                              : const Color(0xFFF4F7F4),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedIcon == icon
                                ? const Color(0xFF354235)
                                : const Color(0xFFE5E7EB),
                            width: _selectedIcon == icon ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(icon, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 취미 이름
            const Text(
              '취미 이름',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'ex. 기타 연습, 클라이밍, 베이킹, 러닝',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF354235), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 시작일 선택 (공통 캘린더 팝업 호출)
            const Text(
              '취미 시작일',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _onPickStartDate,
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
                        const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF354235)),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedStartDate.year}.${_selectedStartDate.month.toString().padLeft(2, '0')}.${_selectedStartDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                        ),
                      ],
                    ),
                    const Text('변경', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF354235))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 메모 (선택 사항)
            const Text(
              '한 줄 목표 또는 메모 (선택)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _memoController,
              decoration: InputDecoration(
                hintText: 'ex. 주 2회 꾸준히 하기, 올해 안에 마스터하기',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF354235), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 저장 및 삭제 버튼
            Row(
              children: [
                if (isEdit) ...[
                  IconButton(
                    onPressed: _onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    tooltip: '취미 삭제',
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF354235),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isEdit ? '수정 완료' : '취미 추가하기',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on TextEditingController {
  void disposenatural() {
    dispose();
  }
}
