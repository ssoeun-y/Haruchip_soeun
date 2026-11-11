import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/providers/category_provider.dart';
import 'package:haruchip/services/storage/local_store.dart';
import 'package:haruchip/services/storage/user_data_remote.dart';
import 'package:haruchip/services/storage/user_scoped_local_store.dart';
import 'package:haruchip/services/storage/user_session.dart';

class _FakeRemote implements UserDataRemote {
  _FakeRemote([Map<String, Map<String, String>>? data]) : data = data ?? {};
  final Map<String, Map<String, String>> data;
  final users = <String>{};
  bool failLoad = false;

  @override
  Future<void> ensureUserDoc({required String uid, String? name, String? email, String? provider}) async =>
      users.add(uid);
  @override
  Future<Map<String, String>> loadAll(String uid) async {
    if (failLoad) throw Exception('offline');
    return {...?data[uid]};
  }

  @override
  Future<void> save(String uid, String key, String value) async => (data[uid] ??= {})[key] = value;
  @override
  Future<void> remove(String uid, String key) async => data[uid]?.remove(key);
  @override
  Future<void> deleteAll(String uid) async => data.remove(uid);
}

const _catA = '[{"id":"c1","categoryKey":"goal","name":"A의 목표","emoji":"🎯","colorHex":"#4F46E5"}]';

ProviderContainer _container(InMemoryLocalStore base, _FakeRemote remote) {
  final c = ProviderContainer(overrides: [
    baseLocalStoreProvider.overrideWithValue(base),
    userDataRemoteProvider.overrideWithValue(remote),
    localStoreProvider.overrideWith((ref) => UserScopedLocalStore(
          base: ref.watch(baseLocalStoreProvider),
          uid: ref.watch(userSessionProvider.select((s) => s.uid)),
          remote: ref.watch(userDataRemoteProvider),
        )),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  const a = AuthIdentity(uid: 'A', name: '에이', email: 'a@x.com', provider: 'google.com');
  const b = AuthIdentity(uid: 'B');

  test('로그인하면 서버에 저장된 카테고리를 불러와 그린다 + 사용자 문서 생성', () async {
    final remote = _FakeRemote({'A': {LocalStoreKeys.categories: _catA}});
    final c = _container(InMemoryLocalStore(), remote);
    expect(c.read(categoryListProvider), isEmpty);

    await c.read(userSessionProvider.notifier).onAuthChanged(a);

    expect(remote.users, contains('A'));
    expect(c.read(categoryListProvider).single.name, 'A의 목표');
  });

  test('새 계정은 로그인 전 기기 데이터를 계정으로 옮기고, 다른 계정이 물려받지 않는다', () async {
    final base = InMemoryLocalStore({LocalStoreKeys.categories: _catA});
    final remote = _FakeRemote();
    final c = _container(base, remote);

    await c.read(userSessionProvider.notifier).onAuthChanged(a);
    expect(c.read(categoryListProvider).single.name, 'A의 목표');
    expect(remote.data['A']![LocalStoreKeys.categories], _catA);

    await c.read(userSessionProvider.notifier).onAuthChanged(null); // 로그아웃
    expect(c.read(categoryListProvider), isEmpty);

    await c.read(userSessionProvider.notifier).onAuthChanged(b); // 다른 계정
    expect(c.read(categoryListProvider), isEmpty);
  });

  test('변경은 서버에도 저장되고, 다른 기기(빈 캐시)에서 로그인하면 그대로 복원된다', () async {
    final remote = _FakeRemote();
    final c1 = _container(InMemoryLocalStore(), remote);
    await c1.read(userSessionProvider.notifier).onAuthChanged(a);
    c1.read(categoryListProvider.notifier).addCategory(
        categoryKey: 'goal', name: '새 목표', emoji: '🎯', colorHex: '#4F46E5');
    await Future<void>.delayed(Duration.zero);
    expect(remote.data['A']![LocalStoreKeys.categories], contains('새 목표'));

    final c2 = _container(InMemoryLocalStore(), remote); // 다른 기기
    await c2.read(userSessionProvider.notifier).onAuthChanged(a);
    expect(c2.read(categoryListProvider).single.name, '새 목표');
  });

  test('오프라인 첫 로그인이면 서버 데이터를 덮어쓰지 않도록 게스트 범위로 둔다', () async {
    final remote = _FakeRemote({'A': {LocalStoreKeys.categories: _catA}})..failLoad = true;
    final c = _container(InMemoryLocalStore(), remote);

    await c.read(userSessionProvider.notifier).onAuthChanged(a);

    expect(c.read(userSessionProvider).uid, isNull);
    c.read(categoryListProvider.notifier).addCategory(
        categoryKey: 'goal', name: '오프라인', emoji: '🎯', colorHex: '#4F46E5');
    await Future<void>.delayed(Duration.zero);
    expect(remote.data['A']![LocalStoreKeys.categories], _catA, reason: '서버 값 유지');
  });
}
