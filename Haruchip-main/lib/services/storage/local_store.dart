import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 재시작 후에도 남아야 하는 로컬 데이터 저장소.
///
/// 아직 Firestore 미연동 단계(CLAUDE.md §4)라 카테고리/일정/휴지통 상태를
/// 기기 로컬에 JSON 문자열로 보관한다. 읽기는 동기(앱 시작 시 한 번 로드한
/// 캐시), 쓰기는 비동기 fire-and-forget이다 — Riverpod Notifier의 `build()`
/// 가 동기라서 이 형태가 가장 단순하다.
///
/// 토큰·시크릿은 여기 저장하지 않는다(§9-7 — flutter_secure_storage 대상).
abstract class LocalStore {
  String? readString(String key);
  Future<void> writeString(String key, String value);
  Future<void> remove(String key);
}

/// 테스트 및 [localStoreProvider] 기본값 — 프로세스 메모리에만 보관한다.
class InMemoryLocalStore implements LocalStore {
  InMemoryLocalStore([Map<String, String>? initial]) : _data = {...?initial};

  final Map<String, String> _data;

  @override
  String? readString(String key) => _data[key];

  @override
  Future<void> writeString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }
}

/// 실제 앱에서 쓰는 `shared_preferences` 기반 구현. `main()`에서
/// [SharedPreferences.getInstance]로 미리 로드한 인스턴스를 받는다.
class SharedPrefsLocalStore implements LocalStore {
  SharedPrefsLocalStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? readString(String key) => _prefs.getString(key);

  @override
  Future<void> writeString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// 기본값은 메모리 저장소 — 기존 테스트처럼 override 없이 만든
/// `ProviderScope`에서도 그대로 동작한다. 앱은 `main()`에서
/// [SharedPrefsLocalStore]로 override 한다.
final localStoreProvider = Provider<LocalStore>((ref) => InMemoryLocalStore());

/// 저장 키 — 스키마가 바뀌면 버전 접미사를 올린다.
abstract final class LocalStoreKeys {
  static const categories = 'haruchip.categories.v1';
  static const plans = 'haruchip.plans.v1';
  static const trash = 'haruchip.trash.v1';
  static const couple = 'haruchip.couple.v1';

  /// 계정에 붙여 보관(동기화)하는 모든 키.
  static const all = [categories, plans, trash, couple];
}

/// [key]에 저장된 JSON 배열을 [fromJson]으로 복원한다. 저장된 값이 없으면
/// null(= 첫 실행, 호출부가 기본값을 쓴다). 손상된 항목은 건너뛰고, 배열
/// 자체가 깨졌으면 null을 돌려 기본값으로 시작한다 — 앱이 죽는 것보다 낫다.
List<T>? readJsonList<T>(
  LocalStore store,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  final raw = store.readString(key);
  if (raw == null) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    final result = <T>[];
    for (final e in decoded) {
      if (e is! Map) continue;
      try {
        result.add(fromJson(Map<String, dynamic>.from(e)));
      } catch (err) {
        developer.log('skip corrupt entry in $key: $err', name: 'Haruchip.LocalStore');
      }
    }
    return result;
  } catch (err) {
    developer.log('corrupt list in $key: $err', name: 'Haruchip.LocalStore');
    return null;
  }
}

/// [items]를 JSON 배열로 [key]에 저장한다. metadata 안에 DateTime 등
/// JSON 비호환 값이 섞여 있어도 문자열로 바꿔 저장이 실패하지 않게 한다.
Future<void> writeJsonList<T>(
  LocalStore store,
  String key,
  List<T> items,
  Map<String, dynamic> Function(T) toJson,
) {
  final encoded = jsonEncode(
    items.map(toJson).toList(),
    toEncodable: (Object? value) {
      if (value is DateTime) return value.toIso8601String();
      try {
        return (value as dynamic).toJson();
      } catch (_) {
        return value.toString();
      }
    },
  );
  return store.writeString(key, encoded);
}
