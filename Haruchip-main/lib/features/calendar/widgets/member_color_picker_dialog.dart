import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../models/schedule_room.dart';

/// 50색 파스텔 팔레트 컬러 피커 다이얼로그 (방 멤버 1인 1색상 전용)
///
/// 이미 방의 다른 멤버가 선점한 색상은 `[🔒]` 자물쇠 배지와 함께 비활성화됩니다.
Future<String?> showMemberColorPickerDialog(
  BuildContext context, {
  required String currentColorHex,
  required List<String> takenColorHexList,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _MemberColorPickerDialog(
      currentColorHex: currentColorHex,
      takenColorHexList: takenColorHexList,
    ),
  );
}

class _MemberColorPickerDialog extends StatefulWidget {
  const _MemberColorPickerDialog({
    required this.currentColorHex,
    required this.takenColorHexList,
  });

  final String currentColorHex;
  final List<String> takenColorHexList;

  @override
  State<_MemberColorPickerDialog> createState() => _MemberColorPickerDialogState();
}

class _MemberColorPickerDialogState extends State<_MemberColorPickerDialog> {
  late String _selectedHex;

  @override
  void initState() {
    super.initState();
    _selectedHex = widget.currentColorHex;
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎨 나만의 칩 컬러 선택',
                      style: AppTypography.cardLabel.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.protoHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '모임 공유 캘린더에서 내 일정 표시 색상으로 사용돼요',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.protoSubtitle,
                      ),
                    ),
                  ],
                ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 키보드 등으로 세로 자리가 줄면 색상 목록이 먼저 줄어든다
            Flexible(
              child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final hex in kPreset50PastelColors)
                      _buildColorChip(hex),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _hexToColor(_selectedHex),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '선택된 색상: $_selectedHex',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selectedHex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorChip(String hex) {
    final color = _hexToColor(hex);
    final isTaken = widget.takenColorHexList.contains(hex) && hex != widget.currentColorHex;
    final isSelected = hex == _selectedHex;

    return GestureDetector(
      onTap: isTaken
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔒 다른 멤버가 이미 사용 중인 색상입니다.'),
                  duration: Duration(milliseconds: 1200),
                ),
              );
            }
          : () {
              setState(() => _selectedHex = hex);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isTaken ? color.withValues(alpha: 0.35) : color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : (isTaken ? Colors.black12 : Colors.black12),
            width: isSelected ? 2.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: isTaken
            ? const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF64748B))
            : (isSelected
                ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF0F172A))
                : null),
      ),
    );
  }
}
