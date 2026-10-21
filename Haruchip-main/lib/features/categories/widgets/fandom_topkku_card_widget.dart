import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import '../../../design_system/colors.dart';
import '../models/category_model.dart';
import '../models/fandom_profile.dart';

class FandomTopkkuCardWidget extends StatefulWidget {
  const FandomTopkkuCardWidget({
    super.key,
    required this.topkkuCard,
    required this.artistName,
    required this.fandomName,
    this.debutDate,
    this.fandomStartDate,
    required this.onTopkkuChanged,
  });

  final FandomTopkkuCard topkkuCard;
  final String artistName;
  final String fandomName;
  final DateTime? debutDate;
  final DateTime? fandomStartDate;
  final ValueChanged<FandomTopkkuCard> onTopkkuChanged;

  @override
  State<FandomTopkkuCardWidget> createState() => _FandomTopkkuCardWidgetState();
}

class _FandomTopkkuCardWidgetState extends State<FandomTopkkuCardWidget>
    with SingleTickerProviderStateMixin {
  final GlobalKey _repaintKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _musicAnimController;
  bool _isPlayingMusic = false;
  String? _selectedStickerId;

  static const List<String> _stickerPresets = [
    '🎀', '✨', '💖', '👑', '⭐', '🌸', '💎', '🧸',
    '💫', '💌', '🌷', '🦋', '🍀', '🍰', '🍓', '🥑',
    '🎉', '🔥', '🎤', '💿', '🎧', '🎸', '🌟', '🌙',
  ];

  @override
  void initState() {
    super.initState();
    _musicAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _musicAnimController.dispose();
    super.dispose();
  }

  void _toggleMusic() {
    setState(() {
      _isPlayingMusic = !_isPlayingMusic;
      if (_isPlayingMusic) {
        _musicAnimController.repeat();
      } else {
        _musicAnimController.stop();
      }
    });
  }

  Future<void> _pickPhotocard() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1536,
        imageQuality: 90,
      );
      if (file != null) {
        final updated = widget.topkkuCard.copyWith(photocardUrl: file.path);
        widget.onTopkkuChanged(updated);
      }
    } catch (_) {}
  }

  Future<void> _addPhotoSticker() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (file != null) {
        final newSticker = StickerConfig(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          stickerType: file.path,
          x: 100.0,
          y: 120.0,
          scale: 1.0,
          rotation: 0.0,
        );
        final updated = widget.topkkuCard.copyWith(
          decorations: [...widget.topkkuCard.decorations, newSticker],
        );
        widget.onTopkkuChanged(updated);
        setState(() => _selectedStickerId = newSticker.id);
      }
    } catch (_) {}
  }

  void _addEmojiSticker(String emoji) {
    final newSticker = StickerConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      stickerType: emoji,
      x: 100.0,
      y: 120.0,
      scale: 1.2,
      rotation: 0.0,
    );
    final updated = widget.topkkuCard.copyWith(
      decorations: [...widget.topkkuCard.decorations, newSticker],
    );
    widget.onTopkkuChanged(updated);
    setState(() => _selectedStickerId = newSticker.id);
  }

  void _removeSticker(String id) {
    final updatedList = widget.topkkuCard.decorations.where((d) => d.id != id).toList();
    final updated = widget.topkkuCard.copyWith(decorations: updatedList);
    widget.onTopkkuChanged(updated);
    setState(() {
      if (_selectedStickerId == id) _selectedStickerId = null;
    });
  }

  void _showStickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '스티커 & 사진 누끼 추가',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.protoHeading,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFF3E8FF)),
                          backgroundColor: const Color(0xFFFAF5FF),
                        ),
                        icon: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF9333EA)),
                        label: const Text(
                          '사진/얼굴 누끼 스티커',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9333EA),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _addPhotoSticker();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '키치 데코 스티커',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.protoSubtitle),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _stickerPresets.map((emoji) {
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _addEmojiSticker(emoji);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOverlayTextEditor() {
    final controller = TextEditingController(text: widget.topkkuCard.customOverlayText);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '포토카드 문구 설정',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.fandomStartDate != null)
                      ActionChip(
                        label: Text('입덕 ${DateTime.now().difference(widget.fandomStartDate!).inDays + 1}일째'),
                        backgroundColor: const Color(0xFFFAF5FF),
                        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF9333EA)),
                        onPressed: () {
                          controller.text = '입덕 ${DateTime.now().difference(widget.fandomStartDate!).inDays + 1}일째 ✨';
                        },
                      ),
                    if (widget.debutDate != null)
                      ActionChip(
                        label: Text('데뷔 ${DateTime.now().year - widget.debutDate!.year}주년 💖'),
                        backgroundColor: const Color(0xFFFFF0F5),
                        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFFDB2777)),
                        onPressed: () {
                          controller.text = '데뷔 ${DateTime.now().year - widget.debutDate!.year}주년 💖';
                        },
                      ),
                    ActionChip(
                      label: const Text('우리의 찬란한 계절 🌸'),
                      backgroundColor: const Color(0xFFF0FDF4),
                      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF16A34A)),
                      onPressed: () {
                        controller.text = '우리의 찬란한 계절 🌸';
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: '포토카드 상단에 띄울 문구를 입력하세요',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.protoSubtitle),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFACC15), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFACC15),
                      foregroundColor: const Color(0xFF451A03),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final updated = widget.topkkuCard.copyWith(customOverlayText: controller.text.trim());
                      widget.onTopkkuChanged(updated);
                      Navigator.pop(ctx);
                    },
                    child: const Text('저장하기', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMusicTrackEditor() {
    final titleController = TextEditingController(text: widget.topkkuCard.musicTrack?.title ?? '');
    final artistController = TextEditingController(text: widget.topkkuCard.musicTrack?.artist ?? widget.artistName);
    final linkController = TextEditingController(text: widget.topkkuCard.musicTrack?.audioPreviewUrl ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '최애곡 (BGM) 설정',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: '노래 제목',
                    hintText: '예: Supernova, Hype Boy',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: artistController,
                  decoration: InputDecoration(
                    labelText: '아티스트',
                    hintText: '예: aespa, NewJeans',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: linkController,
                  decoration: InputDecoration(
                    labelText: '미리듣기 링크 (선택)',
                    hintText: '유튜브/스포티파이/음원 링크',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFACC15),
                      foregroundColor: const Color(0xFF451A03),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final updated = widget.topkkuCard.copyWith(
                        musicTrack: FandomMusicTrack(
                          title: titleController.text.trim().isEmpty ? '최애곡을 등록해보세요' : titleController.text.trim(),
                          artist: artistController.text.trim(),
                          audioPreviewUrl: linkController.text.trim(),
                        ),
                      );
                      widget.onTopkkuChanged(updated);
                      Navigator.pop(ctx);
                    },
                    child: const Text('저장하기', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportTopkkuImage() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Unselect any active sticker border before capturing
      setState(() => _selectedStickerId = null);
      await Future.delayed(const Duration(milliseconds: 50));

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('🎉 탑꾸 포토카드 완성!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(byteData.buffer.asUint8List(), fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                const Text(
                  '고화질 PNG로 렌더링되었습니다.\n인스타그램 스토리나 X(트위터)에 자랑해보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.protoSubtitle),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('닫기', style: TextStyle(color: AppColors.protoSubtitle)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  foregroundColor: const Color(0xFF451A03),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('SNS 공유 / 저장', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✨ 포토카드 이미지가 클립보드/갤러리에 저장되었습니다!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.topkkuCard.photocardUrl;
    final track = widget.topkkuCard.musicTrack;

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
          // Header Bar with Toploader Title & Export Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('✨', style: TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        '포토카드 탑꾸 (Toploader)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.protoHeading,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _exportTopkkuImage,
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
                      Icon(Icons.ios_share_rounded, size: 14, color: Color(0xFF9333EA)),
                      SizedBox(width: 4),
                      Text(
                        'SNS 공유',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9333EA)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2D Acrylic Toploader Area (Captured with RepaintBoundary)
          Center(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Container(
                width: 250,
                height: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  // Acrylic glossy borders & reflections
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFF8FAFC),
                      Color(0xFFEFF6FF),
                    ],
                  ),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 2,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.antiAlias,
                  children: [
                    // Toploader Inner Acrylic Slot
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Photocard Image or Placeholder
                              if (photo != null && photo.isNotEmpty)
                                (photo.startsWith('http')
                                    ? Image.network(photo, fit: BoxFit.cover)
                                    : Image.file(File(photo), fit: BoxFit.cover))
                              else
                                GestureDetector(
                                  onTap: _pickPhotocard,
                                  child: Container(
                                    color: const Color(0xFFFAF5FF),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF3E8FF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add_a_photo_rounded,
                                            size: 32,
                                            color: Color(0xFF9333EA),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          '최애 포토카드 등록',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF7E22CE),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          '터치하여 사진을 넣어보세요',
                                          style: TextStyle(fontSize: 11, color: AppColors.protoSubtitle),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Custom Overlay Text
                              if (widget.topkkuCard.customOverlayText.isNotEmpty)
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      widget.topkkuCard.customOverlayText,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ),

                              // Acrylic Top Gloss Sheen Overlay (Simulating 2D Toploader)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 50,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.35),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Toploader Top Cutout Notch
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 50,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
                        ),
                      ),
                    ),

                    // Stickers & Photo Stickers Canvas Layer
                    ...widget.topkkuCard.decorations.map((sticker) {
                      final isSelected = _selectedStickerId == sticker.id;
                      final isEmoji = !sticker.stickerType.contains('/') && !sticker.stickerType.contains('\\');

                      return Positioned(
                        left: sticker.x,
                        top: sticker.y,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedStickerId = sticker.id);
                          },
                          onPanUpdate: (details) {
                            final idx = widget.topkkuCard.decorations.indexWhere((d) => d.id == sticker.id);
                            if (idx != -1) {
                              final updatedList = List<StickerConfig>.from(widget.topkkuCard.decorations);
                              updatedList[idx] = sticker.copyWith(
                                x: (sticker.x + details.delta.dx).clamp(0.0, 200.0),
                                y: (sticker.y + details.delta.dy).clamp(0.0, 290.0),
                              );
                              widget.onTopkkuChanged(widget.topkkuCard.copyWith(decorations: updatedList));
                            }
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Transform.rotate(
                                angle: sticker.rotation,
                                child: Transform.scale(
                                  scale: sticker.scale,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: isSelected
                                        ? BoxDecoration(
                                            border: Border.all(color: const Color(0xFF9333EA), width: 1.5),
                                            borderRadius: BorderRadius.circular(8),
                                          )
                                        : null,
                                    child: isEmoji
                                        ? Text(sticker.stickerType, style: const TextStyle(fontSize: 26))
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.file(
                                              File(sticker.stickerType),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: GestureDetector(
                                    onTap: () => _removeSticker(sticker.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Action Toolbar for Toploader (Photo Change, Stickers, Overlay Text)
          // 버튼 3개가 폰 폭보다 넓어서(430에서도) 자리가 모자라면 다음 줄로.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildToolButton(
                icon: Icons.image_rounded,
                label: '사진 교체',
                onTap: _pickPhotocard,
              ),
              _buildToolButton(
                icon: Icons.auto_awesome_rounded,
                label: '스티커 / 누끼',
                onTap: _showStickerSheet,
              ),
              _buildToolButton(
                icon: Icons.text_fields_rounded,
                label: '문구 설정',
                onTap: _showOverlayTextEditor,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mini Music Player Bar (최애곡)
          InkWell(
            onTap: _showMusicTrackEditor,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3E8FF)),
              ),
              child: Row(
                children: [
                  // Animated Turntable Vinyl Icon
                  RotationTransition(
                    turns: _musicAnimController,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E24),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFACC15),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track?.title.isNotEmpty == true ? track!.title : '최애곡을 등록해보세요 🎵',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.protoHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track?.artist.isNotEmpty == true ? track!.artist : widget.artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.protoSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlayingMusic ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      color: const Color(0xFF9333EA),
                      size: 28,
                    ),
                    onPressed: _toggleMusic,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF4B5563)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
