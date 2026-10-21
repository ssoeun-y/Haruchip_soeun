import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/birthday_profile.dart';
import 'custom_avatar_builder_widget.dart';

/// 친구 생일 추가 / 수정 모달 바텀시트
Future<BirthdayProfile?> showBirthdayFriendModal(
  BuildContext context, {
  BirthdayProfile? existingFriend,
  bool allowDelete = false,
  VoidCallback? onDelete,
}) {
  return showModalBottomSheet<BirthdayProfile>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BirthdayFriendModal(
      existingFriend: existingFriend,
      allowDelete: allowDelete,
      onDelete: onDelete,
    ),
  );
}

class _BirthdayFriendModal extends StatefulWidget {
  const _BirthdayFriendModal({
    this.existingFriend,
    this.allowDelete = false,
    this.onDelete,
  });

  final BirthdayProfile? existingFriend;
  final bool allowDelete;
  final VoidCallback? onDelete;

  @override
  State<_BirthdayFriendModal> createState() => _BirthdayFriendModalState();
}

class _BirthdayFriendModalState extends State<_BirthdayFriendModal>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _memoController;
  late DateTime _selectedDate;
  late bool _hasYear;
  late bool _isLunar;

  late BirthdayAvatarType _avatarType;
  String? _photoUrl;
  late String _selectedEmoji;
  late CustomAvatarConfig _avatarConfig;

  late TabController _avatarTabController;
  final ImagePicker _picker = ImagePicker();

  final List<String> _emojiPresets = [
    '🎂', '🎉', '🎁', '👑', '👧', '👦', '👩', '👨', '🧑', '👶',
    '🐱', '🐶', '🐰', '🐻', '🦊', '🐼', '🐨', '🐯', '🦁', '🦄',
    '🎀', '⭐', '💖', '🌸', '🍓', '🍰', '☕', '🥑', '🐣', '✨',
  ];

  @override
  void initState() {
    super.initState();
    final friend = widget.existingFriend;

    _nameController = TextEditingController(text: friend?.name ?? '');
    _memoController = TextEditingController(text: friend?.memo ?? '');
    _selectedDate = friend?.birthDate ?? DateTime(2000, 5, 20);
    _hasYear = friend?.hasYear ?? true;
    _isLunar = friend?.isLunar ?? false;

    _avatarType = friend?.avatarType ?? BirthdayAvatarType.customAvatar;
    _photoUrl = friend?.photoUrl;
    _selectedEmoji = friend?.emoji ?? '🎂';
    _avatarConfig = friend?.avatarConfig ?? const CustomAvatarConfig();

    _avatarTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: switch (_avatarType) {
        BirthdayAvatarType.photo => 0,
        BirthdayAvatarType.emoji => 1,
        BirthdayAvatarType.customAvatar => 2,
      },
    );

    _avatarTabController.addListener(() {
      if (!_avatarTabController.indexIsChanging) {
        setState(() {
          _avatarType = switch (_avatarTabController.index) {
            0 => BirthdayAvatarType.photo,
            1 => BirthdayAvatarType.emoji,
            _ => BirthdayAvatarType.customAvatar,
          };
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    _avatarTabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (xFile != null) {
        final bytes = await xFile.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _photoUrl = base64String;
          _avatarType = BirthdayAvatarType.photo;
        });
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  void _openDatePicker() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HaruCalendarPicker(
                initialDate: _selectedDate,
                firstDate: DateTime(1920, 1, 1),
                lastDate: DateTime(2035, 12, 31),
                onDateChanged: (picked) {
                  setState(() => _selectedDate = picked);
                  Navigator.of(dialogCtx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 별명 또는 이름을 입력해주세요.')),
      );
      return;
    }

    final friend = BirthdayProfile(
      id: widget.existingFriend?.id ?? 'bday-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      birthDate: _selectedDate,
      hasYear: _hasYear,
      isLunar: _isLunar,
      avatarType: _avatarType,
      photoUrl: _photoUrl,
      emoji: _selectedEmoji,
      avatarConfig: _avatarConfig,
      memo: _memoController.text.trim().isNotEmpty ? _memoController.text.trim() : null,
    );

    Navigator.of(context).pop(friend);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingFriend != null;
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    final dateDisplay = _hasYear ? '${_selectedDate.year}년 $m월 $d일' : '$m월 $d일';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 상단 핸들 바 & 타이틀
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? '🎂 친구 생일 수정' : '🎂 새 친구 생일 추가',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading2.copyWith(
                            color: AppColors.protoHeading,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppColors.protoSubtitle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // 스크롤 본문
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 별명(이름) 입력
                    Text(
                      '별명 (이름)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: AppTypography.body.copyWith(
                        color: AppColors.protoHeading,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '예: 엄마, 베프 지민, 민수',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. 생년월일 & 옵션 토글
                    Text(
                      '생년월일',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _openDatePicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cake_outlined, size: 20, color: Color(0xFFDB2777)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                dateDisplay,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const Text(
                              '변경',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 토글 옵션 행 [연도 미포함] & [음력 생일]
                    Row(
                      children: [
                        // 연도 미포함
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _hasYear = !_hasYear),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: !_hasYear ? const Color(0xFFFDF2F8) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !_hasYear ? const Color(0xFFDB2777) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    !_hasYear ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                    size: 16,
                                    color: !_hasYear ? const Color(0xFFDB2777) : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      '연도 미포함(월/일만)',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 음력 생일
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isLunar = !_isLunar),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isLunar ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isLunar ? const Color(0xFFD97706) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isLunar ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                    size: 16,
                                    color: _isLunar ? const Color(0xFFD97706) : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      '음력 생일 🌙',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // 3. 프로필 비주얼 3가지 선택 탭
                    Text(
                      '프로필 비주얼 선택',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _avatarTabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        labelColor: const Color(0xFF0F172A),
                        unselectedLabelColor: const Color(0xFF64748B),
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        tabs: const [
                          Tab(text: '📷 사진 등록'),
                          Tab(text: '😀 이모티콘'),
                          Tab(text: '✨ 커스텀 아바타'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 탭별 비주얼 선택 패널
                    if (_avatarType == BirthdayAvatarType.photo)
                      _buildPhotoSection()
                    else if (_avatarType == BirthdayAvatarType.emoji)
                      _buildEmojiSection()
                    else
                      CustomAvatarBuilderWidget(
                        initialConfig: _avatarConfig,
                        onChanged: (cfg) => setState(() => _avatarConfig = cfg),
                      ),

                    const SizedBox(height: 20),

                    // 4. 간단 메모 (선택)
                    Text(
                      '메모 (선택)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.protoSubtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _memoController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '좋아하는 선물, 취향 등 메모하기',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 버튼 바
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  if (isEditing && widget.allowDelete) ...[
                    IconButton(
                      onPressed: () {
                        widget.onDelete?.call();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      tooltip: '삭제하기',
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDB2777),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isEditing ? '수정 완료' : '친구 등록하기',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    ImageProvider? imageProvider;
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      if (_photoUrl!.startsWith('data:image')) {
        try {
          final base64Content = _photoUrl!.split(',').last;
          imageProvider = MemoryImage(base64Decode(base64Content));
        } catch (_) {}
      } else {
        imageProvider = NetworkImage(_photoUrl!);
      }
    }

    return Center(
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F8),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFCE7F3), width: 3),
              image: imageProvider != null
                  ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                  : null,
            ),
            child: imageProvider == null
                ? const Icon(Icons.person_rounded, size: 48, color: Color(0xFFDB2777))
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text('갤러리', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text('카메라', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (_photoUrl != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _photoUrl = null),
                  child: const Text('삭제', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiSection() {
    return Column(
      children: [
        // 선택된 이모지 미리보기
        Center(
          child: Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFDF2F8),
              shape: BoxShape.circle,
            ),
            child: Text(_selectedEmoji, style: const TextStyle(fontSize: 40)),
          ),
        ),
        const SizedBox(height: 12),

        // 이모지 프리셋 그리드
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _emojiPresets.map((emoji) {
            final isSelected = _selectedEmoji == emoji;
            return GestureDetector(
              onTap: () => setState(() => _selectedEmoji = emoji),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFCE7F3) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFDB2777) : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
