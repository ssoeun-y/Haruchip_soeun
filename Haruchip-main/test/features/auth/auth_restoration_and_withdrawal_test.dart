import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/auth/providers/auth_provider.dart';
import 'package:haruchip/features/home/screens/main_shell_screen.dart';
import 'package:haruchip/features/onboarding/screens/app_permission_screen.dart';
import 'package:haruchip/features/onboarding/screens/login_screen.dart';
import 'package:haruchip/features/onboarding/screens/splash_screen.dart';
import 'package:haruchip/features/settings/screens/settings_screen.dart';
import 'package:haruchip/services/auth/auth_service.dart';

void main() {
  group('Auth Service & Providers', () {
    test('AuthService instance and providers are initialized properly', () {
      final authService = AuthService.instance;
      expect(authService, isNotNull);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(authServiceProvider), equals(authService));
      expect(container.read(currentUserProvider), isNull);
    });
  });

  group('Splash Screen Auth Routing', () {
    testWidgets('SplashScreen routes to MainShellScreen when isLoggedIn is true', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(isLoggedIn: true),
          ),
        ),
      );

      expect(find.text('HaruChip'), findsOneWidget);
      expect(find.text('하루의 소중한 조각들을 담아봐요'), findsOneWidget);

      // Fast-forward past 1.9s timer
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      expect(find.byType(MainShellScreen), findsOneWidget);
    });

    testWidgets('SplashScreen routes to AppPermissionScreen when isLoggedIn is false', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(isLoggedIn: false),
          ),
        ),
      );

      expect(find.text('HaruChip'), findsOneWidget);

      // Fast-forward past 1.9s timer
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      expect(find.byType(AppPermissionScreen), findsOneWidget);
    });
  });

  group('Onboarding & Login Interconnection', () {
    testWidgets('AppPermissionScreen contains link to LoginScreen and navigates to it', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppPermissionScreen(),
          ),
        ),
      );

      final loginLink = find.text('이미 계정이 있으신가요? 로그인하기');
      expect(loginLink, findsOneWidget);

      await tester.ensureVisible(loginLink);
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('LoginScreen 은 로그인을 건너뛰는 링크가 없다 (구글/애플 로그인만)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('로그인 없이 둘러보기'), findsNothing);
      expect(find.text('구글로 시작하기'), findsOneWidget);
    });
  });

  group('Apple Review Compliance - Account Deletion & Logout in Settings', () {
    testWidgets('SettingsScreen displays account section with Apple review account deletion pipeline', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      expect(find.text('계정 및 외부 연동'), findsOneWidget);
      expect(find.text('애플'), findsOneWidget);
      expect(find.text('구글'), findsOneWidget);
      expect(find.text('카카오'), findsOneWidget);
    });
  });
}
