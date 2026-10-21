import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../design_system/colors.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/fandom_profile.dart';

class FandomMemberListWidget extends StatelessWidget {
  const FandomMemberListWidget({
    super.key,
    required this.members,
    required this.onMembersChanged,
  });

  final List<FandomMember> members;
  final ValueChanged<List<FandomMember>> onMembersChanged;

  List<FandomMember> get _sortedMembers {
    final list = List<FandomMember>.from(members);
    list.sort((a, b) {
      final rankComp = a.biasRank.priority.compareTo(b.biasRank.priority);
      if (rankComp != 0) return rankComp;
      return a.birthDate.compareTo(b.birthDate);
    });
    return list;
  }

  void _showAddOrEditMemberDialog(BuildContext context, {FandomMember? existingMember}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MemberEditSheet(
        member: existingMember,
        onSave: (savedMember) {
          final list = List<FandomMember>.from(members);
          if (existingMember != null) {
            final idx = list.indexWhere((m) => m.id == existingMember.id);
            if (idx != -1) {
              list[idx] = savedMember;
            }
          } else {
            list.add(savedMember);
          }
          onMembersChanged(list);
        },
        onDelete: existingMember != null
            ? () {
                final list = List<FandomMember>.from(members)..removeWhere((m) => m.id == existingMember.id);
                onMembersChanged(list);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedMembers;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEFCE8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('👑', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      '멤버 프로필 & 최애 순위',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.protoHeading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${sorted.length}명',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9333EA),
                    ),
                  ),
                ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showAddOrEditMemberDialog(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF3E8FF)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: Color(0xFF9333EA)),
                      SizedBox(width: 4),
                      Text(
                        '멤버 추가',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9333EA)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (sorted.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Text('🎤', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    const Text(
                      '등록된 멤버가 없습니다',
                      style: TextStyle(fontSize: 13, color: AppColors.protoSubtitle),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showAddOrEditMemberDialog(context),
                      child: const Text('첫 번째 멤버 등록하기'),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, idx) {
                  final member = sorted[idx];
                  return _buildMemberCard(context, member);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, FandomMember member) {
    final now = DateTime.now();
    var nextBirthday = DateTime(now.year, member.birthDate.month, member.birthDate.day);
    if (nextBirthday.isBefore(DateTime(now.year, now.month, now.day))) {
      nextBirthday = DateTime(now.year + 1, member.birthDate.month, member.birthDate.day);
    }
    final daysUntilBirthday = nextBirthday.difference(DateTime(now.year, now.month, now.day)).inDays;

    final (badgeBg, badgeText, badgeBorder) = switch (member.biasRank) {
      BiasRank.first => (const Color(0xFFFEFCE8), const Color(0xFFB45309), const Color(0xFFFDE68A)),
      BiasRank.second => (const Color(0xFFFFF0F5), const Color(0xFFDB2777), const Color(0xFFFCE7F3)),
      BiasRank.third => (const Color(0xFFFAF5FF), const Color(0xFF9333EA), const Color(0xFFF3E8FF)),
      BiasRank.member => (const Color(0xFFF3F4F6), const Color(0xFF4B5563), const Color(0xFFE5E7EB)),
    };

    return InkWell(
      onTap: () => _showAddOrEditMemberDialog(context, existingMember: member),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: member.biasRank == BiasRank.first
                ? const Color(0xFFFACC15)
                : const Color(0xFFF3F4F6),
            width: member.biasRank == BiasRank.first ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bias Rank Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: badgeBorder),
              ),
              child: Text(
                member.biasRank.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badgeText,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Avatar / Photo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              clipBehavior: Clip.antiAlias,
              child: member.photoUrl != null && member.photoUrl!.isNotEmpty
                  ? (member.photoUrl!.startsWith('http')
                      ? Image.network(member.photoUrl!, fit: BoxFit.cover)
                      : Image.file(File(member.photoUrl!), fit: BoxFit.cover))
                  : Center(
                      child: Text(member.emoji, style: const TextStyle(fontSize: 22)),
                    ),
            ),
            const SizedBox(height: 6),

            // Name
            Text(
              member.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.protoHeading,
              ),
            ),
            const SizedBox(height: 2),

            // Birthday Countdown
            Text(
              daysUntilBirthday == 0 ? '🎉 오늘 생일!' : 'D-$daysUntilBirthday',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: daysUntilBirthday == 0 ? const Color(0xFFDB2777) : AppColors.protoSubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberEditSheet extends StatefulWidget {
  const _MemberEditSheet({
    this.member,
    required this.onSave,
    this.onDelete,
  });

  final FandomMember? member;
  final ValueChanged<FandomMember> onSave;
  final VoidCallback? onDelete;

  @override
  State<_MemberEditSheet> createState() => _MemberEditSheetState();
}

class _MemberEditSheetState extends State<_MemberEditSheet> {
  late TextEditingController _nameController;
  late TextEditingController _positionController;
  late TextEditingController _memoController;
  late DateTime _birthDate;
  late BiasRank _biasRank;
  late String _emoji;
  String? _photoUrl;
  final ImagePicker _picker = ImagePicker();

  static const List<String> _emojiPresets = ['🎤', '🐰', '🐱', '🐶', '🐻', '🦊', '🐿️', '🐯', '🐺', '🐹', '🍒', '⭐', '💎', '🌸'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _positionController = TextEditingController(text: widget.member?.position ?? '');
    _memoController = TextEditingController(text: widget.member?.memo ?? '');
    _birthDate = widget.member?.birthDate ?? DateTime(2000, 1, 1);
    _biasRank = widget.member?.biasRank ?? BiasRank.member;
    _emoji = widget.member?.emoji ?? '🎤';
    _photoUrl = widget.member?.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
      if (file != null) {
        setState(() => _photoUrl = file.path);
      }
    } catch (_) {}
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HaruCalendarPicker(
              initialDate: _birthDate,
              firstDate: DateTime(1950, 1, 1),
              lastDate: DateTime.now(),
              onDateChanged: (picked) {
                setState(() => _birthDate = picked);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.member != null ? '멤버 정보 수정' : '새 멤버 추가',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      onPressed: () {
                        widget.onDelete!();
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // 최애 순위 선택기
              const Text('최애 순위 설정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.protoSubtitle)),
              const SizedBox(height: 8),
              Row(
                children: BiasRank.values.map((rank) {
                  final isSelected = _biasRank == rank;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => setState(() => _biasRank = rank),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFEFCE8) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFACC15) : const Color(0xFFE5E7EB),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            rank.shortLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF78350F) : AppColors.protoSubtitle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // 아바타 / 사진 선택 & 이모지
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _photoUrl != null && _photoUrl!.isNotEmpty
                          ? Image.file(File(_photoUrl!), fit: BoxFit.cover)
                          : Center(child: Text(_emoji, style: const TextStyle(fontSize: 26))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _emojiPresets.take(7).map((e) {
                        return InkWell(
                          onTap: () => setState(() {
                            _emoji = e;
                            _photoUrl = null;
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _emoji == e && _photoUrl == null ? const Color(0xFFF3E8FF) : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _emoji == e && _photoUrl == null ? const Color(0xFF9333EA) : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Text(e, style: const TextStyle(fontSize: 16)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 이름
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '멤버 이름 (예: 카리나, 정국)',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),

              // 생일 선택
              InkWell(
                onTap: _showDatePicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '생일: ${_birthDate.year}년 ${_birthDate.month}월 ${_birthDate.day}일',
                        style: const TextStyle(fontSize: 13, color: AppColors.protoHeading),
                      ),
                      const Icon(Icons.cake_outlined, size: 18, color: Color(0xFF9333EA)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 포지션 / 메모
              TextField(
                controller: _positionController,
                decoration: InputDecoration(
                  labelText: '포지션 / 한 줄 소개 (선택)',
                  hintText: '예: 메인보컬, 리더',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFACC15),
                    foregroundColor: const Color(0xFF451A03),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;

                    final member = FandomMember(
                      id: widget.member?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      birthDate: _birthDate,
                      photoUrl: _photoUrl,
                      emoji: _emoji,
                      position: _positionController.text.trim(),
                      memo: _memoController.text.trim(),
                      biasRank: _biasRank,
                    );
                    widget.onSave(member);
                    Navigator.pop(context);
                  },
                  child: const Text('저장하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
