import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import 'skin_theme_card_container.dart';

Future<CategoryModel?> showCategoryEditModal(
  BuildContext context, {
  required CategoryModel category,
}) {
  return showModalBottomSheet<CategoryModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CategoryEditModal(category: category),
  );
}

class CategoryEditModal extends StatefulWidget {
  const CategoryEditModal({super.key, required this.category});

  final CategoryModel category;

  @override
  State<CategoryEditModal> createState() => _CategoryEditModalState();
}

class _CategoryEditModalState extends State<CategoryEditModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late String _selectedIcon;
  CategorySkinTheme? _skinTheme;

  // Typography
  late String _selectedFontFamily;
  late Color _selectedTextColor;
  late double _fontSize;
  late double _opacity;
  late TextPositionPreset _textPosition;

  // Background
  late BackgroundType _selectedBgType;
  late Color _selectedSingleColor;
  late List<Color> _gradientColors;
  String? _imageUrl;
  File? _localImageFile;

  // Stickers & Text Decos
  late List<StickerConfig> _decorations;
  String? _selectedStickerId;

  // Presets & Constants
  static const List<String> _fontOptions = [
    'Pretendard',
    'NanumGothic',
    'MaruBuri',
    'CookieRun',
    'GmarketSans',
  ];

  static const List<String> _iconPresets = [
    '❤️', '💍', '🎂', '🎓', '👶', '🐶', '🐱', '✈️',
    '🎖️', '🎸', '☕', '💼', '🏖️', '🌸', '🎮', '🏋️',
    '📚', '🏡', '🚗', '🎁', '💎', '🍀', '🍕', '🍦',
    '🥂', '🌿', '🌟', '🎈', '🧸', '⚽', '🍿', '🎨',
    '🎵', '🚀', '💡', '🥑', '🍔', '🍓', '🎀', '📌',
  ];

  static const List<Color> _textColors = [
    Color(0xFF111827), // Gray 900
    Color(0xFFFFFFFF), // White
    Color(0xFFFF7A59), // Haruchip Primary
    Color(0xFFDB2777), // Pink
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF6B7280), // Gray 500
  ];

  static const List<Color> _solidColorPresets = [
    Color(0xFFFF8DA1), // 연핑크 (Pastel Pink)
    Color(0xFFC084FC), // 연보라 (Pastel Purple)
    Color(0xFFFBBF24), // 파스텔 옐로우 (Pastel Yellow)
    Color(0xFFFDE047), // 소프트 옐로우 (Soft Warm Yellow)
    Color(0xFFFB923C), // 파스텔 피치/오렌지 (Pastel Peach)
    Color(0xFF34D399), // 파스텔 에메랄드 그린 (Pastel Emerald)
    Color(0xFF6EE7B7), // 파스텔 민트/세이지 (Pastel Mint)
    Color(0xFF818CF8), // 파스텔 인디고/블루 (Pastel Indigo)
    Color(0xFF38BDF8), // 파스텔 스카이 블루 (Pastel Sky)
    Color(0xFFFDA4AF), // 로맨틱 로즈 (Romantic Rose)
    Color(0xFFA3E635), // 파스텔 카키 (Pastel Khaki)
    Color(0xFFF472B6), // 파스텔 핑크 (Pastel Pink)
    Color(0xFF94A3B8), // 파스텔 슬레이트 (Pastel Slate)
    Color(0xFFFFF0F5), // Lavender Blush
    Color(0xFFFFFDF4), // Cream Yellow
    Color(0xFFF0F9FF), // Sky Light
    Color(0xFFF0FDF4), // Mint Light
    Color(0xFFFAF5FF), // Purple Light
    Color(0xFFF5F5F7), // Apple Gray
    Color(0xFF2B2D42), // Dark Navy
  ];

  static const List<({String name, List<Color> colors})> _gradientPresets = [
    (name: '코랄 핑크', colors: [Color(0xFFFF9A8B), Color(0xFFFF6A88), Color(0xFFFF99AC)]),
    (name: '선셋 오렌지', colors: [Color(0xFFFFA751), Color(0xFFFFE259)]),
    (name: '오션 블루', colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)]),
    (name: '라벤더 퍼플', colors: [Color(0xFFB993D6), Color(0xFF8CA6DB)]),
    (name: '민트 그린', colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
    (name: '소프트 피치', colors: [Color(0xFFFFECD2), Color(0xFFFCB69F)]),
    (name: '로즈 골드', colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)]),
    (name: '딥 나이트', colors: [Color(0xFF2C3E50), Color(0xFF3498DB)]),
    (name: '파스텔 드림', colors: [Color(0xFFA1C4FD), Color(0xFFC2E9FB)]),
    (name: '체리 블라썸', colors: [Color(0xFFFBC2EB), Color(0xFFA6C1EE)]),
    (name: '선샤인', colors: [Color(0xFFFEE140), Color(0xFFFA709A)]),
    (name: '오로라', colors: [Color(0xFF84FAB0), Color(0xFF8FD3F4)]),
  ];

  static const List<({String symbol, String category, bool isPro})> _stickerLibrary = [
    // Hearts & Love
    (symbol: '❤️', category: '하트', isPro: false),
    (symbol: '💕', category: '하트', isPro: false),
    (symbol: '💖', category: '하트', isPro: false),
    (symbol: '💘', category: '하트', isPro: false),
    (symbol: '💝', category: '하트', isPro: true),
    (symbol: '💌', category: '하트', isPro: false),
    (symbol: '💍', category: '하트', isPro: true),
    // Stars & Sparkles
    (symbol: '⭐', category: '반짝', isPro: false),
    (symbol: '✨', category: '반짝', isPro: false),
    (symbol: '🌟', category: '반짝', isPro: false),
    (symbol: '💫', category: '반짝', isPro: true),
    (symbol: '👑', category: '반짝', isPro: true),
    // Deco & Stationery
    (symbol: '🎀', category: '다꾸', isPro: false),
    (symbol: '📌', category: '다꾸', isPro: false),
    (symbol: '📝', category: '다꾸', isPro: false),
    (symbol: '🏷️', category: '다꾸', isPro: false),
    (symbol: '🩹', category: '다꾸', isPro: true),
    (symbol: '🧸', category: '다꾸', isPro: false),
    // Flowers & Nature
    (symbol: '🌸', category: '자연', isPro: false),
    (symbol: '🌷', category: '자연', isPro: false),
    (symbol: '🍀', category: '자연', isPro: false),
    (symbol: '🌿', category: '자연', isPro: false),
    (symbol: '🌻', category: '자연', isPro: true),
    // Foods & Cafe
    (symbol: '🍰', category: '음식', isPro: false),
    (symbol: '☕', category: '음식', isPro: false),
    (symbol: '🍓', category: '음식', isPro: false),
    (symbol: '🥂', category: '음식', isPro: true),
    (symbol: '🍦', category: '음식', isPro: false),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    _nameController = TextEditingController(text: widget.category.name);
    _selectedIcon = widget.category.icon;

    _selectedFontFamily = widget.category.typography.fontFamily;
    _selectedTextColor = colorFromHex(widget.category.typography.textColor);
    _fontSize = widget.category.typography.fontSize;
    _opacity = widget.category.typography.opacity;
    _textPosition = widget.category.typography.position;

    _selectedBgType = widget.category.background.type;
    _selectedSingleColor = widget.category.background.colorValues.isNotEmpty
        ? colorFromHex(widget.category.background.colorValues.first)
        : const Color(0xFFFFF0F5);

    if (widget.category.background.colorValues.length >= 2) {
      _gradientColors = widget.category.background.colorValues
          .map((h) => colorFromHex(h))
          .toList();
    } else {
      _gradientColors = _gradientPresets.first.colors;
    }

    _imageUrl = widget.category.background.imageUrl;
    _decorations = List.from(widget.category.background.decorations ?? []);

    _skinTheme = widget.category.skinTheme ??
        (widget.category.categoryKey == 'couple'
            ? Y2kSkinPresets.cyberPink2000
            : Y2kSkinPresets.windowsPixelClassic);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Sticker operations
  void _addSticker(String symbol, {bool isPro = false, bool isText = false, String? textContent}) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _decorations.add(
        StickerConfig(
          id: newId,
          stickerType: isText ? (textContent ?? '메모') : symbol,
          x: 0.5,
          y: 0.5,
          scale: 1.0,
          rotation: 0.0,
          isText: isText,
          textColor: colorToHex(_selectedTextColor),
          fontFamily: _selectedFontFamily,
          fontSize: isText ? 16 : null,
          isPro: isPro,
        ),
      );
      _selectedStickerId = newId;
    });
  }

  void _removeSticker(String id) {
    setState(() {
      _decorations.removeWhere((d) => d.id == id);
      if (_selectedStickerId == id) _selectedStickerId = null;
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _localImageFile = File(picked.path);
          _imageUrl = picked.path;
          _selectedBgType = BackgroundType.image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진을 가져오는 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  Future<void> _showAddTextDecoDialog() async {
    final textCtrl = TextEditingController();
    Color textColor = _selectedTextColor;
    String font = _selectedFontFamily;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('자유 텍스트 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '카드에 넣을 문구를 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('폰트', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: font,
                        items: _fontOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => font = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _textColors.map((c) {
                      return InkWell(
                        onTap: () => setDialogState(() => textColor = c),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: textColor == c ? const Color(0xFF007AFF) : Colors.transparent, width: 2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final text = textCtrl.text.trim();
                    if (text.isNotEmpty) {
                      _addSticker('', isText: true, textContent: text);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleSave() {
    final name = _nameController.text.trim();

    List<String> hexColors;
    if (_selectedBgType == BackgroundType.gradient) {
      hexColors = _gradientColors.map((c) => colorToHex(c)).toList();
    } else if (_skinTheme != null) {
      hexColors = [_skinTheme!.backgroundColor];
    } else {
      hexColors = [colorToHex(_selectedSingleColor)];
    }

    final currentMeta = Map<String, dynamic>.from(widget.category.metadata ?? {});
    if (_skinTheme != null) {
      currentMeta['skinTheme'] = _skinTheme!.toJson();
    }

    final updatedCategory = widget.category.copyWith(
      name: name.isEmpty ? widget.category.name : name,
      icon: _skinTheme?.accentEmoji.isNotEmpty == true ? _skinTheme!.accentEmoji : _selectedIcon,
      metadata: currentMeta,
      typography: TypographyConfig(
        fontFamily: _selectedFontFamily,
        textColor: _skinTheme != null ? _skinTheme!.textColor : colorToHex(_selectedTextColor),
        fontSize: _fontSize,
        opacity: _opacity,
        position: _textPosition,
      ),
      background: BackgroundConfig(
        type: _selectedBgType,
        colorValues: hexColors,
        imageUrl: _imageUrl,
        decorations: _decorations,
      ),
    );

    Navigator.of(context).pop(updatedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          // Top Navigation Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소', style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 16)),
                ),
                const Text(
                  '카테고리 꾸미기',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                ),
                ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('적용', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 1. Live Preview Card (Top Zone)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildLivePreviewCard(),
          ),

          const SizedBox(height: 14),

          // 2. Toolbar Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFF1C1C1E),
              unselectedLabelColor: const Color(0xFF8E8E93),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: '스킨(리모콘)'),
                Tab(text: '기본 정보'),
                Tab(text: '텍스트'),
                Tab(text: '배경'),
                Tab(text: '스티커'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Tab Panel Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSkinThemeTab(),
                _buildBasicInfoTab(),
                _buildTextCustomTab(),
                _buildBackgroundTab(),
                _buildStickersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard() {
    final isImage = _selectedBgType == BackgroundType.image && _imageUrl != null;
    final isGradient = _selectedBgType == BackgroundType.gradient;

    DecorationImage? bgDecoImage;
    if (isImage) {
      if (_localImageFile != null && _localImageFile!.existsSync()) {
        bgDecoImage = DecorationImage(
          image: FileImage(_localImageFile!),
          fit: BoxFit.cover,
        );
      } else {
        bgDecoImage = DecorationImage(
          image: NetworkImage(_imageUrl!),
          fit: BoxFit.cover,
        );
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        const cardHeight = 200.0;

        final activeTextColor = _skinTheme != null
            ? colorFromHex(_skinTheme!.textColor)
            : _selectedTextColor;

        final cardContent = Stack(
          children: [
            // Main text block positioned according to _textPosition
            Align(
              alignment: _textPosition.alignment,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Opacity(
                  opacity: _opacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: switch (_textPosition) {
                      TextPositionPreset.topLeft || TextPositionPreset.bottomLeft => CrossAxisAlignment.start,
                      TextPositionPreset.topRight || TextPositionPreset.bottomRight => CrossAxisAlignment.end,
                      _ => CrossAxisAlignment.center,
                    },
                    children: [
                      Text(
                        '${_selectedIcon.isNotEmpty ? _selectedIcon : '📌'} ${_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : '카테고리'}',
                        style: TextStyle(
                          fontFamily: _selectedFontFamily,
                          fontSize: _fontSize,
                          fontWeight: FontWeight.w800,
                          color: activeTextColor,
                          shadows: isImage || isGradient
                              ? [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '700일째 · 2024.12.24 ~ ing',
                        style: TextStyle(
                          fontFamily: _selectedFontFamily,
                          fontSize: (_fontSize * 0.75).clamp(10.0, 20.0),
                          fontWeight: FontWeight.w600,
                          color: activeTextColor.withValues(alpha: 0.85),
                          shadows: isImage || isGradient
                              ? [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 3)]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Movable / Resizable Stickers
            for (int i = 0; i < _decorations.length; i++)
              _buildDraggableSticker(
                _decorations[i],
                cardWidth,
                cardHeight,
                i,
              ),
          ],
        );

        if (_skinTheme != null) {
          return SkinThemeCardContainer(
            theme: _skinTheme!,
            width: cardWidth,
            height: cardHeight,
            child: cardContent,
          );
        }

        return Container(
          width: cardWidth,
          height: cardHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _selectedBgType == BackgroundType.singleColor ? _selectedSingleColor : null,
            gradient: isGradient ? LinearGradient(colors: _gradientColors) : null,
            image: bgDecoImage,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: cardContent,
        );
      },
    );
  }

  Widget _buildDraggableSticker(StickerConfig sticker, double cardWidth, double cardHeight, int index) {
    final isSelected = _selectedStickerId == sticker.id;
    final left = (sticker.x * cardWidth).clamp(0.0, cardWidth - 50.0);
    final top = (sticker.y * cardHeight).clamp(0.0, cardHeight - 50.0);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStickerId = isSelected ? null : sticker.id;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            final newX = (left + details.delta.dx) / cardWidth;
            final newY = (top + details.delta.dy) / cardHeight;
            _decorations[index] = sticker.copyWith(
              x: newX.clamp(0.0, 1.0),
              y: newY.clamp(0.0, 1.0),
            );
          });
        },
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(color: const Color(0xFF007AFF), width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          padding: const EdgeInsets.all(4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.rotate(
                angle: sticker.rotation,
                child: Transform.scale(
                  scale: sticker.scale,
                  child: sticker.isText
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: Text(
                            sticker.stickerType,
                            style: TextStyle(
                              fontSize: sticker.fontSize ?? 15,
                              fontFamily: sticker.fontFamily ?? 'Pretendard',
                              color: sticker.textColor != null ? colorFromHex(sticker.textColor!) : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Text(
                          sticker.stickerType,
                          style: const TextStyle(fontSize: 32),
                        ),
                ),
              ),
              if (isSelected)
                Positioned(
                  right: -8,
                  top: -8,
                  child: GestureDetector(
                    onTap: () => _removeSticker(sticker.id),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 1: 기본 정보 (Basic Info)
  Widget _buildBasicInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildPanelSection(
          title: '카테고리 이름',
          child: TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '카테고리 이름을 입력하세요 (예: 커플, 우리 여행)',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPanelSection(
          title: '대표 아이콘 / 이모지 선택',
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconPresets.map((icon) {
                final isSelected = _selectedIcon == icon;
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = icon),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE5F0FF) : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // TAB 2: 텍스트 커스텀 (Text Custom)
  Widget _buildTextCustomTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. Text Position Presets (5 Directions)
        _buildPanelSection(
          title: '텍스트 위치 정렬',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: TextPositionPreset.values.map((pos) {
              final isSelected = _textPosition == pos;
              final iconData = switch (pos) {
                TextPositionPreset.center => Icons.filter_center_focus_rounded,
                TextPositionPreset.topLeft => Icons.north_west_rounded,
                TextPositionPreset.bottomLeft => Icons.south_west_rounded,
                TextPositionPreset.topRight => Icons.north_east_rounded,
                TextPositionPreset.bottomRight => Icons.south_east_rounded,
              };

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => setState(() => _textPosition = pos),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF007AFF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(iconData, size: 20, color: isSelected ? Colors.white : const Color(0xFF1C1C1E)),
                          const SizedBox(height: 4),
                          Text(
                            pos.labelKo,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Text Color Palette
        _buildPanelSection(
          title: '텍스트 색상',
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _textColors.map((c) {
                final isSelected = _selectedTextColor == c;
                return InkWell(
                  onTap: () => setState(() => _selectedTextColor = c),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFD1D1D6),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Opacity Slider
        _buildPanelSection(
          title: '텍스트 투명도: ${(_opacity * 100).round()}%',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Slider.adaptive(
              value: _opacity,
              min: 0.1,
              max: 1.0,
              divisions: 18,
              activeColor: const Color(0xFF007AFF),
              onChanged: (v) => setState(() => _opacity = v),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Font Family & Size
        _buildPanelSection(
          title: '글꼴(폰트) 및 크기',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('폰트 스타일', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    DropdownButton<String>(
                      value: _fontOptions.contains(_selectedFontFamily) ? _selectedFontFamily : _fontOptions.first,
                      underline: const SizedBox(),
                      items: _fontOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedFontFamily = v);
                      },
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Text('크기: ${_fontSize.toInt()}pt', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Expanded(
                      child: Slider.adaptive(
                        value: _fontSize,
                        min: 14.0,
                        max: 32.0,
                        divisions: 18,
                        activeColor: const Color(0xFF007AFF),
                        onChanged: (v) => setState(() => _fontSize = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // TAB 3: 배경 디자인 (Background Design)
  Widget _buildBackgroundTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Sub-segment (단색 / 그라데이션 / 사진)
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E5EA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildSubSegmentItem('단색', BackgroundType.singleColor),
              _buildSubSegmentItem('그라데이션', BackgroundType.gradient),
              _buildSubSegmentItem('사진', BackgroundType.image),
            ],
          ),
        ),
        const SizedBox(height: 18),

        if (_selectedBgType == BackgroundType.singleColor) ...[
          _buildPanelSection(
            title: '단색 배경 팔레트',
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _solidColorPresets.map((c) {
                      final isSelected = _selectedSingleColor == c;
                      return InkWell(
                        onTap: () => setState(() => _selectedSingleColor = c),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFD1D1D6),
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '이 카테고리 색상은 캘린더 일정 표시에도 동일하게 적용됩니다',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else if (_selectedBgType == BackgroundType.gradient) ...[
          _buildPanelSection(
            title: '감성 그라데이션 프리셋',
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemCount: _gradientPresets.length,
              itemBuilder: (context, index) {
                final preset = _gradientPresets[index];
                final isSelected = _gradientColors == preset.colors;
                return InkWell(
                  onTap: () => setState(() => _gradientColors = preset.colors),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: preset.colors),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      preset.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ] else ...[
          // Photo/Image Background
          _buildPanelSection(
            title: '사진 배경 업로드 및 조절',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: Text(_imageUrl != null ? '사진 변경' : '갤러리에서 사진 추가'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (_imageUrl != null) ...[
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _imageUrl = null;
                              _localImageFile = null;
                              _selectedBgType = BackgroundType.singleColor;
                            });
                          },
                          child: const Text('사진 제거', style: TextStyle(color: Color(0xFFEF4444))),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '💡 선택한 사진은 상단 카드 비율에 맞춰 자동으로 최적화되어 100% 핏으로 렌더링됩니다.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubSegmentItem(String title, BackgroundType type) {
    final isSelected = _selectedBgType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedBgType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF1C1C1E) : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }

  // TAB 4: 스티커 및 텍스트 데코 (Stickers & Text Deco)
  Widget _buildStickersTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Top Action: Add Custom Text Sticker
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '스티커 & 글씨 데코',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
            ),
            ElevatedButton.icon(
              onPressed: _showAddTextDecoDialog,
              icon: const Icon(Icons.text_fields_rounded, size: 16),
              label: const Text('+ 텍스트 추가'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '💡 스티커를 탭하면 카드 중앙에 추가되며, 드래그하여 원하는 위치로 자유롭게 이동할 수 있습니다.',
          style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
        ),
        const SizedBox(height: 14),

        // Sticker Library Grid
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: _stickerLibrary.length,
            itemBuilder: (context, index) {
              final item = _stickerLibrary[index];
              return InkWell(
                onTap: () => _addSticker(item.symbol, isPro: item.isPro),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(item.symbol, style: const TextStyle(fontSize: 24)),
                      if (item.isPro)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9500),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Active Stickers Manager List
        if (_decorations.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('배치된 스티커 목록 (탭하여 삭제)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _decorations.map((d) {
              return Chip(
                backgroundColor: Colors.white,
                label: Text(d.isText ? '글씨: ${d.stickerType}' : d.stickerType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFFEF4444)),
                onDeleted: () => _removeSticker(d.id),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE5E5EA)),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSkinThemeTab() {
    final theme = _skinTheme ?? Y2kSkinPresets.cyberPink2000;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Title Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFEDD5)),
          ),
          child: Row(
            children: [
              const Text('🕹️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Y2K 블로그 리모콘 스킨 시스템',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '원터치 큐레이션 프리셋 및 나만의 패턴/테두리를 커스텀하세요.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFFC2410C)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. Curated Default Presets
        _buildPanelSection(
          title: '💖 Y2K 큐레이션 프리셋 (원터치 적용)',
          child: SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Y2kSkinPresets.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final preset = Y2kSkinPresets.all[index];
                final isSelected = theme.id == preset.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _skinTheme = preset;
                      _selectedIcon = preset.accentEmoji;
                      _selectedSingleColor = colorFromHex(preset.backgroundColor);
                      _selectedTextColor = colorFromHex(preset.textColor);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 120,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorFromHex(preset.backgroundColor),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF007AFF) : colorFromHex(preset.borderColor),
                        width: isSelected ? 2.5 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isSelected ? 0.12 : 0.04),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(preset.accentEmoji, style: const TextStyle(fontSize: 20)),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF007AFF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 12, color: Colors.white),
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorFromHex(preset.textColor),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${preset.patternTypeEnum.labelKo} · ${preset.borderStyleEnum.labelKo}',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: colorFromHex(preset.textColor).withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 3. Background Color
        _buildPanelSection(
          title: '🎨 카드 배경색',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              '#FFE8F0', // 사이버 핑크
              '#C5CBD9', // 윈도우 그레이/블루
              '#FFF9E6', // 밀크 옐로우
              '#E0F7F6', // 민트 소다
              '#F8FAFC', // 클린 화이트
              '#FFF0F5', // 라벤더 블러시
              '#FAF5FF', // 파스텔 퍼플
              '#E0F2FE', // 스카이 라이트
              '#FEF2F2', // 로즈 라이트
              '#FFF7ED', // 피치 오렌지
              '#1E1E24', // Y2K 챠콜
            ].map((hex) {
              final isSelected = theme.backgroundColor.toUpperCase() == hex.toUpperCase();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _skinTheme = theme.copyWith(backgroundColor: hex);
                    _selectedSingleColor = colorFromHex(hex);
                  });
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorFromHex(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFD1D1D6),
                      width: isSelected ? 3.0 : 1.0,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 18, color: Color(0xFF007AFF))
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),

        // 4. Pattern Type
        _buildPanelSection(
          title: '✨ 배경 패턴 유형',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SkinPatternType.values.map((p) {
              final isSelected = theme.patternTypeEnum == p;
              return ChoiceChip(
                label: Text(p.labelKo),
                selected: isSelected,
                selectedColor: const Color(0xFFEFF6FF),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF374151),
                ),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E7EB),
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _skinTheme = theme.copyWith(patternType: p.toJson());
                    });
                  }
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),

        // 5. Pattern Color (Independent from background)
        _buildPanelSection(
          title: '🎯 패턴 자체 색상 (배경과 분리 커스텀)',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              '#FFFFFF', // 화이트
              '#FF85A2', // 핑크
              '#80CBC4', // 민트
              '#E6D5AC', // 크림 베이지
              '#94A3B8', // 슬레이트
              '#8B5CF6', // 퍼플
              '#F59E0B', // 앰버
              '#000080', // 네이비
              '#004D40', // 딥 민트
              '#5D4037', // 브라운
            ].map((hex) {
              final isSelected = theme.patternColor.toUpperCase() == hex.toUpperCase();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _skinTheme = theme.copyWith(patternColor: hex);
                  });
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorFromHex(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFD1D1D6),
                      width: isSelected ? 3.0 : 1.0,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: hex == '#FFFFFF' ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // 6. Pattern Opacity Slider
        _buildPanelSection(
          title: '🌫️ 패턴 투명도 (${(theme.patternOpacity * 100).round()}%)',
          child: Slider(
            value: theme.patternOpacity,
            min: 0.05,
            max: 0.50,
            divisions: 9,
            activeColor: const Color(0xFF007AFF),
            onChanged: (val) {
              setState(() {
                _skinTheme = theme.copyWith(patternOpacity: val);
              });
            },
          ),
        ),
        const SizedBox(height: 18),

        // 7. Border Style (Naver Blog Box Style)
        _buildPanelSection(
          title: '📦 테두리 스타일 (네이버 블로그 구성 박스)',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SkinBorderStyle.values.map((b) {
              final isSelected = theme.borderStyleEnum == b;
              return ChoiceChip(
                label: Text(b.labelKo),
                selected: isSelected,
                selectedColor: const Color(0xFFEFF6FF),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF374151),
                ),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E7EB),
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _skinTheme = theme.copyWith(
                        borderStyle: b.toJson(),
                        borderRadius: b == SkinBorderStyle.window98Bevel ? 0.0 : theme.borderRadius,
                      );
                    });
                  }
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),

        // 8. Border Color
        _buildPanelSection(
          title: '🖌️ 테두리 선 색상',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              '#FF85A2', // 핑크
              '#808080', // 윈도우 그레이
              '#8C6D52', // 브라운
              '#00897B', // 딥 민트
              '#000080', // 네이비
              '#E2E8F0', // 연그레이
              '#EC407A', // 핫핑크
              '#7C3AED', // 바이올렛
              '#2563EB', // 블루
              '#059669', // 에메랄드
            ].map((hex) {
              final isSelected = theme.borderColor.toUpperCase() == hex.toUpperCase();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _skinTheme = theme.copyWith(borderColor: hex);
                  });
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorFromHex(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFD1D1D6),
                      width: isSelected ? 3.0 : 1.0,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // 9. Border Width & Border Radius Sliders
        Row(
          children: [
            Expanded(
              child: _buildPanelSection(
                title: '선 굵기 (${theme.borderWidth.toStringAsFixed(1)}px)',
                child: Slider(
                  value: theme.borderWidth,
                  min: 0.5,
                  max: 5.0,
                  divisions: 9,
                  activeColor: const Color(0xFF007AFF),
                  onChanged: (val) {
                    setState(() {
                      _skinTheme = theme.copyWith(borderWidth: val);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPanelSection(
                title: '모서리 (${theme.borderRadius.round()}px)',
                child: Slider(
                  value: theme.borderRadius,
                  min: 0.0,
                  max: 24.0,
                  divisions: 12,
                  activeColor: const Color(0xFF007AFF),
                  onChanged: (val) {
                    setState(() {
                      _skinTheme = theme.copyWith(borderRadius: val);
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '💡 0px: 레트로 직각 (윈도우98) · 16~24px: 소프트 둥근 모서리',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 18),

        // 10. Accent Emoji
        _buildPanelSection(
          title: '🌟 대표 이모지 / 아이콘',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              '💖', '💻', '📖', '🫧', '✨', '🎀', '🧸', '🌸', '🍓', '💍', '🍀', '🎮', '☕', '🎂', '💌'
            ].map((emoji) {
              final isSelected = theme.accentEmoji == emoji;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _skinTheme = theme.copyWith(accentEmoji: emoji);
                    _selectedIcon = emoji;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E7EB),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPanelSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
