import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/onboarding/providers/app_permissions_provider.dart';
import 'package:haruchip/features/onboarding/screens/app_permission_screen.dart';

void main() {
  testWidgets('AppPermissionScreen renders all 6 permissions and information texts', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AppPermissionScreen(),
        ),
      ),
    );

    expect(find.textContaining('하루칩을 더 편리하게 쓰기 위해'), findsOneWidget);
    expect(find.text('전체 동의하기'), findsOneWidget);
    expect(find.text('알림'), findsOneWidget);
    expect(find.text('갤러리/사진'), findsOneWidget);
    expect(find.text('카메라'), findsOneWidget);
    expect(find.text('캘린더'), findsOneWidget);
    expect(find.text('모임 간편 정산 연결'), findsOneWidget);
    expect(find.text('혜택 및 마케팅 알림'), findsOneWidget);
    expect(find.text('동의하고 계속하기'), findsOneWidget);
  });

  testWidgets('Tapping 전체 동의하기 toggles all permissions simultaneously', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AppPermissionScreen(),
        ),
      ),
    );

    // Initial state: not all agreed
    expect(container.read(appPermissionsProvider).allAgreed, isFalse);

    // Tap 전체 동의하기
    await tester.tap(find.text('전체 동의하기'));
    await tester.pump();

    expect(container.read(appPermissionsProvider).allAgreed, isTrue);
    expect(container.read(appPermissionsProvider).notification, isTrue);
    expect(container.read(appPermissionsProvider).photos, isTrue);
    expect(container.read(appPermissionsProvider).camera, isTrue);
    expect(container.read(appPermissionsProvider).calendar, isTrue);
    expect(container.read(appPermissionsProvider).settlement, isTrue);
    expect(container.read(appPermissionsProvider).marketing, isTrue);
  });

  testWidgets('Tapping 동의하고 계속하기 navigates to CategorySelectionScreen', (tester) async {
    var nextCalled = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AppPermissionScreen(onNext: () => nextCalled = true),
        ),
      ),
    );

    await tester.tap(find.text('동의하고 계속하기'));
    await tester.pump();

    expect(nextCalled, isTrue);
  });
}
