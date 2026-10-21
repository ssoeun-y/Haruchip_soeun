import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/typography.dart';
import '../../plan/models/plan_item.dart';
import '../../plan/providers/plan_provider.dart';
import '../../shared/widgets/add_event_bottom_sheet.dart';
import '../../trash/logic/trash_service.dart';
import '../../trash/models/trash_item.dart';
import '../data/baby_health_database.dart';
import '../logic/category_entry_mirrors.dart';
import '../models/baby_profile.dart';
import '../models/birthday_profile.dart';
import '../models/category.dart';
import '../models/fandom_profile.dart';
import '../models/pet_profile.dart';
import '../providers/category_provider.dart';
import '../widgets/baby_care_history_modal.dart';
import '../widgets/baby_care_quick_bar_widget.dart';
import '../widgets/baby_growth_card_widget.dart';
import '../widgets/baby_growth_record_modal.dart';
import '../widgets/baby_health_checkup_widget.dart';
import '../widgets/baby_vaccine_timeline_widget.dart';
import '../widgets/birthday_friend_modal.dart';
import '../widgets/birthday_grid_card_widget.dart';
import '../widgets/category_edit_modal.dart';
import '../widgets/category_onboarding_sheets.dart';
import '../widgets/fandom_member_list_widget.dart';
import '../widgets/fandom_topkku_card_widget.dart';
import '../widgets/pet_family_card_carousel_widget.dart';
import '../../professional/models/appointment_model.dart';
import '../../professional/models/goal_model.dart';
import '../../professional/models/routine_model.dart';
import '../../professional/widgets/add_appointment_modal.dart';
import '../../professional/widgets/add_goal_modal.dart';
import '../../professional/widgets/add_routine_modal.dart';
import '../../professional/widgets/appointment_category_view.dart';
import '../../professional/widgets/goal_category_view.dart';
import '../../professional/widgets/professional_archive_modal.dart';
import '../../professional/widgets/routine_category_view.dart';
import '../controllers/exam_category_controller.dart';
import '../models/exam_model.dart';
import '../models/solo_profile.dart';
import '../widgets/add_exam_modal.dart';
import '../widgets/exam_card_widget.dart';
import '../widgets/exam_official_db_modal.dart';
import '../widgets/solo_top_card_widget.dart';

/// 전체 카테고리 범용 상세 화면 (듀얼 리스트 & 카테고리 온보딩 & 꾸미기 에디터 연동)
class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  final CategoryModel category;

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  late CategoryModel _category;

  // Edit / Reordering mode for 'N일째' items
  bool _isReorderingMode = false;
  List<PlanItem> _customCountUpOrder = [];

  @override
  void initState() {
    super.initState();
    _category = widget.category;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  void _checkOnboarding() {
    final meta = _category.metadata;
    final isInitialized = meta?['isInitialized'] == true;
    if (isInitialized) return;

    switch (_category.categoryKey) {
      case 'military':
        showMilitaryOnboardingSheet(context, category: _category, ref: ref).then((updated) {
          if (updated == true && mounted) _reloadCategory();
        });
        break;
      case 'baby':
        showBabyOnboardingSheet(context, category: _category, ref: ref).then((updated) {
          if (updated == true && mounted) _reloadCategory();
        });
        break;
      case 'solo':
        showSoloOnboardingSheet(context, category: _category, ref: ref).then((updated) {
          if (updated == true && mounted) _reloadCategory();
        });
        break;
      case 'fandom':
        showFandomOnboardingSheet(context, category: _category, ref: ref).then((updated) {
          if (updated == true && mounted) _reloadCategory();
        });
        break;
      case 'pet':
        showPetOnboardingSheet(context, category: _category, ref: ref).then((updated) {
          if (updated == true && mounted) _reloadCategory();
        });
        break;
      case 'custom':
        showCustomOnboardingSheet(context, category: _category, ref: ref).then((updated) {
          if (updated == true && mounted) _reloadCategory();
        });
        break;
      default:
        // 생일, 시험/자격증, 계획/일정 등은 즉시 진입
        break;
    }
  }

  void _reloadCategory() {
    final categories = ref.read(categoryListProvider);
    final found = categories.where((c) => c.id == _category.id).toList();
    if (found.isNotEmpty && mounted) {
      setState(() {
        _category = found.first;
      });
    }
  }

  Future<void> _openEditModal() async {
    final updated = await showCategoryEditModal(
      context,
      category: _category,
    );

    if (updated != null && mounted) {
      setState(() {
        _category = updated;
      });
      ref.read(categoryListProvider.notifier).updateCategory(updated);
    }
  }

  Future<void> _openCategorySpecificSettings() async {
    switch (_category.categoryKey) {
      case 'military':
        await showMilitaryOnboardingSheet(context, category: _category, ref: ref);
        break;
      case 'baby':
        await showBabyOnboardingSheet(context, category: _category, ref: ref);
        break;
      case 'solo':
        await showSoloOnboardingSheet(context, category: _category, ref: ref);
        break;
      case 'fandom':
        await showFandomOnboardingSheet(context, category: _category, ref: ref);
        break;
      case 'pet':
        await showPetOnboardingSheet(context, category: _category, ref: ref);
        break;
      case 'custom':
        await showCustomOnboardingSheet(context, category: _category, ref: ref);
        break;
      default:
        break;
    }
    if (mounted) _reloadCategory();
  }

  FandomTopkkuCard _getFandomTopkku() {
    final meta = _category.metadata;
    if (meta != null && meta['topkku'] != null) {
      return FandomTopkkuCard.fromJson(Map<String, dynamic>.from(meta['topkku'] as Map));
    }
    return const FandomTopkkuCard();
  }

  List<FandomMember> _getFandomMembers() {
    final meta = _category.metadata;
    if (meta != null && meta['members'] != null) {
      final list = meta['members'] as List<dynamic>;
      return list
          .map((m) => FandomMember.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
    }
    return const [];
  }

  void _saveFandomTopkku(FandomTopkkuCard topkku) {
    final updatedMeta = Map<String, dynamic>.from(_category.metadata ?? {});
    updatedMeta['topkku'] = topkku.toJson();
    final updated = _category.copyWith(metadata: updatedMeta);
    setState(() => _category = updated);
    ref.read(categoryListProvider.notifier).updateCategory(updated);
  }

  void _saveFandomMembers(List<FandomMember> members) {
    final updatedMeta = Map<String, dynamic>.from(_category.metadata ?? {});
    updatedMeta['members'] = members.map((m) => m.toJson()).toList();
    final updated = _category.copyWith(metadata: updatedMeta);
    setState(() => _category = updated);
    ref.read(categoryListProvider.notifier).updateCategory(updated);
  }

  SoloProfile _getSoloProfile() {
    final meta = _category.metadata;
    final now = DateTime.now();
    if (meta?['soloProfile'] != null) {
      try {
        return SoloProfile.fromJson(Map<String, dynamic>.from(meta!['soloProfile'] as Map));
      } catch (_) {}
    }
    final legacySoloStart = meta?['soloStartDate'] != null
        ? DateTime.parse(meta!['soloStartDate'] as String)
        : null;

    return SoloProfile(
      mode: SoloMode.selfCare,
      selfCareStartDate: legacySoloStart ?? now.subtract(const Duration(days: 30)),
      crushStartDate: now.subtract(const Duration(days: 7)),
      showTopCard: true,
    );
  }

  void _saveSoloProfile(SoloProfile profile) {
    final updatedMeta = Map<String, dynamic>.from(_category.metadata ?? {});
    updatedMeta['soloProfile'] = profile.toJson();
    updatedMeta['soloStartDate'] = profile.activeStartDate.toIso8601String();
    updatedMeta['isInitialized'] = true;

    final updated = _category.copyWith(metadata: updatedMeta);
    setState(() => _category = updated);
    ref.read(categoryListProvider.notifier).updateCategory(updated);

    // Sync primary count-up item
    final planNotifier = ref.read(planListProvider.notifier);
    final allPlanItems = ref.read(planListProvider);
    final soloItems = allPlanItems.where((p) => p.categoryKey == 'solo').toList();

    final primaryTitle = profile.mode == SoloMode.selfCare ? '나에게 집중하기 시작한 날' : '마음이 설레기 시작한 날';

    if (soloItems.isNotEmpty) {
      final first = soloItems.first;
      planNotifier.updateItem(
        first.copyWith(
          title: primaryTitle,
          date: profile.activeStartDate,
          displayMode: DdayDisplayMode.daysCount,
        ),
      );
    } else {
      planNotifier.addItem(
        PlanItem(
          id: 'plan-solo-${DateTime.now().microsecondsSinceEpoch}',
          title: primaryTitle,
          date: profile.activeStartDate,
          categoryKey: 'solo',
          categoryInstanceId: _category.id,
          isAllDay: true,
          displayMode: DdayDisplayMode.daysCount,
        ),
      );
    }
  }

  void _addSoloTag(String newTag) {
    final profile = _getSoloProfile();
    if (!profile.tags.contains(newTag)) {
      final updatedTags = [...profile.tags, newTag];
      _saveSoloProfile(profile.copyWith(tags: updatedTags));
    }
  }

  void _openAddEventWithTag(String tag) {
    showAddEventBottomSheet(
      context,
      categoryKey: 'solo',
      initialTitle: tag,
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _calculateDaysCount(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays + 1;
    return diff > 0 ? '$diff일째' : 'D-Day';
  }

  String _calculateDDayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${-diff}';
  }

  List<BirthdayProfile> _getBirthdayFriends() {
    final meta = _category.metadata;
    final friendsRaw = meta?['friends'] as List<dynamic>?;
    if (friendsRaw != null) {
      return friendsRaw
          .map((e) => BirthdayProfile.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return kDefaultMockBirthdayFriends;
  }

  /// [before]에서 빠진(=사용자가 삭제한) 항목을 바로 지우지 않고 휴지통으로
  /// 보낸다 — 30일 안에 원래 카테고리로 복구할 수 있다. 수정은 id가
  /// 그대로라 해당하지 않는다.
  void _trashRemoved<T>({
    required List<T> before,
    required List<T> after,
    required String Function(T) idOf,
    required TrashEntityType type,
    required String metaKey,
    required Map<String, dynamic> Function(T) toJson,
    required String Function(T) titleOf,
    Set<String> Function(T)? mirrorPlanIdsOf,
  }) {
    final trash = ref.read(trashServiceProvider);
    for (final e in removedById(before, after, idOf)) {
      trash.trashCategoryEntry(
        type: type,
        category: _category,
        metaKey: metaKey,
        entry: toJson(e),
        title: titleOf(e),
        mirrorPlanIds: mirrorPlanIdsOf?.call(e) ?? const {},
      );
    }
  }

  void _saveBirthdayFriends(List<BirthdayProfile> friends) {
    _trashRemoved(
      before: _getBirthdayFriends(),
      after: friends,
      idOf: (f) => f.id,
      type: TrashEntityType.birthday,
      metaKey: 'friends',
      toJson: (f) => f.toJson(),
      titleOf: (f) => '${f.name} 생일',
      mirrorPlanIdsOf: (f) => {f.id},
    );
    final currentMeta = Map<String, dynamic>.from(_category.metadata ?? {});
    currentMeta['friends'] = friends.map((f) => f.toJson()).toList();
    currentMeta['isInitialized'] = true;

    final updated = _category.copyWith(metadata: currentMeta);
    setState(() {
      _category = updated;
    });
    ref.read(categoryListProvider.notifier).updateCategory(updated);

    // Sync with planListProvider so birthdays appear in calendar and notification
    final planNotifier = ref.read(planListProvider.notifier);
    final allPlanItems = ref.read(planListProvider);

    for (final friend in friends) {
      final existing = allPlanItems.where((p) => p.id == friend.id).toList();
      if (existing.isNotEmpty) {
        planNotifier.updateItem(
          existing.first.copyWith(
            title: '${friend.name} 생일',
            date: friend.nextBirthdayDate(),
            photoUrl: friend.photoUrl,
          ),
        );
      } else {
        planNotifier.addItem(birthdayMirror(friend, _category.id));
      }
    }
  }

  Future<void> _openAddBirthdayFriend() async {
    final newFriend = await showBirthdayFriendModal(context);
    if (newFriend != null && mounted) {
      final friends = _getBirthdayFriends();
      final updated = [...friends, newFriend];
      _saveBirthdayFriends(updated);
    }
  }

  Future<void> _openEditBirthdayFriend(BirthdayProfile friend) async {
    final updatedFriend = await showBirthdayFriendModal(
      context,
      existingFriend: friend,
      allowDelete: true,
      onDelete: () {
        final friends = _getBirthdayFriends();
        final updated = friends.where((f) => f.id != friend.id).toList();
        _saveBirthdayFriends(updated);
        ref.read(planListProvider.notifier).removeItem(friend.id);
      },
    );
    if (updatedFriend != null && mounted) {
      final friends = _getBirthdayFriends();
      final updated = friends.map((f) => f.id == friend.id ? updatedFriend : f).toList();
      _saveBirthdayFriends(updated);
    }
  }

  // --- Professional Category (Goal / Appointment / Routine) Logic ---
  bool get _isProfessionalCategory =>
      ['plan', 'goal', 'routine'].contains(_category.categoryKey);

  // 1. Goal methods
  List<GoalItem> _getGoals() {
    final meta = _category.metadata;
    final raw = meta?['goals'] as List<dynamic>?;
    if (raw != null) {
      return raw.map((e) => GoalItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    return kDefaultMockGoals;
  }

  void _saveGoals(List<GoalItem> goals) {
    _trashRemoved(
      before: _getGoals(),
      after: goals,
      idOf: (g) => g.id,
      type: TrashEntityType.goal,
      metaKey: 'goals',
      toJson: (g) => g.toJson(),
      titleOf: (g) => g.title,
      mirrorPlanIdsOf: (g) => {g.id},
    );
    final currentMeta = Map<String, dynamic>.from(_category.metadata ?? {});
    currentMeta['goals'] = goals.map((g) => g.toJson()).toList();
    currentMeta['isInitialized'] = true;

    final updated = _category.copyWith(metadata: currentMeta);
    setState(() {
      _category = updated;
    });
    ref.read(categoryListProvider.notifier).updateCategory(updated);

    final planNotifier = ref.read(planListProvider.notifier);
    final allPlanItems = ref.read(planListProvider);
    for (final g in goals) {
      final mirror = goalMirror(g, _category.id);
      if (mirror != null) {
        final existing = allPlanItems.where((p) => p.id == g.id).toList();
        if (existing.isNotEmpty) {
          planNotifier.updateItem(
            existing.first.copyWith(
              title: g.title,
              date: g.deadline!,
            ),
          );
        } else {
          planNotifier.addItem(mirror);
        }
      } else {
        ref.read(planListProvider.notifier).removeItem(g.id);
      }
    }
  }

  Future<void> _openAddGoalModal([GoalItem? existing]) async {
    final result = await showAddGoalModal(context, existingGoal: existing);
    if (result != null && mounted) {
      final goals = _getGoals();
      List<GoalItem> updated;
      if (existing != null) {
        updated = goals.map((g) => g.id == existing.id ? result : g).toList();
      } else {
        updated = [result, ...goals];
      }
      _saveGoals(updated);
    }
  }

  // 2. Appointment methods
  List<AppointmentItem> _getAppointments() {
    final meta = _category.metadata;
    final raw = meta?['appointments'] as List<dynamic>?;
    if (raw != null) {
      return raw.map((e) => AppointmentItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    return kDefaultMockAppointments;
  }

  void _saveAppointments(List<AppointmentItem> appointments) {
    _trashRemoved(
      before: _getAppointments(),
      after: appointments,
      idOf: (a) => a.id,
      type: TrashEntityType.appointment,
      metaKey: 'appointments',
      toJson: (a) => a.toJson(),
      titleOf: (a) => a.title,
      mirrorPlanIdsOf: (a) => {a.id},
    );
    final currentMeta = Map<String, dynamic>.from(_category.metadata ?? {});
    currentMeta['appointments'] = appointments.map((a) => a.toJson()).toList();
    currentMeta['isInitialized'] = true;

    final updated = _category.copyWith(metadata: currentMeta);
    setState(() {
      _category = updated;
    });
    ref.read(categoryListProvider.notifier).updateCategory(updated);

    final planNotifier = ref.read(planListProvider.notifier);
    final allPlanItems = ref.read(planListProvider);
    for (final a in appointments) {
      final existing = allPlanItems.where((p) => p.id == a.id).toList();
      if (existing.isNotEmpty) {
        planNotifier.updateItem(
          existing.first.copyWith(
            title: a.title,
            date: a.date,
          ),
        );
      } else {
        planNotifier.addItem(appointmentMirror(a, _category.id));
      }
    }
  }

  Future<void> _openAddAppointmentModal([AppointmentItem? existing]) async {
    final result = await showAddAppointmentModal(context, existingAppointment: existing);
    if (result != null && mounted) {
      final appointments = _getAppointments();
      List<AppointmentItem> updated;
      if (existing != null) {
        updated = appointments.map((a) => a.id == existing.id ? result : a).toList();
      } else {
        updated = [result, ...appointments];
      }
      _saveAppointments(updated);
    }
  }

  // 3. Routine methods
  List<RoutineItem> _getRoutines() {
    final meta = _category.metadata;
    final raw = meta?['routines'] as List<dynamic>?;
    if (raw != null) {
      return raw.map((e) => RoutineItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    return kDefaultMockRoutines;
  }

  void _saveRoutines(List<RoutineItem> routines) {
    _trashRemoved(
      before: _getRoutines(),
      after: routines,
      idOf: (r) => r.id,
      type: TrashEntityType.routine,
      metaKey: 'routines',
      toJson: (r) => r.toJson(),
      titleOf: (r) => r.title,
    );
    final currentMeta = Map<String, dynamic>.from(_category.metadata ?? {});
    currentMeta['routines'] = routines.map((r) => r.toJson()).toList();
    currentMeta['isInitialized'] = true;

    final updated = _category.copyWith(metadata: currentMeta);
    setState(() {
      _category = updated;
    });
    ref.read(categoryListProvider.notifier).updateCategory(updated);
  }

  Future<void> _openAddRoutineModal([RoutineItem? existing]) async {
    final result = await showAddRoutineModal(context, existingRoutine: existing);
    if (result != null && mounted) {
      final routines = _getRoutines();
      List<RoutineItem> updated;
      if (existing != null) {
        updated = routines.map((r) => r.id == existing.id ? result : r).toList();
      } else {
        updated = [result, ...routines];
      }
      _saveRoutines(updated);
    }
  }

  // 4. Archive modal
  void _openProfessionalArchiveModal() {
    showProfessionalArchiveModal(
      context,
      goals: _getGoals(),
      appointments: _getAppointments(),
      onGoalsChanged: (updated) => _saveGoals(updated),
      onAppointmentsChanged: (updated) => _saveAppointments(updated),
    );
  }

  // 5. Baby category methods
  BabyProfile _getBabyProfile() {
    final meta = _category.metadata;
    if (meta?['babyProfile'] != null) {
      try {
        return BabyProfile.fromJson(Map<String, dynamic>.from(meta!['babyProfile'] as Map));
      } catch (_) {}
    }
    return BabyProfile(
      name: meta?['babyName'] as String? ?? '우리 아기 👶',
      birthDate: meta?['birthDate'] != null
          ? DateTime.parse(meta!['birthDate'] as String)
          : DateTime.now().subtract(const Duration(days: 100)),
      birthTime: meta?['birthTime'] as String?,
      gender: BabyGender.fromJson(meta?['gender'] as String?),
      bloodType: meta?['bloodType'] as String?,
      photoUrl: meta?['photoUrl'] as String?,
      feedingIntervalHours: meta?['feedingIntervalHours'] as int? ?? 3,
      vaccineDoses: kDefaultVaccineDoses,
      checkupDoses: kDefaultHealthCheckupDoses,
      careLogs: const [],
      growthRecords: const [],
    );
  }

  void _saveBabyProfile(BabyProfile profile) {
    final currentMeta = Map<String, dynamic>.from(_category.metadata ?? {});
    currentMeta['babyProfile'] = profile.toJson();
    currentMeta['babyName'] = profile.name;
    currentMeta['birthDate'] = profile.birthDate.toIso8601String();
    currentMeta['photoUrl'] = profile.photoUrl;
    currentMeta['gender'] = profile.gender.toJson();
    currentMeta['bloodType'] = profile.bloodType;
    currentMeta['feedingIntervalHours'] = profile.feedingIntervalHours;
    currentMeta['isInitialized'] = true;

    final updated = _category.copyWith(metadata: currentMeta);
    setState(() {
      _category = updated;
    });
    ref.read(categoryListProvider.notifier).updateCategory(updated);
  }

  void _handleQuickCareLog(BabyCareLogType type) {
    final profile = _getBabyProfile();
    final newLog = BabyCareLogItem(
      id: 'log-${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      timestamp: DateTime.now(),
    );
    final updatedLogs = [...profile.careLogs, newLog];
    final updatedProfile = profile.copyWith(careLogs: updatedLogs);
    _saveBabyProfile(updatedProfile);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${type.emoji} ${type.label} 기록 완료 (${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleDetailedCareLog(BabyCareLogItem item) {
    final profile = _getBabyProfile();
    final updatedLogs = [...profile.careLogs, item];
    final updatedProfile = profile.copyWith(careLogs: updatedLogs);
    _saveBabyProfile(updatedProfile);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.type.emoji} ${item.type.label} 상세 기록 완료'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleOpenCareHistory() async {
    final profile = _getBabyProfile();
    final result = await showBabyCareHistoryModal(context, careLogs: profile.careLogs);
    if (result != null && mounted) {
      final updatedProfile = profile.copyWith(careLogs: result);
      _saveBabyProfile(updatedProfile);
    }
  }

  void _handleToggleVaccine(VaccineDose dose) {
    final profile = _getBabyProfile();
    final doses = profile.vaccineDoses.isNotEmpty ? profile.vaccineDoses : kDefaultVaccineDoses;
    final updatedDoses = doses.map((d) {
      if (d.id == dose.id) {
        final willComplete = !d.isCompleted;
        return d.copyWith(
          isCompleted: willComplete,
          completedDate: willComplete ? DateTime.now() : null,
        );
      }
      return d;
    }).toList();
    final updatedProfile = profile.copyWith(vaccineDoses: updatedDoses);
    _saveBabyProfile(updatedProfile);
  }

  void _handleToggleCheckup(HealthCheckupDose dose) {
    final profile = _getBabyProfile();
    final doses = profile.checkupDoses.isNotEmpty ? profile.checkupDoses : kDefaultHealthCheckupDoses;
    final updatedDoses = doses.map((d) {
      if (d.stage == dose.stage) {
        final willComplete = !d.isCompleted;
        return d.copyWith(
          isCompleted: willComplete,
          completedDate: willComplete ? DateTime.now() : null,
        );
      }
      return d;
    }).toList();
    final updatedProfile = profile.copyWith(checkupDoses: updatedDoses);
    _saveBabyProfile(updatedProfile);
  }

  Future<void> _handleOpenAddGrowthRecord() async {
    final record = await showBabyGrowthRecordModal(context);
    if (record != null && mounted) {
      final profile = _getBabyProfile();
      final updatedRecords = [...profile.growthRecords, record];
      final updatedProfile = profile.copyWith(growthRecords: updatedRecords);
      _saveBabyProfile(updatedProfile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📏 신체 성장 기록이 저장되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 6. Exam category methods
  List<ExamProfile> _getExams() {
    final meta = _category.metadata;
    final raw = meta?['exams'] as List<dynamic>?;
    if (raw != null) {
      return raw.map((e) => ExamProfile.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    // Default preset if not initialized
    final now = DateTime.now();
    return [
      ExamProfile(
        id: 'default-exam-1',
        title: '정보처리기사 (2026년 정기 기사 2회차)',
        type: ExamType.qualification,
        categoryName: '국가기술자격',
        colorHex: '#4F46E5',
        targetScore: '동차 합격',
        showInMainCalendar: true,
        stages: [
          ExamStageItem(
            id: 'st-1',
            stageType: ExamStageType.application,
            name: '원서 접수 마감',
            startDate: DateTime(now.year, 4, 15),
            endDate: DateTime(now.year, 4, 18),
            isCompleted: true,
          ),
          ExamStageItem(
            id: 'st-2',
            stageType: ExamStageType.writtenTest,
            name: '필기 시험 (CBT)',
            startDate: now.add(const Duration(days: 14)),
            testTime: '09:20 입실완료',
            location: '서울공업고등학교 CBT 2실',
            checklist: const ['신분증', '수험표', '컴싸'],
          ),
          ExamStageItem(
            id: 'st-3',
            stageType: ExamStageType.writtenResult,
            name: '필기 합격자 발표',
            startDate: now.add(const Duration(days: 35)),
            testTime: '오전 09:00',
          ),
          ExamStageItem(
            id: 'st-4',
            stageType: ExamStageType.practicalTest,
            name: '실기 시험 (필답형)',
            startDate: now.add(const Duration(days: 60)),
            testTime: '09:00 입실완료',
            checklist: const ['검정 볼펜', '신분증'],
          ),
          ExamStageItem(
            id: 'st-5',
            stageType: ExamStageType.finalResult,
            name: '최종 합격자 발표',
            startDate: now.add(const Duration(days: 90)),
          ),
        ],
      ),
    ];
  }

  void _saveExams(List<ExamProfile> exams) {
    _trashRemoved(
      before: _getExams(),
      after: exams,
      idOf: (e) => e.id,
      type: TrashEntityType.exam,
      metaKey: 'exams',
      toJson: (e) => e.toJson(),
      titleOf: (e) => e.title,
      mirrorPlanIdsOf: (e) => {
        for (final s in e.subjects) 'exam-plan-${s.id}',
        for (final s in e.stages) 'exam-plan-${s.id}',
      },
    );
    final currentMeta = Map<String, dynamic>.from(_category.metadata ?? {});
    currentMeta['exams'] = exams.map((e) => e.toJson()).toList();
    currentMeta['isInitialized'] = true;

    final updated = _category.copyWith(metadata: currentMeta);
    setState(() {
      _category = updated;
    });
    ref.read(categoryListProvider.notifier).updateCategory(updated);

    // Sync with planListProvider
    final planNotifier = ref.read(planListProvider.notifier);
    final allPlanItems = ref.read(planListProvider);

    // Remove previous exam plans for this category
    final existingExamPlans = allPlanItems
        .where((p) => p.categoryKey == 'exam' && p.categoryInstanceId == _category.id)
        .toList();
    for (final oldP in existingExamPlans) {
      planNotifier.removeItem(oldP.id);
    }

    // Add updated plans
    for (final exam in exams) {
      for (final mirror in examMirrors(exam, _category.id)) {
        planNotifier.addItem(mirror);
      }
    }
  }

  Future<void> _openAddExamModal([ExamProfile? existing]) async {
    final result = await showAddExamModal(
      context,
      existingExam: existing,
      allowDelete: existing != null,
      onDelete: existing != null
          ? () {
              final exams = _getExams();
              final updated = exams.where((e) => e.id != existing.id).toList();
              _saveExams(updated);
            }
          : null,
    );

    if (result != null && mounted) {
      final exams = _getExams();
      List<ExamProfile> updated;
      if (existing != null) {
        updated = exams.map((e) => e.id == existing.id ? result : e).toList();
      } else {
        updated = [result, ...exams];
      }
      _saveExams(updated);
    }
  }

  Future<void> _openExamOfficialDbModal() async {
    final result = await showExamOfficialDbModal(context);
    if (result != null && mounted) {
      final exams = _getExams();
      final updated = [result, ...exams];
      _saveExams(updated);
    }
  }

  List<PetProfile> _getPetProfiles() {
    final meta = _category.metadata;
    final petsRaw = meta?['pets'] as List<dynamic>?;
    if (petsRaw != null && petsRaw.isNotEmpty) {
      return petsRaw.map((e) => PetProfile.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    return [];
  }

  PetProfile? _findPetForItem(PlanItem item, List<PetProfile> pets) {
    if (item.categoryInstanceId != null) {
      final match = pets.where((p) => p.id == item.categoryInstanceId).toList();
      if (match.isNotEmpty) return match.first;
    }
    for (final p in pets) {
      if (item.title.contains(p.name)) return p;
    }
    return pets.isNotEmpty ? pets.first : null;
  }

  List<PlanItem> _sortCountDownItems(List<PlanItem> items) {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);

    final futureItems = <PlanItem>[];
    final pastItems = <PlanItem>[];

    for (final item in items) {
      DateTime targetDate = item.date;
      if (_category.categoryKey == 'pet' && (item.title.contains('생일') || item.repeat)) {
        final thisYear = DateTime(todayOnly.year, item.date.month, item.date.day);
        if (thisYear.isBefore(todayOnly)) {
          targetDate = DateTime(todayOnly.year + 1, item.date.month, item.date.day);
        } else {
          targetDate = thisYear;
        }
      }

      final targetOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
      if (targetOnly.isBefore(todayOnly)) {
        pastItems.add(item);
      } else {
        futureItems.add(item);
      }
    }

    futureItems.sort((a, b) {
      DateTime dateA = a.date;
      DateTime dateB = b.date;
      if (_category.categoryKey == 'pet') {
        if (a.title.contains('생일') || a.repeat) {
          final tA = DateTime(todayOnly.year, a.date.month, a.date.day);
          dateA = tA.isBefore(todayOnly) ? DateTime(todayOnly.year + 1, a.date.month, a.date.day) : tA;
        }
        if (b.title.contains('생일') || b.repeat) {
          final tB = DateTime(todayOnly.year, b.date.month, b.date.day);
          dateB = tB.isBefore(todayOnly) ? DateTime(todayOnly.year + 1, b.date.month, b.date.day) : tB;
        }
      }
      return dateA.compareTo(dateB);
    });

    pastItems.sort((a, b) => b.date.compareTo(a.date));

    return [...futureItems, ...pastItems];
  }

  @override
  Widget build(BuildContext context) {
    final rawItems = ref.watch(planItemsByCategoryProvider(_category.categoryKey));

    final countUpItems = rawItems.where((i) => i.displayMode == DdayDisplayMode.daysCount).toList();
    final countDownRaw = rawItems.where((i) => i.displayMode != DdayDisplayMode.daysCount).toList();
    final countDownItems = _sortCountDownItems(countDownRaw);

    final petProfiles = _getPetProfiles();

    // Sync count up order
    if (_customCountUpOrder.length != countUpItems.length) {
      _customCountUpOrder = List.from(countUpItems);
    }

    final bgConfig = _category.background;
    final typoConfig = _category.typography;

    Color? singleColor;
    List<Color>? gradientColors;

    if (bgConfig.type == BackgroundType.singleColor && bgConfig.colorValues.isNotEmpty) {
      singleColor = colorFromHex(bgConfig.colorValues.first);
    } else if (bgConfig.type == BackgroundType.gradient && bgConfig.colorValues.length >= 2) {
      gradientColors = bgConfig.colorValues.map((h) => colorFromHex(h)).toList();
    }

    final textColor = colorFromHex(typoConfig.textColor);
    final hasImage = bgConfig.type == BackgroundType.image && bgConfig.imageUrl != null;

    return Scaffold(
      backgroundColor: AppColors.protoBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.protoHeading),
          onPressed: () {
            if (_isReorderingMode) {
              setState(() => _isReorderingMode = false);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        backgroundColor: AppColors.protoBackground,
        elevation: 0,
        title: Text(
          '${_category.icon} ${_category.name}',
          style: AppTypography.heading2.copyWith(color: AppColors.protoHeading),
        ),
        actions: [
          if (_isProfessionalCategory) ...[
            IconButton(
              onPressed: _openProfessionalArchiveModal,
              icon: const Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF64748B)),
              tooltip: '기록 (보관함)',
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  if (_category.categoryKey == 'goal') {
                    _openAddGoalModal();
                  } else if (_category.categoryKey == 'plan') {
                    _openAddAppointmentModal();
                  } else if (_category.categoryKey == 'routine') {
                    _openAddRoutineModal();
                  }
                },
                icon: const Icon(Icons.add, size: 17, color: Color(0xFF0F172A)),
                label: const Text(
                  '항목 추가',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ] else if (_category.categoryKey == 'birthday')
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _openAddBirthdayFriend,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Color(0xFFDB2777)),
                label: const Text(
                  '+ 친구 추가',
                  style: TextStyle(
                    color: Color(0xFFDB2777),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else if (_category.categoryKey == 'exam')
            Row(
              children: [
                TextButton.icon(
                  onPressed: _openExamOfficialDbModal,
                  icon: const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF2563EB)),
                  label: const Text(
                    '공식 DB',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: () => _openAddExamModal(),
                    icon: const Icon(Icons.add_rounded, size: 17, color: Color(0xFF0F172A)),
                    label: const Text(
                      '+ 시험 추가',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            if (_category.categoryKey != 'pet')
              TextButton.icon(
                onPressed: _openEditModal,
                icon: const Icon(Icons.palette_outlined, size: 17, color: AppColors.protoHeading),
                label: Text(
                  '꾸미기',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.protoHeading,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () => showAddEventBottomSheet(
                context,
                categoryKey: _category.categoryKey,
              ),
              icon: const Icon(Icons.add, size: 17, color: Color(0xFF007AFF)),
              label: const Text(
                '항목 추가',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: _category.categoryKey == 'goal'
                  ? GoalCategoryView(
                      goals: _getGoals(),
                      onGoalsChanged: (updated) => _saveGoals(updated),
                      onOpenAddModal: () => _openAddGoalModal(),
                    )
                  : _category.categoryKey == 'plan'
                      ? AppointmentCategoryView(
                          appointments: _getAppointments(),
                          onAppointmentsChanged: (updated) => _saveAppointments(updated),
                          onOpenAddModal: () => _openAddAppointmentModal(),
                        )
                      : _category.categoryKey == 'routine'
                          ? RoutineCategoryView(
                              routines: _getRoutines(),
                              onRoutinesChanged: (updated) => _saveRoutines(updated),
                              onOpenAddModal: () => _openAddRoutineModal(),
                            )
                          : _category.categoryKey == 'birthday'
                              ? _buildBirthdayBody()
                              : _category.categoryKey == 'exam'
                                  ? _buildExamBody()
                                  : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                  // 1. 상단 카드 영역 (Pet: 패밀리 카드 캐러셀 / 기타: 커스텀 꾸미기 카드)
                  if (_category.categoryKey == 'pet') ...[
                    PetFamilyCardCarouselWidget(
                      pets: petProfiles,
                      onEditPet: (pet) async {
                        final updated = await showPetOnboardingSheet(
                          context,
                          category: _category,
                          ref: ref,
                          editPet: pet,
                        );
                        if (updated == true && mounted) _reloadCategory();
                      },
                      onAddNewPet: () async {
                        final updated = await showPetOnboardingSheet(
                          context,
                          category: _category,
                          ref: ref,
                          isAddingNewPet: true,
                        );
                        if (updated == true && mounted) _reloadCategory();
                      },
                    ),
                    const SizedBox(height: 20),
                  ] else if (_category.categoryKey == 'fandom') ...[
                    FandomTopkkuCardWidget(
                      topkkuCard: _getFandomTopkku(),
                      artistName: _category.metadata?['starName'] as String? ?? _category.name,
                      fandomName: _category.metadata?['fandomName'] as String? ?? '팬덤',
                      debutDate: _category.metadata?['debutDate'] != null
                          ? DateTime.parse(_category.metadata!['debutDate'] as String)
                          : null,
                      fandomStartDate: _category.metadata?['fandomStartDate'] != null
                          ? DateTime.parse(_category.metadata!['fandomStartDate'] as String)
                          : null,
                      onTopkkuChanged: (topkku) => _saveFandomTopkku(topkku),
                    ),
                    const SizedBox(height: 10),
                    FandomMemberListWidget(
                      members: _getFandomMembers(),
                      onMembersChanged: (members) => _saveFandomMembers(members),
                    ),
                  ] else if (_category.categoryKey == 'baby') ...[
                    BabyGrowthCardWidget(
                      profile: _getBabyProfile(),
                      onTapEdit: () async {
                        final updated = await showBabyOnboardingSheet(
                          context,
                          category: _category,
                          ref: ref,
                          editProfile: _getBabyProfile(),
                        );
                        if (updated == true && mounted) _reloadCategory();
                      },
                    ),
                    const SizedBox(height: 16),
                    BabyCareQuickBarWidget(
                      profile: _getBabyProfile(),
                      onLogQuickCare: _handleQuickCareLog,
                      onLogDetailedCare: _handleDetailedCareLog,
                      onOpenCareHistory: _handleOpenCareHistory,
                    ),
                    const SizedBox(height: 16),
                    BabyVaccineTimelineWidget(
                      profile: _getBabyProfile(),
                      onToggleVaccine: _handleToggleVaccine,
                      onUpdateVaccine: (v) {},
                    ),
                    const SizedBox(height: 16),
                    BabyHealthCheckupWidget(
                      profile: _getBabyProfile(),
                      onToggleCheckup: _handleToggleCheckup,
                      onOpenAddGrowthRecord: _handleOpenAddGrowthRecord,
                    ),
                    const SizedBox(height: 20),
                  ] else if (_category.categoryKey == 'solo') ...[
                    SoloTopCardWidget(
                      profile: _getSoloProfile(),
                      onProfileChanged: (updated) => _saveSoloProfile(updated),
                      onSelectTag: (tag) => _openAddEventWithTag(tag),
                      onAddNewTag: (tag) => _addSoloTag(tag),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_category.showVisualCard) ...[
                    GestureDetector(
                      onTap: _openCategorySpecificSettings,
                      child: Container(
                        width: double.infinity,
                        height: 190,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: singleColor ?? AppColors.protoCardBg,
                          gradient: gradientColors != null ? LinearGradient(colors: gradientColors) : null,
                          image: hasImage
                              ? DecorationImage(
                                  image: bgConfig.imageUrl!.startsWith('http')
                                      ? NetworkImage(bgConfig.imageUrl!) as ImageProvider
                                      : AssetImage(bgConfig.imageUrl!),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.15), BlendMode.darken),
                                )
                              : null,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.protoCardBorder, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, cardConstraints) {
                            final cWidth = cardConstraints.maxWidth;
                            final cHeight = cardConstraints.maxHeight;

                            return Stack(
                              children: [
                                Align(
                                  alignment: typoConfig.position.alignment,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Opacity(
                                      opacity: typoConfig.opacity,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: switch (typoConfig.position) {
                                          TextPositionPreset.topLeft || TextPositionPreset.bottomLeft => CrossAxisAlignment.start,
                                          TextPositionPreset.topRight || TextPositionPreset.bottomRight => CrossAxisAlignment.end,
                                          _ => CrossAxisAlignment.center,
                                        },
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(_category.icon, style: const TextStyle(fontSize: 28)),
                                              const SizedBox(width: 8),
                                              Text(
                                                _category.name,
                                                style: TextStyle(
                                                  fontFamily: typoConfig.fontFamily,
                                                  color: hasImage ? Colors.white : textColor,
                                                  fontSize: typoConfig.fontSize + 4,
                                                  fontWeight: FontWeight.bold,
                                                  shadows: hasImage
                                                      ? const [Shadow(color: Colors.black54, blurRadius: 4)]
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.85),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '등록된 디데이: ${rawItems.length}개',
                                                  style: AppTypography.caption.copyWith(
                                                    color: AppColors.protoHeading,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                if (['military', 'baby', 'solo', 'fandom', 'custom'].contains(_category.categoryKey)) ...[
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.settings_rounded, size: 12, color: Color(0xFF007AFF)),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (bgConfig.decorations != null)
                                  for (final sticker in bgConfig.decorations!)
                                    Positioned(
                                      left: sticker.x * cWidth,
                                      top: sticker.y * cHeight,
                                      child: Transform.rotate(
                                        angle: sticker.rotation,
                                        child: Transform.scale(
                                          scale: sticker.scale,
                                          child: sticker.isText
                                              ? Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.85),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    sticker.stickerType,
                                                    style: TextStyle(
                                                      fontSize: sticker.fontSize ?? 12,
                                                      color: sticker.textColor != null ? colorFromHex(sticker.textColor!) : Colors.black87,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                )
                                              : Text(sticker.stickerType, style: const TextStyle(fontSize: 28)),
                                        ),
                                      ),
                                    ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 구분선
                  const Divider(height: 1, color: AppColors.protoCardBorder),
                  const SizedBox(height: 24),

                  // 3. [영역 A] 'N일째 리스트' (Count-up List)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, size: 18, color: AppColors.protoHeading),
                          const SizedBox(width: 6),
                          Text(
                            'N일째 리스트',
                            style: AppTypography.cardLabel.copyWith(
                              color: AppColors.protoHeading,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (countUpItems.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _customCountUpOrder = List.from(countUpItems);
                              _isReorderingMode = true;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            '편집',
                            style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (countUpItems.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: const Text('등록된 N일째 항목이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    )
                  else
                    for (final item in _customCountUpOrder)
                      _buildCountUpCard(
                        item: item,
                        pet: _findPetForItem(item, petProfiles),
                        onTap: () => showAddEventBottomSheet(
                          context,
                          categoryKey: _category.categoryKey,
                          existingItem: item,
                        ),
                      ),

                  const SizedBox(height: 28),

                  // 4. [영역 B] '세부 D-Day 리스트' (Countdown List)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.event_note_rounded, size: 18, color: AppColors.protoHeading),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '세부 D-Day 리스트',
                                style: AppTypography.cardLabel.copyWith(
                                  color: AppColors.protoHeading,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '총 ${countDownItems.length}개',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (countDownItems.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.event_available_rounded, size: 28, color: Colors.grey),
                          SizedBox(height: 6),
                          Text('예정된 D-Day 일정이 없어요', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    for (final item in countDownItems) ...[
                      _buildCountDownCard(
                        item: item,
                        pet: _findPetForItem(item, petProfiles),
                        onTap: () => showAddEventBottomSheet(
                          context,
                          categoryKey: _category.categoryKey,
                          existingItem: item,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                ],
              ),
            ),
          ),

          // Reordering Modal Overlay for Zone A
          if (_isReorderingMode)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Notification
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            children: [
                              Text(
                                'N일째 항목 순서 변경',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.protoHeading),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '💡 상단 2개 항목만 메인 화면에 우선 표시됩니다.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF007AFF), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reorderable list
                        Expanded(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: ReorderableListView(
                              // ignore: deprecated_member_use
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (oldIndex < newIndex) newIndex -= 1;
                                  final item = _customCountUpOrder.removeAt(oldIndex);
                                  _customCountUpOrder.insert(newIndex, item);
                                });
                              },
                              children: [
                                for (int i = 0; i < _customCountUpOrder.length; i++)
                                  Container(
                                    key: ValueKey(_customCountUpOrder[i].id),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: i < 2
                                          ? Border.all(color: const Color(0xFF007AFF), width: 2)
                                          : Border.all(color: const Color(0xFFE5E5EA)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: i < 2 ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${i + 1}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: i < 2 ? Colors.white : const Color(0xFF8E8E93),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _customCountUpOrder[i].title,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.protoHeading,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.drag_handle_rounded, color: Color(0xFF8E8E93)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            setState(() {
                              _isReorderingMode = false;
                            });
                          },
                          child: const Text('수정 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountUpCard({
    required PlanItem item,
    PetProfile? pet,
    required VoidCallback onTap,
  }) {
    final dDayText = _calculateDaysCount(item.date);

    Widget? avatarWidget;
    if (_category.categoryKey == 'pet' && pet != null) {
      final imgProvider = getPetAvatarImageProvider(pet.photoUrl);
      if (imgProvider != null) {
        avatarWidget = CircleAvatar(
          radius: 17,
          backgroundImage: imgProvider,
        );
      } else {
        avatarWidget = Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFFFECE8),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(pet.icon, style: const TextStyle(fontSize: 17)),
        );
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE4D8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (avatarWidget != null) ...[
              avatarWidget,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_category.categoryKey == 'pet' && pet != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECE8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pet.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B4A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTypography.body.copyWith(
                            color: AppColors.protoHeading,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(item.date),
                    style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                dDayText,
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountDownCard({
    required PlanItem item,
    PetProfile? pet,
    required VoidCallback onTap,
  }) {
    String dDayLabel = _calculateDDayLabel(item.date);
    DateTime displayDate = item.date;

    if ((_category.categoryKey == 'pet' || _category.categoryKey == 'fandom') &&
        (item.title.contains('생일') || item.title.contains('데뷔') || item.repeat)) {
      final now = DateTime.now();
      final todayOnly = DateTime(now.year, now.month, now.day);
      var nextDate = DateTime(todayOnly.year, item.date.month, item.date.day);
      if (nextDate.isBefore(todayOnly)) {
        nextDate = DateTime(todayOnly.year + 1, item.date.month, item.date.day);
      }
      final diff = nextDate.difference(todayOnly).inDays;
      if (diff == 0) {
        dDayLabel = 'D-Day';
      } else {
        dDayLabel = 'D-$diff';
      }
      displayDate = nextDate;
    }

    final isTicketing = item.title.contains('티켓팅');
    if (isTicketing) {
      final now = DateTime.now();
      final diffDuration = item.date.difference(now);
      if (!diffDuration.isNegative) {
        final hours = diffDuration.inHours;
        final mins = diffDuration.inMinutes % 60;
        final secs = diffDuration.inSeconds % 60;
        if (diffDuration.inDays == 0) {
          dDayLabel = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
        } else {
          dDayLabel = 'D-${diffDuration.inDays} ${hours % 24}h';
        }
      }
    }

    final isPast = dDayLabel.startsWith('D+');

    Widget? avatarWidget;
    if (_category.categoryKey == 'pet' && pet != null) {
      final imgProvider = getPetAvatarImageProvider(pet.photoUrl);
      if (imgProvider != null) {
        avatarWidget = CircleAvatar(
          radius: 17,
          backgroundImage: imgProvider,
        );
      } else {
        avatarWidget = Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFFFECE8),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(pet.icon, style: const TextStyle(fontSize: 17)),
        );
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE4D8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (avatarWidget != null) ...[
              avatarWidget,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_category.categoryKey == 'pet' && pet != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECE8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pet.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B4A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTypography.body.copyWith(
                            color: AppColors.protoHeading,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(displayDate),
                    style: AppTypography.caption.copyWith(color: AppColors.protoSubtitle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPast ? const Color(0xFFFFEAEA) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                dDayLabel,
                style: TextStyle(
                  color: isPast ? const Color(0xFFEF4444) : const Color(0xFF007AFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdayBody() {
    final friends = _getBirthdayFriends();
    friends.sort((a, b) => a.dDay().compareTo(b.dDay()));

    if (friends.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Column(
          children: [
            const Text('🎂', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              '등록된 친구 생일이 없습니다',
              style: AppTypography.heading2.copyWith(color: AppColors.protoHeading),
            ),
            const SizedBox(height: 6),
            const Text(
              '소중한 친구, 가족의 생일을 추가해보세요!',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _openAddBirthdayFriend,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('친구 생일 추가하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB2777),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.cake_rounded, size: 18, color: Color(0xFFDB2777)),
                const SizedBox(width: 6),
                Text(
                  '소중한 사람들의 생일',
                  style: AppTypography.cardLabel.copyWith(
                    color: AppColors.protoHeading,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              '총 ${friends.length}명',
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: friends.length,
          // 폭 비례(childAspectRatio)면 좁은 폰에서 카드가 낮아져 내용이 넘친다 —
          // 사진·여백(140)은 고정, 글자 부분(76 — 좁은 폰에서 날짜가 두 줄이 되는 경우 포함)은
          // 폰의 글씨 크기 설정만큼 키운다.
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 140 + MediaQuery.textScalerOf(context).scale(76),
          ),
          itemBuilder: (context, index) {
            final friend = friends[index];
            return BirthdayGridCardWidget(
              friend: friend,
              onTap: () => _openEditBirthdayFriend(friend),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExamBody() {
    final exams = _getExams();
    final sortedExams = const ExamCategoryController().sortExamsByUrgency(exams);

    if (exams.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Column(
          children: [
            const Text('📝', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              '등록된 시험 일정이 없습니다',
              style: AppTypography.heading2.copyWith(color: AppColors.protoHeading),
            ),
            const SizedBox(height: 6),
            const Text(
              '원클릭으로 공식 시험 일정을 불러오거나 직접 추가해보세요!',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // 좁은 폭(375 등)에서는 두 버튼이 한 줄에 안 들어가 넘쳤다 — 줄바꿈 허용.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _openExamOfficialDbModal,
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: const Text('공식 DB 불러오기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openAddExamModal(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('직접 시험 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 요약 & 빠른 액션 바
        Container(
          // Wrap은 내용 폭만큼만 차지하므로, 버튼이 오른쪽 끝에 붙도록 가로를 꽉 채운다.
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          // 한 줄 유지 — 좁으면 제목과 개수 배지가 말줄임으로 줄어들고, 오른쪽 버튼은 그대로.
          child: Row(
            children: [
              Expanded(
                child: Row(
                children: [
                  const Icon(Icons.school_rounded, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '시험 파이프라인 관리',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardLabel.copyWith(
                        color: AppColors.protoHeading,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '총 ${exams.length}개',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  ),
                ],
              ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _openExamOfficialDbModal,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('📚', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Text(
                            '공식 DB',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _openAddExamModal(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 14, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            '추가',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
        const SizedBox(height: 14),

        // 시험 카드 목록 (가장 임박한 세부 일정순으로 정렬)
        ...sortedExams.map((exam) {
          return ExamCardWidget(
            key: ValueKey(exam.id),
            exam: exam,
            onEdit: () => _openAddExamModal(exam),
            onDelete: () {
              final updated = exams.where((e) => e.id != exam.id).toList();
              _saveExams(updated);
            },
            onExamChanged: (updatedExam) {
              final updated = exams.map((e) => e.id == updatedExam.id ? updatedExam : e).toList();
              _saveExams(updated);
            },
          );
        }),
      ],
    );
  }
}
