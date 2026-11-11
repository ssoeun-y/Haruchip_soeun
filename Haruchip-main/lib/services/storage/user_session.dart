import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_store.dart';
import 'user_data_remote.dart';
import 'user_scoped_local_store.dart';

/// 로그인한 사용자 (Firebase Auth에서 필요한 값만 — 테스트에서 직접 만들 수 있게 분리).
class AuthIdentity {
  const AuthIdentity({required this.uid, this.name, this.email, this.provider});

  final String uid;
  final String? name;
  final String? email;
  final String? provider;
}

/// 현재 데이터가 어느 계정 기준인지. [uid]가 null이면 게스트(기기 로컬).
class UserSession {
  const UserSession({this.uid, this.ready = true});

  final String? uid;

  /// 로그인 직후 서버 데이터를 불러오는 동안 false.
  final bool ready;
}

/// 기기 로컬 저장소(계정 구분 없는 원본). 앱은 `main()`에서 SharedPreferences로 override.
final baseLocalStoreProvider = Provider<LocalStore>((ref) => InMemoryLocalStore());

/// 원격 저장소. 로그인 전/테스트에서는 null → 서버 동기화 없이 로컬만 동작.
final userDataRemoteProvider = Provider<UserDataRemote?>((ref) => null);

final userSessionProvider =
    NotifierProvider<UserSessionNotifier, UserSession>(UserSessionNotifier.new);

/// 로그인 상태 변화에 따라 "데이터를 어느 계정 기준으로 읽고 쓸지"를 바꾼다.
///
/// 로그인 → 서버(`users/{uid}/appData`)에서 저장된 데이터를 내려받아 계정별 로컬
/// 캐시에 채운 뒤 [state]를 바꾼다. 이 값을 보는 [localStoreProvider]가 새로 만들어지면서
/// 카테고리·일정·휴지통 Provider가 저장된 데이터로 다시 그려진다.
/// 로그아웃 → 게스트 범위로 돌아가 이전 계정 데이터가 화면에 남지 않는다.
class UserSessionNotifier extends Notifier<UserSession> {
  StreamSubscription<AuthIdentity?>? _sub;
  int _generation = 0;
  Completer<void> _ready = Completer<void>()..complete();

  @override
  UserSession build() {
    ref.onDispose(() => _sub?.cancel());
    return const UserSession();
  }

  /// 로그인 상태 스트림을 구독한다 (앱: FirebaseAuth, 테스트: 직접 주입).
  void start(Stream<AuthIdentity?> authChanges) {
    _sub?.cancel();
    _sub = authChanges.listen(onAuthChanged);
  }

  /// 진행 중인 로그인 데이터 불러오기가 끝날 때까지 기다린다.
  Future<void> waitUntilReady({Duration timeout = const Duration(seconds: 10)}) =>
      _ready.future.timeout(timeout, onTimeout: () {});

  Future<void> onAuthChanged(AuthIdentity? user) async {
    final gen = ++_generation;
    if (user == null) {
      _complete();
      state = const UserSession();
      return;
    }
    if (state.uid == user.uid && state.ready) return;
    _ready = Completer<void>();
    var hydrated = true;
    try {
      await _hydrate(user);
    } catch (e) {
      hydrated = false;
      developer.log('hydrate failed: $e', name: 'Haruchip.UserSession');
    }
    if (gen != _generation) {
      _complete();
      return; // 그 사이 다른 로그인/로그아웃이 있었다
    }
    // 서버에서 못 불러왔는데(오프라인 등) 이 기기에 이 계정의 캐시도 없으면, 빈 상태로
    // 계정 범위에 들어가 서버의 기존 데이터를 덮어쓸 수 있다 → 게스트 범위로 둔다.
    final base = ref.read(baseLocalStoreProvider);
    final hasCache = LocalStoreKeys.all.any(
      (k) => base.readString(UserScopedLocalStore.scopedKey(user.uid, k)) != null,
    );
    state = (hydrated || hasCache) ? UserSession(uid: user.uid) : const UserSession();
    _complete();
  }

  void _complete() {
    if (!_ready.isCompleted) _ready.complete();
  }

  Future<void> _hydrate(AuthIdentity user) async {
    final remote = ref.read(userDataRemoteProvider);
    if (remote == null) return;
    final base = ref.read(baseLocalStoreProvider);

    await remote.ensureUserDoc(
      uid: user.uid,
      name: user.name,
      email: user.email,
      provider: user.provider,
    );
    final saved = await remote.loadAll(user.uid);

    if (saved.isNotEmpty) {
      // 기존 계정(다른 기기에서 쓰던 데이터 포함): 서버 값을 이 계정의 로컬 캐시에 채운다.
      for (final key in LocalStoreKeys.all) {
        final value = saved[key];
        final local = UserScopedLocalStore.scopedKey(user.uid, key);
        if (value != null) {
          await base.writeString(local, value);
        } else {
          await base.remove(local);
        }
      }
      return;
    }

    // 서버에 데이터가 없는 새 계정: 로그인 전에 이 기기에서 만든 데이터를 계정으로 옮긴다.
    // (옮긴 뒤 게스트 키는 지워서 다음에 로그인하는 다른 계정이 물려받지 않게 한다.)
    for (final key in LocalStoreKeys.all) {
      final guest = base.readString(key);
      if (guest == null) continue;
      await remote.save(user.uid, key, guest);
      await base.writeString(UserScopedLocalStore.scopedKey(user.uid, key), guest);
      await base.remove(key);
    }
  }
}
