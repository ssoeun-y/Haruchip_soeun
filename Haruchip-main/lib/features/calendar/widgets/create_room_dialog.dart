import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/schedule_room.dart';
import '../providers/schedule_room_provider.dart';

/// 새 모임 방 생성 다이얼로그
Future<ScheduleRoom?> showCreateRoomDialog(BuildContext context, [WidgetRef? ref]) {
  return showDialog<ScheduleRoom>(
    context: context,
    builder: (ctx) => const _CreateRoomDialog(),
  );
}

class _CreateRoomDialog extends ConsumerStatefulWidget {
  const _CreateRoomDialog();

  @override
  ConsumerState<_CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends ConsumerState<_CreateRoomDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _nicknameController = TextEditingController(text: '하루');

  String _selectedEmoji = '🐥';
  String _selectedColor = kPreset50PastelColors[0];
  String _selectedCategory = '동창회';

  final List<String> _emojis = ['🐥', '🐶', '🐱', '🦊', '🐻', '🐰', '🦁', '🐼', '🐨', '🦄', '🐯', '🐧'];
  final List<String> _categories = ['동창회', '스터디', '프로젝트', '동호회', '가족', '여행', '모임'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  bool _submitting = false;

  Future<void> _handleCreate() async {
    if (_submitting) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 모임 방 이름을 입력해주세요.')),
      );
      return;
    }

    final nickname = _nicknameController.text.trim().isEmpty ? '나' : _nicknameController.text.trim();

    // 멤버 구분은 계정 uid로 (닉네임은 표시용 이름일 뿐)
    final host = RoomMember(
      uid: ref.read(currentUserProfileProvider).uid,
      name: nickname,
      icon: _selectedEmoji,
      colorHex: _selectedColor,
      isHost: true,
    );

    setState(() => _submitting = true);
    try {
      final newRoom = await ref.read(scheduleRoomsProvider.notifier).createRoomSynced(
            name: name,
            description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
            categoryTag: _selectedCategory,
            hostMember: host,
          );
      if (!mounted) return;
      Navigator.of(context).pop(newRoom);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 방을 만들지 못했어요. 로그인·네트워크·보안 규칙을 확인해주세요. ($e)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '✨ 새 모임 방 만들기',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.protoHeading,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 1. 모임 이름
            const Text('모임 이름', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '예: 2026 대학 동창 정기 모임',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. 카테고리 태그
            const Text('모임 분류', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      selectedColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : const Color(0xFF334155),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // 3. 내 프로필 설정 (이모티콘 + 닉네임 + 고유 색상)
            const Text('내 모임 프로필 & 식별 컬러', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            Row(
              children: [
                // 이모티콘 팝업 선택
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF${_selectedColor.replaceAll('#', '')}')),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedEmoji,
                      items: _emojis.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 20)))).toList(),
                      onChanged: (v) => setState(() => _selectedEmoji = v ?? _selectedEmoji),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      hintText: '내 닉네임 입력',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 파스텔 50색 팔레트 프리뷰 (최대 10개 나열 및 더보기)
            const Text('공유 캘린더 전용 1인 1색상', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kPreset50PastelColors.take(18).map((hex) {
                final isSel = _selectedColor == hex;
                final col = Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel ? const Color(0xFF0F172A) : Colors.black12,
                        width: isSel ? 2.5 : 1,
                      ),
                    ),
                    child: isSel ? const Icon(Icons.check, size: 14, color: Color(0xFF0F172A)) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 생성 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('모임 방 개설하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
