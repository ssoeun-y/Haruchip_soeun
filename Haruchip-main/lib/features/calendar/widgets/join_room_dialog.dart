import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/schedule_room.dart';
import '../data/room_remote.dart';
import '../providers/schedule_room_provider.dart';

/// 초대 코드로 모임 방 참가 다이얼로그
Future<bool?> showJoinRoomDialog(BuildContext context, [WidgetRef? ref]) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => const _JoinRoomDialog(),
  );
}

class _JoinRoomDialog extends ConsumerStatefulWidget {
  const _JoinRoomDialog();

  @override
  ConsumerState<_JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends ConsumerState<_JoinRoomDialog> {
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController(text: '나');
  String _selectedEmoji = '🐱';
  String _selectedColor = kPreset50PastelColors[3];

  final List<String> _emojis = ['🐥', '🐶', '🐱', '🦊', '🐻', '🐰', '🦁', '🐼', '🐨', '🦄', '🐯', '🐧'];

  @override
  void dispose() {
    _codeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  bool _submitting = false;

  Future<void> _handleJoin() async {
    if (_submitting) return;
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 초대 코드를 입력해주세요.')),
      );
      return;
    }

    final nickname = _nicknameController.text.trim().isEmpty ? '나' : _nicknameController.text.trim();

    // 멤버 구분은 계정 uid로 (닉네임은 표시용 이름일 뿐)
    final member = RoomMember(
      uid: ref.read(currentUserProfileProvider).uid,
      name: nickname,
      icon: _selectedEmoji,
      colorHex: _selectedColor,
    );

    setState(() => _submitting = true);
    JoinRoomResult result;
    try {
      result = await ref.read(scheduleRoomsProvider.notifier).joinRoomSynced(code, member);
    } catch (_) {
      result = JoinRoomResult.failed;
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    final message = switch (result) {
      JoinRoomResult.joined => '🎉 모임 방에 성공적으로 참여했습니다!',
      JoinRoomResult.alreadyMember => '이미 참여 중인 모임 방이에요.',
      JoinRoomResult.notFound => '❌ 일치하는 모임 방 코드를 찾을 수 없습니다.',
      JoinRoomResult.expired => '⌛ 만료된 초대 코드예요 (7일). 방장에게 새 코드를 받아주세요.',
      JoinRoomResult.failed => '❌ 참여하지 못했어요. 로그인·네트워크를 확인해주세요.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    if (result == JoinRoomResult.joined || result == JoinRoomResult.alreadyMember) {
      Navigator.of(context).pop(true);
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
                    '🔑 모임 방 참가하기',
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

            // 1. 초대 코드 입력
            const Text('모임 초대 보안 코드 (8~10자리)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: '예: HC-8829AF 또는 TEAM99',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. 모임에서 쓸 프로필 설정
            const Text('내 모임 프로필 & 식별 컬러', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            Row(
              children: [
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
                      hintText: '내 이름 / 닉네임',
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

            // 파스텔 색상 선택
            const Text('식별 컬러 선택 (중복 색상은 자동 변경됩니다)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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

            // 참가 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('모임 방 입장하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
