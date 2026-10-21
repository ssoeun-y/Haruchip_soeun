import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';

/// "캘린더에 등록하시겠습니까?" 팝업 — haruchip_app.html 708~724줄
/// `openCalendarPopup()`/`confirmCalendarSync()` 재현 (§5/§6).
///
/// 구글/네이버/하루칩 단독 3개 버튼 중 하나를 고르면 안내 스낵바만 띄운다
/// — 실제 구글/네이버 캘린더 API 연동은 CLAUDE.md 다섯 칸 ⑤(제휴/실연동
/// 붙이기 전 사람 확인)에 해당해 이번 범위에서 만들지 않는다.
///
/// 대시보드의 커플/시험 카드 "캘린더 연동" 버튼과 캘린더 탭에서 함께
/// 재사용하도록 함수형 API로 제공한다. CLAUDE.md 공통 UI 모달 닫기 규칙
/// (X 버튼 / 하단 닫기 버튼 / 배경 클릭)을 모두 지원한다 — 원본 html은
/// X/닫기 버튼이 없지만 공통 규칙을 우선한다.
Future<void> showCalendarSyncDialog(BuildContext context, String eventName) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _CalendarSyncDialog(eventName: eventName),
  );
}

class _CalendarSyncDialog extends StatelessWidget {
  const _CalendarSyncDialog({required this.eventName});

  final String eventName;

  void _confirm(BuildContext context, String label) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('✨ $label에 일정이 성공적으로 등록되었습니다!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.protoCardBg,
          borderRadius: BorderRadius.circular(24),
        ),
        // 키보드가 올라오거나 세로가 짧은 폰에서는 스크롤
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.protoSubtitle,
                  ),
                ),
              ],
            ),
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.protoCardSelectedBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('📅', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 12),
            Text(
              '캘린더에 등록하시겠습니까?',
              textAlign: TextAlign.center,
              style: AppTypography.heading2.copyWith(
                color: AppColors.protoHeading,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$eventName 일정을 어떤 캘린더에 추가할까요?',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.protoSubtitle,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _confirm(context, '구글 캘린더'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.protoCardSelectedText,
                  backgroundColor: AppColors.protoCardSelectedBg,
                  side: BorderSide(
                    color: AppColors.protoCardSelectedBorder
                        .withValues(alpha: 0.6),
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('구글 캘린더 동시 업로드'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _confirm(context, '네이버 캘린더'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.protoCardText,
                  backgroundColor: AppColors.surfaceMuted,
                  side: const BorderSide(
                    color: AppColors.protoCardBorder,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('네이버 캘린더 동시 업로드'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _confirm(context, '하루칩 단독'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.protoSubtitle,
                  backgroundColor: AppColors.surfaceMuted,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('하루칩 캘린더만 사용'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
