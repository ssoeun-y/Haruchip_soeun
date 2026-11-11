import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// 애플 소셜 로그인 담당 서비스 (CLAUDE.md §1 — 로그인 전체는 도메인 담당).
///
/// [GoogleAuthService]와 같은 자리(`lib/services/auth/`)에 둔다. 애플은
/// idToken 재전송(replay) 공격을 막기 위해 요청 시 보낸 nonce의 SHA-256
/// 해시가 응답 토큰에 그대로 실려오는지 Firebase가 검증하는 구조라, 매
/// 로그인 시도마다 원본(raw) nonce를 만들고 해시해서 같이 보내야 한다
/// (CLAUDE.md §9 — Cryptographic Failures 대응).
///
/// iOS/macOS는 OS 네이티브 "Apple로 로그인" 시트를 띄운다 — 이걸 쓰려면
/// Xcode에서 "Sign in with Apple" capability가 켜져 있어야 하고(이미
/// `ios/Runner/Runner.entitlements`, `macos/Runner/*.entitlements`에
/// `com.apple.developer.applesignin`으로 반영해둠), Apple Developer
/// 계정에 App ID 단위로도 이 capability가 켜져 있어야 한다 — 세부 절차는
/// PR 설명/작업 요약 참고.
///
/// Android는 애플이 네이티브 SDK를 제공하지 않아 웹 기반 OAuth(리다이렉트)
/// 흐름을 쓴다. 이 흐름은 Apple Developer의 별도 "Services ID" +
/// 리다이렉트로 쓸 호스팅 URL이 있어야 동작한다 — 아직 그 값이 없어서
/// [webAuthenticationOptions]는 비워뒀다. 가입/발급 후
/// `_androidWebAuthOptions`를 채우면 Android도 동작한다. 그 전까지
/// Android에서 이 메서드를 호출하면 `sign_in_with_apple` 패키지가 명확한
/// 예외를 던진다 (조용히 실패하지 않음).
///
/// 웹(`kIsWeb`)은 `sign_in_with_apple` 패키지도, 위 Services ID/리다이렉트
/// 설정도 거치지 않는다 — [GoogleAuthService]와 같은 이유로 Firebase의
/// `signInWithPopup`을 직접 써서 브라우저 팝업으로 처리한다. 이쪽은 Apple
/// Developer의 Services ID 설정(§Firebase 콘솔 Apple 제공자의 "OAuth 코드
/// 흐름 구성")이 이미 돼 있어야 팝업이 뜬다 — 그건 플랫폼 공통으로 필요한
/// 설정이라 이 파일과는 무관하다.
class AppleAuthService {
  AppleAuthService._();

  static final AppleAuthService instance = AppleAuthService._();

  /// TODO(Android): Apple Developer → Services ID 발급 + 리다이렉트
  /// 페이지 준비 후 채운다. (clientId: Services ID, redirectUri: 리다이렉트
  /// 페이지 URL)
  static const WebAuthenticationOptions? _androidWebAuthOptions = null;

  /// 애플 로그인 시트를 띄우고, 성공하면 Firebase로 로그인까지 완료한다.
  /// 사용자가 취소하면 [SignInWithAppleAuthorizationException]
  /// (`AuthorizationErrorCode.canceled`)이 던져진다 — 호출부에서
  /// try/catch로 "취소"와 "그 외 실패"를 구분해 처리할 것.
  Future<fb_auth.UserCredential> signIn() async {
    if (kIsWeb) {
      final appleProvider = fb_auth.OAuthProvider('apple.com')
        ..addScope('email')
        ..addScope('name');
      return fb_auth.FirebaseAuth.instance.signInWithPopup(appleProvider);
    }

    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    if (defaultTargetPlatform == TargetPlatform.android &&
        _androidWebAuthOptions == null) {
      throw StateError(
        'Android 애플 로그인은 Apple Developer Services ID / 리다이렉트 URL이 '
        '설정되기 전까지 사용할 수 없습니다. AppleAuthService._androidWebAuthOptions '
        '참고.',
      );
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
      webAuthenticationOptions: _androidWebAuthOptions,
    );

    final oauthCredential = fb_auth.OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential = await fb_auth.FirebaseAuth.instance
        .signInWithCredential(oauthCredential);

    // 애플은 이름(givenName/familyName)을 최초 로그인 시 딱 한 번만
    // 내려준다 — Firebase 계정에 displayName이 아직 없으면 지금 채워둔다.
    final user = userCredential.user;
    final hasName =
        appleCredential.givenName != null || appleCredential.familyName != null;
    if (user != null &&
        (user.displayName == null || user.displayName!.isEmpty) &&
        hasName) {
      final fullName = [
        appleCredential.familyName,
        appleCredential.givenName,
      ].whereType<String>().join();
      if (fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
      }
    }

    return userCredential;
  }

  Future<void> signOut() {
    // 애플은 클라이언트 SDK에 별도 signOut API가 없다 — Firebase 세션만
    // 끊으면 된다 (FirebaseAuth.instance.signOut()은 상위 인증 화면에서
    // 공통으로 호출).
    return Future.value();
  }

  /// Apple 심사 기준 준수를 위한 계정 탈퇴/삭제 파이프라인 (Guideline 5.1.1(v))
  Future<void> deleteAccount() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
