import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wedding_budget_item.dart';

/// 표준 한국 결혼 예산 기본 초기 템플릿 항목
List<WeddingBudgetItem> createDefaultWeddingBudgetItems() {
  return [
    const WeddingBudgetItem(
      id: 'budget-1',
      title: '웨딩홀 대관료 & 식대',
      estimatedBudget: 25000000,
      deposit: 3000000,
      balance: 22000000,
      payer: ExpensePayer.joint,
      isDepositPaid: true,
      memo: '식대 350명 보증 인원 기준',
    ),
    const WeddingBudgetItem(
      id: 'budget-2',
      title: '스드메 패키지 (스튜디오+드레스+메이크업)',
      estimatedBudget: 3800000,
      deposit: 800000,
      balance: 3000000,
      payer: ExpensePayer.joint,
      isDepositPaid: true,
      memo: '스튜디오 원본/수정본 별도',
    ),
    const WeddingBudgetItem(
      id: 'budget-3',
      title: '본식 스냅 & DVD 영상',
      estimatedBudget: 1900000,
      deposit: 400000,
      balance: 1500000,
      payer: ExpensePayer.joint,
      memo: '1인 2캠 4K 촬영',
    ),
    const WeddingBudgetItem(
      id: 'budget-4',
      title: '웨딩 밴드 (결혼반지)',
      estimatedBudget: 3200000,
      deposit: 1200000,
      balance: 2000000,
      payer: ExpensePayer.joint,
      memo: '백화점 브랜드 투어 및 각인 서비스',
    ),
    const WeddingBudgetItem(
      id: 'budget-5',
      title: '신랑 맞춤 예복 & 수제화',
      estimatedBudget: 1600000,
      deposit: 500000,
      balance: 1100000,
      payer: ExpensePayer.bride,
      memo: '이태리 원단 맞춤 정장',
    ),
    const WeddingBudgetItem(
      id: 'budget-6',
      title: '신혼여행 (항공편 + 숙소 + 경비)',
      estimatedBudget: 8000000,
      deposit: 3500000,
      balance: 4500000,
      payer: ExpensePayer.joint,
      isDepositPaid: true,
      memo: '발리 풀빌라 5박 7일',
    ),
    const WeddingBudgetItem(
      id: 'budget-7',
      title: '혼주 한복 대여 및 헤어/메이크업',
      estimatedBudget: 1400000,
      deposit: 300000,
      balance: 1100000,
      payer: ExpensePayer.joint,
      memo: '양가 어머님 한복 대여',
    ),
    const WeddingBudgetItem(
      id: 'budget-8',
      title: '종이 청첩장 & 모바일 청첩장',
      estimatedBudget: 350000,
      deposit: 350000,
      balance: 0,
      payer: ExpensePayer.joint,
      isDepositPaid: true,
      memo: '종이 300장 + 모바일 무제한',
    ),
    const WeddingBudgetItem(
      id: 'budget-9',
      title: '사회자/축가/헬퍼 이모님 사례비',
      estimatedBudget: 1100000,
      deposit: 0,
      balance: 1100000,
      payer: ExpensePayer.groom,
      memo: '당일 현금 봉투 준비',
    ),
  ];
}

class WeddingBudgetNotifier extends StateNotifier<List<WeddingBudgetItem>> {
  WeddingBudgetNotifier() : super(createDefaultWeddingBudgetItems());

  void addItem(WeddingBudgetItem item) {
    state = [...state, item];
  }

  void updateItem(WeddingBudgetItem updated) {
    state = state.map((i) => i.id == updated.id ? updated : i).toList();
  }

  void removeItem(String id) {
    state = state.where((i) => i.id != id).toList();
  }

  void resetDefaults() {
    state = createDefaultWeddingBudgetItems();
  }
}

final weddingBudgetListProvider =
    StateNotifierProvider<WeddingBudgetNotifier, List<WeddingBudgetItem>>((ref) {
  return WeddingBudgetNotifier();
});

/// 예산 총계 및 부담자별 요약 정보
final weddingBudgetSummaryProvider = Provider<({
  int totalEstimated,
  int totalActual,
  int groomShare,
  int brideShare,
  int jointShare,
})>((ref) {
  final items = ref.watch(weddingBudgetListProvider);

  int totalEstimated = 0;
  int totalActual = 0;
  int groomShare = 0;
  int brideShare = 0;
  int jointShare = 0;

  for (final item in items) {
    totalEstimated += item.estimatedBudget;
    final cost = item.totalActualCost;
    totalActual += cost;

    switch (item.payer) {
      case ExpensePayer.groom:
        groomShare += cost;
        break;
      case ExpensePayer.bride:
        brideShare += cost;
        break;
      case ExpensePayer.joint:
        jointShare += cost;
        break;
    }
  }

  return (
    totalEstimated: totalEstimated,
    totalActual: totalActual,
    groomShare: groomShare,
    brideShare: brideShare,
    jointShare: jointShare,
  );
});
