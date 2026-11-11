import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_permissions.dart';

/// 앱 권한 설정 상태 노티파이어
class AppPermissionsNotifier extends StateNotifier<AppPermissionsState> {
  AppPermissionsNotifier() : super(const AppPermissionsState());

  void toggleAll() {
    final nextVal = !state.allAgreed;
    state = state.setAll(nextVal);
    _syncWithLocalAndServer();
  }

  void toggle(String key) {
    state = state.toggle(key);
    _syncWithLocalAndServer();
  }

  void setPermission(String key, bool value) {
    switch (key) {
      case 'notification':
        state = state.copyWith(notification: value);
        break;
      case 'photos':
        state = state.copyWith(photos: value);
        break;
      case 'camera':
        state = state.copyWith(camera: value);
        break;
      case 'calendar':
        state = state.copyWith(calendar: value);
        break;
      case 'settlement':
        state = state.copyWith(settlement: value);
        break;
      case 'marketing':
        state = state.copyWith(marketing: value);
        break;
    }
    _syncWithLocalAndServer();
  }

  /// 로컬 저장소 및 서버 DB(User Settings) 동기화
  void _syncWithLocalAndServer() {
    debugPrint('AppPermissions synced: ${state.toJson()}');
    // 로컬 상태 및 서버 User Settings 연동 스텁: 향후 Firebase Firestore User Settings와 실시간 연동
  }
}

final appPermissionsProvider =
    StateNotifierProvider<AppPermissionsNotifier, AppPermissionsState>(
  (ref) => AppPermissionsNotifier(),
);
