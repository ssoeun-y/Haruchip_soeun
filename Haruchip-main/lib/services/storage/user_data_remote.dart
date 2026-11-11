import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

/// 로그인한 사용자의 앱 데이터(카테고리/일정/휴지통 등)를 계정에 붙여 보관하는 원격 저장소.
///
/// Firestore 구조 (CLAUDE.md §4 `users/{uid}`):
/// ```
/// users/{uid}                 name, email, provider, createdAt, lastLoginAt
/// users/{uid}/appData/{key}   json(문자열), updatedAt   ← LocalStoreKeys 하나당 문서 하나
/// ```
/// 접근 제어는 `firestore.rules` — 본인(uid 일치)만 읽고 쓴다.
abstract class UserDataRemote {
  /// 로그인 시 `users/{uid}` 문서를 만들거나(첫 로그인) 마지막 로그인 시각을 갱신한다.
  Future<void> ensureUserDoc({
    required String uid,
    String? name,
    String? email,
    String? provider,
  });

  /// 이 사용자의 저장된 데이터 전체 (`key → json 문자열`). 없으면 빈 맵.
  Future<Map<String, String>> loadAll(String uid);

  Future<void> save(String uid, String key, String value);

  Future<void> remove(String uid, String key);

  /// 회원 탈퇴 — 이 사용자의 저장 데이터와 사용자 문서를 모두 지운다.
  Future<void> deleteAll(String uid);
}

/// 문서 하나(1MiB 한도)에 안전하게 들어가는 최대 크기. 넘으면 저장을 건너뛴다
/// (로컬에는 남아 있으므로 데이터가 사라지지는 않는다).
const int kMaxRemoteValueBytes = 900 * 1024;

class FirestoreUserDataRemote implements UserDataRemote {
  FirestoreUserDataRemote(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _appData(String uid) =>
      _userDoc(uid).collection('appData');

  @override
  Future<void> ensureUserDoc({
    required String uid,
    String? name,
    String? email,
    String? provider,
  }) async {
    final ref = _userDoc(uid);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.update({'lastLoginAt': FieldValue.serverTimestamp()});
      return;
    }
    await ref.set({
      'name': name ?? '',
      'email': email ?? '',
      'provider': provider ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Map<String, String>> loadAll(String uid) async {
    final snap = await _appData(uid).get();
    final result = <String, String>{};
    for (final doc in snap.docs) {
      final json = doc.data()['json'];
      if (json is String) result[doc.id] = json;
    }
    return result;
  }

  @override
  Future<void> save(String uid, String key, String value) async {
    if (value.length > kMaxRemoteValueBytes) {
      developer.log('skip remote save of $key: too large (${value.length})',
          name: 'Haruchip.UserData');
      return;
    }
    await _appData(uid).doc(key).set({
      'json': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> remove(String uid, String key) => _appData(uid).doc(key).delete();

  @override
  Future<void> deleteAll(String uid) async {
    final snap = await _appData(uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_userDoc(uid));
    await batch.commit();
  }
}
