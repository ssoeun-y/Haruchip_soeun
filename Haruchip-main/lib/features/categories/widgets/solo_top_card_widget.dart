import 'package:flutter/material.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/solo_profile.dart';
import 'unified_category_top_card.dart';

/// 솔로 카테고리 심플형 상단 비주얼 카드 및 빠른 태그 위젯
class SoloTopCardWidget extends StatelessWidget {
  const SoloTopCardWidget({
    super.key,
    required this.profile,
    required this.onProfileChanged,
    required this.onSelectTag,
    required this.onAddNewTag,
  });

  final SoloProfile profile;
  final ValueChanged<SoloProfile> onProfileChanged;
  final ValueChanged<String> onSelectTag;
  final ValueChanged<String> onAddNewTag;

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showHaruDatePicker(
      context,
      initialDate: profile.activeStartDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      if (profile.mode == SoloMode.selfCare) {
        onProfileChanged(profile.copyWith(selfCareStartDate: picked));
      } else {
        onProfileChanged(profile.copyWith(crushStartDate: picked));
      }
    }
  }

  void _showAddTagDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '새 태그 추가',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '예: 혼밥 맛집투어, 자격증 공부',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                onAddNewTag(text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelfCare = profile.mode == SoloMode.selfCare;
    final days = profile.daysCount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 상단 상태 세그먼트 (모드 간편 전환 탭)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (profile.mode != SoloMode.selfCare) {
                      onProfileChanged(profile.copyWith(mode: SoloMode.selfCare));
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelfCare ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelfCare
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🌱', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                          '나를 위한 시간',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelfCare ? FontWeight.bold : FontWeight.w500,
                            color: isSelfCare ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (profile.mode != SoloMode.crush) {
                      onProfileChanged(profile.copyWith(mode: SoloMode.crush));
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: !isSelfCare ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !isSelfCare
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💌', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          '마음 진행 중',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: !isSelfCare ? FontWeight.bold : FontWeight.w500,
                            color: !isSelfCare ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. 상단 미니멀 파스텔 비주얼 카드 (통일 폼 팩터)
        if (profile.showTopCard) ...[
          UnifiedCategoryTopCard(
            categoryKey: 'solo',
            title: profile.mode.labelKo,
            symbol: profile.mode.emoji,
            coreDDayText: '${profile.mode.cardTitlePrefix} $days일째',
            startDateText: '시작일: ${_formatDate(profile.activeStartDate)}',
            reunionOrExtraBadge: isSelfCare ? '나에게 집중하는 시간' : '설레는 마음 진행 중',
            onEditAvatar: () => _pickStartDate(context),
            onManageSection: () => _pickStartDate(context),
            onHideCard: () => onProfileChanged(profile.copyWith(showTopCard: false)),
            manageSectionText: '시작일 변경',
            fallbackEmoji: isSelfCare ? '🌱' : '💌',
          ),
          const SizedBox(height: 16),
        ] else ...[
          // 카드 숨겼을 때 미니 언하이드 버튼
          InkWell(
            onTap: () {
              onProfileChanged(profile.copyWith(showTopCard: true));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    '${profile.mode.cardTitlePrefix} $days일째 (상단 카드 보기)',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 3. 나를 가꾸는 자기계발 & 갓생 프리셋 빠른 태그 칩
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Text('✨', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '나만의 갓생 & 플랜 빠른 태그',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddTagDialog(context),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('태그 추가', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 태그 칩 리스트
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...profile.tags.map((tag) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(tag),
                    onPressed: () => onSelectTag(tag),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                    avatar: Text(_getTagEmoji(tag), style: const TextStyle(fontSize: 13)),
                  ),
                );
              }),
              ActionChip(
                label: const Text('+ 직접 추가'),
                onPressed: () => _showAddTagDialog(context),
                backgroundColor: const Color(0xFFF1F5F9),
                side: const BorderSide(color: Color(0xFFCBD5E1), style: BorderStyle.solid),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _getTagEmoji(String tag) {
    if (tag.contains('여행')) return '✈️';
    if (tag.contains('바디프로필') || tag.contains('운동')) return '💪';
    if (tag.contains('취미')) return '🎨';
    if (tag.contains('새출발')) return '🌅';
    if (tag.contains('데이트') || tag.contains('소개팅')) return '☕';
    if (tag.contains('공부') || tag.contains('자격증')) return '📚';
    return '📌';
  }
}
