import 'package:flutter/material.dart';
import '../models/y2k_diary_models.dart';
import 'y2k_decorations.dart';

/// Y2K 스티커북 서랍 바텀시트
Future<void> showY2KStickerDrawer(
  BuildContext context, {
  required void Function(StickerItemModel model, {String? customText, String? tapeColor}) onSelectSticker,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _Y2KStickerDrawerContent(onSelectSticker: onSelectSticker),
  );
}

class _Y2KStickerDrawerContent extends StatefulWidget {
  const _Y2KStickerDrawerContent({required this.onSelectSticker});

  final void Function(StickerItemModel model, {String? customText, String? tapeColor}) onSelectSticker;

  @override
  State<_Y2KStickerDrawerContent> createState() => _Y2KStickerDrawerContentState();
}

class _Y2KStickerDrawerContentState extends State<_Y2KStickerDrawerContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _tapeTextController = TextEditingController();
  String _selectedTapeColor = '#FFE4E6';

  static const List<({String colorHex, String name})> kTapeColors = [
    (colorHex: '#FFE4E6', name: '스트로베리 핑크'),
    (colorHex: '#FEF3C7', name: '바닐라 옐로우'),
    (colorHex: '#F3E8FF', name: '라벤더 퍼플'),
    (colorHex: '#D1FAE5', name: '민트 그린'),
    (colorHex: '#E0F2FE', name: '스카이 블루'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tapeTextController.dispose();
    super.dispose();
  }

  void _showProModal(StickerItemModel sticker) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFFFDF5),
        title: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              'PRO 전용 스티커',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.pink.shade700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFB6C1)),
                ),
                child: Text(sticker.icon, style: const TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '\'${sticker.name}\' 스티커는 하루칩 PRO 전용 팩 아이템입니다.',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'PRO 멤버십으로 무제한 Y2K 레트로 플래시 스티커와 프리미엄 다이어리 테마를 즐겨보세요! ✨',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('다음에', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4081),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✨ 하루칩 PRO 체험 프로모션이 활성화되었습니다!')),
              );
            },
            child: const Text('PRO 혜택 보기', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _createCustomTape() {
    final text = _tapeTextController.text.trim();
    if (text.isEmpty) return;

    widget.onSelectSticker(
      const StickerItemModel(
        id: 'custom_tape',
        pack: StickerPackCategory.memoTape,
        name: '손글씨 테이프',
        icon: '🏷️',
        isTape: true,
      ),
      customText: text,
      tapeColor: _selectedTapeColor,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFFFF94B8), width: 3),
          left: BorderSide(color: Color(0xFFFF94B8), width: 3),
          right: BorderSide(color: Color(0xFFFF94B8), width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 스파인 & 드래그 핸들
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB6C1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Text('🎀', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Y2K 슈게임 스티커북 서랍',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF882046),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // 탭바
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDF3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFCCD9)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: const Color(0xFFFF4081),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF882046),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: '⭐ 레트로 팬시'),
                Tab(text: '🎀 테이프 & 메모'),
                Tab(text: '💮 칭찬 도장'),
                Tab(text: '✍️ 손글씨 테이프'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 탭 콘텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStickerGrid(StickerPackCategory.retroFancy),
                _buildStickerGrid(StickerPackCategory.memoTape),
                _buildStickerGrid(StickerPackCategory.stampPraise),
                _buildCustomTapeSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerGrid(StickerPackCategory pack) {
    final stickers = kDefaultStickerPacks.where((s) => s.pack == pack).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: stickers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final item = stickers[index];
        return GestureDetector(
          onTap: () {
            if (item.isPro) {
              _showProModal(item);
            } else {
              widget.onSelectSticker(item);
              Navigator.of(context).pop();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: item.isPro ? const Color(0xFFFFC107) : const Color(0xFFFFD1DC),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF69B4).withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.icon, style: const TextStyle(fontSize: 30)),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF882046),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (item.isPro)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC107),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTapeSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✍️ 나만의 손글씨 마스킹 테이프 제작',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF882046)),
          ),
          const SizedBox(height: 4),
          const Text(
            '다이어리 캔버스에 붙일 문구와 파스텔 테이프 색상을 골라주세요.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // 테이프 텍스트 입력창
          TextField(
            controller: _tapeTextController,
            decoration: InputDecoration(
              hintText: '예: 오늘 하루도 파이팅 💖',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
              filled: true,
              fillColor: const Color(0xFFFFF0F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFFFB6C1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFFF4081), width: 2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // 테이프 색상 선택
          const Text(
            '테이프 컬러',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in kTapeColors)
                  GestureDetector(
                    onTap: () => setState(() => _selectedTapeColor = c.colorHex),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(int.parse('FF${c.colorHex.replaceAll('#', '')}', radix: 16)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedTapeColor == c.colorHex
                              ? const Color(0xFFFF4081)
                              : Colors.black12,
                          width: _selectedTapeColor == c.colorHex ? 2.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        c.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _selectedTapeColor == c.colorHex ? const Color(0xFFAD1457) : Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 미리보기 테이프
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: Color(int.parse('FF${_selectedTapeColor.replaceAll('#', '')}', radix: 16)),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Text(
              _tapeTextController.text.trim().isEmpty
                  ? '✨ 문구를 입력하면 테이프가 생성됩니다 ✨'
                  : _tapeTextController.text.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 부착 버튼
          Y2KJellyButton(
            label: '다이어리에 부착하기 🎀',
            onTap: _createCustomTape,
            height: 48,
          ),
        ],
      ),
    );
  }
}
