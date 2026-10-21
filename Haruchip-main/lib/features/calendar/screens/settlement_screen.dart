import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/typography.dart';
import '../logic/settlement_calculator.dart';
import '../models/schedule_room.dart';
import '../providers/schedule_room_provider.dart';

/// 다차수 & 예외 공제 스마트 정산 화면
class SettlementScreen extends ConsumerStatefulWidget {
  const SettlementScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends ConsumerState<SettlementScreen> {
  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  void _handleSend(
    BuildContext context,
    String provider,
    String toName,
    int amount,
  ) {
    final label = provider == 'kakao' ? '카카오페이' : '토스';
    Clipboard.setData(ClipboardData(text: '$toName $amount원'));
    ref
        .read(scheduleRoomsProvider.notifier)
        .recordSettlementConfirmation(widget.roomId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '💸 $label 송금 정보 복사 완료 — $toName에게 $amount원',
        ),
      ),
    );
  }

  void _showAddRoundDialog(ScheduleRoom room) {
    final titleController = TextEditingController(text: '${room.rounds.length + 1}차 ');
    final amountController = TextEditingController();
    String selectedPayerUid = room.members.isNotEmpty ? room.members.first.uid : '';
    final selectedAttendees = room.members.map((m) => m.uid).toSet();

    final exceptionNameController = TextEditingController();
    final exceptionAmountController = TextEditingController();
    final exemptMembers = <String>{};
    final tempExceptions = <SettlementException>[];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(modalCtx).size.height * 0.90,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 38,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🧾 정산 차수 추가',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(modalCtx).pop(),
                          icon: const Icon(Icons.close_rounded, size: 22, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('차수 이름', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              hintText: '예: 1차 삼겹살, 2차 맥주창고',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text('총 결제 금액 (원)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '예: 85000',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text('결제한 멤버', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedPayerUid,
                                items: room.members.map((m) {
                                  return DropdownMenuItem(
                                    value: m.uid,
                                    child: Text('${m.icon} ${m.name}'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedPayerUid = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text('참석 멤버 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: room.members.map((m) {
                              final isSelected = selectedAttendees.contains(m.uid);
                              return FilterChip(
                                label: Text('${m.icon} ${m.name}'),
                                selected: isSelected,
                                onSelected: (sel) {
                                  setModalState(() {
                                    if (sel) {
                                      selectedAttendees.add(m.uid);
                                    } else {
                                      if (selectedAttendees.length > 1) {
                                        selectedAttendees.remove(m.uid);
                                      }
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),

                          // Exceptions section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('특정 항목 예외 공제 (술값 등)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              TextButton.icon(
                                onPressed: () {
                                  if (exceptionNameController.text.trim().isNotEmpty &&
                                      int.tryParse(exceptionAmountController.text) != null) {
                                    setModalState(() {
                                      tempExceptions.add(SettlementException(
                                        id: 'exp-${DateTime.now().microsecondsSinceEpoch}',
                                        title: exceptionNameController.text.trim(),
                                        amount: int.parse(exceptionAmountController.text),
                                        exemptMemberUids: exemptMembers.toList(),
                                      ));
                                      exceptionNameController.clear();
                                      exceptionAmountController.clear();
                                      exemptMembers.clear();
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('예외 추가', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: exceptionNameController,
                                  decoration: InputDecoration(
                                    hintText: '항목명 (예: 술값)',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: exceptionAmountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '금액',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('비참여(미부담) 멤버 선택:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Wrap(
                            spacing: 6,
                            children: room.members.map((m) {
                              final isExempt = exemptMembers.contains(m.uid);
                              return FilterChip(
                                label: Text('${m.icon} ${m.name} 제외'),
                                selected: isExempt,
                                onSelected: (sel) {
                                  setModalState(() {
                                    if (sel) {
                                      exemptMembers.add(m.uid);
                                    } else {
                                      exemptMembers.remove(m.uid);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),

                          if (tempExceptions.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            for (int idx = 0; idx < tempExceptions.length; idx++)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${tempExceptions[idx].name}: ${tempExceptions[idx].amount}원 (${tempExceptions[idx].exemptMemberUids.length}명 제외)',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16, color: Color(0xFF991B1B)),
                                      onPressed: () => setModalState(() => tempExceptions.removeAt(idx)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final totalAmt = int.tryParse(amountController.text) ?? 0;
                          if (titleController.text.trim().isEmpty || totalAmt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('⚠️ 차수 이름과 유효한 금액을 입력해주세요.')),
                            );
                            return;
                          }

                          final newRound = SettlementRound(
                            id: 'round-${DateTime.now().microsecondsSinceEpoch}',
                            roundNumber: room.rounds.length + 1,
                            title: titleController.text.trim(),
                            payerUid: selectedPayerUid,
                            totalAmount: totalAmt,
                            attendeeUids: selectedAttendees.toList(),
                            exceptions: tempExceptions,
                          );

                          final updatedRounds = [...room.rounds, newRound];
                          ref.read(scheduleRoomsProvider.notifier).saveMultiRoundSettlement(room.id, updatedRounds);
                          Navigator.of(modalCtx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('차수 저장하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(scheduleRoomsProvider);
    final room = rooms.firstWhere(
      (r) => r.id == widget.roomId,
      orElse: () => ScheduleRoom(
        id: widget.roomId,
        name: '정산',
        inviteCode: '-',
        members: const [],
        dates: const {},
      ),
    );

    final multiResult = calculateMultiRoundSettlement(
      rounds: room.rounds,
      members: room.members,
    );

    String nameOf(String uid) {
      final match = room.members.where((m) => m.uid == uid);
      return match.isEmpty ? uid : match.first.name;
    }

    String iconOf(String uid) {
      final match = room.members.where((m) => m.uid == uid);
      return match.isEmpty ? '👤' : match.first.icon;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        title: Text(
          '${room.name} 스마트 정산',
          style: AppTypography.cardLabel.copyWith(
            color: const Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '차수 추가',
            icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
            onPressed: () => _showAddRoundDialog(room),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grand Total Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
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
                        const Text(
                          '총 모임 지출액',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '총 ${room.rounds.length}개 차수',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${multiResult.grandTotal}원',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFF334155)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '참여 인원: ${room.members.length}명',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                        ),
                        InkWell(
                          onTap: () => _showAddRoundDialog(room),
                          child: const Row(
                            children: [
                              Icon(Icons.add_rounded, size: 14, color: Colors.amberAccent),
                              SizedBox(width: 4),
                              Text(
                                '차수 추가하기',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Multi-Rounds Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '차수별 지출 내역 (${room.rounds.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (room.rounds.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text('등록된 정산 차수가 없습니다. [차수 추가하기]를 눌러 등록해보세요.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  ),
                )
              else
                for (int i = 0; i < room.rounds.length; i++) ...[
                  () {
                    final r = room.rounds[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  r.title,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${r.totalAmount}원',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '결제자: ${iconOf(r.payerUid)} ${nameOf(r.payerUid)} · 참석: ${r.attendeeUids.length}명',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          if (r.exceptions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            for (final exp in r.exceptions)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '예외 항목: ${exp.name} ${exp.amount}원 (${exp.exemptMemberUids.length}명 제외)',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ],
                      ),
                    );
                  }(),
                ],

              const SizedBox(height: 22),

              // Individual Member Balances
              const Text(
                '멤버별 최종 정산 현황',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    for (final d in multiResult.memberDetails)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _hexToColor(d.member.colorHex),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${d.member.icon} ${d.member.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 금액은 자르지 않는다 — 좁으면 줄바꿈해서 다 보이게
                            Flexible(
                              flex: 2,
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  d.netBalance >= 0
                                      ? '+${d.netBalance}원 (받을 돈)'
                                      : '${d.netBalance}원 (보낼 돈)',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: d.netBalance >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                ),
                                Text(
                                  '결제: ${d.totalPaid}원 | 부담: ${d.totalOwed}원',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Minimum Transactions & Remittance Cards
              const Text(
                '최소 송금 안내 (스마트 매칭)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),

              if (multiResult.transactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text('정산할 차액이 없습니다. 깔끔하게 완료되었습니다! 🎉', style: TextStyle(fontSize: 13, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                  ),
                )
              else
                for (final tx in multiResult.transactions)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 이름이 길면 말줄임 — 금액(오른쪽)은 항상 다 보이게
                            Flexible(
                              child: Text(
                                '${iconOf(tx.from)} ${nameOf(tx.from)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
                            ),
                            Flexible(
                              child: Text(
                                '${iconOf(tx.to)} ${nameOf(tx.to)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${tx.amount}원',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _handleSend(context, 'kakao', nameOf(tx.to), tx.amount),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEE500),
                                  foregroundColor: const Color(0xFF3C1E1E),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: const Text('카카오페이 송금', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _handleSend(context, 'toss', nameOf(tx.to), tx.amount),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0064FF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: const Text('토스 송금', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final totalAmt = room.rounds.fold<int>(0, (sum, r) => sum + r.totalAmount);
                    final perMemberAmounts = <String, int>{};
                    final transferStatus = <String, bool>{};

                    for (final d in multiResult.memberDetails) {
                      if (d.netBalance < 0) {
                        perMemberAmounts[d.member.uid] = -d.netBalance;
                        transferStatus[d.member.uid] = false;
                      } else {
                        transferStatus[d.member.uid] = true;
                      }
                    }

                    final newRecord = SettlementRecord(
                      id: 'settle-rec-${DateTime.now().microsecondsSinceEpoch}',
                      roomId: room.id,
                      title: '${DateTime.now().month}/${DateTime.now().day} ${room.name} ${room.rounds.length}차 정산',
                      date: DateTime.now(),
                      totalAmount: totalAmt,
                      rounds: room.rounds,
                      payerUid: room.members.isNotEmpty ? room.members.first.uid : null,
                      attendeeUids: room.members.map((m) => m.uid).toList(),
                      perMemberAmounts: perMemberAmounts,
                      transferStatus: transferStatus,
                      createdAt: DateTime.now(),
                    );

                    ref.read(scheduleRoomsProvider.notifier).addSettlementRecord(room.id, newRecord);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🧾 정산 영수증이 모임 장부에 성공적으로 저장되었습니다!')),
                    );
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('정산 완료 및 영수증 장부에 저장', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
