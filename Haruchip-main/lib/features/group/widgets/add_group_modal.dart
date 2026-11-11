import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/common_date_time_picker.dart';
import '../models/group_category_item.dart';
import '../providers/group_category_provider.dart';

class AddGroupModal extends ConsumerStatefulWidget {
  const AddGroupModal({super.key, this.existingGroup});

  final GroupCategoryItem? existingGroup;

  static Future<void> show(BuildContext context, {GroupCategoryItem? existingGroup}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddGroupModal(existingGroup: existingGroup),
    );
  }

  @override
  ConsumerState<AddGroupModal> createState() => _AddGroupModalState();
}

class _AddGroupModalState extends ConsumerState<AddGroupModal> {
  final _nameController = TextEditingController();
  final _regularInfoController = TextEditingController();
  final _memoController = TextEditingController();

  String _selectedIcon = '👥';
  late DateTime _foundationDate;
  int _memberCount = 5;

  final List<String> _availableIcons = [
    '👥', '🍻', '⚽', '☕', '🎮', '🏕️',
    '🎸', '📚', '🍕', '🏸', '🎬', '🧗',
    '🎳', '🍣', '🍷', '🚴', '🎤', '🏓',
  ];

  final List<String> _regularPresets = [
    '매월 둘째 주 토요일',
    '매월 마지막 주 금요일',
    '매주 일요일 오전 10시',
    '격주 목요일 저녁 7시',
    '분기별 1회 정모',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingGroup != null) {
      final g = widget.existingGroup!;
      _nameController.text = g.name;
      _regularInfoController.text = g.regularScheduleInfo;
      _memoController.text = g.memo ?? '';
      _selectedIcon = g.icon;
      _foundationDate = g.foundationDate;
      _memberCount = g.memberCount;
    } else {
      _foundationDate = DateTime.now().subtract(const Duration(days: 100));
      _regularInfoController.text = _regularPresets.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regularInfoController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모임 명칭을 입력해주세요.')),
      );
      return;
    }

    final regularInfo = _regularInfoController.text.trim().isEmpty
        ? '정기 모임 일정 미정'
        : _regularInfoController.text.trim();

    if (widget.existingGroup != null) {
      final updated = widget.existingGroup!.copyWith(
        name: name,
        icon: _selectedIcon,
        foundationDate: _foundationDate,
        regularScheduleInfo: regularInfo,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        memberCount: _memberCount,
      );
      ref.read(groupListProvider.notifier).updateGroup(updated);
    } else {
      final newGroup = GroupCategoryItem(
        id: 'group-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        icon: _selectedIcon,
        foundationDate: _foundationDate,
        regularScheduleInfo: regularInfo,
        themeColorHex: '#FFF5F2',
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        createdAt: DateTime.now(),
        memberCount: _memberCount,
      );
      ref.read(groupListProvider.notifier).addGroup(newGroup);
      ref.read(selectedGroupIdProvider.notifier).state = newGroup.id;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingGroup != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 핸들 바
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 타이틀 & 완료 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? '모임 정보 수정' : '새 모임 추가',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF42302A),
                      ),
                    ),
                    TextButton(
                      onPressed: _onSave,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE56B48),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      child: const Text('저장'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. 모임 대표 아이콘 선택
                const Text(
                  '모임 대표 아이콘',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableIcons.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final ic = _availableIcons[index];
                      final isSelected = ic == _selectedIcon;
                      return InkWell(
                        onTap: () => setState(() => _selectedIcon = ic),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFE2D9) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFE56B48) : const Color(0xFFE5E7EB),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(ic, style: const TextStyle(fontSize: 22)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // 2. 모임 명칭 입력
                const Text(
                  '모임 이름',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: '예: 고교 동창회, 주말 풋살 클럽, 독서 토론',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. 모임 결성일 (N일째 카운트 기준일)
                const Text(
                  '모임 결성일 (지속일수 계산)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showCommonDatePickerModal(
                      context,
                      initialDate: _foundationDate,
                      title: '모임 결성일 선택',
                    );
                    if (picked != null) {
                      setState(() => _foundationDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_foundationDate.year}.${_foundationDate.month.toString().padLeft(2, '0')}.${_foundationDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF42302A)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE2D9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '모임 ${DateTime.now().difference(_foundationDate).inDays + 1}일째',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE56B48)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 4. 정기 모임 주기 정보
                const Text(
                  '정기 모임 주기 정보',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _regularInfoController,
                  decoration: InputDecoration(
                    hintText: '예: 매월 둘째 주 토요일, 매주 일요일',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _regularPresets.map((preset) {
                    return ActionChip(
                      label: Text(preset, style: const TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFFFF5F2),
                      side: const BorderSide(color: Color(0xFFFFE2D9)),
                      onPressed: () {
                        setState(() {
                          _regularInfoController.text = preset;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 5. 모임 멤버 수 및 메모
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '모임 인원 수',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$_memberCount명', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: _memberCount > 1
                                          ? () => setState(() => _memberCount--)
                                          : null,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFFE56B48)),
                                      onPressed: () => setState(() => _memberCount++),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                const Text(
                  '모임 소개 / 메모 (선택)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _memoController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: '모임에 대한 짧은 메모를 남겨보세요.',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
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

                // 하단 등록 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE56B48),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isEdit ? '모임 정보 저장하기' : '모임 개설 완료',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
