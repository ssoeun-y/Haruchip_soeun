import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../models/wedding_budget_item.dart';
import '../providers/wedding_budget_provider.dart';

/// 결혼 예산 항목 추가/수정 바텀시트 모달
class WeddingBudgetEditModal extends ConsumerStatefulWidget {
  const WeddingBudgetEditModal({super.key, this.item});

  final WeddingBudgetItem? item;

  static Future<void> show(BuildContext context, [WeddingBudgetItem? item]) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WeddingBudgetEditModal(item: item),
    );
  }

  @override
  ConsumerState<WeddingBudgetEditModal> createState() => _WeddingBudgetEditModalState();
}

class _WeddingBudgetEditModalState extends ConsumerState<WeddingBudgetEditModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _estimatedController;
  late final TextEditingController _depositController;
  late final TextEditingController _balanceController;
  late final TextEditingController _memoController;

  late ExpensePayer _selectedPayer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _estimatedController = TextEditingController(
      text: widget.item != null && widget.item!.estimatedBudget > 0
          ? widget.item!.estimatedBudget.toString()
          : '',
    );
    _depositController = TextEditingController(
      text: widget.item != null && widget.item!.deposit > 0 ? widget.item!.deposit.toString() : '',
    );
    _balanceController = TextEditingController(
      text: widget.item != null && widget.item!.balance > 0 ? widget.item!.balance.toString() : '',
    );
    _memoController = TextEditingController(text: widget.item?.memo ?? '');
    _selectedPayer = widget.item?.payer ?? ExpensePayer.joint;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _estimatedController.dispose();
    _depositController.dispose();
    _balanceController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('항목명을 입력해주세요.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final estimated = int.tryParse(_estimatedController.text.trim()) ?? 0;
    final deposit = int.tryParse(_depositController.text.trim()) ?? 0;
    final balance = int.tryParse(_balanceController.text.trim()) ?? 0;

    if (widget.item != null) {
      final updated = widget.item!.copyWith(
        title: title,
        estimatedBudget: estimated,
        deposit: deposit,
        balance: balance,
        payer: _selectedPayer,
        memo: _memoController.text.trim(),
      );
      ref.read(weddingBudgetListProvider.notifier).updateItem(updated);
    } else {
      final newItem = WeddingBudgetItem(
        id: 'budget-custom-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        estimatedBudget: estimated,
        deposit: deposit,
        balance: balance,
        payer: _selectedPayer,
        memo: _memoController.text.trim(),
      );
      ref.read(weddingBudgetListProvider.notifier).addItem(newItem);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💰 예산 항목이 저장되었습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _delete() {
    if (widget.item == null) return;
    ref.read(weddingBudgetListProvider.notifier).removeItem(widget.item!.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('예산 항목이 삭제되었습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 바
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 상단 헤더
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item != null ? '예산 항목 수정' : '새 결혼 예산 항목 추가',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.protoHeading,
                    ),
                  ),
                ),
                if (widget.item != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48)),
                    tooltip: '항목 삭제',
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 항목명
            const Text(
              '항목명',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '예: 웨딩홀 대관료 & 식대, 스냅 촬영비',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // 지출 담당자 선택 칩
            const Text(
              '지출 담당자',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final p in ExpensePayer.values) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Center(
                          child: Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: _selectedPayer == p ? p.color : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        selected: _selectedPayer == p,
                        selectedColor: p.bgColor,
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedPayer == p ? p.color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        showCheckmark: false,
                        onSelected: (val) {
                          if (val) setState(() => _selectedPayer = p);
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // 예상 예산
            const Text(
              '총 예상 예산 (원)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _estimatedController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '예: 25000000',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixText: '₩ ',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // 계약금 (예약금) & 잔금 분할 입력
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '계약금 (예약금)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _depositController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '3000000',
                          prefixText: '₩ ',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '잔금',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _balanceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '22000000',
                          prefixText: '₩ ',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 메모
            const Text(
              '결제 메모 / 특이사항',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _memoController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: '현금영수증 발행 여부, 분할 납부 일정 등',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53E3E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  widget.item != null ? '예산 수정 저장하기' : '새 예산 항목 추가하기',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
