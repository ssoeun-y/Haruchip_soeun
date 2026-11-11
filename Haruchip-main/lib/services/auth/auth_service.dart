import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'apple_auth_service.dart';
import '../storage/user_data_remote.dart';
import 'google_auth_service.dart';

/// 통합 인증 및 세션/계정 탈퇴 관리 서비스
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  fb_auth.User? get currentUser {
    if (Firebase.apps.isEmpty) return null;
    return fb_auth.FirebaseAuth.instance.currentUser;
  }

  Stream<fb_auth.User?> get authStateChanges {
    if (Firebase.apps.isEmpty) return const Stream.empty();
    return fb_auth.FirebaseAuth.instance.authStateChanges();
  }

  Future<fb_auth.UserCredential> signInWithGoogle() {
    return GoogleAuthService.instance.signIn();
  }

  Future<fb_auth.UserCredential> signInWithApple() {
    return AppleAuthService.instance.signIn();
  }

  /// 전체 로그아웃 (소셜 세션 + Firebase 세션 해제)
  Future<void> signOut() async {
    try {
      await GoogleAuthService.instance.signOut();
    } catch (_) {}
    try {
      await AppleAuthService.instance.signOut();
    } catch (_) {}
    if (Firebase.apps.isNotEmpty) {
      await fb_auth.FirebaseAuth.instance.signOut();
    }
  }

  /// 애플 앱스토어 심사 기준(Guideline 5.1.1(v)) 준수: 계정 즉시 영구 삭제 (회원 탈퇴)
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user != null) {
      // 탈퇴 = 서버에 저장된 내 데이터도 함께 삭제 (실패하면 계정 삭제 전에 중단 — 데이터만 남지 않게).
      await FirestoreUserDataRemote(FirebaseFirestore.instance).deleteAll(user.uid);
      await user.delete();
    }
    await signOut();
  }
}
