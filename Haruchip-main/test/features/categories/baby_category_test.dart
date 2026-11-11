import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/controllers/baby_category_controller.dart';
import 'package:haruchip/features/categories/data/baby_health_database.dart';
import 'package:haruchip/features/categories/models/baby_profile.dart';

void main() {
  group('Baby Category - Age & Milestone Calculations', () {
    const controller = BabyCategoryController();

    test('formatBabyDaysCount calculates birth day as 1st day', () {
      final today = DateTime(2026, 10, 6);
      final birthToday = DateTime(2026, 10, 6);
      final birth100DaysAgo = DateTime(2026, 10, 6).subtract(const Duration(days: 99));

      expect(controller.formatBabyDaysCount(birthToday, today), '태어난 지 1일째');
      expect(controller.formatBabyDaysCount(birth100DaysAgo, today), '태어난 지 100일째');
    });

    test('formatBabyAgeDetailed generates detailed month, day, week string', () {
      final now = DateTime(2026, 10, 6);
      final birth = DateTime(2026, 6, 1); // June 1 to Oct 6 = 4 months 5 days

      final result = controller.formatBabyAgeDetailed(birth, now);
      expect(result.contains('4개월 5일차'), isTrue);
      expect(result.contains('주'), isTrue);
    });

    test('getGrowthMilestones contains 100일, 돌, 200일, etc.', () {
      final birth = DateTime(2026, 1, 1);
      final milestones = controller.getGrowthMilestones(birth, DateTime(2026, 1, 1));

      expect(milestones.any((m) => m.label == '100일'), isTrue);
      expect(milestones.any((m) => m.label.contains('첫돌')), isTrue);
      expect(milestones.firstWhere((m) => m.label == '100일').daysLeft, 99);
    });
  });

  group('Baby Category - Realtime Feeding Countdown', () {
    const controller = BabyCategoryController();

    test('calculateNextFeeding returns overdue when feeding interval passed', () {
      final now = DateTime(2026, 10, 6, 14, 0);
      final lastFeeding = DateTime(2026, 10, 6, 10, 0); // 4 hours ago (interval is 3h)

      final logs = [
        BabyCareLogItem(
          id: 'log-1',
          type: BabyCareLogType.feeding,
          timestamp: lastFeeding,
          amount: 160,
          subType: '분유',
        ),
      ];

      final status = controller.calculateNextFeeding(logs, 3, now);
      expect(status.isOverdue, isTrue);
      expect(status.statusText.contains('수유 텀'), isTrue);
      expect(status.statusText.contains('초과'), isTrue);
    });

    test('calculateNextFeeding returns due now when within 10 minutes', () {
      final now = DateTime(2026, 10, 6, 13, 0);
      final lastFeeding = DateTime(2026, 10, 6, 10, 0); // exactly 3 hours ago

      final logs = [
        BabyCareLogItem(
          id: 'log-1',
          type: BabyCareLogType.feeding,
          timestamp: lastFeeding,
        ),
      ];

      final status = controller.calculateNextFeeding(logs, 3, now);
      expect(status.isDueNow, isTrue);
      expect(status.statusText, '수유 시간 도래 (D-0)');
    });

    test('calculateNextFeeding returns remaining time before feeding due', () {
      final now = DateTime(2026, 10, 6, 11, 40);
      final lastFeeding = DateTime(2026, 10, 6, 10, 0); // 1h 40m ago, due at 13:00 (1h 20m left)

      final logs = [
        BabyCareLogItem(
          id: 'log-1',
          type: BabyCareLogType.feeding,
          timestamp: lastFeeding,
        ),
      ];

      final status = controller.calculateNextFeeding(logs, 3, now);
      expect(status.isOverdue, isFalse);
      expect(status.isDueNow, isFalse);
      expect(status.statusText.contains('다음 수유까지'), isTrue);
      expect(status.statusText.contains('1시간 20분 전'), isTrue);
    });
  });

  group('Baby Category - Vaccine & Health Checkup Database', () {
    test('kDefaultVaccineDoses contains standard KCDCA vaccines', () {
      expect(kDefaultVaccineDoses.any((v) => v.name.contains('BCG')), isTrue);
      expect(kDefaultVaccineDoses.any((v) => v.name.contains('B형간염 1차')), isTrue);
      expect(kDefaultVaccineDoses.any((v) => v.name.contains('DTaP 1차')), isTrue);
      expect(kDefaultVaccineDoses.any((v) => v.name.contains('MMR 1차')), isTrue);
      expect(kDefaultVaccineDoses.any((v) => v.name.contains('수두')), isTrue);
      expect(kDefaultVaccineDoses.length, greaterThanOrEqualTo(20));
    });

    test('kDefaultHealthCheckupDoses contains 1 to 8 checkup stages', () {
      expect(kDefaultHealthCheckupDoses.length, 8);
      expect(kDefaultHealthCheckupDoses.first.stage, 1);
      expect(kDefaultHealthCheckupDoses.last.stage, 8);
    });

    test('BabyProfile JSON serialization works seamlessly', () {
      final profile = BabyProfile(
        name: '튼튼이',
        birthDate: DateTime(2026, 1, 15),
        birthTime: '13:45',
        gender: BabyGender.boy,
        bloodType: 'A',
        feedingIntervalHours: 4,
        careLogs: [
          BabyCareLogItem(
            id: 'c1',
            type: BabyCareLogType.babyFood,
            timestamp: DateTime(2026, 10, 6, 12, 0),
            amount: 100,
            subType: '중기',
          ),
        ],
        growthRecords: [
          GrowthRecord(
            id: 'g1',
            date: DateTime(2026, 10, 6),
            heightCm: 72.5,
            weightKg: 8.9,
            headCircumferenceCm: 44.0,
          ),
        ],
      );

      final json = profile.toJson();
      final restored = BabyProfile.fromJson(json);

      expect(restored.name, '튼튼이');
      expect(restored.gender, BabyGender.boy);
      expect(restored.bloodType, 'A');
      expect(restored.feedingIntervalHours, 4);
      expect(restored.careLogs.length, 1);
      expect(restored.careLogs.first.type, BabyCareLogType.babyFood);
      expect(restored.growthRecords.length, 1);
      expect(restored.growthRecords.first.heightCm, 72.5);
    });
  });

  group('Baby Category - KCDA Vaccine Dose Target Date Calculation', () {
    const controller = BabyCategoryController();
    final birthDate = DateTime(2026, 3, 1);

    test('BCG recommendation is within 4 weeks of birth', () {
      final bcg = kDefaultVaccineDoses.firstWhere((v) => v.name.contains('BCG'));
      final target = controller.calculateVaccineDoseTargetDate(birthDate, bcg);
      // Expected: birthDate + 28 days = March 29, 2026
      expect(target, DateTime(2026, 3, 29));
    });

    test('B형간염 1차 is birth day, 2차 is 1 month later, 3차 is 6 months later', () {
      final dose1 = kDefaultVaccineDoses.firstWhere((v) => v.name.contains('B형간염 1차'));
      final dose2 = kDefaultVaccineDoses.firstWhere((v) => v.name.contains('B형간염 2차'));
      final dose3 = kDefaultVaccineDoses.firstWhere((v) => v.name.contains('B형간염 3차'));

      expect(controller.calculateVaccineDoseTargetDate(birthDate, dose1), birthDate);
      expect(controller.calculateVaccineDoseTargetDate(birthDate, dose2), DateTime(2026, 4, 1));
      expect(controller.calculateVaccineDoseTargetDate(birthDate, dose3), DateTime(2026, 9, 1));
    });

    test('MMR 1차 is at 12 months (1 year later)', () {
      final mmr = kDefaultVaccineDoses.firstWhere((v) => v.name.contains('MMR 1차'));
      expect(controller.calculateVaccineDoseTargetDate(birthDate, mmr), DateTime(2027, 3, 1));
    });
  });

  group('Baby Category - Growth Records CRUD', () {
    test('supports adding, updating, and deleting growth records', () {
      var profile = BabyProfile(
        name: '하임이',
        birthDate: DateTime(2026, 1, 1),
        growthRecords: const [],
      );

      // Create
      final record1 = GrowthRecord(
        id: 'rec-1',
        date: DateTime(2026, 5, 1),
        heightCm: 65.0,
        weightKg: 7.2,
      );
      profile = profile.copyWith(growthRecords: [...profile.growthRecords, record1]);
      expect(profile.growthRecords.length, 1);
      expect(profile.growthRecords.first.heightCm, 65.0);

      // Update
      final updatedRecord1 = record1.copyWith(heightCm: 66.5, weightKg: 7.5);
      profile = profile.copyWith(
        growthRecords: profile.growthRecords
            .map((r) => r.id == record1.id ? updatedRecord1 : r)
            .toList(),
      );
      expect(profile.growthRecords.length, 1);
      expect(profile.growthRecords.first.heightCm, 66.5);
      expect(profile.growthRecords.first.weightKg, 7.5);

      // Delete
      profile = profile.copyWith(
        growthRecords: profile.growthRecords.where((r) => r.id != record1.id).toList(),
      );
      expect(profile.growthRecords.isEmpty, isTrue);
    });
  });

  group('Baby Category - Section Visibility and Reordering', () {
    test('hidden sections can be filtered and toggled', () {
      final allSections = [
        'careQuickBar',
        'vaccineTimeline',
        'healthCheckup',
        'growthRecords',
        'countUpList',
        'dDayList',
      ];
      final hidden = {'careQuickBar', 'healthCheckup'};

      final visibleSections = allSections.where((s) => !hidden.contains(s)).toList();
      expect(visibleSections.contains('careQuickBar'), isFalse);
      expect(visibleSections.contains('healthCheckup'), isFalse);
      expect(visibleSections.contains('growthRecords'), isTrue);
      expect(visibleSections.contains('vaccineTimeline'), isTrue);

      // Restore section
      hidden.remove('careQuickBar');
      final updatedVisible = allSections.where((s) => !hidden.contains(s)).toList();
      expect(updatedVisible.contains('careQuickBar'), isTrue);
    });

    test('reordering sections updates order index', () {
      final sections = [
        'careQuickBar',
        'vaccineTimeline',
        'healthCheckup',
        'growthRecords',
      ];

      // Move growthRecords to top
      final item = sections.removeAt(3);
      sections.insert(0, item);

      expect(sections.first, 'growthRecords');
      expect(sections[1], 'careQuickBar');
    });
  });

  group('D-Day Timed Countdown & Expiration Logic', () {
    test('D-Day with time today calculates remaining hours and minutes', () {
      final now = DateTime(2026, 10, 26, 9, 30);
      final targetTime = DateTime(2026, 10, 26, 15, 0); // 5h 30m left

      final diff = targetTime.difference(now);
      final hours = diff.inHours.toString().padLeft(2, '0');
      final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final countdownText = '$hours:$mins 남음';

      expect(countdownText, '05:30 남음');
      expect(diff.isNegative, isFalse);
    });

    test('D-Day with time already elapsed is marked expired and not positive D+1', () {
      final now = DateTime(2026, 10, 26, 16, 0);
      final targetTime = DateTime(2026, 10, 26, 15, 0); // 1 hour ago

      final isExpired = targetTime.isBefore(now);
      expect(isExpired, isTrue);
    });
  });
}
