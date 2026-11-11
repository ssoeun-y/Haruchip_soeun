import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// 구글 소셜 로그인 담당 서비스 (CLAUDE.md §1 — 로그인 전체는 도메인 담당).
///
/// 웹(`kIsWeb`)에서는 `google_sign_in` 패키지를 아예 쓰지 않는다 — Firebase가
/// 제공하는 `signInWithPopup`이 브라우저 팝업으로 구글 계정 선택까지
/// 알아서 처리해주기 때문에, 웹 전용 OAuth 클라이언트 등록/CORS 설정 없이
/// 훨씬 단순하게 동작한다. 모바일(iOS/Android)만 `google_sign_in`의 네이티브
/// 흐름을 탄다.
///
/// `google_sign_in` v7 API는 싱글턴 [GoogleSignIn.instance]를 쓰기 전에
/// [GoogleSignIn.initialize]를 **정확히 한 번** 호출해 완료를 기다려야
/// 한다 — 이걸 빼먹으면 버튼을 눌러도 아무 반응 없이 조용히 실패한다
/// (온보딩 로그인 화면이 스텁일 때 보이던 "로그인 창 자체가 안 뜬다"
/// 증상의 원인).
///
/// [_serverClientId]는 `android/app/google-services.json`의
/// `client_type: 3`(웹) OAuth 클라이언트 ID다. Android에서 Firebase가
/// 검증할 수 있는 ID 토큰을 받으려면 필수 — 안드로이드/iOS 전용 클라이언트
/// ID는 google-services.json / GoogleService-Info.plist에서 플랫폼이
/// 자동으로 읽으므로 여기서 별도로 넘기지 않는다.
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  static const _serverClientId =
      '932846129523-thk0m57ug48ff3hbn5necvd78eqqpbu9.apps.googleusercontent.com';

  Future<void>? _initFuture;

  Future<void> _ensureInitialized() {
    // initialize()는 앱 생애주기 동안 한 번만 호출되어야 하므로 Future를
    // 캐싱해 중복 초기화를 막는다. (웹에서는 signIn()이 이 메서드를 아예
    // 호출하지 않는다.)
    return _initFuture ??= GoogleSignIn.instance.initialize(
      serverClientId: _serverClientId,
    );
  }

  /// 구글 계정 선택 → 인증 창을 띄우고, 성공하면 Firebase로 로그인까지
  /// 완료한다. 사용자가 계정 선택 창에서 취소하면 [GoogleSignInException]
  /// (`GoogleSignInExceptionCode.canceled`, 웹은 [fb_auth.FirebaseAuthException]
  /// `popup-closed-by-user`)이 던져진다 — 호출부에서 취소와 그 외 실패를
  /// 구분해 처리할 것.
  Future<fb_auth.UserCredential> signIn() async {
    if (kIsWeb) {
      final googleProvider = fb_auth.GoogleAuthProvider();
      return fb_auth.FirebaseAuth.instance.signInWithPopup(googleProvider);
    }

    await _ensureInitialized();

    final GoogleSignInAccount account =
        await GoogleSignIn.instance.authenticate();

    final String? idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError(
        '구글 로그인에서 idToken을 받지 못했습니다 (serverClientId 설정을 확인하세요).',
      );
    }

    final credential = fb_auth.GoogleAuthProvider.credential(
      idToken: idToken,
    );
    return fb_auth.FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    // 웹은 signInWithPopup만 썼을 뿐 별도의 google_sign_in 로컬 세션이
    // 없다 — Firebase 세션 해제는 [AppleAuthService.signOut]과 동일하게
    // 상위 인증 화면이 `FirebaseAuth.instance.signOut()`으로 공통 처리한다.
    if (kIsWeb) return;
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }

  /// 계정 즉시 탈퇴 및 삭제 파이프라인
  Future<void> deleteAccount() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.delete();
    }
    await signOut();
  }
}
