import 'dart:developer' as developer;

import 'local_store.dart';
import 'user_data_remote.dart';

/// 계정별로 분리된 저장소. 읽기는 동기 로컬 캐시, 쓰기는 로컬 + (로그인 상태면) Firestore.
///
/// - 로그아웃(게스트) 상태: [uid]가 null → 예전과 같은 키로 기기에만 저장.
/// - 로그인 상태: 로컬 키를 `u.{uid}.{key}`로 분리해, 한 기기에서 계정을 바꿔도
///   서로의 데이터가 섞이지 않는다. 쓸 때마다 원격에도 반영한다(실패해도 로컬은 유지).
class UserScopedLocalStore implements LocalStore {
  UserScopedLocalStore({required this.base, this.uid, this.remote});

  final LocalStore base;
  final String? uid;
  final UserDataRemote? remote;

  /// 로그인 사용자의 로컬 캐시 키.
  static String scopedKey(String uid, String key) => 'u.$uid.$key';

  String _k(String key) => uid == null ? key : scopedKey(uid!, key);

  @override
  String? readString(String key) => base.readString(_k(key));

  @override
  Future<void> writeString(String key, String value) async {
    await base.writeString(_k(key), value);
    final id = uid;
    final r = remote;
    if (id == null || r == null) return;
    try {
      await r.save(id, key, value);
    } catch (e) {
      // 오프라인 등 — 로컬에는 저장돼 있다. 다음 로그인 때 서버 값이 우선하므로
      // 반복 실패하면 서버가 오래된 값일 수 있다는 점은 알려진 한계.
      developer.log('remote save failed for $key: $e', name: 'Haruchip.UserData');
    }
  }

  @override
  Future<void> remove(String key) async {
    await base.remove(_k(key));
    final id = uid;
    final r = remote;
    if (id == null || r == null) return;
    try {
      await r.remove(id, key);
    } catch (e) {
      developer.log('remote remove failed for $key: $e', name: 'Haruchip.UserData');
    }
  }
}
