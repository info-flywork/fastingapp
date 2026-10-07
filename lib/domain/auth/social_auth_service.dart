import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:fastingapp/domain/auth/auth_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Firebase'den alınan kimlik: backend `POST /auth/register` bunu doğrular.
final class SocialCredential {
  const SocialCredential({
    required this.idToken,
    this.givenName,
    this.familyName,
  });

  /// Firebase ID token (Google/Apple token'ı değil).
  final String idToken;

  /// Apple adı yalnızca ilk girişte gelir.
  final String? givenName;
  final String? familyName;
}

/// Apple / Google girişi Firebase Auth üzerinden. Backend yalnızca Firebase ID
/// token'ı görür. (backend doküman 06 §2.1)
final class SocialAuthService {
  SocialAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Firebase projesinin web OAuth istemcisi; Android'de ID token için şart.
  static const _googleServerClientId =
      '247049126883-pqfhq0rr235jotcofp5dqc9j2l6g5l3k'
      '.apps.googleusercontent.com';

  Future<void>? _googleInit;

  Future<SocialCredential> signInWithGoogle() async {
    await (_googleInit ??= _googleSignIn.initialize(
      serverClientId: _googleServerClientId,
    ));
    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelledException();
      }
      rethrow;
    }
    final googleIdToken = account.authentication.idToken;
    if (googleIdToken == null) {
      throw const AuthException('Google kimlik bilgisi alınamadı.');
    }
    final result = await _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: googleIdToken),
    );
    return SocialCredential(idToken: await _idToken(result));
  }

  Future<SocialCredential> signInWithApple() async {
    final rawNonce = _nonce();
    final AuthorizationCredentialAppleID apple;
    try {
      apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthCancelledException();
      }
      rethrow;
    }
    final appleIdToken = apple.identityToken;
    if (appleIdToken == null) {
      throw const AuthException('Apple kimlik bilgisi alınamadı.');
    }
    final result = await _firebaseAuth.signInWithCredential(
      OAuthProvider('apple.com').credential(
        idToken: appleIdToken,
        rawNonce: rawNonce,
        accessToken: apple.authorizationCode,
      ),
    );
    return SocialCredential(
      idToken: await _idToken(result),
      givenName: apple.givenName,
      familyName: apple.familyName,
    );
  }

  /// Hesap silmeden önce Apple token'ını iptal eder (App Store 5.1.1(v)).
  /// Apple ile girilmediyse bir şey yapmaz. Kullanıcı Apple penceresini
  /// kapatırsa [AuthCancelledException].
  Future<void> revokeAppleIfLinked() async {
    final user = _firebaseAuth.currentUser;
    final linked =
        user?.providerData.any((p) => p.providerId == 'apple.com') ?? false;
    if (!linked) return;
    final AuthorizationCredentialAppleID apple;
    try {
      apple = await SignInWithApple.getAppleIDCredential(scopes: const []);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthCancelledException();
      }
      rethrow;
    }
    await _firebaseAuth.revokeTokenWithAuthorizationCode(
      apple.authorizationCode,
    );
  }

  /// Backend oturumu kapanınca Firebase/Google oturumu da kapanır.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (_googleInit != null) await _googleSignIn.signOut();
  }

  Future<String> _idToken(UserCredential result) async {
    final token = await result.user?.getIdToken();
    if (token == null) throw AuthException.emptyResponse();
    return token;
  }

  static String _nonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
