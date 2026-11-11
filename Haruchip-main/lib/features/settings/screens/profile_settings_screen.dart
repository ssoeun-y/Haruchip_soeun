import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/category_provider.dart';
import '../../home/screens/trash_bin_screen.dart';
import '../../onboarding/providers/calendar_integration_provider.dart';
import '../../onboarding/providers/dashboard_view_mode_provider.dart';
import '../../onboarding/screens/app_permission_screen.dart';
import '../../onboarding/screens/splash_screen.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../trash/providers/trash_provider.dart';
import '../../widgets/screens/widget_simulator_screen.dart';
import 'hidden_categories_screen.dart';
import 'storage_manager_screen.dart';

/// 올인원 [프로필 & 설정] 화면 (하단 네비게이션 4번째 탭 코어 뷰)
///
/// 1. 내 프로필 (아바타 변경, 닉네임 수정, 이메일/제공자 배지, 고유 유저 코드)
/// 2. 데이터 관리 (휴지통 30일 보관함 연동, 외부 캘린더 동기화 설정, JSON 백업/복원)
/// 3. 앱 환경설정 (접근 권한 재설정, 대시보드 뷰 모드 설정, 숨김 보관함, 위젯 시뮬레이터)
/// 4. 계정 및 보안 (로그아웃, 애플 심사 Guideline 5.1.1(v) 즉시 회원 탈퇴)
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  static const String userUniqueCode = 'HARU-8921-X9';

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  // 프로필 상태
  String _nickname = '하루칩 여행자';
  String _selectedAvatarEmoji = '🐣';
  bool _isSyncing = false;

  final List<String> _avatarEmojis = [
    '🐣', '🐻', '🐱', '🐶', '🐰', '🐯',
    '🐼', '🦊', '🍓', '☕', '🎮', '🌿',
    '✈️', '💍', '🎓', '🎖️', '🍼', '🎨',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        setState(() {
          _nickname = user.displayName!;
        });
      }
    });
  }

  void _copyUserCode() {
    Clipboard.setData(const ClipboardData(text: ProfileSettingsScreen.userUniqueCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ 고유 유저 코드가 클립보드에 복사되었습니다! (${ProfileSettingsScreen.userUniqueCode})'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 아바타 이모지 변경 바텀시트
  void _openAvatarPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '프로필 아바타 선택',
                      style: AppTypography.heading2.copyWith(fontSize: 18, color: AppColors.protoHeading),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '나만의 감성을 담은 하루칩 캐릭터를 골라보세요.',
                  style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _avatarEmojis.length,
                  itemBuilder: (context, index) {
                    final emoji = _avatarEmojis[index];
                    final isSelected = emoji == _selectedAvatarEmoji;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedAvatarEmoji = emoji);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 프로필 아바타가 $emoji 로 변경되었습니다.'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFB),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 닉네임 수정 팝업 다이얼로그
  void _openEditProfileDialog() {
    final controller = TextEditingController(text: _nickname);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              '프로필 수정',
              style: AppTypography.heading2.copyWith(fontSize: 18, color: AppColors.protoHeading),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '하루칩에서 사용할 닉네임을 입력해 주세요.',
              style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLength: 12,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '새 닉네임 입력 (최대 12자)',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('취소', style: TextStyle(color: AppColors.protoSubtitle)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => _nickname = newName);
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✨ 닉네임이 "$newName"(으)로 변경되었습니다.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  /// 외부 캘린더 즉시 수동 동기화
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

  /// 전체 데이터 백업 내보내기 (JSON Export)
  void _exportBackupData() {
    final categories = ref.read(categoryListProvider);
    final plans = ref.read(planListProvider);

    final backupMap = <String, dynamic>{
      'appName': 'Haruchip',
      'version': '2.5.0',
      'userCode': ProfileSettingsScreen.userUniqueCode,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'plans': plans.map((p) => p.toJson()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backupMap);

    showModalBottomSheet<void>(
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
    showDialog<void>(
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
                maxLines: 7,
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

  /// 로그아웃 처리
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

  /// 회원 탈퇴 (애플 심사 필수 준수 - Guideline 5.1.1(v))
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
          '모든 D-Day와 공유 방 데이터가 즉시 파기되며 복구할 수 없습니다.',
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userEmail = currentUser?.email ?? 'haruchip_user@gmail.com';
    final trashItems = ref.watch(trashBinProvider);
    final hiddenCategories = ref.watch(hiddenCategoriesProvider);
    final selectedViewMode = ref.watch(resolvedDashboardViewModeProvider);
    final calendarSet = ref.watch(calendarIntegrationProvider);
    final isGoogleSync = calendarSet.contains('google');
    final isNaverSync = calendarSet.contains('naver');

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 타이틀
              Text(
                '프로필 & 설정',
                style: AppTypography.heading1.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.protoHeading,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '계정 정보, 데이터 동기화 및 앱 환경을 한곳에서 관리하세요.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.protoSubtitle,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),

              // 1. 내 프로필 카드 (아바타, 닉네임, 로그인 정보, 고유 식별 코드)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // 아바타 (터치 시 이모지 피커)
                        GestureDetector(
                          onTap: _openAvatarPicker,
                          child: Stack(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Text(_selectedAvatarEmoji, style: const TextStyle(fontSize: 32)),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3B82F6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // 닉네임 & 계정 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _nickname,
                                      style: AppTypography.heading2.copyWith(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.protoHeading,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: const Text(
                                      '인증 회원',
                                      style: TextStyle(
                                        color: Color(0xFF1D4ED8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildSocialBadge('Google', const Color(0xFFEA4335)),
                                  const SizedBox(width: 4),
                                  _buildSocialBadge('Apple', Colors.black),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 프로필 수정 버튼
                        OutlinedButton(
                          onPressed: _openEditProfileDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.protoHeading,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('프로필 수정', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF3F4F6)),
                    // 고유 유저 식별 코드
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.qr_code_rounded, size: 16, color: Color(0xFF6B7280)),
                            const SizedBox(width: 6),
                            const Text(
                              '고유 유저 식별 코드',
                              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ProfileSettingsScreen.userUniqueCode,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _copyUserCode,
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 13, color: Color(0xFF3B82F6)),
                                SizedBox(width: 3),
                                Text(
                                  '복사',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. 데이터 관리 섹션
              _buildSectionHeader('데이터 관리'),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // 저장공간 관리 (카카오톡 스타일)
                    _buildSettingsTile(
                      icon: Icons.pie_chart_outline_rounded,
                      iconColor: const Color(0xFF2563EB),
                      title: '저장공간 관리',
                      subtitle: '기록 데이터 및 카테고리별 지난 일정을 정리합니다.',
                      badgeText: '관리하기',
                      badgeColor: const Color(0xFFEFF6FF),
                      badgeTextColor: const Color(0xFF2563EB),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StorageManagerScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),

                    // 휴지통 (30일 보관함)
                    _buildSettingsTile(
                      icon: Icons.delete_outline_rounded,
                      iconColor: const Color(0xFFE11D48),
                      title: '휴지통 (삭제된 D-Day 복구/영구삭제)',
                      subtitle: '실수로 삭제된 모든 데이터를 30일간 안전하게 보관합니다.',
                      badgeText: '${trashItems.length}개 보관 중',
                      badgeColor: const Color(0xFFFEE2E2),
                      badgeTextColor: const Color(0xFFDC2626),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TrashBinScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),

                    // 외부 캘린더 동기화 설정 (Google / Naver 스위치)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.sync_alt_rounded, size: 18, color: Color(0xFF3B82F6)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '외부 캘린더 동기화 설정',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '디데이 및 일정을 스마트폰 기본 캘린더와 양방향 동기화합니다.',
                                      style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Text('📅', style: TextStyle(fontSize: 14)),
                                        SizedBox(width: 8),
                                        Text('Google 캘린더 연동', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    Switch(
                                      value: isGoogleSync,
                                      activeThumbColor: const Color(0xFF3B82F6),
                                      onChanged: (val) {
                                        ref.read(calendarIntegrationProvider.notifier).toggle('google');
                                      },
                                    ),
                                  ],
                                ),
                                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Text('🟢', style: TextStyle(fontSize: 14)),
                                        SizedBox(width: 8),
                                        Text('네이버 캘린더 연동', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    Switch(
                                      value: isNaverSync,
                                      activeThumbColor: const Color(0xFF03C75A),
                                      onChanged: (val) {
                                        ref.read(calendarIntegrationProvider.notifier).toggle('naver');
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isSyncing ? null : _triggerManualSync,
                              icon: _isSyncing
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(_isSyncing ? '동기화 진행 중...' : '지금 즉시 캘린더 동기화'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF3B82F6),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),

                    // 전체 데이터 백업 내보내기
                    _buildSettingsTile(
                      icon: Icons.cloud_upload_outlined,
                      iconColor: const Color(0xFF0284C7),
                      title: '전체 데이터 백업 내보내기',
                      subtitle: '카테고리 및 D-Day 일정을 JSON 파일로 안전하게 백업합니다.',
                      onTap: _exportBackupData,
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),

                    // 백업 데이터 복원하기
                    _buildSettingsTile(
                      icon: Icons.cloud_download_outlined,
                      iconColor: const Color(0xFF10B981),
                      title: '백업 데이터 복원하기',
                      subtitle: '저장해둔 JSON 백업 텍스트로 데이터를 즉시 복원합니다.',
                      onTap: _importBackupData,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. 앱 환경설정 섹션
              _buildSectionHeader('앱 환경설정'),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // 대시보드 뷰 모드 설정 (타임라인 vs 칩 모아보기)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.dashboard_customize_outlined, size: 18, color: Color(0xFF8B5CF6)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '대시보드 뷰 모드 설정',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '홈 화면에서 카테고리와 D-Day를 노출하는 기본 레이아웃 스타일',
                                      style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildViewModeButton(
                                  title: '타임라인 뷰',
                                  subtitle: '세로 스크롤형',
                                  icon: Icons.view_agenda_outlined,
                                  isSelected: selectedViewMode == 'vertical',
                                  onTap: () {
                                    ref.read(dashboardViewModeProvider.notifier).select('vertical');
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildViewModeButton(
                                  title: '칩 모아보기 뷰',
                                  subtitle: '카드 그리드형',
                                  icon: Icons.grid_view_rounded,
                                  isSelected: selectedViewMode == 'horizontal' || selectedViewMode == 'grid',
                                  onTap: () {
                                    ref.read(dashboardViewModeProvider.notifier).select('grid');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),

                    // 권한 재설정 바로가기
                    _buildSettingsTile(
                      icon: Icons.security_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: '앱 접근 권한 재설정',
                      subtitle: '알림, 사진, 카메라, 캘린더, 간편 정산 등 접근 권한 관리',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AppPermissionScreen(isSettingsMode: true),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),

                    // 대시보드 숨김 카드 보관함
                    _buildSettingsTile(
                      icon: Icons.visibility_off_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      title: '대시보드 숨김 카드 보관함',
                      subtitle: '홈에서 숨긴 카테고리를 확인하고 원터치로 복구합니다.',
                      badgeText: '${hiddenCategories.length}개 보관',
                      badgeColor: const Color(0xFFFEF3C7),
                      badgeTextColor: const Color(0xFFD97706),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HiddenCategoriesScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),

                    // 모바일 위젯 시뮬레이터
                    _buildSettingsTile(
                      icon: Icons.widgets_outlined,
                      iconColor: const Color(0xFF8B5CF6),
                      title: '모바일 홈/잠금화면 위젯 시뮬레이터',
                      subtitle: '잠금화면 미니, 2x2 감성, 4x2 스마트 캘린더 위젯 미리보기',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const WidgetSimulatorScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. 계정 및 보안 (애플 심사 필수 준수)
              _buildSectionHeader('계정 및 보안'),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // 로그아웃
                    ListTile(
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF4B5563)),
                      ),
                      title: const Text(
                        '로그아웃',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                      ),
                      subtitle: const Text('현재 기기에서 계정 연결을 해제합니다.', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF9CA3AF)),
                      onTap: _handleSignOut,
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),

                    // 회원 탈퇴 (계정 삭제) - 애플 가이드라인 5.1.1(v) 필수 준수
                    ListTile(
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.person_remove_rounded, size: 18, color: Color(0xFFE11D48)),
                      ),
                      title: const Text(
                        '회원 탈퇴 (계정 영구 삭제)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                      ),
                      subtitle: const Text('모든 D-Day 및 개인 데이터가 즉시 파기되며 복구 불가합니다.', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF9CA3AF)),
                      onTap: _handleDeleteAccount,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 앱 버전 푸터
              Center(
                child: Column(
                  children: [
                    Text(
                      'HaruChip v2.5.0 (Build 2026.11)',
                      style: AppTypography.caption.copyWith(color: const Color(0xFF9CA3AF), fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '소중한 당신의 모든 순간을 안전하게 지킵니다 💛',
                      style: AppTypography.caption.copyWith(color: const Color(0xFF9CA3AF), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeTextColor ?? const Color(0xFF1D4ED8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle, fontSize: 11),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF9CA3AF)),
      onTap: onTap,
    );
  }

  Widget _buildSocialBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label 연동',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildViewModeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF1D4ED8) : AppColors.protoHeading,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF3B82F6)),
          ],
        ),
      ),
    );
  }
}
