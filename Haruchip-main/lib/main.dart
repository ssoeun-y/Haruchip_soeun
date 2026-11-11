import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'design_system/colors.dart';
import 'features/calendar/data/room_remote.dart';
import 'features/onboarding/screens/splash_screen.dart';
import 'firebase_options.dart';
import 'services/storage/local_store.dart';

/// 전역 스크롤 및 마우스/터치 드래그 제스처 인에이블러
class HaruAppScrollBehavior extends MaterialScrollBehavior {
  const HaruAppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

/// Firebase 프로젝트: `haruchip-6a5aa` (flutterfire configure로 생성된
/// `firebase_options.dart` 사용). 앱 위젯 트리를 그리기 전에 Firebase를
/// 반드시 초기화해야 하므로 `main()`을 async로 바꾸고
/// `WidgetsFlutterBinding.ensureInitialized()`를 먼저 호출한다 — 이게
/// 없으면 플랫폼 채널이 아직 준비되지 않아 `Firebase.initializeApp()`이
/// 실패한다.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 카테고리/일정/휴지통 로컬 저장소 — Notifier.build()가 동기로 읽을 수
  // 있도록 runApp 전에 미리 로드한다.
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(SharedPrefsLocalStore(prefs)),
        // 모임방 Firestore 실시간 동기화 (로그인 시)
        roomRemoteProvider.overrideWithValue(
          FirestoreRoomRemote(FirebaseFirestore.instance, authChanges: firebaseRoomUserChanges()),
        ),
      ],
      child: const HaruChipApp(),
    ),
  );
}

class HaruChipApp extends StatelessWidget {
  const HaruChipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '하루칩',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const HaruAppScrollBehavior(),
      // 폰 글씨 크기 설정은 따르되 최대 1.3배까지만 — 그 이상은 레이아웃이 깨진다.
      // (반응형 점검 테스트도 1.3배 기준: test/responsive/)
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: child!,
      ),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// 앱 시작 지점에서 Firebase 로그인 세션을 확인해 스플래시 완료 후 어디로
/// 전환할지 결정한다.
///
/// 모든 유저는 앱 진입 시 브랜드 경험(로고 및 "하루의 소중한 조각들을 담아봐요")
/// 스플래시를 경험하며, 스플래시 종료 시:
/// - 기존 로그인 세션이 유지된 유저([User] 존재) → 즉시 [MainShellScreen]으로 진입
/// - 최초 진입 또는 미인증 유저 → [AppPermissionScreen] 및 토스 온보딩 퍼널로 연결
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return const SplashScreen();
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.data != null;
        return SplashScreen(isLoggedIn: isLoggedIn);
      },
    );
  }
}
