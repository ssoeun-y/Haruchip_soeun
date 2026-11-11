import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/auth/auth_service.dart';

/// Firebase Auth 상태 변화를 실시간으로 스트리밍하는 Provider
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges;
});

/// 현재 로그인된 유저 객체 Provider
final currentUserProvider = Provider<User?>((ref) {
  final asyncUser = ref.watch(authStateChangesProvider);
  return asyncUser.valueOrNull ?? AuthService.instance.currentUser;
});

/// 인증 서비스 인스턴스 Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});
