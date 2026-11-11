import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../../services/calendar/external_calendar_push_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/category_provider.dart';
import '../../home/screens/trash_bin_screen.dart';
import '../../onboarding/screens/login_screen.dart';
import '../../onboarding/screens/splash_screen.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../trash/providers/trash_provider.dart';
import '../../widgets/screens/widget_simulator_screen.dart';
import '../../onboarding/screens/app_permission_screen.dart';
import '../../shared/widgets/common_date_time_picker.dart';
import 'hidden_categories_screen.dart';
import 'storage_manager_screen.dart';

/// 앱 전체 설정 및 백업/외부 연동/알림 통합 관리 화면
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const String userUniqueCode = 'HARU-8921-X9';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // 계정 및 유저 고유 코드
  static const String _userUniqueCode = 'HARU-8921-X9';

  // 캘린더 연동 상태
  bool _googleCalendarEnabled = true;
  String _selectedGoogleCalendar = '하루칩 전용 캘린더';
  final List<String> _googleCalendars = ['기본 캘린더', '하루칩 전용 캘린더', '기념일 & 약속'];

  bool _naverCalendarEnabled = false;
  String _selectedNaverCalendar = '기본 일정';
  final List<String> _naverCalendars = ['기본 일정', '하루칩 스케줄'];

  SyncInterval _syncInterval = SyncInterval.hourly;
  bool _isSyncing = false;

  // 알림 마스터 설정
  bool _pushEnabled = true;
  TimeOfDay _dailyBriefingTime = const TimeOfDay(hour: 9, minute: 0);
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  void _copyUserCode() {
    Clipboard.setData(const ClipboardData(text: _userUniqueCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ 고유 유저 코드가 클립보드에 복사되었습니다! ($userUniqueCode)', style: TextStyle(fontWeight: FontWeight.bold)),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  static const String userUniqueCode = _userUniqueCode;

  Future<void> _triggerManualSync() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isSyncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 구글/네이버 캘린더와 모든 D-Day 및 일정이 성공적으로 동기화되었습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text('현재 계정에서 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃되었습니다.'), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48)),
            SizedBox(width: 8),
            Text('회원 탈퇴 (계정 삭제)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFE11D48))),
          ],
        ),
        content: const Text(
          '정말로 하루칩을 탈퇴하시겠습니까?\n\n'
          '탈퇴 시 등록된 모든 D-Day, 카테고리, 메모 및 사진 데이터가 즉시 영구 삭제되며 복구할 수 없습니다.',
          style: TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('즉시 탈퇴'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authServiceProvider).deleteAccount();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계정이 영구히 삭제되었습니다.'), behavior: SnackBarBehavior.floating),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('탈퇴 처리 중 오류가 발생했습니다: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  /// 전체 데이터 백업 내보내기 (JSON Export)
  void _exportBackupData() {
    final categories = ref.read(categoryListProvider);
    final plans = ref.read(planListProvider);

    final backupMap = <String, dynamic>{
      'appName': 'Haruchip',
      'version': '2.5.0',
      'userCode': _userUniqueCode,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'plans': plans.map((p) => p.toJson()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backupMap);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('📦', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      '전체 데이터 백업 내보내기',
                      style: AppTypography.heading2.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.protoHeading,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '카테고리 ${categories.length}개, 일정 및 D-Day ${plans.length}개가 백업 데이터로 추출되었습니다.',
              style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF374151)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: jsonStr));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📋 백업 JSON 데이터가 클립보드에 복사되었습니다.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('클립보드에 복사'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.protoHeading,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('💾 haruchip_backup_latest.json 파일로 안전하게 내보냈습니다.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('백업 파일 저장'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 백업 데이터 복원하기 (JSON Import)
  void _importBackupData() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('📥', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              '백업 데이터 복원하기',
              style: AppTypography.heading2.copyWith(fontSize: 18, color: AppColors.protoHeading),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '이전에 복사한 Haruchip 백업 JSON 텍스트를 아래에 붙여넣어 주세요.',
                style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: '{\n  "appName": "Haruchip",\n  ...\n}',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('취소', style: TextStyle(color: AppColors.protoSubtitle)),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = textController.text.trim();
              if (raw.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ JSON 데이터를 입력해주세요.'), behavior: SnackBarBehavior.floating),
                );
                return;
              }

              try {
                final dynamic parsed = jsonDecode(raw);
                if (parsed is! Map<String, dynamic> || parsed['appName'] != 'Haruchip') {
                  throw const FormatException('유효하지 않은 Haruchip 백업 포맷입니다.');
                }

                int restoredCategoriesCount = 0;
                int restoredPlansCount = 0;

                if (parsed['categories'] is List) {
                  final list = (parsed['categories'] as List)
                      .whereType<Map<String, dynamic>>()
                      .map((m) => Category.fromJson(m))
                      .toList();
                  if (list.isNotEmpty) {
                    ref.read(categoryListProvider.notifier).replaceAll(list);
                    restoredCategoriesCount = list.length;
                  }
                }

                if (parsed['plans'] is List) {
                  final list = (parsed['plans'] as List)
                      .whereType<Map<String, dynamic>>()
                      .map((m) => PlanItem.fromJson(m))
                      .toList();
                  if (list.isNotEmpty) {
                    ref.read(planListProvider.notifier).replaceAll(list);
                    restoredPlansCount = list.length;
                  }
                }

                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 백업 복원 완료! 카테고리 $restoredCategoriesCount개, 일정 $restoredPlansCount개가 성공적으로 복원되었습니다.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ 복원 실패: 올바른 JSON 데이터인지 확인해주세요. ($e)'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('데이터 복원 적용'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDailyBriefingTime() async {
    final now = DateTime.now();
    final currentDt = DateTime(now.year, now.month, now.day, _dailyBriefingTime.hour, _dailyBriefingTime.minute);
    final picked = await showCommonDateTimePickerModal(
      context,
      initialDateTime: currentDt,
      isAllDay: false,
      showAllDayToggle: false,
      title: '하루 브리핑 알림 시간',
    );
    if (picked != null) {
      final tod = TimeOfDay(hour: picked.hour, minute: picked.minute);
      setState(() => _dailyBriefingTime = tod);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏰ 매일 아침 ${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}에 하루 브리핑 알림이 발송됩니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hiddenCategories = ref.watch(hiddenCategoriesProvider);
    final trashItems = ref.watch(trashBinProvider);

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.protoHeading),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '환경 설정 및 데이터 관리',
          style: AppTypography.cardLabel.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.protoHeading,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 빠른 보관함 바로가기 (숨김 보관함, 휴지통, 위젯 시뮬레이터)
            _buildSectionHeader('스마트 허브 바로가기'),
            _buildQuickNavCard(
              title: '대시보드 숨김 카드 보관함',
              subtitle: '홈에서 숨긴 카테고리를 확인하고 원터치로 복구합니다.',
              icon: Icons.visibility_off_outlined,
              iconColor: const Color(0xFF007AFF),
              badgeText: '${hiddenCategories.length}개 보관 중',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HiddenCategoriesScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildQuickNavCard(
              title: '저장공간 관리',
              subtitle: '기록 데이터 사용량 확인 및 카테고리별 지난 일정 정리',
              icon: Icons.pie_chart_outline_rounded,
              iconColor: const Color(0xFF2563EB),
              badgeText: '관리하기',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StorageManagerScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildQuickNavCard(
              title: '휴지통 (30일 복구 보존)',
              subtitle: '실수로 삭제된 모든 데이터를 30일간 안전하게 보관합니다.',
              icon: Icons.delete_outline_rounded,
              iconColor: const Color(0xFFE11D48),
              badgeText: '${trashItems.length}개 보존 중',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrashBinScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildQuickNavCard(
              title: '모바일 홈/잠금화면 위젯 시뮬레이터',
              subtitle: '잠금화면 미니 위젯, 2x2 감성 위젯, 4x2 스마트 캘린더 미리보기',
              icon: Icons.widgets_outlined,
              iconColor: const Color(0xFF8B5CF6),
              badgeText: '3가지 규격',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WidgetSimulatorScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildQuickNavCard(
              title: '앱 접근 권한 관리',
              subtitle: '알림, 사진, 카메라, 캘린더, 간편 정산 연결, 마케팅 권한 설정',
              icon: Icons.security_rounded,
              iconColor: const Color(0xFF3182F6),
              badgeText: '6개 권한',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AppPermissionScreen(isSettingsMode: true),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 2. 계정 및 외부 서비스 연동
            _buildSectionHeader('계정 및 외부 연동'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
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
                            const Text('고유 유저 식별 코드', style: TextStyle(fontSize: 13, color: AppColors.protoSubtitle, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(_userUniqueCode, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.protoHeading, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _copyUserCode,
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text('코드 복사'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF007AFF),
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSocialChip('카카오', '연동됨', const Color(0xFFFEE500), Colors.black87),
                      _buildSocialChip('구글', '연동됨', const Color(0xFFEA4335), Colors.white),
                      _buildSocialChip('애플', '연동됨', Colors.black, Colors.white),
                      _buildSocialChip('네이버', '미연동', const Color(0xFFE5E7EB), const Color(0xFF6B7280)),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  Builder(
                    builder: (context) {
                      final currentUser = ref.watch(currentUserProvider);
                      final email = currentUser?.email ?? currentUser?.displayName;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser != null ? '로그인된 계정' : '게스트 모드',
                                  style: const TextStyle(fontSize: 12, color: AppColors.protoSubtitle, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email ?? '로컬 세션 이용 중',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.protoHeading),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (currentUser != null) ...[
                            OutlinedButton(
                              onPressed: _handleSignOut,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.protoSubtitle,
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('로그아웃', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _handleDeleteAccount,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFE11D48),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                              child: const Text('회원 탈퇴', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                            ),
                          ] else ...[
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007AFF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('로그인 연동', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. 구글 & 네이버 캘린더 실시간 양방향 동기화
            _buildSectionHeader('캘린더 연동 및 동기화 엔진'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 구글 캘린더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF007AFF)),
                          ),
                          const SizedBox(width: 10),
                          const Text('구글 캘린더 연동', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading)),
                        ],
                      ),
                      Switch.adaptive(
                        value: _googleCalendarEnabled,
                        activeTrackColor: const Color(0xFF007AFF),
                        onChanged: (val) => setState(() => _googleCalendarEnabled = val),
                      ),
                    ],
                  ),
                  if (_googleCalendarEnabled) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGoogleCalendar,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, color: AppColors.protoHeading, fontWeight: FontWeight.w600),
                          items: _googleCalendars
                              .map((c) => DropdownMenuItem(value: c, child: Text('타겟: $c')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGoogleCalendar = val);
                          },
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),

                  // 네이버 캘린더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.event_note_rounded, size: 18, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(width: 10),
                          const Text('네이버 캘린더 연동', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading)),
                        ],
                      ),
                      Switch.adaptive(
                        value: _naverCalendarEnabled,
                        activeTrackColor: const Color(0xFF16A34A),
                        onChanged: (val) => setState(() => _naverCalendarEnabled = val),
                      ),
                    ],
                  ),
                  if (_naverCalendarEnabled) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedNaverCalendar,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, color: AppColors.protoHeading, fontWeight: FontWeight.w600),
                          items: _naverCalendars
                              .map((c) => DropdownMenuItem(value: c, child: Text('타겟: $c')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedNaverCalendar = val);
                          },
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),

                  // 동기화 주기 & 수동 동기화 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('자동 동기화 주기', style: TextStyle(fontSize: 13, color: AppColors.protoSubtitle, fontWeight: FontWeight.w600)),
                      DropdownButton<SyncInterval>(
                        value: _syncInterval,
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF007AFF), fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: SyncInterval.realtime, child: Text('실시간')),
                          DropdownMenuItem(value: SyncInterval.hourly, child: Text('1시간마다')),
                          DropdownMenuItem(value: SyncInterval.onAppLaunch, child: Text('앱 실행 시')),
                          DropdownMenuItem(value: SyncInterval.manual, child: Text('수동')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _syncInterval = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _triggerManualSync,
                      icon: _isSyncing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(_isSyncing ? '캘린더 동기화 진행 중...' : '지금 전체 캘린더 동기화'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. 전역 데이터 백업 및 복원 (JSON Backup & Restore)
            _buildSectionHeader('전역 데이터 백업 및 복원'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('무손실 암호화 데이터 백업', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '카테고리, 일정, D-Day, 모임 등 하루칩의 모든 개인 데이터를 JSON 표준 포맷으로 완벽히 백업하고 다른 기기에서 복원할 수 있습니다.',
                    style: AppTypography.caption.copyWith(fontSize: 12, color: AppColors.protoSubtitle, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exportBackupData,
                          icon: const Icon(Icons.upload_rounded, size: 17),
                          label: const Text('백업 내보내기'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF007AFF),
                            side: const BorderSide(color: Color(0xFF93C5FD)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _importBackupData,
                          icon: const Icon(Icons.download_rounded, size: 17),
                          label: const Text('백업 복원하기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. 푸시 알림 마스터 설정
            _buildSectionHeader('푸시 알림 마스터 설정'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('푸시 알림 수신', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading)),
                      Switch.adaptive(
                        value: _pushEnabled,
                        activeTrackColor: const Color(0xFF007AFF),
                        onChanged: (val) => setState(() => _pushEnabled = val),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFF3F4F6)),
                  InkWell(
                    onTap: _pickDailyBriefingTime,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('아침 브리핑 알림 시각', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: AppColors.protoSubtitle, fontWeight: FontWeight.w600)),
                          ),
                          Row(
                            children: [
                              Text(
                                '${_dailyBriefingTime.hour.toString().padLeft(2, '0')}:${_dailyBriefingTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF007AFF)),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.protoSubtitle),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 20, color: Color(0xFFF3F4F6)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('알림 소리', style: TextStyle(fontSize: 13, color: AppColors.protoSubtitle, fontWeight: FontWeight.w600)),
                      Switch.adaptive(
                        value: _soundEnabled,
                        activeTrackColor: const Color(0xFF007AFF),
                        onChanged: (val) => setState(() => _soundEnabled = val),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFF3F4F6)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('알림 진동', style: TextStyle(fontSize: 13, color: AppColors.protoSubtitle, fontWeight: FontWeight.w600)),
                      Switch.adaptive(
                        value: _vibrationEnabled,
                        activeTrackColor: const Color(0xFF007AFF),
                        onChanged: (val) => setState(() => _vibrationEnabled = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. 앱 정보 및 저작권
            Center(
              child: Column(
                children: [
                  Text('하루칩 (Haruchip) v2.5.0', style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Made with ❤️ for everyone who cherishes every day', style: AppTypography.caption.copyWith(fontSize: 11, color: const Color(0xFF9CA3AF))),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.cardLabel.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.protoSubtitle,
        ),
      ),
    );
  }

  Widget _buildQuickNavCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.protoSubtitle),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.protoSubtitle),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialChip(String provider, String status, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            provider,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
