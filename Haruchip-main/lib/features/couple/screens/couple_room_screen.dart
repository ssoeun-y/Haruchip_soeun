import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../shared/widgets/haru_calendar_picker.dart';
import '../models/y2k_diary_models.dart';
import '../providers/couple_provider.dart';
import '../providers/y2k_diary_provider.dart';
import '../widgets/y2k_decorations.dart';
import '../widgets/y2k_free_canvas.dart';
import '../widgets/y2k_stamp_board.dart';
import '../widgets/y2k_sticker_drawer.dart';

/// 하단 네비게이션 [우리의 방] — Y2K 고전 플래시(슈의 다이어리북 감성) 모바일 세로형 다꾸 & 계획 공간
class CoupleRoomScreen extends ConsumerStatefulWidget {
  const CoupleRoomScreen({super.key});

  @override
  ConsumerState<CoupleRoomScreen> createState() => _CoupleRoomScreenState();
}

class _CoupleRoomScreenState extends ConsumerState<CoupleRoomScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _todoInputController = TextEditingController();
  late TextEditingController _diaryController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _diaryController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _todoInputController.dispose();
    _diaryController.dispose();
    super.dispose();
  }

  void _onPreviousDay() {
    final current = ref.read(selectedDiaryDateProvider);
    ref.read(selectedDiaryDateProvider.notifier).state = current.subtract(const Duration(days: 1));
  }

  void _onNextDay() {
    final current = ref.read(selectedDiaryDateProvider);
    ref.read(selectedDiaryDateProvider.notifier).state = current.add(const Duration(days: 1));
  }

  Future<void> _pickDate() async {
    final current = ref.read(selectedDiaryDateProvider);
    final picked = await showHaruDatePicker(
      context,
      initialDate: current,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(selectedDiaryDateProvider.notifier).state = picked;
    }
  }

  void _addTodo() {
    final text = _todoInputController.text.trim();
    if (text.isEmpty) return;

    final date = ref.read(selectedDiaryDateProvider);
    ref.read(y2kDiaryProvider.notifier).addTodo(date, text);
    _todoInputController.clear();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDiaryDateProvider);
    final dayData = ref.watch(currentDayDataProvider);
    final totalDaysTogether = ref.watch(totalDaysTogetherProvider);

    // Sync diary text controller if date changed
    if (_diaryController.text != dayData.diaryText) {
      _diaryController.text = dayData.diaryText;
    }

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                children: [
                  // 상단 링 바인더 스파인
                  const Y2KBinderSpine(),
                  const SizedBox(height: 6),

                  // Y2K 메인 프레임 컨테이너
                  Y2KDiaryContainer(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. 상단 타이틀 & 연애 일수 배지 & BGM 토글
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                              children: [
                                const Text('🍓', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '하루칩 다이어리',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF882046),
                                      ),
                                    ),
                                    Text(
                                      'D+$totalDaysTogether일째 함께하는 중 💕',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFD81B60),
                                      ),
                                    ),
                                  ],
                                ),
                                ),
                              ],
                            ),
                            ),
                            // BGM / SFX 음소거 토글
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFFFB6C1), width: 1),
                                ),
                                child: Text(
                                  dayData.soundEnabled ? '🎵' : '🔇',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              onPressed: () {
                                ref.read(y2kDiaryProvider.notifier).toggleSound(selectedDate);
                                HapticFeedback.selectionClick();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 2. 상단 네비게이터 (공통 한글 캘린더 연동 날짜 선택부)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFB6C1), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4081).withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFFFF4081), size: 24),
                                onPressed: _onPreviousDay,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              Flexible(
                                child: GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F5),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFFFF4081)),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                        '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF882046),
                                        ),
                                      ),
                                      ),
                                      if (selectedDate.year == DateTime.now().year &&
                                          selectedDate.month == DateTime.now().month &&
                                          selectedDate.day == DateTime.now().day) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF6B81),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            '오늘',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down_rounded, size: 18, color: Color(0xFFFF4081)),
                                    ],
                                  ),
                                ),
                              ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFFFF4081), size: 24),
                                onPressed: _onNextDay,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 3. 당일 목표 달성률 젤리 프로그레스 바
                        Y2KJellyProgressBar(
                          progress: dayData.progress,
                          completedCount: dayData.completedTodoCount,
                          totalCount: dayData.todos.length,
                        ),
                        const SizedBox(height: 16),

                        // 4. 모바일 세그먼트 탭 전환 (탭 1: 투두 & 도장판 / 탭 2: 일기 & 다꾸북)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4EC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFCCD9), width: 1.2),
                          ),
                          child: TabBar(
                            controller: _tabController,
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
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            tabs: const [
                              Tab(text: '🍓 투두 & 도장판'),
                              Tab(text: '🎨 일기 & 다꾸북'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 5. 탭별 뷰
                        SizedBox(
                          height: 520,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // [탭 1: 🍓 투두 & 도장판]
                              _buildTodoAndStampTab(selectedDate, dayData),

                              // [탭 2: 🎨 일기 & 다꾸북]
                              _buildDiaryAndDecorateTab(selectedDate, dayData),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 탭 1: 투두 & 칭찬 도장판
  Widget _buildTodoAndStampTab(DateTime date, Y2KDayData dayData) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 오늘의 할 일 인풋 & 체크리스트
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFB6C1), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4081).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('📝', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '오늘의 할 일 체크리스트',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Color(0xFF882046),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 할 일 등록 인풋 필드
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _todoInputController,
                        onSubmitted: (_) => _addTodo(),
                        decoration: InputDecoration(
                          hintText: '새로운 할 일을 적어보세요 🍓',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                          filled: true,
                          fillColor: const Color(0xFFFFF5F8),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFFC0CB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFF4081), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Y2KJellyButton(
                      label: '+ 추가',
                      onTap: _addTodo,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 투두 목록
                if (dayData.todos.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Text('✨', style: TextStyle(fontSize: 24)),
                        SizedBox(height: 4),
                        Text(
                          '등록된 할 일이 없어요.\n오늘의 미션을 추가해보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  for (final todo in dayData.todos) ...[
                    _buildTodoItemRow(date, todo, dayData.soundEnabled),
                    const SizedBox(height: 6),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. 6칸 칭찬 도장판
          Y2KStampBoard(
            stampCount: dayData.stampCount,
            maxStamps: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildTodoItemRow(DateTime date, RoomTodo todo, bool soundEnabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: todo.isCompleted ? const Color(0xFFFFF0F5) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: todo.isCompleted ? const Color(0xFFFF4081) : const Color(0xFFEFEFEF),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // 체크박스
          GestureDetector(
            onTap: () {
              ref.read(y2kDiaryProvider.notifier).toggleTodo(date, todo.id);
              if (!todo.isCompleted) {
                HapticFeedback.mediumImpact();
              }
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: todo.isCompleted ? const Color(0xFFFF4081) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: todo.isCompleted ? const Color(0xFFFF4081) : const Color(0xFFFFB6C1),
                  width: 2,
                ),
              ),
              child: todo.isCompleted
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),

          // 타이틀
          Expanded(
            child: Text(
              todo.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: todo.isCompleted ? const Color(0xFFAD1457) : AppColors.protoHeading,
                decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: const Color(0xFFFF4081),
              ),
            ),
          ),

          // 삭제 버튼
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.black26),
            onPressed: () {
              ref.read(y2kDiaryProvider.notifier).deleteTodo(date, todo.id);
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  /// 탭 2: 일기 & 프리 다꾸 캔버스
  Widget _buildDiaryAndDecorateTab(DateTime date, Y2KDayData dayData) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 오늘의 한 줄 일기 (빈티지 줄노트)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('📖', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    '오늘의 한 줄 일기',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF882046)),
                  ),
                ],
              ),
              Text(
                '${dayData.diaryText.length}자',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          VintageLinedPaper(
            lineHeight: 32.0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(44, 10, 16, 10),
              child: TextField(
                controller: _diaryController,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                  height: 2.3,
                ),
                decoration: const InputDecoration(
                  hintText: '오늘 하루 어떤 일들이 있었나요? 소중한 감상을 적어보세요... 💖',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.black38),
                  border: InputBorder.none,
                ),
                onChanged: (text) {
                  ref.read(y2kDiaryProvider.notifier).updateDiaryText(date, text);
                },
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2. 프리 다꾸 캔버스 & 스티커 서랍 액션
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🎨', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  const Text(
                    '프리 다꾸 캔버스',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF882046)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '스티커 ${dayData.stickers.length}개',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD81B60)),
                    ),
                  ),
                ],
              ),
              if (dayData.stickers.isNotEmpty)
                TextButton(
                  onPressed: () {
                    ref.read(y2kDiaryProvider.notifier).clearCanvas(date);
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  child: const Text('초기화', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 캔버스 위젯
          Y2KFreeCanvas(
            height: 260,
            stickers: dayData.stickers,
            onUpdateSticker: (sticker) {
              ref.read(y2kDiaryProvider.notifier).updateSticker(date, sticker);
            },
            onDeleteSticker: (id) {
              ref.read(y2kDiaryProvider.notifier).deleteSticker(date, id);
            },
          ),
          const SizedBox(height: 14),

          // 스티커북 서랍 열기 버튼
          Y2KJellyButton(
            label: '+ 스티커북 열기 🎀',
            onTap: () {
              showY2KStickerDrawer(
                context,
                onSelectSticker: (model, {customText, tapeColor}) {
                  ref.read(y2kDiaryProvider.notifier).addSticker(
                        date,
                        model,
                        customText: customText,
                        tapeColor: tapeColor,
                      );
                  HapticFeedback.lightImpact();
                },
              );
            },
            height: 48,
          ),
        ],
      ),
    );
  }
}
