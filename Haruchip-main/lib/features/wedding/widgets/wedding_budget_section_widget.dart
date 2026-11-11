import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../providers/wedding_budget_provider.dart';
import 'wedding_budget_edit_modal.dart';

/// 금액 천단위 쉼표 포맷터
String _formatWon(int amount) {
  return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
}

/// 독립된 하단 [결혼 예산 & 지출 정리표] 섹션 위젯
class WeddingBudgetSectionWidget extends ConsumerWidget {
  const WeddingBudgetSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(weddingBudgetListProvider);
    final summary = ref.watch(weddingBudgetSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 섹션 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Text('💰', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '결혼 예산 & 지출 정리표',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.protoHeading,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => WeddingBudgetEditModal.show(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('예산 추가', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE53E3E),
                side: const BorderSide(color: Color(0xFFFECDD3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. 상단 총계 요약 카드 (총 예상 예산 vs 총 실제 결제액 + 분담 요약)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFED7D7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53E3E).withValues(alpha: 0.05),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '총 예상 예산',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatWon(summary.totalEstimated),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '총 실제 결제(계약+잔금)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Color(0xFFE53E3E), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _formatWon(summary.totalActual),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE53E3E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // 신랑 / 신부 / 공동 부담 요약 칩
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildShareChip(
                    label: '👦 신랑 부담',
                    amount: summary.groomShare,
                    color: const Color(0xFF2563EB),
                    bg: const Color(0xFFEFF6FF),
                  ),
                  _buildShareChip(
                    label: '👧 신부 부담',
                    amount: summary.brideShare,
                    color: const Color(0xFFDB2777),
                    bg: const Color(0xFFFDF2F8),
                  ),
                  _buildShareChip(
                    label: '🤝 공동 부담',
                    amount: summary.jointShare,
                    color: const Color(0xFF059669),
                    bg: const Color(0xFFECFDF5),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. 세부 지출 항목 리스트 (카드/테이블 형식)
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              '등록된 예산 항목이 없습니다. [+ 예산 추가]를 눌러보세요.',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          )
        else
          for (final item in items) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 지출 담당자 배지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.payer.bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: item.payer.color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      item.payer.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: item.payer.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 항목명 및 세부 금액 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 좁으면 계약금/잔금이 다음 줄로 내려간다.
                        Wrap(
                          children: [
                            Text(
                              '계약금 ${_formatWon(item.deposit)}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                            const Text(' · ', style: TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1))),
                            Text(
                              '잔금 ${_formatWon(item.balance)}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 총 금액
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 104),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _formatWon(item.totalActualCost),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (item.estimatedBudget > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '예상: ${_formatWon(item.estimatedBudget)}',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF94A3B8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => WeddingBudgetEditModal.show(context, item),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildShareChip({
    required String label,
    required int amount,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _formatWon(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
