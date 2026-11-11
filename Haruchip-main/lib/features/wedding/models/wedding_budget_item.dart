import 'package:flutter/material.dart';

/// 지출 담당자 (신랑 / 신부 / 공동)
enum ExpensePayer {
  groom('신랑 부담', Color(0xFF2563EB), Color(0xFFEFF6FF)),
  bride('신부 부담', Color(0xFFDB2777), Color(0xFFFDF2F8)),
  joint('공동 부담', Color(0xFF059669), Color(0xFFECFDF5));

  const ExpensePayer(this.label, this.color, this.bgColor);
  final String label;
  final Color color;
  final Color bgColor;
}

/// 독립된 결혼 예산 & 지출 정리표 항목 모델
class WeddingBudgetItem {
  const WeddingBudgetItem({
    required this.id,
    required this.title,
    required this.estimatedBudget,
    this.deposit = 0,
    this.balance = 0,
    this.payer = ExpensePayer.joint,
    this.isDepositPaid = false,
    this.isBalancePaid = false,
    this.memo = '',
  });

  final String id;
  final String title;
  final int estimatedBudget; // 예상 예산
  final int deposit; // 계약금 (예약금)
  final int balance; // 잔금
  final ExpensePayer payer; // 지출 담당자 (신랑/신부/공동)
  final bool isDepositPaid; // 계약금 결제 완료 여부
  final bool isBalancePaid; // 잔금 결제 완료 여부
  final String memo;

  /// 총 실제 지출액 (계약금 + 잔금)
  int get totalActualCost => deposit + balance;

  WeddingBudgetItem copyWith({
    String? id,
    String? title,
    int? estimatedBudget,
    int? deposit,
    int? balance,
    ExpensePayer? payer,
    bool? isDepositPaid,
    bool? isBalancePaid,
    String? memo,
  }) {
    return WeddingBudgetItem(
      id: id ?? this.id,
      title: title ?? this.title,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      deposit: deposit ?? this.deposit,
      balance: balance ?? this.balance,
      payer: payer ?? this.payer,
      isDepositPaid: isDepositPaid ?? this.isDepositPaid,
      isBalancePaid: isBalancePaid ?? this.isBalancePaid,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'estimatedBudget': estimatedBudget,
      'deposit': deposit,
      'balance': balance,
      'payer': payer.name,
      'isDepositPaid': isDepositPaid,
      'isBalancePaid': isBalancePaid,
      'memo': memo,
    };
  }

  factory WeddingBudgetItem.fromJson(Map<String, dynamic> json) {
    return WeddingBudgetItem(
      id: json['id'] as String,
      title: json['title'] as String,
      estimatedBudget: json['estimatedBudget'] as int? ?? 0,
      deposit: json['deposit'] as int? ?? 0,
      balance: json['balance'] as int? ?? 0,
      payer: ExpensePayer.values.firstWhere(
        (p) => p.name == json['payer'],
        orElse: () => ExpensePayer.joint,
      ),
      isDepositPaid: json['isDepositPaid'] as bool? ?? false,
      isBalancePaid: json['isBalancePaid'] as bool? ?? false,
      memo: json['memo'] as String? ?? '',
    );
  }
}
