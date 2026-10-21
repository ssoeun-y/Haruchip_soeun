import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/schedule_room.dart';

/// 모임 공지/메모 추가 및 수정 다이얼로그
Future<RoomNotice?> showAddRoomNoticeDialog(
  BuildContext context, {
  required String authorName,
  required String authorIcon,
  String? authorUid,
  RoomNotice? existingNotice,
}) {
  return showDialog<RoomNotice>(
    context: context,
    builder: (ctx) => _AddRoomNoticeDialog(
      authorName: authorName,
      authorIcon: authorIcon,
      authorUid: authorUid,
      existingNotice: existingNotice,
    ),
  );
}

class _AddRoomNoticeDialog extends StatefulWidget {
  const _AddRoomNoticeDialog({
    required this.authorName,
    required this.authorIcon,
    this.authorUid,
    this.existingNotice,
  });

  final String authorName;
  final String authorIcon;
  final String? authorUid;
  final RoomNotice? existingNotice;

  @override
  State<_AddRoomNoticeDialog> createState() => _AddRoomNoticeDialogState();
}

class _AddRoomNoticeDialogState extends State<_AddRoomNoticeDialog> {
  late TextEditingController _contentController;
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.existingNotice?.content ?? '');
    _isPinned = widget.existingNotice?.isPinned ?? false;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 공지 내용을 입력해주세요.')),
      );
      return;
    }

    final notice = RoomNotice(
      id: widget.existingNotice?.id ?? 'notice-${DateTime.now().microsecondsSinceEpoch}',
      authorName: widget.existingNotice?.authorName ?? widget.authorName,
      authorIcon: widget.existingNotice?.authorIcon ?? widget.authorIcon,
      authorUid: widget.existingNotice?.authorUid ?? widget.authorUid,
      content: content,
      createdAt: widget.existingNotice?.createdAt ?? DateTime.now(),
      isPinned: _isPinned,
      confirmedMemberUids: widget.existingNotice?.confirmedMemberUids ?? const [],
      comments: widget.existingNotice?.comments ?? const [],
    );

    Navigator.of(context).pop(notice);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingNotice != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
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
                    isEditing ? '📌 공지 / 메모 수정' : '📌 공지 / 메모 등록',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardLabel.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.protoHeading,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '공지사항 또는 구성원에게 남길 메모를 작성하세요.',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _isPinned,
                  onChanged: (val) => setState(() => _isPinned = val ?? false),
                  activeColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                const Text(
                  '상단에 핀으로 고정하기',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: const Text('취소', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      isEditing ? '수정 완료' : '등록하기',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
